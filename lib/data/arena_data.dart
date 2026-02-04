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
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      isMe: json['isMe'] as bool? ?? false,
    );
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

/// 擂台页数据（来自后端接口，失败时用 fallback）
class ArenaPageData {
  const ArenaPageData({
    required this.pkLeaderboard,
    required this.personalLeaderboardEntries,
    required this.zoneLeaderboardTemplate,
    this.zoneLeaders = const {},
  });

  /// 在线 PK 排行（与个人积分同源，按 total_score）
  final List<LeaderboardEntry> pkLeaderboard;
  /// 个人积分排行（与 pk 同源，前端会合并「你」并重排）
  final List<LeaderboardEntry> personalLeaderboardEntries;
  /// 分区榜模板（接口无数据时 fallback）
  final List<LeaderboardEntry> zoneLeaderboardTemplate;
  /// 分区榜按主题的榜单（topic -> list），有则优先用
  final Map<String, List<LeaderboardEntry>> zoneLeaders;

  factory ArenaPageData.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toJson() => {
        'pkLeaderboard': pkLeaderboard.map((e) => e.toJson()).toList(),
        'personalLeaderboardEntries': personalLeaderboardEntries.map((e) => e.toJson()).toList(),
        'zoneLeaderboardTemplate': zoneLeaderboardTemplate.map((e) => e.toJson()).toList(),
      };

  static ArenaPageData fallback() {
    return const ArenaPageData(
      pkLeaderboard: [
        LeaderboardEntry(rank: 1, name: '星知战神', score: 2350),
        LeaderboardEntry(rank: 2, name: '小小挑战王', score: 2190),
        LeaderboardEntry(rank: 3, name: '知识飞船', score: 2045),
        LeaderboardEntry(rank: 4, name: '星际飞手', score: 1980),
        LeaderboardEntry(rank: 5, name: '闪电回答', score: 1920),
      ],
      personalLeaderboardEntries: [
        LeaderboardEntry(rank: 0, name: '小星星', score: 1740),
        LeaderboardEntry(rank: 0, name: '光速答题王', score: 1695),
        LeaderboardEntry(rank: 0, name: '跃迁少年', score: 1580),
        LeaderboardEntry(rank: 0, name: '知识火箭', score: 1470),
      ],
      zoneLeaderboardTemplate: [
        LeaderboardEntry(rank: 0, name: '星河小队', score: 1820),
        LeaderboardEntry(rank: 0, name: '晨星', score: 1710),
        LeaderboardEntry(rank: 0, name: '飞快答题', score: 1640),
        LeaderboardEntry(rank: 0, name: '知识通关', score: 1550),
        LeaderboardEntry(rank: 0, name: '探索者', score: 1470),
      ],
    );
  }
}

/// 擂台页数据仓库：从后端获取排行榜，失败则用 fallback
class ArenaDataRepository {
  static Future<ArenaPageData> load() async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final scoreRes = await http.get(
        Uri.parse('$baseUrl/arena/leaderboard/score?limit=10'),
        headers: headers,
      );
      if (scoreRes.statusCode != 200) return ArenaPageData.fallback();
      final scoreData = jsonDecode(scoreRes.body) as Map<String, dynamic>?;
      final listRaw = scoreData?['list'];
      if (listRaw is! List) return ArenaPageData.fallback();
      final scoreList = listRaw
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final pkList = scoreList.take(5).toList();
      final personalList = List<LeaderboardEntry>.from(scoreList);

      final topics = ['历史', '篮球', '科学', '计算机'];
      final zoneLeaders = <String, List<LeaderboardEntry>>{};
      for (final topic in topics) {
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

      return ArenaPageData(
        pkLeaderboard: pkList,
        personalLeaderboardEntries: personalList,
        zoneLeaderboardTemplate: ArenaPageData.fallback().zoneLeaderboardTemplate,
        zoneLeaders: zoneLeaders,
      );
    } catch (_) {
      return ArenaPageData.fallback();
    }
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

/// 擂台题库：从 GET /arena/questions 拉取，失败或空则返回空列表
class ArenaQuestionsRepository {
  static Future<List<Question>> load({String? topic}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    try {
      final uri = topic != null && topic.isNotEmpty && topic != '全部'
          ? Uri.parse('$baseUrl/arena/questions?topic=${Uri.encodeComponent(topic)}')
          : Uri.parse('$baseUrl/arena/questions');
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
