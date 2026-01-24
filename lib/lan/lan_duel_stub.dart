import 'duel_connection.dart';

class LanDuelHost {
  Future<int> start({int port = 36666}) async {
    throw UnsupportedError('LAN duel not supported on this platform.');
  }

  Future<LanDuelConnection> waitForClient() async {
    throw UnsupportedError('LAN duel not supported on this platform.');
  }

  Future<List<String>> localIps() async {
    return const [];
  }

  void close() {}
}

class LanDuelClient {
  Future<LanDuelConnection> connect(String host, {int port = 36666}) async {
    throw UnsupportedError('LAN duel not supported on this platform.');
  }
}

class LanDuelConnection implements DuelConnection {
  @override
  Stream<Map<String, dynamic>> get messages => const Stream.empty();
  @override
  void send(Map<String, dynamic> data) {}
  @override
  void close() {}
}
