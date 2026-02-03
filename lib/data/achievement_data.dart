import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_proxy.dart';
import 'profile.dart';

/// 单条成就定义（来自 GET /achievements）
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconKey = 'star',
    this.category = 'arena',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final String category;
  final int sortOrder;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'star',
      category: json['category'] as String? ?? 'arena',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 成就墙数据：全部成就 + 当前用户已解锁 id 列表
class AchievementWallData {
  const AchievementWallData({
    required this.achievements,
    required this.unlockedIds,
  });

  final List<Achievement> achievements;
  final List<String> unlockedIds;

  bool isUnlocked(String achievementId) => unlockedIds.contains(achievementId);
}

/// 成就数据仓库：GET /achievements、GET /user/achievements
class AchievementRepository {
  static Future<List<Achievement>> loadAll() async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    try {
      final res = await http.get(Uri.parse('$baseUrl/achievements'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data is! List) return [];
      return (data as List)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> loadUnlockedIds() async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/achievements'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final list = data?['unlockedIds'];
      if (list is! List) return [];
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// 一次拉取成就墙所需数据
  static Future<AchievementWallData> loadWall() async {
    final all = await loadAll();
    final ids = await loadUnlockedIds();
    return AchievementWallData(achievements: all, unlockedIds: ids);
  }
}
