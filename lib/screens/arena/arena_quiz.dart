import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/arena_data.dart';
import '../../data/demo_data.dart';
import '../../lan/lan_duel.dart';
import '../../widgets/starry_background.dart';
import '../growth/profile_page.dart' show AchievementUnlockPopup;

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.topic,
    required this.subtopic,
    required this.data,
  });

  final String topic;
  final String subtopic;
  final DemoData data;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class DuelQuizPage extends StatefulWidget {
  const DuelQuizPage({
    super.key,
    required this.topic,
    required this.subtopic,
    required this.data,
  });

  final String topic;
  final String subtopic;
  final DemoData data;

  @override
  State<DuelQuizPage> createState() => _DuelQuizPageState();
}

class LanDuelPage extends StatefulWidget {
  const LanDuelPage({
    super.key,
    required this.connection,
    required this.data,
    required this.topic,
    required this.subtopic,
    required this.seed,
    required this.count,
    required this.isHost,
    required this.room,
    this.opponentPhone,
    this.opponentName,
  });

  final DuelConnection connection;
  final DemoData data;
  final String topic;
  final String subtopic;
  final int seed;
  final int count;
  final bool isHost;
  final String? room;
  /// 对手手机号（用于提交局域网对战记录）
  final String? opponentPhone;
  final String? opponentName;

  @override
  State<LanDuelPage> createState() => _LanDuelPageState();
}

class _LanDuelPageState extends State<LanDuelPage> {
  static const int _secondsPerQuestion = 12;
  static const int _waitOpponentSeconds = 60;
  late final List<Question> _questions;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _sub;
  int _index = 0;
  int _score = 0;
  int _opponentScore = 0;
  int _opponentCorrect = 0;
  int _opponentTotal = 0;
  int _correct = 0;
  late final DateTime _quizStartTime;
  int _remaining = _secondsPerQuestion;
  bool _answered = false;
  String? _selected;
  Completer<void>? _opponentFinishCompleter;
  bool _waitingOpponent = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    _quizStartTime = DateTime.now();
    _listen();
    _startTimer();
    if (!widget.isHost) {
      widget.connection.send({'type': 'ready'});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    widget.connection.close();
    super.dispose();
  }

  static int _parseInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  void _listen() {
    _sub = widget.connection.messages.listen((msg) {
      final type = msg['type']?.toString();
      if (type != 'finish') return;
      final score = _parseInt(msg['score'] ?? msg['Score'], _opponentScore);
      final correctCount = _parseInt(msg['correctCount'] ?? msg['correct_count'], _opponentCorrect);
      final total = _parseInt(msg['total'] ?? msg['Total'], _opponentTotal);
      if (!mounted) return;
      setState(() {
        _opponentScore = score;
        _opponentCorrect = correctCount;
        _opponentTotal = total;
      });
      if (_opponentFinishCompleter != null && !_opponentFinishCompleter!.isCompleted) {
        _opponentFinishCompleter!.complete();
        _opponentFinishCompleter = null;
      }
    });
  }

  List<Question> _buildQuestions() {
    final pool = widget.topic == '全部'
        ? widget.data.questions
        : widget.data.questions.where((q) => q.topic == widget.topic).toList();
    final filtered = widget.subtopic == '全部'
        ? pool
        : pool.where((q) => q.subtopic == widget.subtopic).toList();
    final list = List<Question>.from(filtered.isEmpty ? pool : filtered);
    list.shuffle(Random(widget.seed));
    return list.take(min(widget.count, list.length)).toList();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _secondsPerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_answered) return;
      if (_remaining <= 1) {
        timer.cancel();
        _timeout();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _timeout() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selected = null;
    });
  }

  void _answer(String option) {
    if (_answered) return;
    final correct = _questions[_index].answer;
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
      if (option.startsWith(correct)) {
        _score += 10 + _remaining;
        _correct += 1;
      }
    });
  }

  void _goToResult(int totalSeconds) {
    final oppScore = _opponentScore;
    final oppCorrect = _opponentCorrect;
    final oppTotal = _opponentTotal > 0 ? _opponentTotal : _questions.length;
    final hasOpponentResult = _opponentTotal > 0;
    _opponentFinishCompleter = null;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LanDuelResultPage(
          myScore: _score,
          opponentScore: oppScore,
          myCorrect: _correct,
          myTotal: _questions.length,
          opponentCorrect: oppCorrect,
          opponentTotal: oppTotal,
          hasOpponentResult: hasOpponentResult,
          timeUsed: totalSeconds,
        ),
      ),
    );
  }

  void _skipWait() {
    if (_opponentFinishCompleter != null && !_opponentFinishCompleter!.isCompleted) {
      _opponentFinishCompleter!.complete();
      _opponentFinishCompleter = null;
    }
  }

  void _next() async {
    final done = _index + 1 >= _questions.length;
    if (done) {
      final totalSeconds = DateTime.now().difference(_quizStartTime).inSeconds;
      final finishPayload = {
        'type': 'finish',
        'score': _score,
        'correctCount': _correct,
        'total': _questions.length,
      };
      _send(finishPayload);
      for (final delay in [100, 400, 1000]) {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted) return;
        _send(finishPayload);
      }
      await ArenaPkRepository.submitScore(_score);
      final oppPhone = widget.opponentPhone?.trim() ?? '';
      if (oppPhone.isNotEmpty) {
        await ArenaDuelRepository.submitDuelRecord(
          opponentPhone: oppPhone,
          myScore: _score,
          opponentScore: _opponentScore,
        );
      }
      if (mounted) await ArenaStatsStore.syncFromServer();
      if (!mounted) return;
      if (_opponentTotal == 0) {
        _opponentFinishCompleter = Completer<void>();
        setState(() => _waitingOpponent = true);
        try {
          await _opponentFinishCompleter!.future.timeout(
            const Duration(seconds: _waitOpponentSeconds),
            onTimeout: () {},
          );
        } catch (_) {}
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
      }
      setState(() => _waitingOpponent = false);
      _goToResult(totalSeconds);
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _selected = null;
    });
    _startTimer();
  }

  void _send(Map<String, dynamic> data) {
    if (widget.room != null) {
      data = {...data, 'room': widget.room};
    }
    widget.connection.send(data);
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingOpponent) {
      return Scaffold(
        body: Stack(
          children: [
            const StarryBackground(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFF9F1C)),
                      const SizedBox(height: 24),
                      Text(
                        '等待对手提交…',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '对方交卷后会自动显示结果，也可先跳过',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextButton.icon(
                        onPressed: () {
                          _skipWait();
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 20),
                        label: const Text('跳过等待'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final q = _questions[_index];
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 6),
                      Text('局域网对战', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_index + 1) / _questions.length,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFFFF1D0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_index + 1}/${_questions.length}'),
                    ],
                  ),
                  if (_index > 0 || _answered) ...[
                    const SizedBox(height: 6),
                    Text(
                      '当前正确率：${_index + (_answered ? 1 : 0) > 0 ? (100 * _correct / (_index + (_answered ? 1 : 0))).round() : 0}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _remaining / _secondsPerQuestion,
                      backgroundColor: const Color(0xFFFFF1D0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFD166)),
                    ),
                    child: Text(q.title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 14),
                  ...q.options.map(
                    (opt) {
                      final isSelected = _selected == opt;
                      final isCorrect = _answered && opt.startsWith(q.answer);
                      final isWrong = _answered && isSelected && !isCorrect;
                      final color = isCorrect
                          ? const Color(0xFFB8F1E0)
                          : isWrong
                              ? const Color(0xFFFFD6D6)
                              : isSelected
                                  ? const Color(0xFFFFE1A8)
                                  : Colors.white;
                      return GestureDetector(
                        onTap: () => _answer(opt),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1E6CE)),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(opt)),
                              if (_answered && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6))
                              else if (_answered && isWrong)
                                const Icon(Icons.cancel_rounded, color: Color(0xFFE63946)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  if (_answered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _selected != null && _selected!.startsWith(q.answer)
                            ? '回答正确！继续下一题～'
                            : _selected == null
                                ? '时间到！正确答案：${q.answer}'
                                : '正确答案：${q.answer}，再接再厉！',
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _answered ? _next : null,
                      child: Text(_index + 1 == _questions.length ? '完成' : '下一题'),
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
}

class _DuelQuizPageState extends State<DuelQuizPage> {
  static const int _total = 10;
  static const int _secondsPerQuestion = 12;
  late final List<Question> _questions;
  Timer? _timer;
  Timer? _aiTimer;
  int _index = 0;
  int _score = 0;
  int _aiScore = 0;
  int _correct = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;
  late final DateTime _quizStartTime;
  int _remaining = _secondsPerQuestion;
  bool _answered = false;
  bool _aiAnswered = false;
  bool _autoAdvanceScheduled = false;
  String? _selected;

  @override
  void initState() {
    super.initState();
    final pool = widget.topic == '全部'
        ? widget.data.questions
        : widget.data.questions.where((q) => q.topic == widget.topic).toList();
    final filtered = widget.subtopic == '全部'
        ? pool
        : pool.where((q) => q.subtopic == widget.subtopic).toList();
    final list = List<Question>.from(filtered.isEmpty ? pool : filtered);
    list.shuffle(Random());
    final count = min(_total, list.length);
    _questions = list.take(count).toList();
    _quizStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _aiTimer?.cancel();
    _aiAnswered = false;
    setState(() => _remaining = _secondsPerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_answered) return;
      if (_remaining <= 1) {
        timer.cancel();
        _timeout();
      } else {
        setState(() => _remaining -= 1);
      }
    });
    _scheduleAiAnswer();
  }

  void _scheduleAiAnswer() {
    final rng = Random();
    final delay = rng.nextInt(7) + 2; // 2..8s
    if (delay >= _remaining) {
      return;
    }
    _aiTimer = Timer(Duration(seconds: delay), () {
      if (!mounted || _aiAnswered) return;
      _aiAnswered = true;
      final correct = _questions[_index].answer;
      final accuracy = 0.7;
      final willCorrect = rng.nextDouble() < accuracy;
      if (willCorrect) {
        _aiScore += 10 + (_remaining - delay).clamp(0, _secondsPerQuestion);
      }
      setState(() {});
    });
  }

  void _timeout() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selected = null;
      _currentStreak = 0;
    });
    if (_autoAdvanceScheduled) return;
    _autoAdvanceScheduled = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _next();
      }
    });
  }

  void _answer(String option) {
    if (_answered) return;
    final correct = _questions[_index].answer;
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
      if (option.startsWith(correct)) {
        _score += 10 + _remaining;
        _correct += 1;
        _currentStreak += 1;
        if (_currentStreak > _maxStreak) {
          _maxStreak = _currentStreak;
        }
        if (_currentStreak >= 2) {
          _score += 2 * (_currentStreak - 1);
        }
      } else {
        _currentStreak = 0;
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _timer?.cancel();
      _aiTimer?.cancel();
      final totalSeconds = DateTime.now().difference(_quizStartTime).inSeconds;
      final accuracy = _questions.isEmpty ? 0.0 : _correct / _questions.length;
      final bonus = accuracy >= 0.9 ? 30 : accuracy >= 0.8 ? 20 : accuracy >= 0.6 ? 10 : 0;
      final finalScore = _score + bonus;
      // 人机对战不写入个人积分与 PK 排行，仅展示结果
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            score: finalScore,
            total: _questions.length,
            correct: _correct,
            timeUsed: totalSeconds,
            maxStreak: _maxStreak,
            accuracyBonus: bonus,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _selected = null;
      _autoAdvanceScheduled = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 6),
                      Text('本地对战', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      _InfoChip(label: '我方', value: '$_score'),
                      const SizedBox(width: 6),
                      _InfoChip(label: '对手', value: '$_aiScore'),
                      const SizedBox(width: 8),
                      Text('${_index + 1}/${_questions.length}'),
                    ],
                  ),
                  if (_index > 0 || _answered) ...[
                    const SizedBox(height: 6),
                    Text(
                      '当前正确率：${(_index + (_answered ? 1 : 0)) > 0 ? (100 * _correct / (_index + (_answered ? 1 : 0))).round() : 0}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _remaining / _secondsPerQuestion,
                      backgroundColor: const Color(0xFFFFF1D0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFD166)),
                    ),
                    child: Text(q.title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 14),
                  ...q.options.map(
                    (opt) {
                      final isSelected = _selected == opt;
                      final isCorrect = _answered && opt.startsWith(q.answer);
                      final isWrong = _answered && isSelected && !isCorrect;
                      final color = isCorrect
                          ? const Color(0xFFB8F1E0)
                          : isWrong
                              ? const Color(0xFFFFD6D6)
                              : isSelected
                                  ? const Color(0xFFFFE1A8)
                                  : Colors.white;
                      return GestureDetector(
                        onTap: () => _answer(opt),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1E6CE)),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(opt)),
                              if (_answered && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6))
                              else if (_answered && isWrong)
                                const Icon(Icons.cancel_rounded, color: Color(0xFFE63946)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  if (_answered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _selected != null && _selected!.startsWith(q.answer)
                            ? '回答正确！继续下一题～'
                            : _selected == null
                                ? '时间到！正确答案：${q.answer}'
                                : '正确答案：${q.answer}，再接再厉！',
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _answered ? _next : null,
                      child: Text(_index + 1 == _questions.length ? '完成' : '下一题'),
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
}

class _QuizPageState extends State<QuizPage> {
  static const int _total = 10;
  static const int _secondsPerQuestion = 12;
  late final List<Question> _questions;
  Timer? _timer;
  int _index = 0;
  int _score = 0;
  int _correct = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;
  int _accuracyBonus = 0;
  late final DateTime _quizStartTime;
  int _remaining = _secondsPerQuestion;
  bool _answered = false;
  bool _autoAdvanceScheduled = false;
  String? _selected;
  /// 每题作答记录，仅在完成全部题目后随提交一起上报
  final List<Map<String, dynamic>> _answerRecords = [];

  @override
  void initState() {
    super.initState();
    final pool = widget.topic == '全部'
        ? widget.data.questions
        : widget.data.questions.where((q) => q.topic == widget.topic).toList();
    final filtered = widget.subtopic == '全部'
        ? pool
        : pool.where((q) => q.subtopic == widget.subtopic).toList();
    final list = List<Question>.from(filtered.isEmpty ? pool : filtered);
    list.shuffle(Random());
    final count = min(_total, list.length);
    _questions = list.take(count).toList();
    _quizStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _secondsPerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_answered) return;
      if (_remaining <= 1) {
        timer.cancel();
        _timeout();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _timeout() {
    if (_answered) return;
    final q = _questions[_index];
    _answerRecords.add({
      'questionId': q.id,
      'title': q.title,
      'userChoice': '',
      'correctAnswer': q.answer,
      'isCorrect': false,
    });
    setState(() {
      _answered = true;
      _selected = null;
      _currentStreak = 0;
    });
    if (_autoAdvanceScheduled) return;
    _autoAdvanceScheduled = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _next();
      }
    });
  }

  /// 从挑战提交接口返回中解析本次新解锁成就名称列表
  static List<String> _parseNewlyUnlockedNames(Map<String, dynamic>? res) {
    if (res == null) return [];
    final list = res['newlyUnlocked'];
    if (list is! List) return [];
    return list
        .map((e) => e is Map ? (e['name'] as String? ?? '').trim() : '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  void _answer(String option) {
    if (_answered) return;
    final q = _questions[_index];
    final correct = q.answer;
    final isCorrect = option.startsWith(correct);
    _answerRecords.add({
      'questionId': q.id,
      'title': q.title,
      'userChoice': option,
      'correctAnswer': correct,
      'isCorrect': isCorrect,
    });
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
      if (isCorrect) {
        _score += 10 + _remaining;
        _correct += 1;
        _currentStreak += 1;
        if (_currentStreak > _maxStreak) {
          _maxStreak = _currentStreak;
        }
        if (_currentStreak >= 2) {
          _score += 2 * (_currentStreak - 1);
        }
      } else {
        _currentStreak = 0;
      }
    });
  }

  Future<void> _next() async {
    if (_index + 1 >= _questions.length) {
      _timer?.cancel();
      final totalSeconds = DateTime.now().difference(_quizStartTime).inSeconds;
      final accuracy = _questions.isEmpty ? 0.0 : _correct / _questions.length;
      _accuracyBonus = accuracy >= 0.9
          ? 30
          : accuracy >= 0.8
              ? 20
              : accuracy >= 0.6
                  ? 10
                  : 0;
      final finalScore = _score + _accuracyBonus;
      // 仅在做完所有题目后提交到后端并记录得分；成就由接口根据本次+历史匹配后返回
      final res = await ArenaChallengeRepository.submitChallenge(
        topic: widget.topic,
        subtopic: widget.subtopic,
        totalQuestions: _questions.length,
        correctCount: _correct,
        score: finalScore,
        maxStreak: _maxStreak,
        answers: _answerRecords,
      );
      final newlyUnlockedNames = _parseNewlyUnlockedNames(res);
      if (mounted && res != null) {
        ArenaStatsStore.submit(
          score: finalScore,
          correct: _correct,
          topic: widget.topic,
          maxStreak: _maxStreak,
          accuracy: accuracy,
        );
      } else if (mounted) {
        // 提交失败仍更新本地统计，避免用户进度丢失
        ArenaStatsStore.submit(
          score: finalScore,
          correct: _correct,
          topic: widget.topic,
          maxStreak: _maxStreak,
          accuracy: accuracy,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            score: finalScore,
            total: _questions.length,
            correct: _correct,
            timeUsed: totalSeconds,
            maxStreak: _maxStreak,
            accuracyBonus: _accuracyBonus,
            newlyUnlockedNames: newlyUnlockedNames,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _selected = null;
      _autoAdvanceScheduled = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 6),
                      Text('个人答题', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      _InfoChip(label: '得分', value: '$_score'),
                      const SizedBox(width: 8),
                      _InfoChip(label: '剩余', value: '${_remaining}s'),
                      const SizedBox(width: 10),
                      Text('${_index + 1}/${_questions.length}'),
                    ],
                  ),
                  if (_index > 0 || _answered) ...[
                    const SizedBox(height: 6),
                    Text(
                      '当前正确率：${(_index + (_answered ? 1 : 0)) > 0 ? (100 * _correct / (_index + (_answered ? 1 : 0))).round() : 0}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFD166)),
                    ),
                    child: Text(q.title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _remaining / _secondsPerQuestion,
                      backgroundColor: const Color(0xFFFFF1D0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...q.options.map(
                    (opt) {
                      final isSelected = _selected == opt;
                      final isCorrect = _answered && opt.startsWith(q.answer);
                      final isWrong = _answered && isSelected && !isCorrect;
                      final color = isCorrect
                          ? const Color(0xFFB8F1E0)
                          : isWrong
                              ? const Color(0xFFFFD6D6)
                              : isSelected
                              ? const Color(0xFFFFE1A8)
                              : Colors.white;
                      return GestureDetector(
                        onTap: () => _answer(opt),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1E6CE)),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(opt)),
                              if (_answered && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6))
                              else if (_answered && isWrong)
                                const Icon(Icons.cancel_rounded, color: Color(0xFFE63946)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  if (_answered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _selected != null && _selected!.startsWith(q.answer)
                            ? '回答正确！继续下一题～'
                            : _selected == null
                                ? '时间到！正确答案：${q.answer}'
                                : '正确答案：${q.answer}，再接再厉！',
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _answered ? _next : null,
                      child: Text(_index + 1 == _questions.length ? '完成' : '下一题'),
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
}

/// 服务器对战页：通过房间号，不依赖局域网；完成后从服务器取对手成绩
class ServerDuelPage extends StatefulWidget {
  const ServerDuelPage({
    super.key,
    required this.roomId,
    required this.data,
    required this.topic,
    required this.subtopic,
    required this.seed,
    required this.count,
    required this.isHost,
    required this.opponentName,
  });

  final String roomId;
  final DemoData data;
  final String topic;
  final String subtopic;
  final int seed;
  final int count;
  final bool isHost;
  final String opponentName;

  @override
  State<ServerDuelPage> createState() => _ServerDuelPageState();
}

class _ServerDuelPageState extends State<ServerDuelPage> {
  static const int _secondsPerQuestion = 12;
  static const int _pollSeconds = 60;
  late final List<Question> _questions;
  Timer? _timer;
  int _index = 0;
  int _score = 0;
  int _correct = 0;
  late final DateTime _quizStartTime;
  int _remaining = _secondsPerQuestion;
  bool _answered = false;
  String? _selected;
  bool _waitingOpponent = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    _quizStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Question> _buildQuestions() {
    final pool = widget.topic == '全部'
        ? widget.data.questions
        : widget.data.questions.where((q) => q.topic == widget.topic).toList();
    final filtered = widget.subtopic == '全部'
        ? pool
        : pool.where((q) => q.subtopic == widget.subtopic).toList();
    final list = List<Question>.from(filtered.isEmpty ? pool : filtered);
    list.shuffle(Random(widget.seed));
    return list.take(min(widget.count, list.length)).toList();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _secondsPerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_answered) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _answered = true;
          _selected = null;
        });
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _answer(String option) {
    if (_answered) return;
    final correct = _questions[_index].answer;
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
      if (option.startsWith(correct)) {
        _score += 10 + _remaining;
        _correct += 1;
      }
    });
  }

  void _goToResult({
    required int totalSeconds,
    required int opponentScore,
    required int opponentCorrect,
    required int opponentTotal,
    required bool hasOpponentResult,
  }) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LanDuelResultPage(
          myScore: _score,
          opponentScore: opponentScore,
          myCorrect: _correct,
          myTotal: _questions.length,
          opponentCorrect: opponentCorrect,
          opponentTotal: opponentTotal,
          hasOpponentResult: hasOpponentResult,
          timeUsed: totalSeconds,
        ),
      ),
    );
  }

  Future<void> _next() async {
    final done = _index + 1 >= _questions.length;
    if (done) {
      final totalSeconds = DateTime.now().difference(_quizStartTime).inSeconds;
      await ArenaPkRepository.submitScore(_score);
      if (mounted) await ArenaStatsStore.syncFromServer();
      if (!mounted) return;
      final res = await ArenaDuelRepository.submitDuelRoomResult(
        roomId: widget.roomId,
        score: _score,
        correctCount: _correct,
        total: _questions.length,
      );
      if (!mounted) return;
      int oppScore = 0;
      int oppCorrect = 0;
      int oppTotal = _questions.length;
      bool hasOpponent = false;
      if (res != null &&
          res['opponentScore'] != null &&
          res['opponentCorrect'] != null &&
          res['opponentTotal'] != null) {
        oppScore = (res['opponentScore'] is int)
            ? res['opponentScore'] as int
            : (res['opponentScore'] as num).toInt();
        oppCorrect = (res['opponentCorrect'] is int)
            ? res['opponentCorrect'] as int
            : (res['opponentCorrect'] as num).toInt();
        oppTotal = (res['opponentTotal'] is int)
            ? res['opponentTotal'] as int
            : (res['opponentTotal'] as num).toInt();
        hasOpponent = true;
      }
      if (hasOpponent) {
        _goToResult(
          totalSeconds: totalSeconds,
          opponentScore: oppScore,
          opponentCorrect: oppCorrect,
          opponentTotal: oppTotal,
          hasOpponentResult: true,
        );
        return;
      }
      setState(() => _waitingOpponent = true);
      final deadline = DateTime.now().add(const Duration(seconds: _pollSeconds));
      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        final room = await ArenaDuelRepository.getDuelRoom(widget.roomId);
        if (room != null &&
            room['opponentScore'] != null &&
            room['opponentCorrect'] != null &&
            room['opponentTotal'] != null) {
          oppScore = (room['opponentScore'] is int)
              ? room['opponentScore'] as int
              : (room['opponentScore'] as num).toInt();
          oppCorrect = (room['opponentCorrect'] is int)
              ? room['opponentCorrect'] as int
              : (room['opponentCorrect'] as num).toInt();
          oppTotal = (room['opponentTotal'] is int)
              ? room['opponentTotal'] as int
              : (room['opponentTotal'] as num).toInt();
          if (mounted) setState(() => _waitingOpponent = false);
          _goToResult(
            totalSeconds: totalSeconds,
            opponentScore: oppScore,
            opponentCorrect: oppCorrect,
            opponentTotal: oppTotal,
            hasOpponentResult: true,
          );
          return;
        }
      }
      if (mounted) setState(() => _waitingOpponent = false);
      _goToResult(
        totalSeconds: totalSeconds,
        opponentScore: 0,
        opponentCorrect: 0,
        opponentTotal: _questions.length,
        hasOpponentResult: false,
      );
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _selected = null;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingOpponent) {
      return Scaffold(
        body: Stack(
          children: [
            const StarryBackground(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFF9F1C)),
                      const SizedBox(height: 24),
                      Text(
                        '等待对手提交…',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '对方交卷后会自动显示结果',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final q = _questions[_index];
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 6),
                      Text('双人对战', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_index + 1) / _questions.length,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFFFF1D0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_index + 1}/${_questions.length}'),
                    ],
                  ),
                  if (_index > 0 || _answered) ...[
                    const SizedBox(height: 6),
                    Text(
                      '当前正确率：${_index + (_answered ? 1 : 0) > 0 ? (100 * _correct / (_index + (_answered ? 1 : 0))).round() : 0}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...q.options.map((opt) {
                            final correct = q.answer;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _answer(opt),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _selected != null && _selected == opt
                                          ? const Color(0xFFFF9F1C)
                                          : const Color(0xFFE9E0C9),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          opt,
                                          style: TextStyle(
                                            color: _selected != null && opt.startsWith(correct)
                                                ? const Color(0xFF2E7D32)
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (_selected != null && _selected!.startsWith(correct) && opt == _selected)
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _answered ? _next : null,
                      child: Text(_index + 1 >= _questions.length ? '提交' : '下一题'),
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
}

/// 局域网对战结果页：仅显示胜负、我方得分、对手得分与对手答题结果
class LanDuelResultPage extends StatelessWidget {
  const LanDuelResultPage({
    super.key,
    required this.myScore,
    required this.opponentScore,
    required this.myCorrect,
    required this.myTotal,
    required this.opponentCorrect,
    required this.opponentTotal,
    required this.hasOpponentResult,
    required this.timeUsed,
  });

  final int myScore;
  final int opponentScore;
  final int myCorrect;
  final int myTotal;
  final int opponentCorrect;
  final int opponentTotal;
  /// 是否已收到对手的 finish 消息（未超时）
  final bool hasOpponentResult;
  final int timeUsed;

  bool get _isWin => myScore > opponentScore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isWin ? '胜利' : '失败',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _isWin ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD166)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('我的得分', '$myScore'),
                        const SizedBox(height: 12),
                        _row('对手得分', hasOpponentResult ? '$opponentScore' : '--'),
                        const SizedBox(height: 12),
                        _row(
                          '对手答题',
                          hasOpponentResult
                              ? '$opponentCorrect / $opponentTotal 题'
                              : '对手未完成',
                        ),
                        const SizedBox(height: 12),
                        _row('用时', '${timeUsed}s'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PK 分数已计入在线 PK 排行榜',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text('返回'),
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

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.correct,
    required this.timeUsed,
    required this.maxStreak,
    required this.accuracyBonus,
    this.newlyUnlockedNames,
  });

  final int score;
  final int total;
  final int correct;
  final int timeUsed;
  final int maxStreak;
  final int accuracyBonus;
  /// 接口返回的本轮新解锁成就名称列表；为 null 时使用本地 ArenaStatsStore.consumeNewBadges()
  final List<String>? newlyUnlockedNames;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> with SingleTickerProviderStateMixin {
  static const _space8 = 8.0;
  static const _space16 = 16.0;
  static const _space24 = 24.0;
  static const _space32 = 32.0;
  static const _radiusCard = 24.0;
  static const _radiusBtn = 16.0;

  late final AnimationController _stagger;
  late final List<Animation<double>> _reveals;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _reveals = List.generate(6, (i) {
      final start = (i * 0.08).clamp(0.0, 1.0);
      final end = ((i + 1) * 0.12 + 0.2).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _stagger.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final names = widget.newlyUnlockedNames != null
          ? List<String>.from(widget.newlyUnlockedNames!)
          : ArenaStatsStore.consumeNewBadges();
      if (names.isEmpty) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => AchievementUnlockPopup(names: names),
      );
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  String _evaluationText() {
    if (widget.total == 0) return '完成即胜利～';
    final pct = widget.correct / widget.total;
    if (pct >= 0.95) return '观察大师！几乎全对～';
    if (pct >= 0.8) return '很稳，离星光更近一步～';
    if (pct >= 0.6) return '继续加油，多练几遍会更稳～';
    return '再试一次，你一定可以～';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.total > 0 ? (widget.correct / widget.total * 100).round() : 0;
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _stagger,
                    builder: (_, __) => Opacity(
                      opacity: _reveals[0].value,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - _reveals[0].value)),
                        child: Text(
                          '成绩单',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: _space24),
                  AnimatedBuilder(
                    animation: _stagger,
                    builder: (_, __) => Opacity(
                      opacity: _reveals[1].value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _reveals[1].value)),
                        child: _ScoreHeroCard(score: widget.score),
                      ),
                    ),
                  ),
                  const SizedBox(height: _space24),
                  AnimatedBuilder(
                    animation: _stagger,
                    builder: (_, __) => Opacity(
                      opacity: _reveals[2].value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - _reveals[2].value)),
                        child: _StatsGrid(
                          correct: widget.correct,
                          total: widget.total,
                          timeUsed: widget.timeUsed,
                          accuracy: accuracy,
                          maxStreak: widget.maxStreak,
                          accuracyBonus: widget.accuracyBonus,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: _space24),
                  AnimatedBuilder(
                    animation: _stagger,
                    builder: (_, __) => Opacity(
                      opacity: _reveals[3].value,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - _reveals[3].value)),
                        child: _EvaluationCard(message: _evaluationText()),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _stagger,
                    builder: (_, __) => Opacity(
                      opacity: _reveals[5].value,
                      child: _BackButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
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
}

class _ScoreHeroCard extends StatelessWidget {
  const _ScoreHeroCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_QuizResultPageState._radiusCard),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F1C).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
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
          Text(
            '总分',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF6F6B60),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: const Color(0xFFB35C00),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.correct,
    required this.total,
    required this.timeUsed,
    required this.accuracy,
    required this.maxStreak,
    required this.accuracyBonus,
  });

  final int correct;
  final int total;
  final int timeUsed;
  final int accuracy;
  final int maxStreak;
  final int accuracyBonus;

  @override
  Widget build(BuildContext context) {
    final muted = const Color(0xFF6F6B60);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_QuizResultPageState._radiusCard),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.8)),
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
          Text(
            '答题明细',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(label: '正确题数', value: '$correct / $total', valueColor: const Color(0xFF2EC4B6)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(label: '用时', value: '${timeUsed}s', valueColor: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(label: '正确率', value: '$accuracy%', valueColor: const Color(0xFFB35C00)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(label: '最高连击', value: '$maxStreak', valueColor: muted),
              ),
            ],
          ),
          if (accuracyBonus > 0) ...[
            const SizedBox(height: 12),
            _StatItem(label: '准确率加分', value: '+$accuracyBonus', valueColor: const Color(0xFF2EC4B6)),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(_QuizResultPageState._radiusCard),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: const Color(0xFFB35C00).withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                '本次评价',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF6F6B60),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF3d3a35),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: const Color(0xFFFF9F1C),
        borderRadius: BorderRadius.circular(_QuizResultPageState._radiusBtn),
        elevation: 0,
        shadowColor: const Color(0xFFFF9F1C).withOpacity(0.4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_QuizResultPageState._radiusBtn),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_QuizResultPageState._radiusBtn),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 0,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '返回擂台',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
