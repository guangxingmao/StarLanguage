import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ai_proxy.dart';
import 'demo_data.dart';
import 'profile.dart';

class ArenaStats {
  const ArenaStats({
    required this.totalScore,
    required this.pkScore,
    required this.totalCorrect,
    required this.matches,
    required this.maxStreak,
    required this.bestAccuracy,
    required this.topicBest,
  });

  final int totalScore;
  /// 局域网 PK 累计得分，用于在线 PK 排行（与 totalScore 单人挑战分离）
  final int pkScore;
  final int totalCorrect;
  final int matches;
  final int maxStreak;
  final double bestAccuracy;
  final Map<String, int> topicBest;

  static ArenaStats initial() {
    return const ArenaStats(
      totalScore: 0,
      pkScore: 0,
      totalCorrect: 0,
      matches: 0,
      maxStreak: 0,
      bestAccuracy: 0,
      topicBest: {},
    );
  }

  ArenaStats copyWith({
    int? totalScore,
    int? pkScore,
    int? totalCorrect,
    int? matches,
    int? maxStreak,
    double? bestAccuracy,
    Map<String, int>? topicBest,
  }) {
    return ArenaStats(
      totalScore: totalScore ?? this.totalScore,
      pkScore: pkScore ?? this.pkScore,
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

  /// 从服务端拉取用户擂台统计并更新 store（个人积分、排行榜展示用）
  static Future<void> syncFromServer() async {
    final s = await ArenaStatsRepository.load();
    stats.value = s;
  }

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
      // 在线 PK 排行（type=pk）与个人积分排行（type=personal）分开请求
      final pkRes = await http.get(
        Uri.parse('$baseUrl/arena/leaderboard/score?type=pk&limit=5'),
        headers: headers,
      );
      final personalRes = await http.get(
        Uri.parse('$baseUrl/arena/leaderboard/score?type=personal&limit=5'),
        headers: headers,
      );
      if (pkRes.statusCode != 200 || personalRes.statusCode != 200) return ArenaPageData.fallback();
      final pkData = jsonDecode(pkRes.body) as Map<String, dynamic>?;
      final personalData = jsonDecode(personalRes.body) as Map<String, dynamic>?;
      final pkRaw = pkData?['list'];
      final personalRaw = personalData?['list'];
      if (pkRaw is! List || personalRaw is! List) return ArenaPageData.fallback();
      final pkList = pkRaw
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final personalList = personalRaw
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();

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

  /// 详情页全量排行榜（limit=200），type 区分 pk / personal，可选按昵称搜索
  static Future<List<LeaderboardEntry>> loadFullScoreLeaderboard({
    required ScoreLeaderboardType type,
    String? search,
  }) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final typeStr = type == ScoreLeaderboardType.pk ? 'pk' : 'personal';
      final uri = search != null && search.isNotEmpty
          ? Uri.parse('$baseUrl/arena/leaderboard/score?type=$typeStr&limit=200&search=${Uri.encodeComponent(search)}')
          : Uri.parse('$baseUrl/arena/leaderboard/score?type=$typeStr&limit=200');
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

/// 排行榜类型：在线 PK（局域网 pk_score） / 个人积分（单人挑战 total_score）
enum ScoreLeaderboardType { pk, personal }

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
        pkScore: (data['pkScore'] as num?)?.toInt() ?? 0,
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

/// 单次挑战摘要（最近挑战列表项）
class ChallengeSessionSummary {
  const ChallengeSessionSummary({
    required this.id,
    required this.topic,
    required this.subtopic,
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    required this.accuracy,
    required this.createdAt,
  });

  final int id;
  final String topic;
  final String subtopic;
  final int totalQuestions;
  final int correctCount;
  final int score;
  final double accuracy;
  final dynamic createdAt;

  factory ChallengeSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChallengeSessionSummary(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : 0,
      topic: json['topic']?.toString() ?? '全部',
      subtopic: json['subtopic']?.toString() ?? '全部',
      totalQuestions: (json['totalQuestions'] is num) ? (json['totalQuestions'] as num).toInt() : 0,
      correctCount: (json['correctCount'] is num) ? (json['correctCount'] as num).toInt() : 0,
      score: (json['score'] is num) ? (json['score'] as num).toInt() : 0,
      accuracy: (json['accuracy'] is num) ? (json['accuracy'] as num).toDouble() : 0.0,
      createdAt: json['createdAt'],
    );
  }
}

/// 单题作答记录（提交与详情展示）
class ChallengeAnswerRecord {
  const ChallengeAnswerRecord({
    required this.questionId,
    required this.title,
    required this.userChoice,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final String questionId;
  final String title;
  final String userChoice;
  final String correctAnswer;
  final bool isCorrect;

  factory ChallengeAnswerRecord.fromJson(Map<String, dynamic> json) {
    return ChallengeAnswerRecord(
      questionId: json['questionId']?.toString() ?? json['question_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      userChoice: json['userChoice']?.toString() ?? json['user_choice']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? json['correct_answer']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true || json['is_correct'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'title': title,
        'userChoice': userChoice,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
      };
}

/// 挑战详情（含每题作答）
class ChallengeSessionDetail {
  const ChallengeSessionDetail({
    required this.id,
    required this.topic,
    required this.subtopic,
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    required this.accuracy,
    required this.createdAt,
    required this.answers,
  });

  final int id;
  final String topic;
  final String subtopic;
  final int totalQuestions;
  final int correctCount;
  final int score;
  final double accuracy;
  final dynamic createdAt;
  final List<ChallengeAnswerRecord> answers;

  factory ChallengeSessionDetail.fromJson(Map<String, dynamic> json) {
    final ans = json['answers'];
    final list = ans is List
        ? (ans as List).map((e) => ChallengeAnswerRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <ChallengeAnswerRecord>[];
    return ChallengeSessionDetail(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : 0,
      topic: json['topic']?.toString() ?? '全部',
      subtopic: json['subtopic']?.toString() ?? '全部',
      totalQuestions: (json['totalQuestions'] is num) ? (json['totalQuestions'] as num).toInt() : 0,
      correctCount: (json['correctCount'] is num) ? (json['correctCount'] as num).toInt() : 0,
      score: (json['score'] is num) ? (json['score'] as num).toInt() : 0,
      accuracy: (json['accuracy'] is num) ? (json['accuracy'] as num).toDouble() : 0.0,
      createdAt: json['createdAt'],
      answers: list,
    );
  }
}

/// 局域网对战记录摘要（最近挑战列表项）
class DuelSessionSummary {
  const DuelSessionSummary({
    required this.id,
    required this.opponentPhone,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.result,
    required this.createdAt,
  });

  final int id;
  final String opponentPhone;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final String result;
  final dynamic createdAt;

  factory DuelSessionSummary.fromJson(Map<String, dynamic> json) {
    return DuelSessionSummary(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : 0,
      opponentPhone: json['opponentPhone']?.toString() ?? '',
      opponentName: json['opponentName']?.toString() ?? '对手',
      myScore: (json['myScore'] is num) ? (json['myScore'] as num).toInt() : 0,
      opponentScore: (json['opponentScore'] is num) ? (json['opponentScore'] as num).toInt() : 0,
      result: json['result']?.toString() ?? 'lose',
      createdAt: json['createdAt'],
    );
  }
}

/// 局域网对战记录：提交、历史
class ArenaDuelRepository {
  static Future<bool> submitDuelRecord({
    required String opponentPhone,
    required int myScore,
    required int opponentScore,
  }) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return false;
    if (opponentPhone.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/duel/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'opponentPhone': opponentPhone,
          'myScore': myScore,
          'opponentScore': opponentScore,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<DuelSessionSummary>> loadDuelHistory({int limit = 20}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/arena/duel/history?limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final list = data?['list'];
      if (list is! List) return [];
      return list.map((e) => DuelSessionSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// 服务器对战：开始匹配，两人差不多时间点击即可配对
  static Future<Map<String, dynamic>?> matchDuel({String topic = '全部', String subtopic = '全部'}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/duel/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'topic': topic, 'subtopic': subtopic}),
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 服务器对战：轮询是否已匹配（等待中时调用）
  static Future<Map<String, dynamic>?> pollMatchStatus() async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/arena/duel/match'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 服务器对战：创建房间（保留，可选）
  static Future<Map<String, dynamic>?> createDuelRoom({String topic = '全部', String subtopic = '全部'}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/duel/room'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'topic': topic, 'subtopic': subtopic}),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// 服务器对战：加入房间
  static Future<Map<String, dynamic>?> joinDuelRoom(String roomId) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/duel/room/$roomId/join'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({}),
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 服务器对战：查询房间（轮询对手结果）
  static Future<Map<String, dynamic>?> getDuelRoom(String roomId) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/arena/duel/room/$roomId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 服务器对战：提交本局结果，返回含对手结果（若对方已提交）
  static Future<Map<String, dynamic>?> submitDuelRoomResult({
    required String roomId,
    required int score,
    required int correctCount,
    required int total,
  }) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/duel/room/$roomId/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'score': score,
          'correctCount': correctCount,
          'total': total,
        }),
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

/// 局域网 PK 结束后提交得分（只更新在线 PK 排行用的 pk_score）
class ArenaPkRepository {
  static Future<bool> submitScore(int score) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/pk/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'score': score}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// 单人挑战：提交、历史、详情
class ArenaChallengeRepository {
  static Future<Map<String, dynamic>?> submitChallenge({
    required String topic,
    required String subtopic,
    required int totalQuestions,
    required int correctCount,
    required int score,
    required int maxStreak,
    required List<Map<String, dynamic>> answers,
  }) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/arena/challenge/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'topic': topic,
          'subtopic': subtopic,
          'totalQuestions': totalQuestions,
          'correctCount': correctCount,
          'score': score,
          'maxStreak': maxStreak,
          'answers': answers,
        }),
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<List<ChallengeSessionSummary>> loadHistory({int limit = 20}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/arena/challenge/history?limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final list = data?['list'];
      if (list is! List) return [];
      return list.map((e) => ChallengeSessionSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ChallengeSessionDetail?> loadDetail(int id) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/arena/challenge/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data != null ? ChallengeSessionDetail.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }
}

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
