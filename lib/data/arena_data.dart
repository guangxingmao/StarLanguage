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

  LeaderboardEntry copyWith({int? rank, String? name, int? score}) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}
