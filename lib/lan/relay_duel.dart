import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'duel_connection.dart';

class RelayDuelConnection implements DuelConnection {
  RelayDuelConnection(this._channel) {
    _subscription = _channel.stream.listen((event) {
      try {
        final data = jsonDecode(event as String) as Map<String, dynamic>;
        _controller.add(data);
      } catch (_) {}
    });
  }

  final WebSocketChannel _channel;
  late final StreamSubscription _subscription;
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  @override
  void send(Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode(data));
  }

  @override
  void close() {
    _subscription.cancel();
    _controller.close();
    _channel.sink.close();
  }
}

class RelayDuelClient {
  Future<RelayDuelConnection> connect(String baseUrl) async {
    final wsUrl = _toWs(baseUrl);
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    return RelayDuelConnection(channel);
  }

  String _toWs(String baseUrl) {
    var url = baseUrl.trim();
    if (url.isEmpty) {
      url = 'http://localhost:3002';
    }
    if (!url.startsWith('http')) {
      url = 'http://$url';
    }
    url = url.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    if (!url.endsWith('/duel')) {
      if (url.endsWith('/')) {
        url = '${url}duel';
      } else {
        url = '$url/duel';
      }
    }
    return url;
  }
}
