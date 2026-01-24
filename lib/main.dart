import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileStore.init();
  runApp(const StarKnowApp());
}

class StarKnowApp extends StatelessWidget {
  const StarKnowApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF6D8);
    const textColor = Color(0xFF2B2B2B);
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFFF9F1C),
      onPrimary: Colors.white,
      secondary: Color(0xFF2EC4B6),
      onSecondary: Colors.white,
      error: Color(0xFFE63946),
      onError: Colors.white,
      background: background,
      onBackground: textColor,
      surface: Color(0xFFFFFFFF),
      onSurface: textColor,
    );

    final textTheme = ThemeData.light()
        .textTheme
        .apply(fontFamily: 'ZCOOLXiaoWei', bodyColor: textColor, displayColor: textColor);

    return MaterialApp(
      title: '星知',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            color: textColor,
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StarKnowShell()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _visible ? 1 : 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_awesome, size: 64, color: Color(0xFFFF9F1C)),
                  SizedBox(height: 14),
                  Text('星知', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('漫游知识的星空', style: TextStyle(color: Color(0xFF6F6B60))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoRepository {
  static Future<DemoData> load() async {
    final raw = await rootBundle.loadString('assets/data/demo.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DemoData.fromJson(map);
  }
}

final Future<DemoData> demoDataFuture = DemoRepository.load();

class UserProfile {
  const UserProfile({
    required this.name,
    required this.avatarIndex,
    required this.avatarBase64,
  });

  final String name;
  final int avatarIndex;
  final String? avatarBase64;

  UserProfile copyWith({String? name, int? avatarIndex, String? avatarBase64}) {
    return UserProfile(
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
    );
  }

  static UserProfile defaultProfile() {
    return const UserProfile(name: '星知小探险家', avatarIndex: 0, avatarBase64: null);
  }
}

class ProfileStore {
  static const _nameKey = 'profile_name';
  static const _avatarKey = 'profile_avatar';
  static const _avatarImageKey = 'profile_avatar_image';

  static final ValueNotifier<UserProfile> profile =
      ValueNotifier<UserProfile>(UserProfile.defaultProfile());

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_nameKey);
      final avatarIndex = prefs.getInt(_avatarKey);
      final avatarImage = prefs.getString(_avatarImageKey);
      profile.value = profile.value.copyWith(
        name: name,
        avatarIndex: avatarIndex,
        avatarBase64: avatarImage,
      );
    } on MissingPluginException {
      // Fallback to in-memory profile when plugins are not registered (e.g. hot restart).
      profile.value = UserProfile.defaultProfile();
    }
  }

  static Future<void> update(UserProfile next) async {
    profile.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, next.name);
      await prefs.setInt(_avatarKey, next.avatarIndex);
      if (next.avatarBase64 == null) {
        await prefs.remove(_avatarImageKey);
      } else {
        await prefs.setString(_avatarImageKey, next.avatarBase64!);
      }
    } on MissingPluginException {
      // Ignore persistence if plugin isn't available.
    }
  }
}

const _avatarColors = [
  Color(0xFFFFD166),
  Color(0xFFBFD7FF),
  Color(0xFFB8F1E0),
  Color(0xFFFFC857),
  Color(0xFFF4A261),
  Color(0xFF9BDEAC),
];

const _avatarIcons = [
  Icons.star_rounded,
  Icons.explore_rounded,
  Icons.lightbulb_rounded,
  Icons.sports_basketball_rounded,
  Icons.pets_rounded,
  Icons.rocket_launch_rounded,
];

Widget buildAvatar(int index, {double size = 36, String? base64Image}) {
  if (base64Image != null && base64Image.isNotEmpty) {
    final bytes = base64Decode(base64Image);
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
    );
  }
  final safeIndex = index % _avatarColors.length;
  return CircleAvatar(
    radius: size / 2,
    backgroundColor: _avatarColors[safeIndex],
    child: Icon(_avatarIcons[safeIndex], color: Colors.white, size: size * 0.55),
  );
}

class DemoData {
  DemoData({
    required this.topics,
    required this.contents,
    required this.questions,
    required this.achievements,
  });

  final List<Topic> topics;
  final List<ContentItem> contents;
  final List<Question> questions;
  final List<Achievement> achievements;

  factory DemoData.fromJson(Map<String, dynamic> json) {
    return DemoData(
      topics: (json['topics'] as List<dynamic>? ?? [])
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList(),
      contents: (json['contents'] as List<dynamic>? ?? [])
          .map((item) => ContentItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static DemoData fallback() {
    return DemoData(
      topics: const [
        Topic(id: 'basketball', name: '篮球'),
        Topic(id: 'history', name: '历史'),
        Topic(id: 'nature', name: '自然'),
        Topic(id: 'geography', name: '地理'),
        Topic(id: 'science', name: '科学'),
      ],
      contents: const [
        ContentItem(
          id: 'c1',
          title: '篮球为什么是五个人？',
          summary: '从战术分工到场地尺寸，三分钟搞懂。',
          tag: '篮球小百科',
          videoLabel: '抖音 · 2:30',
          accent: Color(0xFFFFC857),
          type: 'video',
          source: '抖音',
          url: '',
          imageUrl: '',
        ),
        ContentItem(
          id: 'c2',
          title: '唐朝有多开放？',
          summary: '从服饰、音乐到城市生活，看看大唐风。',
          tag: '历史故事',
          videoLabel: 'B 站 · 6:45',
          accent: Color(0xFF5DADE2),
          type: 'video',
          source: 'B站',
          url: '',
          imageUrl: '',
        ),
        ContentItem(
          id: 'c3',
          title: '为什么星星会闪烁？',
          summary: '空气折射让星光跳舞。',
          tag: '自然科学',
          videoLabel: '小红书 · 图文',
          accent: Color(0xFFB784F8),
          type: 'article',
          source: '小红书',
          url: '',
          imageUrl: '',
        ),
        ContentItem(
          id: 'c4',
          title: '熊猫为什么爱竹子？',
          summary: '挑食还是进化选择？',
          tag: '动物观察',
          videoLabel: '百科 · 图文',
          accent: Color(0xFF6DD3CE),
          type: 'article',
          source: '科普站点',
          url: '',
          imageUrl: '',
        ),
      ],
      questions: const [
        Question(
          id: 'q1',
          title: '“丝绸之路”最繁盛的时期是？',
          options: ['A. 唐朝', 'B. 汉朝', 'C. 明朝', 'D. 清朝'],
          answer: 'A',
          topic: '历史',
        ),
      ],
      achievements: const [
        Achievement(id: 'a1', name: '闪亮新星'),
        Achievement(id: 'a2', name: '连胜三场'),
        Achievement(id: 'a3', name: '探索家'),
        Achievement(id: 'a4', name: '观察大师'),
        Achievement(id: 'a5', name: '历史小通'),
        Achievement(id: 'a6', name: '篮球达人'),
      ],
    );
  }
}

class Topic {
  const Topic({required this.id, required this.name});

  final String id;
  final String name;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.tag,
    required this.videoLabel,
    required this.accent,
    required this.type,
    required this.source,
    required this.url,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String summary;
  final String tag;
  final String videoLabel;
  final Color accent;
  final String type;
  final String source;
  final String url;
  final String imageUrl;

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final accentHex = json['accent'] as String? ?? '#FFC857';
    return ContentItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      videoLabel: json['videoLabel'] as String? ?? '',
      accent: _parseColor(accentHex),
      type: json['type'] as String? ?? 'video',
      source: json['source'] as String? ?? '来源',
      url: json['url'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.title,
    required this.options,
    required this.answer,
    required this.topic,
  });

  final String id;
  final String title;
  final List<String> options;
  final String answer;
  final String topic;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      answer: json['answer'] as String? ?? '',
      topic: json['topic'] as String? ?? '全部',
    );
  }
}

class Achievement {
  const Achievement({required this.id, required this.name});

  final String id;
  final String name;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0xFFC857;
  if (cleaned.length <= 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value);
}

class StarKnowShell extends StatefulWidget {
  const StarKnowShell({super.key});

  @override
  State<StarKnowShell> createState() => _StarKnowShellState();
}

class _StarKnowShellState extends State<StarKnowShell> {
  int _index = 0;

  final _pages = const [
    GrowthPage(),
    CommunityPage(),
    AssistantPage(),
    ArenaPage(),
    LearningPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: SizedBox(
        height: 110,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    label: '成长',
                    icon: Icons.emoji_events_rounded,
                    isActive: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _NavItem(
                    label: '社群',
                    icon: Icons.forum_rounded,
                    isActive: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  const SizedBox(width: 48),
                  _NavItem(
                    label: '擂台',
                    icon: Icons.sports_esports_rounded,
                    isActive: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                  _NavItem(
                    label: '学习',
                    icon: Icons.home_rounded,
                    isActive: _index == 4,
                    onTap: () => setState(() => _index = 4),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 34,
              child: _AssistantOrb(
                isActive: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFFF9F1C) : const Color(0xFFB0A58A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF2CC) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantOrb extends StatefulWidget {
  const _AssistantOrb({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<_AssistantOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.isActive ? 0.65 : 0.4;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final scale = 1 + (_pulse.value * 0.06);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC857), Color(0xFFFF9F1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9F1C).withOpacity(glow),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 14,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _typeFilter = '全部';
  String _sourceFilter = '全部';
  Set<String> _topicFilters = {'全部'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContentItem> _filterContents(List<ContentItem> items) {
    final q = _query.trim();
    return items.where((item) {
      final matchesQuery = q.isEmpty ||
          item.title.contains(q) ||
          item.summary.contains(q) ||
          item.tag.contains(q) ||
          item.source.contains(q);
      final matchesType = _typeFilter == '全部' || item.type == _typeFilter;
      final matchesSource = _sourceFilter == '全部' || item.source == _sourceFilter;
      final activeTopics = _topicFilters.contains('全部') ? <String>{} : _topicFilters;
      final matchesTopic = activeTopics.isEmpty || activeTopics.any((t) => item.tag.contains(t));
      return matchesQuery && matchesType && matchesSource && matchesTopic;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<DemoData>(
            future: demoDataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? DemoData.fallback();
              final sources = [
                '全部',
                ...{...data.contents.map((c) => c.source)}
              ];
              final tags = [
                '全部',
                ...{...data.contents.map((c) => c.tag.split(' ').first)}
              ];
              final filtered = _filterContents(data.contents);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Text('学习', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  SearchBarCard(
                    controller: _searchController,
                    onSubmitted: (value) => setState(() => _query = value),
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: 18),
                  FilterRow(
                    typeValue: _typeFilter,
                    sourceValue: _sourceFilter,
                    sources: sources,
                    topics: tags,
                    onTypeChanged: (value) => setState(() => _typeFilter = value),
                    onSourceChanged: (value) => setState(() => _sourceFilter = value),
                    topicValues: _topicFilters,
                    onTopicsChanged: (values) => setState(() => _topicFilters = values),
                  ),
                  const SizedBox(height: 16),
                  Text('精选内容', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 120,
                    child: filtered.isEmpty
                        ? const EmptyStateCard()
                        : ContentMasonry(contents: filtered),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = DemoData.fallback();
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Text('兴趣社群', style: Theme.of(context).textTheme.headlineLarge),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('加入新社群功能开发中')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9E0C9)),
                      ),
                      child: const Icon(Icons.add_rounded, color: Color(0xFFFF9F1C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('和同好一起探索'),
              const SizedBox(height: 18),
              const CommunityComposer(),
              const SizedBox(height: 18),
              Text('已加入', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: data.topics
                    .take(4)
                    .map((topic) => TopicChip(label: '${topic.name}圈'))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text('今日热门话题', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Reveal(
                delay: 140,
                child: CommunityMasonry(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text('AI 助手', style: Theme.of(context).textTheme.headlineLarge),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD166)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: Color(0xFFFF9F1C)),
                          SizedBox(width: 6),
                          Text('历史记录'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: ChatHistory(),
              ),
              const ChatComposer(),
            ],
          ),
        ),
      ],
    );
  }
}

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  String _selectedTopic = '全部';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<DemoData>(
            future: demoDataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? DemoData.fallback();
              final topics = ['全部', ...data.topics.map((t) => t.name)];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Text('知识擂台', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  const Text('快问快答，看谁最闪'),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: topics.map((topic) {
                        final active = topic == _selectedTopic;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTopic = topic),
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
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 0,
                    child: ArenaHero(
                      onStart: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuizPage(topic: _selectedTopic),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('排行榜', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Reveal(
                    delay: 140,
                    child: LeaderboardCard(
                      title: '在线 PK 排行',
                      entries: [
                        LeaderboardEntry(rank: 1, name: '星知战神', score: '2350'),
                        LeaderboardEntry(rank: 2, name: '小小挑战王', score: '2190'),
                        LeaderboardEntry(rank: 3, name: '知识飞船', score: '2045'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Reveal(
                    delay: 220,
                    child: LeaderboardCard(
                      title: '个人积分排行',
                      entries: [
                        LeaderboardEntry(rank: 1, name: '你', score: '1860'),
                        LeaderboardEntry(rank: 2, name: '小星星', score: '1740'),
                        LeaderboardEntry(rank: 3, name: '光速答题王', score: '1695'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('分区榜', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Reveal(
                    delay: 300,
                    child: ZoneLeaderboardRow(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class GrowthPage extends StatelessWidget {
  const GrowthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<DemoData>(
            future: demoDataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? DemoData.fallback();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Row(
                    children: [
                      Text('成长', style: Theme.of(context).textTheme.headlineLarge),
                      const Spacer(),
                      ValueListenableBuilder<UserProfile>(
                        valueListenable: ProfileStore.profile,
                        builder: (context, profile, _) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfilePage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE9E0C9)),
                              ),
                              child: Row(
                                children: [
                                  buildAvatar(
                                    profile.avatarIndex,
                                    size: 28,
                                    base64Image: profile.avatarBase64,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(profile.name, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('每日提醒与打卡进度'),
                  const SizedBox(height: 14),
                  const Reveal(
                    delay: 60,
                    child: ReminderBar(),
                  ),
                  const SizedBox(height: 18),
                  const Reveal(
                    delay: 120,
                    child: GrowthStats(),
                  ),
                  const SizedBox(height: 18),
                  Text('每日任务', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Reveal(
                    delay: 180,
                    child: DailyTasksCard(),
                  ),
                  const SizedBox(height: 20),
                  Text('今日学习', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 220,
                    child: TodayLearningCard(
                      title: data.contents.isNotEmpty ? data.contents.first.title : '还没有学习内容',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class StarryBackground extends StatelessWidget {
  const StarryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF6D8), Color(0xFFFDE2B1), Color(0xFFFFFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(color: Color(0xFFFFD166), size: 180),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _GlowCircle(color: Color(0xFFB8F1E0), size: 160),
          ),
          Positioned(
            top: 260,
            left: 220,
            child: _GlowCircle(color: Color(0xFFBFD7FF), size: 120),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC857), Color(0xFFFF9F1C)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F1C).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 识图小助手',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  '拍一拍，马上知道。',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '开始识图',
                    style: TextStyle(color: Color(0xFFFF9F1C), fontWeight: FontWeight.w700),
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

class TopicChip extends StatelessWidget {
  const TopicChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
    );
  }
}

class SearchBarCard extends StatelessWidget {
  const SearchBarCard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E0C9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9A8F77)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: '搜索你感兴趣的知识',
                hintStyle: TextStyle(color: Color(0xFF9A8F77)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF9A8F77),
            )
          else
            const Icon(Icons.tune_rounded, color: Color(0xFF9A8F77)),
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E0C9)),
      ),
      child: const Text('没有找到相关内容，换个关键词试试吧。'),
    );
  }
}

class FilterRow extends StatelessWidget {
  const FilterRow({
    super.key,
    required this.typeValue,
    required this.sourceValue,
    required this.sources,
    required this.topics,
    required this.onTypeChanged,
    required this.onSourceChanged,
    required this.topicValues,
    required this.onTopicsChanged,
  });

  final String typeValue;
  final String sourceValue;
  final Set<String> topicValues;
  final List<String> sources;
  final List<String> topics;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<Set<String>> onTopicsChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChip(
          label: '类型',
          value: typeValue,
          options: const ['全部', 'video', 'article'],
          onSelected: onTypeChanged,
          display: const {'video': '视频', 'article': '图文'},
        ),
        _FilterChip(
          label: '平台',
          value: sourceValue,
          options: sources,
          onSelected: onSourceChanged,
        ),
        _MultiFilterChip(
          label: '主题',
          values: topicValues,
          options: topics,
          onSelected: onTopicsChanged,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.display = const {},
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final Map<String, String> display;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (opt) => ListTile(
                    title: Text(display[opt] ?? opt),
                    trailing: opt == value ? const Icon(Icons.check_rounded) : null,
                    onTap: () {
                      onSelected(opt);
                      Navigator.of(context).pop();
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9E0C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ${display[value] ?? value}'),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MultiFilterChip extends StatelessWidget {
  const _MultiFilterChip({
    required this.label,
    required this.values,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final Set<String> values;
  final List<String> options;
  final ValueChanged<Set<String>> onSelected;

  @override
  Widget build(BuildContext context) {
    final display = values.contains('全部')
        ? '全部'
        : values.isEmpty
            ? '全部'
            : values.join(' / ');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final current = Set<String>.from(values);
          return StatefulBuilder(
            builder: (context, setState) {
              return ListView(
                shrinkWrap: true,
                children: options.map((opt) {
                  final checked = current.contains(opt);
                  return CheckboxListTile(
                    title: Text(opt),
                    value: checked,
                    onChanged: (value) {
                      setState(() {
                        if (opt == '全部') {
                          current
                            ..clear()
                            ..add('全部');
                        } else {
                          current.remove('全部');
                          if (value == true) {
                            current.add(opt);
                          } else {
                            current.remove(opt);
                          }
                          if (current.isEmpty) {
                            current.add('全部');
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9E0C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: $display'),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class ContentMasonry extends StatelessWidget {
  const ContentMasonry({super.key, required this.contents});

  final List<ContentItem> contents;

  @override
  Widget build(BuildContext context) {
    final left = <ContentItem>[];
    final right = <ContentItem>[];
    for (var i = 0; i < contents.length; i++) {
      if (i.isEven) {
        left.add(contents[i]);
      } else {
        right.add(contents[i]);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ContentCard(item: item),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: right
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ContentCard(item: item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final mediaHeight = item.type == 'video' ? 120.0 : 150.0;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        if (item.url.isNotEmpty) {
          final uri = Uri.tryParse(item.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.url.isEmpty ? '将跳转到 ${item.source} 查看内容' : '无法打开链接，稍后再试',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: item.accent.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: mediaHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF6F1E3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl.isNotEmpty)
                    Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: item.accent.withOpacity(0.3),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.accent.withOpacity(0.2),
                            item.accent.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  if (item.type == 'video')
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF9F1C)),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(item.type == 'video' ? '视频' : '图文'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Text(item.tag, style: TextStyle(color: item.accent, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(item.source, style: const TextStyle(fontSize: 12, color: Color(0xFF6F6B60))),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(item.summary, style: const TextStyle(color: Color(0xFF6F6B60))),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F1E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.videoLabel, style: const TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                const Icon(Icons.open_in_new_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatHistory extends StatelessWidget {
  const ChatHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = const [
      _ChatMessage(
        isUser: false,
        text: '你好！我可以识图和回答问题～',
      ),
      _ChatMessage(
        isUser: true,
        text: '为什么天空是蓝色的？',
      ),
      _ChatMessage(
        isUser: false,
        text: '因为太阳光通过大气时，蓝光更容易散射，所以我们看到蓝色。',
      ),
      _ChatMessage(
        isUser: true,
        imageLabel: '上传了一张图片',
      ),
      _ChatMessage(
        isUser: false,
        text: '识别结果：向日葵。向日葵会朝着阳光转动哦～',
      ),
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: messages[index]);
      },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, this.text, this.imageLabel});

  final bool isUser;
  final String? text;
  final String? imageLabel;
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isUser ? const Color(0xFFFFE1A8) : Colors.white;
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(message.isUser ? 18 : 6),
      bottomRight: Radius.circular(message.isUser ? 6 : 18),
    );
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: message.imageLabel != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFD7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(message.imageLabel!),
                ],
              )
            : Text(message.text ?? ''),
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.image_rounded),
            color: const Color(0xFFFF9F1C),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('输入问题或发送图片…'),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F1C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class CommunityHero extends StatelessWidget {
  const CommunityHero({super.key});

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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFB8F1E0), Color(0xFF2EC4B6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.group_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('加入兴趣圈', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('和同好一起闯关'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('去看看'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityComposer extends StatelessWidget {
  const CommunityComposer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E0C9)),
      ),
      child: Row(
        children: [
          buildAvatar(ProfileStore.profile.value.avatarIndex,
              base64Image: ProfileStore.profile.value.avatarBase64, size: 36),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '说点什么吧…',
              style: TextStyle(color: Color(0xFF9A8F77)),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('动态发布功能开发中')),
              );
            },
            child: const Text('发布'),
          ),
        ],
      ),
    );
  }
}

class CommunityMasonry extends StatelessWidget {
  const CommunityMasonry({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = const [
      _PostData(
        title: '为什么猫咪爱晒太阳？',
        summary: '一起聊聊小动物的温暖秘密。',
        color: Color(0xFFBFD7FF),
      ),
      _PostData(
        title: '你最喜欢的历史人物是谁？',
        summary: '留言区见～',
        color: Color(0xFFFFC857),
      ),
      _PostData(
        title: '哪一刻让你爱上科学？',
        summary: '分享一个小实验～',
        color: Color(0xFFB8F1E0),
      ),
      _PostData(
        title: '篮球招式大揭秘',
        summary: '从三步上篮说起。',
        color: Color(0xFF5DADE2),
      ),
      _PostData(
        title: '我做了个小程序！',
        summary: '用 Scratch 做小游戏～',
        color: Color(0xFF9BDEAC),
      ),
      _PostData(
        title: '长城到底有多长？',
        summary: '来聊聊历史建筑。',
        color: Color(0xFF5DADE2),
      ),
    ];
    final left = posts.where((p) => posts.indexOf(p).isEven).toList();
    final right = posts.where((p) => posts.indexOf(p).isOdd).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TopicPostCard(data: post),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: right
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TopicPostCard(data: post),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PostData {
  const _PostData({required this.title, required this.summary, required this.color});

  final String title;
  final String summary;
  final Color color;
}

class TopicPostCard extends StatelessWidget {
  const TopicPostCard({super.key, required this.data});

  final _PostData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PublicProfilePage(
              name: '星知小记者',
              avatarIndex: 1,
              bio: '喜欢动物和科学，欢迎来聊天～',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: data.color.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: data.color,
                  child: const Icon(Icons.face_rounded, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '星知小记者',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('2 小时前', style: TextStyle(fontSize: 11, color: Color(0xFF8A8370))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(data.summary),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                Icon(Icons.favorite_border_rounded, size: 18),
                Text('128'),
                Icon(Icons.chat_bubble_outline_rounded, size: 18),
                Text('36'),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showCommentSheet(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('评论'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArenaHero extends StatelessWidget {
  const ArenaHero({super.key, required this.onStart});

  final VoidCallback onStart;

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
              child: Text('60s', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('极速挑战', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('10 题 · 连击加分'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onStart,
                  child: const Text('开始对战'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({required this.rank, required this.name, required this.score});

  final int rank;
  final String name;
  final String score;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1D0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.rank}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(entry.score, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ZoneLeaderboardRow extends StatelessWidget {
  const ZoneLeaderboardRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ZoneLeaderboardCard(
          title: '篮球区榜',
          leader: '运球大师',
          score: '1320',
          color: Color(0xFFFFC857),
        ),
        SizedBox(height: 12),
        ZoneLeaderboardCard(
          title: '历史区榜',
          leader: '唐宋小能手',
          score: '1180',
          color: Color(0xFF5DADE2),
        ),
        SizedBox(height: 12),
        ZoneLeaderboardCard(
          title: '科学区榜',
          leader: '宇宙探险家',
          score: '1040',
          color: Color(0xFFB8F1E0),
        ),
      ],
    );
  }
}

class ZoneLeaderboardCard extends StatelessWidget {
  const ZoneLeaderboardCard({
    super.key,
    required this.title,
    required this.leader,
    required this.score,
    required this.color,
  });

  final String title;
  final String leader;
  final String score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(score, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.topic});

  final String topic;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const int _total = 10;
  late final List<Question> _questions;
  int _index = 0;
  int _score = 0;
  bool _answered = false;
  String? _selected;

  @override
  void initState() {
    super.initState();
    final data = DemoData.fallback();
    final pool = widget.topic == '全部'
        ? data.questions
        : data.questions.where((q) => q.topic == widget.topic).toList();
    final list = List<Question>.from(pool);
    list.shuffle(Random());
    _questions = list.take(_total).toList();
  }

  void _answer(String option) {
    if (_answered) return;
    final correct = _questions[_index].answer;
    setState(() {
      _selected = option;
      _answered = true;
      if (option.startsWith(correct)) {
        _score += 10;
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(score: _score, total: _questions.length),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _answered = false;
      _selected = null;
    });
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
                      Text('${_index + 1}/$_total'),
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

class QuizResultPage extends StatelessWidget {
  const QuizResultPage({super.key, required this.score, required this.total});

  final int score;
  final int total;

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
                        Text('$score', style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 10),
                        Text('正确题数：${score ~/ 10}/$total'),
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
class GrowthStats extends StatelessWidget {
  const GrowthStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _StatItem(value: '7', label: '连续天数'),
          _StatItem(value: '86%', label: '正确率'),
          _StatItem(value: '9', label: '徽章'),
        ],
      ),
    );
  }
}

class DailyTasksCard extends StatelessWidget {
  const DailyTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = const [
      '学习一个新知识点',
      '观看一个视频或图文',
      '参与一次擂台',
      '参与一次社群讨论',
    ];
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
          Row(
            children: const [
              Icon(Icons.today_rounded, color: Color(0xFFFF9F1C)),
              SizedBox(width: 8),
              Text('今日打卡进度'),
              Spacer(),
              Text('1/4', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFC857)),
                      color: task == tasks.first ? const Color(0xFFFFC857) : Colors.transparent,
                    ),
                    child: task == tasks.first
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(task)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayLearningCard extends StatelessWidget {
  const TodayLearningCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFBFD7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今天要学', style: TextStyle(color: Color(0xFF6F6B60))),
                const SizedBox(height: 6),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, this.showEdit});

  final bool? showEdit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile>(
      valueListenable: ProfileStore.profile,
      builder: (context, profile, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _avatarColors[profile.avatarIndex % _avatarColors.length]
                              .withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: buildAvatar(
                      profile.avatarIndex,
                      size: 64,
                      base64Image: profile.avatarBase64,
                    ),
                  ),
                  if (showEdit == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Lv.3 · 今日已学习 18 分钟'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReminderBar extends StatelessWidget {
  const ReminderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_active_rounded, color: Color(0xFFFF9F1C)),
              SizedBox(width: 8),
              Text('每日提醒'),
              Spacer(),
              Text('20:00', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('今天还差 3 项打卡，加油！'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.25,
              minHeight: 8,
              backgroundColor: const Color(0xFFFFEAC0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = DemoData.fallback();
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text('个人主页', style: Theme.of(context).textTheme.headlineLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => showEditProfileSheet(context),
                      child: const Text('编辑资料'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ProfileHeader(showEdit: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFFFD166)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('等级'),
                      SizedBox(height: 6),
                      Text('Lv.3 · 星光探索者', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.62,
                        minHeight: 8,
                        backgroundColor: Color(0xFFFFEAC0),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ValueListenableBuilder<UserProfile>(
                    valueListenable: ProfileStore.profile,
                    builder: (context, profile, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('基础信息', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          _InfoRow(label: '昵称', value: profile.name),
                          const _InfoRow(label: '年龄', value: '9 岁'),
                          const _InfoRow(label: '兴趣', value: '篮球 / 科学'),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('成就墙', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                BadgeWall(badges: data.achievements.map((item) => item.name).toList()),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE9E0C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('个人圈', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('今天学会了“为什么天空是蓝色的”～'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.favorite_border_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('12'),
                          SizedBox(width: 16),
                          Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('3'),
                          Spacer(),
                          Text('发布动态', style: TextStyle(color: Color(0xFFFF9F1C))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE9E0C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('交友', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 10),
                      _SettingRow(label: '添加好友', value: '搜索或扫码'),
                      _SettingRow(label: '好友申请', value: '2 条新申请'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE9E0C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('设置', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 10),
                      _SettingRow(label: '学习提醒', value: '20:00'),
                      _SettingRow(label: '隐私', value: '默认'),
                      _SettingRow(label: '账户绑定', value: '未绑定'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Color(0xFF6F6B60)))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Color(0xFF6F6B60)))),
          Expanded(child: Text(value)),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0A58A)),
        ],
      ),
    );
  }
}

class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({
    super.key,
    required this.name,
    required this.avatarIndex,
    required this.bio,
  });

  final String name;
  final int avatarIndex;
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text('TA 的主页', style: Theme.of(context).textTheme.headlineLarge),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      buildAvatar(avatarIndex, size: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(bio, style: const TextStyle(color: Color(0xFF6F6B60))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9F1C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('加好友', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('TA 的成就', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const BadgeWall(
                  badges: ['好奇宝宝', '探索家', '连续学习 7 天'],
                ),
                const SizedBox(height: 16),
                const Text('TA 的动态', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('今天学会了“为什么猫咪爱晒太阳”～'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showCommentSheet(BuildContext context) async {
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('发表评论', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '说点什么吧…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('评论已发布（本地演示）')),
                  );
                },
                child: const Text('发布'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _GraphemeLimitFormatter extends TextInputFormatter {
  _GraphemeLimitFormatter(this.maxChars);

  final int maxChars;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final characters = newValue.text.characters;
    if (characters.length <= maxChars) {
      return newValue;
    }
    final truncated = characters.take(maxChars).toString();
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}

Future<void> showEditProfileSheet(BuildContext context) async {
  final current = ProfileStore.profile.value;
  final controller = TextEditingController(text: current.name);
  var selectedAvatar = current.avatarIndex;
  String? selectedBase64 = current.avatarBase64;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('编辑资料', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  inputFormatters: [_GraphemeLimitFormatter(8)],
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    final count = controller.text.characters.length;
                    return Text('$count/8');
                  },
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('选择头像'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          final base64Image = base64Encode(bytes);
                          setState(() => selectedBase64 = base64Image);
                        }
                      },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('相册'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (selectedBase64 != null) ...[
                  Row(
                    children: [
                      ClipOval(
                        child: buildAvatar(selectedAvatar, size: 44, base64Image: selectedBase64),
                      ),
                      const SizedBox(width: 10),
                      const Text('已选择相册头像（圆形裁剪预览）'),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => selectedBase64 = null),
                        child: const Text('移除'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_avatarColors.length, (index) {
                    final isSelected = index == selectedAvatar;
                    return GestureDetector(
                      onTap: () => setState(() {
                        selectedAvatar = index;
                        selectedBase64 = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF9F1C) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: buildAvatar(index, size: 44),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim().isEmpty
                          ? UserProfile.defaultProfile().name
                          : controller.text.trim();
                      final trimmed = name.length > 8 ? name.substring(0, 8) : name;
                      ProfileStore.update(
                        current.copyWith(
                          name: trimmed,
                          avatarIndex: selectedAvatar,
                          avatarBase64: selectedBase64,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class GrowthCardRow extends StatelessWidget {
  const GrowthCardRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _GrowthCard(
            title: '连续学习',
            value: '7 天',
            color: Color(0xFFFFD166),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _GrowthCard(
            title: '本周挑战',
            value: '3 / 5',
            color: Color(0xFFB8F1E0),
          ),
        ),
      ],
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF6F6B60))),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF6F6B60))),
      ],
    );
  }
}

class BadgeWall extends StatelessWidget {
  const BadgeWall({super.key, required this.badges});

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badges
          .map(
            (badge) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFD7FF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC857)),
                  const SizedBox(width: 6),
                  Text(badge),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
