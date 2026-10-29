import 'dart:async';

import 'package:devconnect_manage_tool/models/device_info.dart';
import 'package:devconnect_manage_tool/server/protocol/dc_message.dart';
import 'package:devconnect_manage_tool/server/ws_connection.dart';
import 'package:devconnect_manage_tool/server/ws_server.dart';

/// In-memory [WsServer]: [emit] plays a device message into the handler,
/// [connect] a device connecting; [sent] / [sentTo] record what the desktop
/// sent and to which device.
class FakeWsServer implements WsServer {
  final _messages = StreamController<DCMessage>.broadcast(sync: true);
  final _connections = StreamController<DeviceInfo>.broadcast(sync: true);
  final sent = <DCMessage>[];
  final sentTo = <String>[];

  void emit(DCMessage m) => _messages.add(m);
  void connect(DeviceInfo device) => _connections.add(device);

  @override
  Stream<DCMessage> get onMessage => _messages.stream;
  @override
  Stream<DeviceInfo> get onConnection => _connections.stream;
  @override
  Stream<String> get onDisconnection => const Stream.empty();
  @override
  Map<String, WsConnection> get connections => const {};
  @override
  void sendToDevice(String deviceId, DCMessage message) {
    sentTo.add(deviceId);
    sent.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A device → desktop message from device `dev`.
DCMessage deviceMessage(
  String type,
  Map<String, dynamic> payload, {
  String? correlationId,
}) => DCMessage(
  id: 'x',
  type: type,
  deviceId: 'dev',
  timestamp: 0,
  payload: payload,
  correlationId: correlationId,
);
