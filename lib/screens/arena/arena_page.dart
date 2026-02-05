import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/arena_data.dart';
import '../../data/assistant_route.dart';
import '../../data/profile.dart';
import '../../data/demo_data.dart';
import '../../widgets/reveal.dart';
import '../../widgets/starry_background.dart';
import 'arena_quiz.dart' show QuizPage, ServerDuelPage;

class ArenaPage extends StatefulWidget {
  const ArenaPage({
    super.key,
    required this.selectedTabIndex,
    required this.isArenaTabVisible,
  });

  final int selectedTabIndex;
  final bool isArenaTabVisible;

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  String _selectedTopic = '全部';
  String _selectedSubtopic = '全部';
  late Future<ArenaPageData> _arenaDataFuture;

  @override
  void initState() {
    super.initState();
    _arenaDataFuture = Future.value(ArenaPageData.fallback());
  }

  @override
  void didUpdateWidget(covariant ArenaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换到「擂台」tab 时请求接口并同步用户个人积分（GET /arena/stats）
    if (widget.isArenaTabVisible && !oldWidget.isArenaTabVisible) {
      ArenaStatsStore.syncFromServer();
      setState(() {
        _arenaDataFuture = ArenaDataRepository.load();
      });
    }
  }

  Future<void> _refreshArenaData() async {
    await ArenaStatsStore.syncFromServer();
    setState(() {
      _arenaDataFuture = ArenaDataRepository.load();
    });
  }

  List<String> _subTopicsFor(List<ArenaTopicItem> topicItems, String topic) {
    if (topic == '全部') return ['全部'];
    for (final e in topicItems) {
      if (e.topic == topic) return e.subtopics;
    }
    return ['全部'];
  }

  List<LeaderboardEntry> _buildPersonalLeaderboardTop5(
    int yourScore,
    List<LeaderboardEntry> fromApi,
  ) {
    final hasMe = fromApi.any((e) => e.isMe);
    final entries = hasMe
        ? fromApi.map((e) => e.isMe ? e.copyWith(name: '你', score: yourScore) : e).toList()
        : [
            LeaderboardEntry(rank: 0, name: '你', score: yourScore, isMe: true),
            ...fromApi.map((e) => e.copyWith(rank: 0)),
          ];
    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries.asMap().entries.take(5).map((e) => e.value.copyWith(rank: e.key + 1)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              _arenaDataFuture,
              ArenaQuestionsRepository.load(topic: _selectedTopic, subtopic: _selectedSubtopic),
            ]),
            builder: (context, snapshot) {
              final arenaData = snapshot.hasData
                  ? (snapshot.data![0] as ArenaPageData)
                  : ArenaPageData.fallback();
              final apiQuestions = snapshot.hasData && snapshot.data!.length > 1
                  ? (snapshot.data![1] as List<Question>)
                  : <Question>[];
              final topicNames = arenaData.topicNames;
              final topics = ['全部', ...topicNames];
              final subTopics = _subTopicsFor(arenaData.topicItems, _selectedTopic);
              final quizData = DemoData(
                topics: topics.map((name) => Topic(id: name, name: name)).toList(),
                contents: const [],
                questions: apiQuestions,
                achievements: const [],
                communityPosts: const [],
              );
              return ValueListenableBuilder<ArenaStats>(
                valueListenable: ArenaStatsStore.stats,
                builder: (context, stats, _) {
                  final personalTop5 = _buildPersonalLeaderboardTop5(
                    stats.totalScore,
                    arenaData.personalLeaderboardEntries,
                  );
                  return RefreshIndicator(
                    onRefresh: _refreshArenaData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('知识擂台', style: Theme.of(context).textTheme.headlineLarge),
                                  const SizedBox(height: 4),
                                  const Text('快问快答，看谁最闪', style: TextStyle(color: Color(0xFF6F6B60))),
                                ],
                              ),
                            ),
                            IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _ArenaMyRankPage(
                                  yourScore: stats.totalScore,
                                  yourPkScore: stats.pkScore,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.leaderboard_rounded),
                            tooltip: '我的排名',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: topics.map((topic) {
                            final active = topic == _selectedTopic;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedTopic = topic;
                                _selectedSubtopic = '全部';
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFFFFF2CC) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(topic, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_selectedTopic != '全部') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: subTopics.map((sub) {
                              final active = sub == _selectedSubtopic;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSubtopic = sub),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xFFFFF2CC) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE9E0C9)),
                                  ),
                                  child: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 0,
                        child: ArenaHero(
                          onStart: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuizPage(
                                  topic: _selectedTopic,
                                  subtopic: _selectedSubtopic,
                                  data: quizData,
                                ),
                              ),
                            );
                          },
                          onDuel: () {
                            _openLanDuelSheet(context, quizData);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('排行榜', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 140,
                        child: LeaderboardCard(
                          title: '在线 PK 排行',
                          entries: arenaData.pkLeaderboard,
                          maxVisible: 5,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScoreLeaderboardDetailPage(
                                title: '在线 PK 排行',
                                type: ScoreLeaderboardType.pk,
                                yourScore: stats.pkScore,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 220,
                        child: LeaderboardCard(
                          title: '个人积分排行',
                          entries: personalTop5,
                          maxVisible: 5,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScoreLeaderboardDetailPage(
                                title: '个人积分排行',
                                type: ScoreLeaderboardType.personal,
                                yourScore: stats.totalScore,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('分区榜', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 300,
                        child: ZoneLeaderboardRow(
                          topics: topicNames,
                          stats: stats,
                          zoneLeaderboardTemplate: arenaData.zoneLeaderboardTemplate,
                          zoneLeaders: arenaData.zoneLeaders,
                        ),
                      ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openLanDuelSheet(BuildContext context, DemoData data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServerDuelSheet(
        topic: _selectedTopic,
        subtopic: _selectedSubtopic,
        data: data,
      ),
    );
  }
}

class _ArenaMyRankPage extends StatefulWidget {
  const _ArenaMyRankPage({required this.yourScore, required this.yourPkScore});

  final int yourScore;
  final int yourPkScore;

  @override
  State<_ArenaMyRankPage> createState() => _ArenaMyRankPageState();
}

/// 最近挑战单项：单人挑战或局域网对战，用于合并排序
class _RecentChallengeEntry {
  _RecentChallengeEntry.challenge(ChallengeSessionSummary s) : challenge = s, duel = null;
  _RecentChallengeEntry.duel(DuelSessionSummary s) : challenge = null, duel = s;

  final ChallengeSessionSummary? challenge;
  final DuelSessionSummary? duel;

  DateTime get sortDate {
    if (challenge != null) return _parseDate(challenge!.createdAt);
    return _parseDate(duel!.createdAt);
  }
}

DateTime _parseDate(dynamic createdAt) {
  if (createdAt == null) return DateTime(0);
  if (createdAt is DateTime) return createdAt.isUtc ? createdAt.toLocal() : createdAt;
  if (createdAt is String) {
    final d = DateTime.tryParse(createdAt);
    return d != null ? (d.isUtc ? d.toLocal() : d) : DateTime(0);
  }
  if (createdAt is num) {
    return DateTime.fromMillisecondsSinceEpoch(createdAt.toInt() * 1000, isUtc: true).toLocal();
  }
  return DateTime(0);
}

class _ArenaMyRankPageState extends State<_ArenaMyRankPage> {
  List<LeaderboardEntry> _pkList = [];
  List<LeaderboardEntry> _personalList = [];
  List<_RecentChallengeEntry> _recentList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ArenaDataRepository.loadFullScoreLeaderboard(type: ScoreLeaderboardType.pk),
      ArenaDataRepository.loadFullScoreLeaderboard(type: ScoreLeaderboardType.personal),
      ArenaChallengeRepository.loadHistory(limit: 20),
      ArenaDuelRepository.loadDuelHistory(limit: 20),
    ]);
    if (!mounted) return;
    final pkList = results[0] as List<LeaderboardEntry>;
    final personalList = results[1] as List<LeaderboardEntry>;
    final challengeHistory = results[2] as List<ChallengeSessionSummary>;
    final duelHistory = results[3] as List<DuelSessionSummary>;
    final merged = <_RecentChallengeEntry>[
      ...challengeHistory.map((s) => _RecentChallengeEntry.challenge(s)),
      ...duelHistory.map((s) => _RecentChallengeEntry.duel(s)),
    ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    final pkMerged = _mergeYou(pkList, widget.yourPkScore);
    final personalMerged = _mergeYou(personalList, widget.yourScore);
    setState(() {
      _pkList = pkMerged;
      _personalList = personalMerged;
      _recentList = merged;
      _loading = false;
    });
  }

  List<LeaderboardEntry> _mergeYou(List<LeaderboardEntry> fromApi, int yourScore) {
    final hasMe = fromApi.any((e) => e.isMe);
    final merged = hasMe
        ? fromApi.map((e) => e.isMe ? e.copyWith(name: '你', score: yourScore) : e).toList()
        : [
            LeaderboardEntry(rank: 0, name: '你', score: yourScore, isMe: true),
            ...fromApi.map((e) => e.copyWith(rank: 0)),
          ];
    merged.sort((a, b) => b.score.compareTo(a.score));
    return merged.asMap().entries.map((e) => e.value.copyWith(rank: e.key + 1)).toList();
  }

  int _myRank(List<LeaderboardEntry> list) {
    final idx = list.indexWhere((e) => e.isMe || e.name == '你');
    return idx >= 0 ? list[idx].rank : 0;
  }

  @override
  Widget build(BuildContext context) {
    final pkRank = _myRank(_pkList);
    final personalRank = _myRank(_personalList);
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text('我的排名', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RankTile(
                            title: '在线 PK 排行',
                            rank: pkRank,
                            label: pkRank > 0 ? '第 $pkRank 名' : '暂未上榜',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ScoreLeaderboardDetailPage(
                                  title: '在线 PK 排行',
                                  type: ScoreLeaderboardType.pk,
                                  yourScore: widget.yourPkScore,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RankTile(
                            title: '个人积分排行',
                            rank: personalRank,
                            label: personalRank > 0 ? '第 $personalRank 名' : '暂未上榜',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ScoreLeaderboardDetailPage(
                                  title: '个人积分排行',
                                  type: ScoreLeaderboardType.personal,
                                  yourScore: widget.yourScore,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('最近挑战', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          if (_recentList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: const Color(0xFFFFD166)),
                              ),
                              child: Center(
                                child: Text(
                                  '暂无挑战记录，去完成一次单人挑战或在线PK吧～',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ),
                            )
                          else
                            ..._recentList.map((entry) {
                              if (entry.challenge != null) {
                                final s = entry.challenge!;
                                return _ChallengeHistoryTile(
                                  summary: s,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChallengeDetailPage(sessionId: s.id),
                                    ),
                                  ),
                                );
                              }
                              return _DuelHistoryTile(summary: entry.duel!);
                            }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 最近挑战列表项：日期、主题、得分、正确率，点击进入详情
class _ChallengeHistoryTile extends StatelessWidget {
  const _ChallengeHistoryTile({required this.summary, this.onTap});

  final ChallengeSessionSummary summary;
  final VoidCallback? onTap;

  /// 解析为本地时区并格式化为 月/日 时:分
  static String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    DateTime local;
    if (createdAt is DateTime) {
      local = createdAt.isUtc ? createdAt.toLocal() : createdAt;
    } else if (createdAt is String) {
      final d = DateTime.tryParse(createdAt);
      if (d == null) return createdAt;
      local = d.isUtc ? d.toLocal() : d;
    } else if (createdAt is num) {
      final d = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt() * 1000, isUtc: true);
      local = d.toLocal();
    } else {
      return createdAt.toString();
    }
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (summary.accuracy * 100).toStringAsFixed(0);
    final topicLabel = summary.subtopic != '全部' ? '${summary.topic} · ${summary.subtopic}' : summary.topic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD166)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topicLabel, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(summary.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text('${summary.score} 分', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB35C00))),
              const SizedBox(width: 12),
              Text('正确率 $accuracy%', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 局域网对战最近挑战列表项
class _DuelHistoryTile extends StatelessWidget {
  const _DuelHistoryTile({required this.summary});

  final DuelSessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final isWin = summary.result == 'win';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD166)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('在线PK · ${summary.opponentName}', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isWin ? const Color(0xFF4CAF50) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isWin ? '胜利' : '失败',
                          style: TextStyle(fontSize: 12, color: isWin ? Colors.white : Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ChallengeHistoryTile._formatDate(summary.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text('${summary.myScore} : ${summary.opponentScore}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB35C00))),
          ],
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.title,
    required this.rank,
    required this.label,
    this.onTap,
  });

  final String title;
  final int rank;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD166)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: rank > 0 ? const Color(0xFFFF9F1C).withOpacity(0.2) : const Color(0xFFE0E0E0).withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              rank > 0 ? Icons.emoji_events_rounded : Icons.leaderboard_outlined,
              color: rank > 0 ? const Color(0xFFB35C00) : const Color(0xFF9E9E9E),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: rank > 0 ? const Color(0xFFB35C00) : const Color(0xFF6F6B60),
                )),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// 某次挑战详情页：展示该次所有题目、用户选择与正确答案
class ChallengeDetailPage extends StatefulWidget {
  const ChallengeDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  ChallengeSessionDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await ArenaChallengeRepository.loadDetail(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
      _error = detail == null ? '加载失败' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text('挑战详情', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Text(_error!, style: TextStyle(color: Colors.grey[600])),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailHeader(),
                          const SizedBox(height: 20),
                          Text('答题记录', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...?_detail?.answers.asMap().entries.map((e) => _answerCard(e.key + 1, e.value)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailHeader() {
    final d = _detail!;
    final accuracy = (d.accuracy * 100).toStringAsFixed(0);
    final topicLabel = d.subtopic != '全部' ? '${d.topic} · ${d.subtopic}' : d.topic;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(topicLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('得分 ${d.score}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB35C00))),
              const SizedBox(width: 16),
              Text('正确 $accuracy%', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(width: 16),
              Text('${d.correctCount}/${d.totalQuestions} 题', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerCard(int index, ChallengeAnswerRecord a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.isCorrect ? const Color(0xFFB8F1E0) : const Color(0xFFFFD6D6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: a.isCorrect ? const Color(0xFF2EC4B6).withOpacity(0.2) : const Color(0xFFE63946).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: a.isCorrect
                    ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF2EC4B6))
                    : const Icon(Icons.close_rounded, size: 16, color: Color(0xFFE63946)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('第 $index 题', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(a.title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text('你的选择：${a.userChoice.isEmpty ? '未作答' : a.userChoice}', style: const TextStyle(fontSize: 13)),
                    if (!a.isCorrect) ...[
                      const SizedBox(height: 4),
                      Text('正确答案：${a.correctAnswer}', style: TextStyle(fontSize: 13, color: const Color(0xFF2EC4B6), fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                assistantInitialQuestion.value = a.title;
              },
              icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFFF9F1C)),
              label: const Text('问百晓通'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB35C00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 积分排行榜详情页：全量列表 + 搜索（可搜索昵称查当前排名）
class ScoreLeaderboardDetailPage extends StatefulWidget {
  const ScoreLeaderboardDetailPage({
    super.key,
    required this.title,
    required this.type,
    this.yourScore = 0,
  });

  final String title;
  final ScoreLeaderboardType type;
  final int yourScore;

  @override
  State<ScoreLeaderboardDetailPage> createState() => _ScoreLeaderboardDetailPageState();
}

class _ScoreLeaderboardDetailPageState extends State<ScoreLeaderboardDetailPage> {
  List<LeaderboardEntry> _fullList = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    final list = await ArenaDataRepository.loadFullScoreLeaderboard(type: widget.type, search: search);
    final hasMe = list.any((e) => e.isMe);
    final merged = hasMe
        ? list.map((e) => e.isMe ? e.copyWith(name: '你', score: widget.yourScore) : e).toList()
        : [
            LeaderboardEntry(rank: 0, name: '你', score: widget.yourScore, isMe: true),
            ...list.map((e) => e.copyWith(rank: 0)),
          ];
    merged.sort((a, b) => b.score.compareTo(a.score));
    final ranked = merged.asMap().entries.map((e) => e.value.copyWith(rank: e.key + 1)).toList();
    if (!mounted) return;
    setState(() {
      _fullList = ranked;
      _loading = false;
    });
  }

  List<LeaderboardEntry> get _filteredList {
    if (_searchQuery.trim().isEmpty) return _fullList;
    final q = _searchQuery.trim().toLowerCase();
    return _fullList.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索昵称查排名',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty ? '暂无排行数据' : '未找到「$_searchQuery」',
                                style: const TextStyle(color: Color(0xFF6F6B60)),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                final isCurrentUser = entry.isMe || entry.name == '你';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser ? const Color(0xFFFFF8E8) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: isCurrentUser
                                          ? Border.all(color: const Color(0xFFFFD166).withOpacity(0.6))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: isCurrentUser
                                                ? const Color(0xFFFF9F1C).withOpacity(0.2)
                                                : const Color(0xFFFFF1D0),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${entry.rank}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: isCurrentUser ? const Color(0xFFB35C00) : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            entry.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isCurrentUser ? FontWeight.w600 : null,
                                              color: isCurrentUser ? const Color(0xFF8B6914) : null,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${entry.score}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isCurrentUser ? const Color(0xFFB35C00) : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 双人对战（匹配机制）：点击「开始对战」自动匹配，两人差不多时间点击即配对，无需房间号
class _ServerDuelSheet extends StatefulWidget {
  const _ServerDuelSheet({
    required this.topic,
    required this.subtopic,
    required this.data,
  });

  final String topic;
  final String subtopic;
  final DemoData data;

  @override
  State<_ServerDuelSheet> createState() => _ServerDuelSheetState();
}

class _ServerDuelSheetState extends State<_ServerDuelSheet> {
  String _status = '';
  bool _loading = false;
  bool _matching = false;
  static const int _matchTimeoutSeconds = 30;

  void _goToDuel(Map<String, dynamic> res) {
    final roomId = res['roomId']?.toString() ?? '';
    final topic = res['topic']?.toString() ?? widget.topic;
    final subtopic = res['subtopic']?.toString() ?? widget.subtopic;
    final seed = (res['seed'] is int) ? res['seed'] as int : (res['seed'] as num?)?.toInt() ?? 0;
    final count = (res['count'] is int) ? res['count'] as int : (res['count'] as num?)?.toInt() ?? 10;
    final isHost = res['isHost'] == true;
    final opponentName = res['opponentName']?.toString() ?? '对手';
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerDuelPage(
          roomId: roomId,
          data: widget.data,
          topic: topic,
          subtopic: subtopic,
          seed: seed,
          count: count,
          isHost: isHost,
          opponentName: opponentName,
        ),
      ),
    );
  }

  Future<void> _startMatch() async {
    setState(() {
      _loading = true;
      _status = '正在匹配…';
    });
    final res = await ArenaDuelRepository.matchDuel(
      topic: widget.topic,
      subtopic: widget.subtopic,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res == null) {
      setState(() => _status = '匹配失败，请检查网络或登录');
      return;
    }
    if (res['matched'] == true) {
      _goToDuel(res);
      return;
    }
    setState(() => _matching = true);
    final deadline = DateTime.now().add(const Duration(seconds: _matchTimeoutSeconds));
    while (mounted && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) break;
      final pollRes = await ArenaDuelRepository.pollMatchStatus();
      if (mounted && pollRes != null && pollRes['matched'] == true) {
        setState(() => _matching = false);
        _goToDuel(pollRes);
        return;
      }
    }
    if (mounted) {
      setState(() {
        _matching = false;
        _status = '暂时没有对手，请稍后再试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _matching;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('双人对战', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text('当前主题：${widget.topic} · ${widget.subtopic}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _startMatch,
                child: busy ? const Text('匹配中…') : const Text('开始对战'),
              ),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_status, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
            const SizedBox(height: 10),
            const Text('两人差不多时间点击「开始对战」即可自动配对，无需房间号。', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }
}

List<String> _subTopicsFor(DemoData data, String topic) {
  if (topic == '历史') {
    return ['全部', '朝代故事', '名人传记', '古代科技', '古迹巡礼'];
  }
  if (topic == '计算机') {
    return ['全部', '编程入门', '硬件小知识', '网络世界', '人工智能'];
  }
  if (topic == '篮球') {
    return ['全部', '规则基础', '技巧训练', '球星故事', '球队文化'];
  }
  if (topic == '动物') {
    return ['全部', '濒危动物', '生态习性', '动物家族', '自然保护'];
  }
  return ['全部'];
}

class ArenaHero extends StatelessWidget {
  const ArenaHero({super.key, required this.onStart, required this.onDuel});

  final VoidCallback onStart;
  final VoidCallback onDuel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFBFD7FF), Color(0xFF5DADE2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5DADE2).withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text('12s', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('极速挑战', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('最多 10 题 · 12s/题 · 越快越高分'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onStart,
                        child: const Text('单人'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDuel,
                        child: const Text('在线PK'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({
    super.key,
    required this.title,
    required this.entries,
    this.maxVisible,
    this.onTap,
  });

  final String title;
  final List<LeaderboardEntry> entries;
  /// 首页只显示前 N 条，null 表示全部
  final int? maxVisible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showEntries = maxVisible != null ? entries.take(maxVisible!).toList() : entries;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD166)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF6F6B60)),
              ],
            ),
            const SizedBox(height: 10),
            ...showEntries.map(
            (entry) {
              final isCurrentUser = entry.isMe || entry.name == '你';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? const Color(0xFFFFF8E8) : null,
                    borderRadius: BorderRadius.circular(14),
                    border: isCurrentUser ? Border.all(color: const Color(0xFFFFD166).withOpacity(0.6)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCurrentUser ? const Color(0xFFFF9F1C).withOpacity(0.2) : const Color(0xFFFFF1D0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.rank}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCurrentUser ? const Color(0xFFB35C00) : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.w600 : null,
                            color: isCurrentUser ? const Color(0xFF8B6914) : null,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.score}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isCurrentUser ? const Color(0xFFB35C00) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
            if (onTap != null && maxVisible != null && entries.length > maxVisible!)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '查看全部排名',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
        ],
      ),
    ),
    );
  }
}

class ZoneLeaderboardRow extends StatelessWidget {
  const ZoneLeaderboardRow({
    super.key,
    required this.topics,
    required this.stats,
    required this.zoneLeaderboardTemplate,
    this.zoneLeaders = const {},
  });

  final List<String> topics;
  final ArenaStats stats;
  final List<LeaderboardEntry> zoneLeaderboardTemplate;
  final Map<String, List<LeaderboardEntry>> zoneLeaders;

  @override
  Widget build(BuildContext context) {
    final entries = _buildZoneEntries();
    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ZoneLeaderboardCard(
                title: '${entry.topic}区榜',
                leader: entry.leader,
                score: entry.score,
                color: entry.color,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ZoneLeaderboardDetailPage(
                        topic: entry.topic,
                        entries: entry.detailEntries,
                        yourBest: stats.topicBest[entry.topic] ?? 0,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
          .toList(),
    );
  }

  List<_ZoneEntry> _buildZoneEntries() {
    final palette = {
      '历史': const Color(0xFF5DADE2),
      '计算机': const Color(0xFF2EC4B6),
      '篮球': const Color(0xFFFF9F1C),
      '动物': const Color(0xFF6DD3CE),
      '科学': const Color(0xFFB784F8),
    };
    return topics.take(4).map((topic) {
      final color = palette[topic] ?? const Color(0xFFFFC857);
      final best = stats.topicBest[topic] ?? 0;
      final detailEntries = _buildZoneLeaderboard(topic, best);
      final first = detailEntries.isNotEmpty ? detailEntries.first : null;
      return _ZoneEntry(
        topic: topic,
        leader: first?.name ?? '—',
        score: first?.score ?? 0,
        color: color,
        detailEntries: detailEntries,
      );
    }).toList();
  }

  List<LeaderboardEntry> _buildZoneLeaderboard(String topic, int yourBest) {
    final fromApi = zoneLeaders[topic];
    if (fromApi != null && fromApi.isNotEmpty) {
      final hasMe = fromApi.any((e) => e.isMe);
      final merged = hasMe
          ? fromApi.map((e) => e.isMe ? e.copyWith(name: '你', score: yourBest) : e).toList()
          : [
              LeaderboardEntry(rank: 0, name: '你', score: yourBest, isMe: true),
              ...fromApi.map((e) => e.copyWith(rank: 0)),
            ];
      merged.sort((a, b) => b.score.compareTo(a.score));
      return merged.asMap().entries.take(10).map((e) => e.value.copyWith(rank: e.key + 1)).toList();
    }
    final base = List<LeaderboardEntry>.from(
      zoneLeaderboardTemplate.map((e) => LeaderboardEntry(rank: 0, name: e.name, score: e.score)),
    );
    if (yourBest > 0) {
      base.add(LeaderboardEntry(rank: 0, name: '你', score: yourBest, isMe: true));
    }
    base.sort((a, b) => b.score.compareTo(a.score));
    return base.asMap().entries.take(10).map((e) => e.value.copyWith(rank: e.key + 1)).toList();
  }
}

class ZoneLeaderboardCard extends StatelessWidget {
  const ZoneLeaderboardCard({
    super.key,
    required this.title,
    required this.leader,
    required this.score,
    required this.color,
    this.onTap,
  });

  final String title;
  final String leader;
  final int score;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF9F1C)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('榜首：$leader', style: const TextStyle(color: Color(0xFF6F6B60))),
                ],
              ),
            ),
            Text('$score', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ZoneEntry {
  const _ZoneEntry({
    required this.topic,
    required this.leader,
    required this.score,
    required this.color,
    required this.detailEntries,
  });

  final String topic;
  final String leader;
  final int score;
  final Color color;
  final List<LeaderboardEntry> detailEntries;
}

class ZoneLeaderboardDetailPage extends StatefulWidget {
  const ZoneLeaderboardDetailPage({
    super.key,
    required this.topic,
    required this.entries,
    required this.yourBest,
  });

  final String topic;
  final List<LeaderboardEntry> entries;
  final int yourBest;

  @override
  State<ZoneLeaderboardDetailPage> createState() => _ZoneLeaderboardDetailPageState();
}

class _ZoneLeaderboardDetailPageState extends State<ZoneLeaderboardDetailPage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = '总榜';
  }

  @override
  Widget build(BuildContext context) {
    final subTopics = _subTopics(widget.topic);
    final tabs = ['总榜', ...subTopics];
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      Text('${widget.topic} 分区榜', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: tabs.map((label) {
                        final active = label == _selected;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = label),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFFFFF2CC) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _currentList().length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = _currentList()[index];
                        final isCurrentUser = entry.isMe || entry.name == '你';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? const Color(0xFFFFF8E8) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCurrentUser ? const Color(0xFFFFD166).withOpacity(0.8) : const Color(0xFFFFD166),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCurrentUser ? const Color(0xFFFF9F1C).withOpacity(0.2) : const Color(0xFFFFF1D0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.rank}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isCurrentUser ? const Color(0xFFB35C00) : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isCurrentUser ? FontWeight.w600 : null,
                                    color: isCurrentUser ? const Color(0xFF8B6914) : null,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.score}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isCurrentUser ? const Color(0xFFB35C00) : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _subTopics(String topic) {
    switch (topic) {
      case '历史':
        return ['朝代故事', '名人传记', '古代科技', '古迹巡礼'];
      case '计算机':
        return ['编程入门', '硬件小知识', '网络世界', '人工智能'];
      case '篮球':
        return ['规则基础', '技巧训练', '球星故事', '球队文化'];
      case '动物':
        return ['濒危动物', '生态习性', '动物家族', '自然保护'];
      default:
        return ['综合知识', '趣味速答'];
    }
  }

  List<LeaderboardEntry> _buildSubTopicLeaderboard(String topic, String subTopic, int yourBest) {
    final names = ['星海少年', '光点', '快答', '小巡航', '知识号', '跃迁号'];
    final seed = subTopic.codeUnits.fold<int>(0, (a, b) => a + b);
    final list = <LeaderboardEntry>[];
    for (var i = 0; i < names.length; i++) {
      list.add(LeaderboardEntry(rank: 0, name: names[i], score: 1400 + (seed + i * 97) % 420));
    }
    if (yourBest > 0) {
      list.add(LeaderboardEntry(rank: 0, name: '你', score: yourBest));
    }
    list.sort((a, b) => b.score.compareTo(a.score));
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(rank: i + 1);
    }
    return list.take(10).toList();
  }

  List<LeaderboardEntry> _currentList() {
    return _selected == '总榜'
        ? widget.entries
        : _buildSubTopicLeaderboard(widget.topic, _selected, widget.yourBest);
  }
}
