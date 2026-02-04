import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiProxyStore {
  static const _urlKey = 'ai_proxy_url';
  /// 默认连 backend 单服务（API + AI 对话统一 3001）
  static final ValueNotifier<String> url =
      ValueNotifier<String>('http://localhost:3001');

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      url.value = prefs.getString(_urlKey) ?? url.value;
    } catch (_) {}
  }

  static Future<void> setUrl(String value) async {
    url.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_urlKey, value);
    } catch (_) {}
  }
}
