import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/arena_data.dart';
import '../../data/demo_data.dart';
import '../../lan/lan_duel.dart';
import '../../widgets/reveal.dart';
import '../../widgets/starry_background.dart';
import 'arena_quiz.dart' show LanDuelPage, QuizPage;

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  String _selectedTopic = '全部';
  String _selectedSubtopic = '全部';

  List<LeaderboardEntry> _buildPersonalLeaderboard(
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
              demoDataFuture,
              arenaPageDataFuture,
              ArenaQuestionsRepository.load(),
            ]),
            builder: (context, snapshot) {
              final data = snapshot.hasData
                  ? (snapshot.data![0] as DemoData)
                  : DemoData.fallback();
              final arenaData = snapshot.hasData
                  ? (snapshot.data![1] as ArenaPageData)
                  : ArenaPageData.fallback();
              final apiQuestions = snapshot.hasData && snapshot.data!.length > 2
                  ? (snapshot.data![2] as List<Question>)
                  : <Question>[];
              final quizData = apiQuestions.isNotEmpty
                  ? DemoData(
                      topics: data.topics,
                      contents: data.contents,
                      questions: apiQuestions,
                      achievements: data.achievements,
                      communityPosts: data.communityPosts,
                    )
                  : data;
              final topics = ['全部', ...data.topics.map((t) => t.name)];
              final subTopics = _subTopicsFor(data, _selectedTopic);
              return ValueListenableBuilder<ArenaStats>(
                valueListenable: ArenaStatsStore.stats,
                builder: (context, stats, _) {
                  return ListView(
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
                                  pkList: arenaData.pkLeaderboard,
                                  personalList: _buildPersonalLeaderboard(stats.totalScore, arenaData.personalLeaderboardEntries),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 220,
                        child: LeaderboardCard(
                          title: '个人积分排行',
                          entries: _buildPersonalLeaderboard(
                            stats.totalScore,
                            arenaData.personalLeaderboardEntries,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('分区榜', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 300,
                        child: ZoneLeaderboardRow(
                          topics: data.topics.map((t) => t.name).toList(),
                          stats: stats,
                          zoneLeaderboardTemplate: arenaData.zoneLeaderboardTemplate,
                          zoneLeaders: arenaData.zoneLeaders,
                        ),
                      ),
                    ],
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
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web 暂不支持局域网对战')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanDuelSheet(
        topic: _selectedTopic,
        subtopic: _selectedSubtopic,
        data: data,
      ),
    );
  }
}

class _ArenaMyRankPage extends StatelessWidget {
  const _ArenaMyRankPage({
    required this.pkList,
    required this.personalList,
  });

  final List<LeaderboardEntry> pkList;
  final List<LeaderboardEntry> personalList;

  int _myRank(List<LeaderboardEntry> list) {
    final idx = list.indexWhere((e) => e.isMe || e.name == '你');
    return idx >= 0 ? list[idx].rank : 0;
  }

  @override
  Widget build(BuildContext context) {
    final pkRank = _myRank(pkList);
    final personalRank = _myRank(personalList);
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RankTile(
                        title: '在线 PK 排行',
                        rank: pkRank,
                        label: pkRank > 0 ? '第 $pkRank 名' : '暂未上榜',
                      ),
                      const SizedBox(height: 16),
                      _RankTile(
                        title: '个人积分排行',
                        rank: personalRank,
                        label: personalRank > 0 ? '第 $personalRank 名' : '暂未上榜',
                      ),
                    ],
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

class _RankTile extends StatelessWidget {
  const _RankTile({required this.title, required this.rank, required this.label});

  final String title;
  final int rank;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _LanDuelSheet extends StatefulWidget {
  const _LanDuelSheet({
    required this.topic,
    required this.subtopic,
    required this.data,
  });

  final String topic;
  final String subtopic;
  final DemoData data;

  @override
  State<_LanDuelSheet> createState() => _LanDuelSheetState();
}

class _LanDuelSheetState extends State<_LanDuelSheet> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _relayController = TextEditingController(text: 'http://localhost:3002');
  final TextEditingController _roomController = TextEditingController();
  LanDuelHost? _host;
  DuelConnection? _connection;
  String _status = '请选择创建或加入';
  int? _port;
  bool _hosting = false;
  bool _joining = false;
  bool _useRelay = false;
  String? _roomId;
  List<String> _localIps = const [];

  @override
  void dispose() {
    _ipController.dispose();
    _relayController.dispose();
    _roomController.dispose();
    _host?.close();
    _connection?.close();
    super.dispose();
  }

  Future<void> _startHost() async {
    setState(() {
      _hosting = true;
      _status = '正在创建房间…';
    });
    try {
      if (_useRelay) {
        final room = _roomController.text.trim().isEmpty
            ? _generateRoomCode()
            : _roomController.text.trim();
        _roomId = room;
        final client = RelayDuelClient();
        final conn = await client.connect(_relayController.text.trim());
        _connection = conn;
        conn.send({'type': 'host', 'room': room});
        setState(() => _status = '中继房间已创建，等待加入… 房间号：$room');
        final join = await conn.messages.firstWhere((msg) => msg['type'] == 'join');
        if (!mounted) return;
        final accept = await _confirmJoin(join['name']?.toString() ?? '对手');
        if (!accept) {
          _send(conn, {'type': 'deny'});
          conn.close();
          setState(() => _status = '已拒绝对战请求');
          return;
        }
        _send(conn, {'type': 'accept'});
        _startNetworkDuel(conn);
      } else {
        _host = LanDuelHost();
        _port = await _host!.start();
        _localIps = await _host!.localIps();
        setState(() {
          _status = '等待对方连接…';
        });
        final conn = await _host!.waitForClient();
        _connection = conn;
        final remote = conn.messages.firstWhere((msg) => msg['type'] == 'join');
        final join = await remote;
        if (!mounted) return;
        final accept = await _confirmJoin(join['name']?.toString() ?? '对手');
        if (!accept) {
          _send(conn, {'type': 'deny'});
          conn.close();
          setState(() => _status = '已拒绝对战请求');
          return;
        }
        _send(conn, {'type': 'accept'});
        _startNetworkDuel(conn);
      }
    } catch (e) {
      setState(() => _status = '创建失败：$e');
    }
  }

  Future<void> _joinHost() async {
    final ip = _ipController.text.trim();
    final room = _roomController.text.trim();
    if (_useRelay) {
      if (_relayController.text.trim().isEmpty || room.isEmpty) return;
    } else {
      if (ip.isEmpty) return;
    }
    setState(() {
      _joining = true;
      _status = '正在连接…';
    });
    try {
      final DuelConnection conn;
      if (_useRelay) {
        final client = RelayDuelClient();
        conn = await client.connect(_relayController.text.trim());
        _roomId = room;
        conn.send({'type': 'join', 'name': '星知玩家', 'room': room});
      } else {
        final client = LanDuelClient();
        conn = await client.connect(ip);
        conn.send({'type': 'join', 'name': '星知玩家'});
      }
      _connection = conn;
      setState(() => _status = '等待对方确认…');
      await for (final msg in conn.messages) {
        if (msg['type'] == 'accept') {
          setState(() => _status = '已通过，等待开始…');
        }
        if (msg['type'] == 'room_not_found') {
          setState(() => _status = '房间不存在');
          break;
        }
        if (msg['type'] == 'start') {
          if (!mounted) return;
          _startJoinDuel(conn, msg);
          break;
        }
        if (msg['type'] == 'deny') {
          if (!mounted) return;
          setState(() => _status = '对方拒绝了对战');
          break;
        }
      }
    } catch (e) {
      setState(() => _status = '连接失败：$e');
    }
  }

  Future<bool> _confirmJoin(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('对战邀请'),
          content: Text('来自 $name 的对战请求，是否接受？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('拒绝')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('接受')),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _startNetworkDuel(DuelConnection connection) {
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    final count = 10;
    _send(connection, {
      'type': 'start',
      'topic': widget.topic,
      'subtopic': widget.subtopic,
      'seed': seed,
      'count': count,
    });
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanDuelPage(
          connection: connection,
          data: widget.data,
          topic: widget.topic,
          subtopic: widget.subtopic,
          seed: seed,
          count: count,
          isHost: true,
          room: _roomId,
        ),
      ),
    );
  }

  void _startJoinDuel(DuelConnection connection, Map<String, dynamic> msg) {
    final topic = msg['topic']?.toString() ?? widget.topic;
    final subtopic = msg['subtopic']?.toString() ?? widget.subtopic;
    final seed = (msg['seed'] as num?)?.toInt() ?? 0;
    final count = (msg['count'] as num?)?.toInt() ?? 10;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanDuelPage(
          connection: connection,
          data: widget.data,
          topic: topic,
          subtopic: subtopic,
          seed: seed,
          count: count,
          isHost: false,
          room: _roomId,
        ),
      ),
    );
  }

  void _send(DuelConnection connection, Map<String, dynamic> data) {
    if (_roomId != null) {
      data = {...data, 'room': _roomId};
    }
    connection.send(data);
  }

  String _generateRoomCode() {
    final rng = Random();
    return (rng.nextInt(9000) + 1000).toString();
  }

  @override
  Widget build(BuildContext context) {
    final ips = _localIps;
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
            const Text('局域网对战', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Text('当前主题：${widget.topic} · ${widget.subtopic}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('使用中继服务'),
                const Spacer(),
                Switch(
                  value: _useRelay,
                  onChanged: (value) => setState(() => _useRelay = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hosting ? null : _startHost,
                    child: const Text('创建房间'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _joining ? null : _joinHost,
                    child: const Text('加入房间'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_useRelay) ...[
              TextField(
                controller: _relayController,
                decoration: InputDecoration(
                  hintText: '中继地址（如 http://192.168.1.10:3002）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  hintText: '房间号（由房主提供）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              if (_roomId != null) Text('房间号：$_roomId'),
            ] else ...[
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  hintText: '输入对方 IP（如 192.168.1.8）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (_port != null) Text('端口：$_port'),
            if (ips.isNotEmpty) Text('本机 IP：${ips.join(' / ')}'),
            const SizedBox(height: 10),
            Text(_status, style: const TextStyle(color: Color(0xFF6F6B60))),
            const SizedBox(height: 8),
            const Text('提示：双方需在同一 Wi‑Fi 下。'),
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
                        child: const Text('单人挑战'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDuel,
                        child: const Text('局域网对战'),
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
  const LeaderboardCard({super.key, required this.title, required this.entries});

  final String title;
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...entries.map(
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
        ],
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
