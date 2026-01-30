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
  });

  final DuelConnection connection;
  final DemoData data;
  final String topic;
  final String subtopic;
  final int seed;
  final int count;
  final bool isHost;
  final String? room;

  @override
  State<LanDuelPage> createState() => _LanDuelPageState();
}

class _LanDuelPageState extends State<LanDuelPage> {
  static const int _secondsPerQuestion = 12;
  late final List<Question> _questions;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _sub;
  int _index = 0;
  int _score = 0;
  int _opponentScore = 0;
  int _correct = 0;
  int _remaining = _secondsPerQuestion;
  bool _answered = false;
  String? _selected;
  int _opponentIndex = 0;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
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

  void _listen() {
    _sub = widget.connection.messages.listen((msg) {
      switch (msg['type']) {
        case 'progress':
          setState(() {
            _opponentScore = (msg['score'] as num?)?.toInt() ?? _opponentScore;
            _opponentIndex = (msg['index'] as num?)?.toInt() ?? _opponentIndex;
          });
          break;
        case 'finish':
          setState(() {
            _opponentScore = (msg['score'] as num?)?.toInt() ?? _opponentScore;
            _opponentIndex = _questions.length;
          });
          break;
        case 'start':
          if (!widget.isHost) {
            // handled in join flow, ignore if duplicated
          }
          break;
        default:
          break;
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

  void _next() {
    final done = _index + 1 >= _questions.length;
    if (done) {
      _send({'type': 'finish', 'score': _score});
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            score: _score,
            total: _questions.length,
            correct: _correct,
            timeUsed: (_questions.length * _secondsPerQuestion) - _remaining,
            maxStreak: 0,
            accuracyBonus: 0,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _selected = null;
    });
    _send({
      'type': 'progress',
      'score': _score,
      'index': _index,
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
                      const Spacer(),
                      _InfoChip(label: '我方', value: '$_score'),
                      const SizedBox(width: 6),
                      _InfoChip(label: '对手', value: '$_opponentScore'),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_opponentIndex + 1) / _questions.length,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE8F3FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5DADE2)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('对手 ${_opponentIndex + 1}/${_questions.length}'),
                    ],
                  ),
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
  int _elapsedSeconds = 0;
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
      _elapsedSeconds += _secondsPerQuestion;
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
    final used = _secondsPerQuestion - _remaining;
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
      _elapsedSeconds += used;
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
      final accuracy = _questions.isEmpty ? 0.0 : _correct / _questions.length;
      final bonus = accuracy >= 0.9 ? 30 : accuracy >= 0.8 ? 20 : accuracy >= 0.6 ? 10 : 0;
      final finalScore = _score + bonus;
      ArenaStatsStore.submit(
        score: finalScore,
        correct: _correct,
        topic: widget.topic,
        maxStreak: _maxStreak,
        accuracy: accuracy,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            score: finalScore,
            total: _questions.length,
            correct: _correct,
            timeUsed: _elapsedSeconds,
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
  int _elapsedSeconds = 0;
  int _remaining = _secondsPerQuestion;
  bool _answered = false;
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
    setState(() {
      _answered = true;
      _selected = null;
      _currentStreak = 0;
      _elapsedSeconds += _secondsPerQuestion;
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
    final used = _secondsPerQuestion - _remaining;
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
      _elapsedSeconds += used;
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
      final accuracy = _questions.isEmpty ? 0.0 : _correct / _questions.length;
      _accuracyBonus = accuracy >= 0.9
          ? 30
          : accuracy >= 0.8
              ? 20
              : accuracy >= 0.6
                  ? 10
                  : 0;
      final finalScore = _score + _accuracyBonus;
      ArenaStatsStore.submit(
        score: finalScore,
        correct: _correct,
        topic: widget.topic,
        maxStreak: _maxStreak,
        accuracy: accuracy,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            score: finalScore,
            total: _questions.length,
            correct: _correct,
            timeUsed: _elapsedSeconds,
            maxStreak: _maxStreak,
            accuracyBonus: _accuracyBonus,
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

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.correct,
    required this.timeUsed,
    required this.maxStreak,
    required this.accuracyBonus,
  });

  final int score;
  final int total;
  final int correct;
  final int timeUsed;
  final int maxStreak;
  final int accuracyBonus;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newlyUnlocked = ArenaStatsStore.consumeNewBadges();
      if (newlyUnlocked.isEmpty) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => AchievementUnlockPopup(names: newlyUnlocked),
      );
    });
  }

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
                  Text('成绩单', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFD166)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('总分', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('${widget.score}', style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 10),
                        Text('正确题数：${widget.correct}/${widget.total}'),
                        const SizedBox(height: 6),
                        Text('用时：${widget.timeUsed}s'),
                        const SizedBox(height: 6),
                        Text('正确率：${(widget.correct / widget.total * 100).toStringAsFixed(0)}%'),
                        const SizedBox(height: 6),
                        Text('最高连击：${widget.maxStreak}'),
                        const SizedBox(height: 6),
                        Text('准确率加分：+${widget.accuracyBonus}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('本次评价', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 8),
                        Text('继续加油，离星光更近一步～'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('返回擂台'),
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
