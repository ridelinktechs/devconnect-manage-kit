import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Cached host + the server's stable machineId for identity verification.
class _CachedHost {
  final String host;
  final String machineId;
  const _CachedHost(this.host, this.machineId);
}

/// Hands out dart:io's own HttpClient, whatever overrides are installed.
class _NoHttpOverrides extends HttpOverrides {}

/// UDP discovery port — server broadcasts beacons here.
const int _discoveryPort = 41234;

/// Opens DevConnect's own sockets past any HttpOverrides: through
/// `DevConnectHttpOverrides` they would show up as the app's requests.
final wsHttpClient =
    HttpOverrides.runWithHttpOverrides(HttpClient.new, _NoHttpOverrides());

/// XOR key for obfuscating cached data.
const String _cacheKey = 'DcN3t\$ecR7!';

/// Cache file for last known server host.
File get _cacheFile => File('${Directory.systemTemp.path}/.dc_session');

/// XOR encrypt/decrypt with key.
String _xorCipher(String input, String key) {
  final output = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    output.writeCharCode(input.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
  }
  return output.toString();
}

/// Save discovered server host to cache file (encrypted), keyed by host +
/// machineId so stale entries from a different desktop can be invalidated.
Future<void> saveHostCache(String host, int port, String? machineId) async {
  try {
    final plain = jsonEncode({
      'h': host,
      'p': port,
      't': DateTime.now().millisecondsSinceEpoch,
      if (machineId != null) 'm': machineId,
    });
    final encrypted = base64Encode(utf8.encode(_xorCipher(plain, _cacheKey)));
    await _cacheFile.writeAsString(encrypted);
  } catch (_) {}
}

/// Delete cached host entry. Used when verification fails — so the next
/// connect falls through to fresh discovery rather than reusing the
/// stale entry.
Future<void> _clearHostCache() async {
  try {
    if (await _cacheFile.exists()) await _cacheFile.delete();
  } catch (_) {}
}

/// Read cached server host (decrypted). Returns null if expired, missing,
/// or if the cache doesn't carry a machineId (legacy entries are ignored
/// since they can't be verified).
Future<_CachedHost?> _readHostCache(int port) async {
  try {
    if (!await _cacheFile.exists()) return null;
    final encrypted = await _cacheFile.readAsString();
    final decrypted =
        _xorCipher(utf8.decode(base64Decode(encrypted)), _cacheKey);
    final data = jsonDecode(decrypted) as Map<String, dynamic>;
    // Expire after 24 hours
    final cachedTime = data['t'] as int? ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - cachedTime > 24 * 3600000) {
      return null;
    }
    if (data['p'] != port) return null;
    final host = data['h'] as String?;
    final machineId = data['m'] as String?;
    // Require machineId — legacy caches without it cannot be verified and
    // would re-introduce the simulator/device-swap bug we are fixing.
    if (host == null || machineId == null || machineId.isEmpty) return null;
    return _CachedHost(host, machineId);
  } catch (_) {}
  return null;
}

/// Verify a cached host by opening a short-lived WebSocket and checking
/// that the server announces the machineId we cached. This prevents the
/// case where the cached IP now points at a different device or another
/// service that just happens to listen on the same port.
///
/// Returns true only when the server's `server:hello.machineId` matches
/// [expectedMachineId]; false on connect failure, timeout, or mismatch.
Future<bool> _verifyCachedHost(
    String host, int port, String expectedMachineId) async {
  WebSocket? probe;
  try {
    probe =
        await WebSocket.connect('ws://$host:$port', customClient: wsHttpClient)
            .timeout(const Duration(milliseconds: 1500));

    final helloCompleter = Completer<String?>();
    final sub = probe.listen(
      (data) {
        if (helloCompleter.isCompleted) return;
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          if (msg['type'] == 'server:hello') {
            final payload = msg['payload'] as Map<String, dynamic>?;
            helloCompleter.complete(payload?['machineId'] as String?);
          }
        } catch (_) {}
      },
      onError: (_) {
        if (!helloCompleter.isCompleted) helloCompleter.complete(null);
      },
      onDone: () {
        if (!helloCompleter.isCompleted) helloCompleter.complete(null);
      },
      cancelOnError: true,
    );

    final announcedId =
        await helloCompleter.future.timeout(const Duration(milliseconds: 1500));
    unawaited(sub.cancel());
    return announcedId != null && announcedId == expectedMachineId;
  } catch (_) {
    return false;
  } finally {
    try {
      await probe?.close();
    } catch (_) {}
  }
}

/// Auto-detect the DevConnect desktop host IP.
///
/// 0. Try cached host from last session (instant)
/// 1. Race: UDP beacon vs known emulator/USB addresses (parallel)
/// 2. Scan local subnet (real device WiFi)
/// 3. Scan common subnets as fallback
Future<String> autoDetectHost(int port) async {
  // 0. Try cached host from previous session (instant reconnect).
  //    We verify the server's stable machineId matches what we cached —
  //    this catches the case where the cached IP now points at a
  //    different device (e.g. switched from iOS Simulator to a real
  //    iPhone, or back, after the Mac's address changed).
  final cached = await _readHostCache(port);
  if (cached != null) {
    if (await _verifyCachedHost(cached.host, port, cached.machineId)) {
      return cached.host;
    }
    // Stale or wrong machine — invalidate so the next discovery wins.
    await _clearHostCache();
  }

  // 1. Race: UDP beacon + known hosts in parallel
  //    USB (adb reverse) → localhost/10.0.2.2 responds fast
  //    WiFi → UDP beacon responds fast
  //    Whoever wins first, we use it.
  final knownHosts = Platform.isAndroid
      ? ['10.0.2.2', '10.0.3.2', 'localhost', '127.0.0.1']
      : ['localhost', '127.0.0.1'];

  final raceFutures = <Future<String?>>[];

  // UDP beacon listener
  raceFutures.add(_listenForBeacon(port));

  // Known hosts (try all in parallel)
  for (final host in knownHosts) {
    raceFutures.add(
      _tryHost(host, port, 800).then((ok) => ok ? host : null),
    );
  }

  // Wait for first non-null result, or all to complete
  final raceResult = await _firstNonNull(raceFutures);
  if (raceResult != null) {
    await saveHostCache(raceResult, port, null);
    return raceResult;
  }

  // 2. Scan device's own subnet (real device on same WiFi)
  try {
    final interfaces = await NetworkInterface.list();
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
            final found = await _scanSubnet(subnet, port);
            if (found != null) {
              await saveHostCache(found, port, null);
              return found;
            }
          }
        }
      }
    }
  } catch (_) {}

  // 3. Scan common subnets as fallback
  for (final subnet in [
    '192.168.1',
    '192.168.0',
    '192.168.2',
    '10.0.0',
    '10.0.1',
    '172.16.0'
  ]) {
    final found = await _scanSubnet(subnet, port);
    if (found != null) {
      await saveHostCache(found, port, null);
      return found;
    }
  }

  // Fallback
  return Platform.isAndroid ? '10.0.2.2' : 'localhost';
}

/// Returns the first non-null result from a list of futures.
/// Waits for all to complete; returns first non-null in order.
Future<String?> _firstNonNull(List<Future<String?>> futures) async {
  final completer = Completer<String?>();
  int remaining = futures.length;

  for (final future in futures) {
    future.then((value) {
      if (value != null && !completer.isCompleted) {
        completer.complete(value);
      } else {
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      }
    }).catchError((_) {
      remaining--;
      if (remaining == 0 && !completer.isCompleted) {
        completer.complete(null);
      }
    });
  }

  return completer.future;
}

/// Listen for a UDP beacon from the DevConnect server.
/// Server broadcasts {"type":"devconnect_beacon","port":9090,...}
/// every 2 seconds. We listen for up to 3 seconds.
Future<String?> _listenForBeacon(int expectedPort) async {
  RawDatagramSocket? udp;
  try {
    udp = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _discoveryPort,
      reuseAddress: true,
    );

    final completer = Completer<String?>();
    StreamSubscription<RawSocketEvent>? subscription;

    final timer = Timer(const Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.complete(null);
      }
    });

    subscription = udp.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = udp!.receive();
        if (datagram != null && !completer.isCompleted) {
          try {
            final data = jsonDecode(utf8.decode(datagram.data));
            if (data['type'] == 'devconnect_beacon') {
              final serverPort = data['port'] as int?;
              if (serverPort == expectedPort) {
                timer.cancel();
                subscription?.cancel();
                completer.complete(datagram.address.address);
              }
            }
          } catch (_) {}
        }
      }
    });

    return await completer.future;
  } catch (_) {
    return null;
  } finally {
    udp?.close();
  }
}

/// Try connecting to a single host with timeout.
Future<bool> _tryHost(String host, int port, int timeoutMs) async {
  try {
    final socket = await Socket.connect(host, port,
        timeout: Duration(milliseconds: timeoutMs));
    await socket.close();
    return true;
  } catch (_) {
    return false;
  }
}

/// Scan a subnet (x.x.x.1 through x.x.x.30) in parallel.
/// Returns first host that responds, or null.
Future<String?> _scanSubnet(String subnet, int port) async {
  final futures = <Future<String?>>[];
  for (int i = 1; i <= 30; i++) {
    final host = '$subnet.$i';
    futures.add(
      _tryHost(host, port, 400).then((ok) => ok ? host : null),
    );
  }
  final results = await Future.wait(futures);
  for (final result in results) {
    if (result != null) return result;
  }
  return null;
}
