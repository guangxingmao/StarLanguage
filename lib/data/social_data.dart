import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_proxy.dart';
import 'profile.dart';

/// 个人圈动态项（来自 GET /social/feed）
class FeedItem {
  const FeedItem({
    required this.content,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String content;
  final int likeCount;
  final int commentCount;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      content: json['content'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 个人圈数据：从 GET /social/feed 拉取
class SocialFeedRepository {
  static Future<List<FeedItem>> load() async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/social/feed'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data is! List) return [];
      return (data as List)
          .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
