import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'duel_connection.dart';

class LanDuelHost {
  ServerSocket? _server;
  Socket? _client;

  Future<int> start({int port = 36666}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    return _server!.port;
  }

  Future<LanDuelConnection> waitForClient() async {
    if (_server == null) {
      throw StateError('Server not started');
    }
    final completer = Completer<Socket>();
    StreamSubscription<Socket>? sub;
    sub = _server!.listen((Socket socket) {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.complete(socket);
      }
    });
    _client = await completer.future;
    _client!.setOption(SocketOption.tcpNoDelay, true);
    return LanDuelConnection._(_client!);
  }

  Future<List<String>> localIps() async {
    final ips = <String>[];
    final ifaces = await NetworkInterface.list();
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          ips.add(addr.address);
        }
      }
    }
    return ips;
  }

  void close() {
    _client?.destroy();
    _server?.close();
  }
}

class LanDuelClient {
  Future<LanDuelConnection> connect(String host, {int port = 36666}) async {
    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 6));
    socket.setOption(SocketOption.tcpNoDelay, true);
    return LanDuelConnection._(socket);
  }
}

class LanDuelConnection implements DuelConnection {
  LanDuelConnection._(this._socket) {
    _subscription = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      try {
        final data = jsonDecode(line) as Map<String, dynamic>;
        _controller.add(data);
      } catch (_) {}
    });
  }

  final Socket _socket;
  late final StreamSubscription<String> _subscription;
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  @override
  void send(Map<String, dynamic> data) {
    _socket.write('${jsonEncode(data)}\n');
  }

  @override
  void close() {
    _subscription.cancel();
    _controller.close();
    _socket.destroy();
  }
}
