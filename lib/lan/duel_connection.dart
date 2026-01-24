abstract class DuelConnection {
  Stream<Map<String, dynamic>> get messages;
  void send(Map<String, dynamic> data);
  void close();
}
