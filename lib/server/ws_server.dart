import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/ws_constants.dart';
import '../models/device_info.dart';
import 'protocol/dc_message.dart';
import 'ws_connection.dart';

typedef MessageCallback = void Function(DCMessage message);

/// UDP discovery port — clients listen here for server beacons.
const int discoveryPort = 41234;

class WsServer {
  HttpServer? _server;
  final Map<String, WsConnection> _connections = {};
  final _uuid = const Uuid();

  final _messageController = StreamController<DCMessage>.broadcast();
  final _connectionController = StreamController<DeviceInfo>.broadcast();
  final _disconnectionController = StreamController<String>.broadcast();

  Stream<DCMessage> get onMessage => _messageController.stream;
  Stream<DeviceInfo> get onConnection => _connectionController.stream;
  Stream<String> get onDisconnection => _disconnectionController.stream;

  Map<String, WsConnection> get connections => Map.unmodifiable(_connections);
  bool get isRunning => _server != null;
  int get port => _server?.port ?? 0;

  // UDP broadcast beacon
  RawDatagramSocket? _udpSocket;
  Timer? _beaconTimer;

  Future<void> start({int port = AppConstants.defaultPort}) async {
    if (_server != null) return;

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest);

    // Start UDP broadcast beacon so clients can auto-discover us
    _startBeacon(port);
  }

  Future<void> stop() async {
    _stopBeacon();
    for (final conn in _connections.values) {
      await conn.close();
    }
    _connections.clear();
    await _server?.close(force: true);
    _server = null;
  }

  /// Broadcast a UDP beacon every 2 seconds on all network interfaces.
  /// Clients listen on [discoveryPort] and extract server IP from datagram source.
  void _startBeacon(int wsPort) async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // OS picks an ephemeral port for sending
      );
      _udpSocket!.broadcastEnabled = true;

      final beacon = utf8.encode(jsonEncode({
        'type': 'devconnect_beacon',
        'port': wsPort,
        'app': AppConstants.appName,
        'version': AppConstants.appVersion,
      }));

      _beaconTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        try {
          // Broadcast to 255.255.255.255 (limited broadcast)
          _udpSocket?.send(
            beacon,
            InternetAddress('255.255.255.255'),
            discoveryPort,
          );

          // Also send to each subnet broadcast (x.x.x.255) for networks
          // that block limited broadcast
          _sendSubnetBroadcasts(beacon);
        } catch (_) {}
      });
    } catch (_) {
      // UDP broadcast not available — clients fall back to subnet scanning
    }
  }

  void _sendSubnetBroadcasts(List<int> beacon) async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnetBroadcast =
                  '${parts[0]}.${parts[1]}.${parts[2]}.255';
              _udpSocket?.send(
                beacon,
                InternetAddress(subnetBroadcast),
                discoveryPort,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  void _stopBeacon() {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
  }

  void sendToDevice(String deviceId, DCMessage message) {
    final conn = _connections[deviceId];
    if (conn != null) {
      conn.send(message);
    }
  }

  void broadcastMessage(DCMessage message) {
    for (final conn in _connections.values) {
      conn.send(message);
    }
  }

  void _handleRequest(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final remoteIp = request.connectionInfo?.remoteAddress.address;
      final socket = await WebSocketTransformer.upgrade(
        request,
        compression: CompressionOptions.compressionOff,
      );
      _handleWebSocket(socket, remoteIp);
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'app': AppConstants.appName,
          'version': AppConstants.appVersion,
          'connections': _connections.length,
        }));
      await request.response.close();
    }
  }

  void _handleWebSocket(WebSocket socket, String? clientIp) {
    // Send hello
    final helloMsg = DCMessage(
      id: _uuid.v4(),
      type: WsMessageTypes.serverHello,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'version': AppConstants.appVersion},
    );
    socket.add(jsonEncode(helloMsg.toJson()));

    // Listen for messages
    socket.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final message = DCMessage.fromJson(json);

          if (message.type == WsMessageTypes.clientHandshake) {
            _handleHandshake(socket, message, clientIp);
          } else {
            _messageController.add(message);
          }
        } catch (_) {
          // ignore malformed messages
        }
      },
      onDone: () {
        _handleDisconnect(socket);
      },
      onError: (error) {
        _handleDisconnect(socket);
      },
    );
  }

  /// Track sockets that already completed handshake to prevent duplicates.
  final _handshookSockets = <WebSocket>{};

  void _handleHandshake(WebSocket socket, DCMessage message, String? clientIp) {
    // Guard: ignore duplicate handshake from the same socket
    if (_handshookSockets.contains(socket)) return;
    _handshookSockets.add(socket);

    final deviceInfo = DeviceInfo.fromJson(
      message.payload['deviceInfo'] as Map<String, dynamic>,
    );
    final deviceId = deviceInfo.deviceId;

    final connection = WsConnection(
      socket: socket,
      deviceInfo: deviceInfo.copyWith(
        connectedAt: DateTime.now(),
        clientIp: clientIp,
      ),
    );
    // If same deviceId reconnects (hot reload), close old socket
    final oldConn = _connections[deviceId];
    if (oldConn != null && oldConn.socket != socket) {
      try { oldConn.socket.close(); } catch (_) {}
    }

    // Fallback dedup: same clientIp + appName = same device (handles old SDK with random deviceId)
    if (clientIp != null) {
      final appName = deviceInfo.appName;
      final staleIds = <String>[];
      for (final entry in _connections.entries) {
        if (entry.key != deviceId &&
            entry.value.deviceInfo.clientIp == clientIp &&
            entry.value.deviceInfo.appName == appName &&
            entry.value.socket != socket) {
          staleIds.add(entry.key);
          try { entry.value.socket.close(); } catch (_) {}
        }
      }
      for (final id in staleIds) {
        _connections.remove(id);
        _disconnectionController.add(id);
      }
    }

    _connections[deviceId] = connection;

    // Send handshake ack
    final ack = DCMessage(
      id: _uuid.v4(),
      type: WsMessageTypes.serverHandshakeAck,
      deviceId: 'server',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'sessionId': _uuid.v4(), 'deviceId': deviceId},
    );
    socket.add(jsonEncode(ack.toJson()));

    _connectionController.add(connection.deviceInfo);
  }

  void _handleDisconnect(WebSocket socket) {
    _handshookSockets.remove(socket);
    String? disconnectedId;
    _connections.removeWhere((id, conn) {
      if (conn.socket == socket) {
        disconnectedId = id;
        return true;
      }
      return false;
    });
    if (disconnectedId != null) {
      _disconnectionController.add(disconnectedId!);
    }
  }

  void dispose() {
    _messageController.close();
    _connectionController.close();
    _disconnectionController.close();
    stop();
  }
}
