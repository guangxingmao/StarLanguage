import 'package:flutter/material.dart';

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
  });

  final int rank;
  final String name;
  final int score;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'rank': rank, 'name': name, 'score': score};

  LeaderboardEntry copyWith({int? rank, String? name, int? score}) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}

/// 擂台页假数据（可由后端接口填充）
class ArenaPageData {
  const ArenaPageData({
    required this.pkLeaderboard,
    required this.personalLeaderboardEntries,
    required this.zoneLeaderboardTemplate,
  });

  /// 在线 PK 排行（固定 5 条）
  final List<LeaderboardEntry> pkLeaderboard;
  /// 个人积分排行中的假用户（不含「你」），与当前用户分数合并后排序
  final List<LeaderboardEntry> personalLeaderboardEntries;
  /// 分区榜模板（不含「你」），与 yourBest 合并后排序
  final List<LeaderboardEntry> zoneLeaderboardTemplate;

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

/// 擂台页数据仓库：当前返回假数据，之后可改为从后端接口加载
class ArenaDataRepository {
  static Future<ArenaPageData> load() async {
    return Future.value(ArenaPageData.fallback());
  }
}

final Future<ArenaPageData> arenaPageDataFuture = ArenaDataRepository.load();
