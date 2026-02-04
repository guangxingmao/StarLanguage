import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ai_proxy.dart';
import 'demo_data.dart';
import 'profile.dart';

class ArenaStats {
  const ArenaStats({
    required this.totalScore,
    required this.totalCorrect,
    required this.matches,
    required this.maxStreak,
    required this.bestAccuracy,
    required this.topicBest,
  });

  final int totalScore;
  final int totalCorrect;
  final int matches;
  final int maxStreak;
  final double bestAccuracy;
  final Map<String, int> topicBest;

  static ArenaStats initial() {
    return const ArenaStats(
      totalScore: 0,
      totalCorrect: 0,
      matches: 0,
      maxStreak: 0,
      bestAccuracy: 0,
      topicBest: {},
    );
  }

  ArenaStats copyWith({
    int? totalScore,
    int? totalCorrect,
    int? matches,
    int? maxStreak,
    double? bestAccuracy,
    Map<String, int>? topicBest,
  }) {
    return ArenaStats(
      totalScore: totalScore ?? this.totalScore,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      matches: matches ?? this.matches,
      maxStreak: maxStreak ?? this.maxStreak,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      topicBest: topicBest ?? this.topicBest,
    );
  }
}

class ArenaStatsStore {
  static final ValueNotifier<ArenaStats> stats =
      ValueNotifier<ArenaStats>(ArenaStats.initial());
  static final ValueNotifier<Set<String>> unlocked =
      ValueNotifier<Set<String>>(<String>{});
  static List<String> _newlyUnlocked = [];

  static void submit({
    required int score,
    required int correct,
    required String topic,
    required int maxStreak,
    required double accuracy,
  }) {
    final current = stats.value;
    final best = Map<String, int>.from(current.topicBest);
    if (topic != '全部') {
      final prev = best[topic] ?? 0;
      if (score > prev) {
        best[topic] = score;
      }
    }
    final bestAccuracy =
        accuracy > current.bestAccuracy ? accuracy : current.bestAccuracy;
    final bestStreak = maxStreak > current.maxStreak ? maxStreak : current.maxStreak;
    final next = current.copyWith(
      totalScore: current.totalScore + score,
      totalCorrect: current.totalCorrect + correct,
      matches: current.matches + 1,
      maxStreak: bestStreak,
      bestAccuracy: bestAccuracy,
      topicBest: best,
    );
    stats.value = next;
    _newlyUnlocked = _evaluateNewBadges(next);
    if (_newlyUnlocked.isNotEmpty) {
      unlocked.value = {...unlocked.value, ..._newlyUnlocked};
    }
  }

  static List<String> consumeNewBadges() {
    final list = List<String>.from(_newlyUnlocked);
    _newlyUnlocked = [];
    return list;
  }

  static List<String> _evaluateNewBadges(ArenaStats stats) {
    final candidates = <String>[];
    if (stats.matches >= 1) candidates.add('闪亮新星');
    if (stats.maxStreak >= 3) candidates.add('连胜三场');
    if (stats.totalScore >= 300) candidates.add('探索家');
    if (stats.bestAccuracy >= 0.9) candidates.add('观察大师');
    if ((stats.topicBest['历史'] ?? 0) >= 120) candidates.add('历史小通');
    if ((stats.topicBest['篮球'] ?? 0) >= 120) candidates.add('篮球达人');
    final newOnes =
        candidates.where((name) => !unlocked.value.contains(name)).toList();
    return newOnes;
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final int score;
  final bool isMe;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _parseInt(json['rank']),
      name: json['name']?.toString() ?? '',
      score: _parseInt(json['score']),
      isMe: json['isMe'] == true,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {'rank': rank, 'name': name, 'score': score, 'isMe': isMe};

  LeaderboardEntry copyWith({int? rank, String? name, int? score, bool? isMe}) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      score: score ?? this.score,
      isMe: isMe ?? this.isMe,
    );
  }
}

/// 擂台主题（来自 GET /arena/topics）
class ArenaTopicItem {
  const ArenaTopicItem({required this.topic, required this.subtopics});
  final String topic;
  final List<String> subtopics;

  factory ArenaTopicItem.fromJson(Map<String, dynamic> json) {
    final sub = json['subtopics'];
    return ArenaTopicItem(
      topic: json['topic'] as String? ?? '',
      subtopics: sub is List ? sub.map((e) => e.toString()).toList() : ['全部'],
    );
  }
}

/// 擂台页数据（来自后端接口，失败时用空数据，不再用假数据）
class ArenaPageData {
  const ArenaPageData({
    required this.pkLeaderboard,
    required this.personalLeaderboardEntries,
    required this.zoneLeaderboardTemplate,
    this.zoneLeaders = const {},
    this.topicNames = const [],
    this.topicItems = const [],
  });

  /// 在线 PK 排行（与个人积分同源，首页仅前 5）
  final List<LeaderboardEntry> pkLeaderboard;
  /// 个人积分排行（与 pk 同源，首页仅前 5，前端会合并「你」并重排）
  final List<LeaderboardEntry> personalLeaderboardEntries;
  /// 分区榜模板（接口无数据时 fallback）
  final List<LeaderboardEntry> zoneLeaderboardTemplate;
  /// 分区榜按主题的榜单（topic -> list），有则优先用
  final Map<String, List<LeaderboardEntry>> zoneLeaders;
  /// 主题名称列表（用于筛选与分区榜）
  final List<String> topicNames;
  /// 主题与子主题（用于筛选器）
  final List<ArenaTopicItem> topicItems;

  factory ArenaPageData.fromJson(Map<String, dynamic> json) {
    final topicItemsRaw = json['topicItems'] as List<dynamic>? ?? [];
    final topicItems = topicItemsRaw
        .map((e) => ArenaTopicItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ArenaPageData(
      pkLeaderboard: (json['pkLeaderboard'] as List<dynamic>? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      personalLeaderboardEntries: (json['personalLeaderboardEntries'] as List<dynamic>? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      zoneLeaderboardTemplate: (json['zoneLeaderboardTemplate'] as List<dynamic>? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      zoneLeaders: const {},
      topicNames: (json['topicNames'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      topicItems: topicItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'pkLeaderboard': pkLeaderboard.map((e) => e.toJson()).toList(),
        'personalLeaderboardEntries': personalLeaderboardEntries.map((e) => e.toJson()).toList(),
        'zoneLeaderboardTemplate': zoneLeaderboardTemplate.map((e) => e.toJson()).toList(),
      };

  static ArenaPageData fallback() {
    return const ArenaPageData(
      pkLeaderboard: [],
      personalLeaderboardEntries: [],
      zoneLeaderboardTemplate: [],
      zoneLeaders: {},
      topicNames: [],
      topicItems: [],
    );
  }
}

/// 擂台页数据仓库：从后端获取排行榜与主题，不再使用假数据
class ArenaDataRepository {
  static Future<ArenaPageData> load() async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      // 首页只取前 5 名
      final scoreRes = await http.get(
        Uri.parse('$baseUrl/arena/leaderboard/score?limit=5'),
        headers: headers,
      );
      if (scoreRes.statusCode != 200) return ArenaPageData.fallback();
      final scoreData = jsonDecode(scoreRes.body) as Map<String, dynamic>?;
      final listRaw = scoreData?['list'];
      if (listRaw is! List) return ArenaPageData.fallback();
      final scoreList = listRaw
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final pkList = scoreList;
      final personalList = List<LeaderboardEntry>.from(scoreList);

      // 主题列表来自 GET /arena/topics
      final topicNames = await ArenaTopicsRepository.loadTopicNames(baseUrl);
      final zoneLeaders = <String, List<LeaderboardEntry>>{};
      for (final topic in topicNames.take(6)) {
        try {
          final zoneRes = await http.get(
            Uri.parse('$baseUrl/arena/leaderboard/zone?topic=${Uri.encodeComponent(topic)}&limit=10'),
            headers: headers,
          );
          if (zoneRes.statusCode == 200) {
            final zoneData = jsonDecode(zoneRes.body) as Map<String, dynamic>?;
            final zList = zoneData?['list'];
            if (zList is List) {
              zoneLeaders[topic] = zList
                  .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
        } catch (_) {}
      }

      final topicItems = await ArenaTopicsRepository.load(baseUrl);
      return ArenaPageData(
        pkLeaderboard: pkList,
        personalLeaderboardEntries: personalList,
        zoneLeaderboardTemplate: const [],
        zoneLeaders: zoneLeaders,
        topicNames: topicNames,
        topicItems: topicItems,
      );
    } catch (_) {
      return ArenaPageData.fallback();
    }
  }

  /// 详情页全量排行榜（limit=200），可选按昵称搜索
  static Future<List<LeaderboardEntry>> loadFullScoreLeaderboard({String? search}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final uri = search != null && search.isNotEmpty
          ? Uri.parse('$baseUrl/arena/leaderboard/score?limit=200&search=${Uri.encodeComponent(search)}')
          : Uri.parse('$baseUrl/arena/leaderboard/score?limit=200');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final listRaw = data?['list'];
      if (listRaw is! List) return [];
      return listRaw
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// 擂台主题列表：GET /arena/topics
class ArenaTopicsRepository {
  static Future<List<ArenaTopicItem>> load(String baseUrl) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/arena/topics'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final raw = data?['topics'];
      if (raw is! List) return [];
      return raw.map((e) => ArenaTopicItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> loadTopicNames(String baseUrl) async {
    final list = await load(baseUrl);
    return list.map((e) => e.topic).toList();
  }
}

/// 成就墙数据：从 GET /arena/stats 拉取（个人页成就墙用）
class ArenaStatsRepository {
  static Future<ArenaStats> load() async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return ArenaStats.initial();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/arena/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return ArenaStats.initial();
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (data == null) return ArenaStats.initial();
      final topicBestRaw = data['topicBest'];
      final Map<String, int> topicBest = {};
      if (topicBestRaw is Map) {
        for (final e in topicBestRaw.entries) {
          final v = e.value;
          if (v is num) topicBest[e.key.toString()] = v.toInt();
        }
      }
      return ArenaStats(
        totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
        totalCorrect: 0,
        matches: (data['matches'] as num?)?.toInt() ?? 0,
        maxStreak: (data['maxStreak'] as num?)?.toInt() ?? 0,
        bestAccuracy: (data['bestAccuracy'] as num?)?.toDouble() ?? 0,
        topicBest: topicBest,
      );
    } catch (_) {
      return ArenaStats.initial();
    }
  }
}

final Future<ArenaPageData> arenaPageDataFuture = ArenaDataRepository.load();

/// 擂台题库：从 GET /arena/questions 拉取，支持 topic、subtopic 筛选
class ArenaQuestionsRepository {
  static Future<List<Question>> load({String? topic, String? subtopic}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    try {
      Uri uri;
      if (topic != null && topic.isNotEmpty && topic != '全部') {
        if (subtopic != null && subtopic.isNotEmpty && subtopic != '全部') {
          uri = Uri.parse('$baseUrl/arena/questions?topic=${Uri.encodeComponent(topic)}&subtopic=${Uri.encodeComponent(subtopic)}');
        } else {
          uri = Uri.parse('$baseUrl/arena/questions?topic=${Uri.encodeComponent(topic)}');
        }
      } else {
        uri = Uri.parse('$baseUrl/arena/questions');
      }
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final list = data?['questions'];
      if (list is! List) return [];
      return list
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
