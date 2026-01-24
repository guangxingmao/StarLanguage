import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import 'lan/lan_duel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileStore.init();
  await AiProxyStore.init();
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

class AiProxyStore {
  static const _urlKey = 'ai_proxy_url';
  static final ValueNotifier<String> url =
      ValueNotifier<String>('http://localhost:3001');

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      url.value = prefs.getString(_urlKey) ?? url.value;
    } catch (_) {}
  }

  static Future<void> setUrl(String value) async {
    url.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_urlKey, value);
    } catch (_) {}
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
    required this.communityPosts,
  });

  final List<Topic> topics;
  final List<ContentItem> contents;
  final List<Question> questions;
  final List<Achievement> achievements;
  final List<CommunityPost> communityPosts;

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
      communityPosts: (json['communityPosts'] as List<dynamic>? ?? [])
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
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
          topic: '篮球',
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
          topic: '历史',
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
          topic: '科学',
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
          topic: '动物',
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
          subtopic: '朝代故事',
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
      communityPosts: CommunityStore._seedPosts(),
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
    required this.topic,
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
  final String topic;
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
      topic: json['topic'] as String? ?? '历史',
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
    required this.subtopic,
  });

  final String id;
  final String title;
  final List<String> options;
  final String answer;
  final String topic;
  final String subtopic;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      answer: json['answer'] as String? ?? '',
      topic: json['topic'] as String? ?? '全部',
      subtopic: json['subtopic'] as String? ?? '综合知识',
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
          item.topic.contains(q) ||
          item.source.contains(q);
      final matchesType = _typeFilter == '全部' || item.type == _typeFilter;
      final matchesSource = _sourceFilter == '全部' || item.source == _sourceFilter;
      final activeTopics = _topicFilters.contains('全部') ? <String>{} : _topicFilters;
      final matchesTopic = activeTopics.isEmpty || activeTopics.contains(item.topic);
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
                ...data.topics.map((t) => t.name)
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
          child: ValueListenableBuilder<List<CommunityPost>>(
            valueListenable: CommunityStore.posts,
            builder: (context, posts, _) {
              if (posts.isEmpty && data.communityPosts.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  CommunityStore.seedFromData(data.communityPosts);
                });
              }
              final hotPosts = posts.take(6).toList();
              return ListView(
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
                  CommunityComposer(
                    onCompose: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicEditorPage(
                            circles: data.topics.map((t) => t.name).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('已加入', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: data.topics.take(4).map((topic) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CircleHomePage(circle: topic.name),
                            ),
                          );
                        },
                        child: TopicChip(label: '${topic.name}圈'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text('今日热门话题', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 140,
                    child: CommunityMasonry(
                      posts: hotPosts,
                      onTap: (post) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TopicDetailPage(post: post)),
                        );
                      },
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

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(isUser: false, text: '你好！我可以识图和回答问题～'),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 60));
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendText() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(isUser: true, text: text));
      _messages.add(const _ChatMessage(isUser: false, text: '思考中…', isPending: true));
    });
    _composerController.clear();
    await _scrollToBottom();

    final reply = await AiProxyClient.request(
      baseUrl: AiProxyStore.url.value,
      history: _messages,
    );
    setState(() {
      _sending = false;
      _replacePending(reply ?? '暂时无法连接代理，请检查地址或稍后再试。');
    });
    await _scrollToBottom();
  }

  void _replacePending(String text) {
    final idx = _messages.lastIndexWhere((m) => m.isPending);
    if (idx == -1) {
      _messages.add(_ChatMessage(isUser: false, text: text));
      return;
    }
    _messages[idx] = _ChatMessage(isUser: false, text: text);
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/jpeg';
    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(
        isUser: true,
        imageLabel: '上传了一张图片',
        imageBytes: bytes,
        imageMime: mime,
      ));
      _messages.add(const _ChatMessage(isUser: false, text: '识别中…', isPending: true));
    });
    await _scrollToBottom();
    final reply = await AiProxyClient.requestImage(
      baseUrl: AiProxyStore.url.value,
      imageBytes: bytes,
      imageMime: mime,
      question: '请描述图片内容，并用儿童易懂的方式解释。',
    );
    setState(() {
      _sending = false;
      _replacePending(reply ?? '暂时无法识别图片，请检查代理或稍后再试。');
    });
    await _scrollToBottom();
  }

  void _openProxySettings() {
    final controller = TextEditingController(text: AiProxyStore.url.value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                const Text('AI 代理设置', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'http://localhost:3001',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('提示：本机运行可用 localhost，手机请填写电脑 IP。'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AiProxyStore.setUrl(controller.text.trim());
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                    ValueListenableBuilder<String>(
                      valueListenable: AiProxyStore.url,
                      builder: (context, value, _) {
                        return GestureDetector(
                          onTap: _openProxySettings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFD166)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.settings_rounded, size: 16, color: Color(0xFFFF9F1C)),
                                const SizedBox(width: 6),
                                Text(
                                  value.replaceAll('http://', '').replaceAll('https://', ''),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ChatHistory(
                  messages: _messages,
                  controller: _scrollController,
                ),
              ),
              ChatComposer(
                controller: _composerController,
                onSend: _sendText,
                onPickImage: _sendImage,
                sending: _sending,
              ),
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
  static final ValueNotifier<ArenaStats> stats = ValueNotifier<ArenaStats>(ArenaStats.initial());
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
    final bestAccuracy = accuracy > current.bestAccuracy ? accuracy : current.bestAccuracy;
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
    final newOnes = candidates.where((name) => !unlocked.value.contains(name)).toList();
    return newOnes;
  }
}

class _ArenaPageState extends State<ArenaPage> {
  String _selectedTopic = '全部';
  String _selectedSubtopic = '全部';

  List<LeaderboardEntry> _buildPersonalLeaderboard(int yourScore) {
    final entries = [
      LeaderboardEntry(rank: 0, name: '你', score: yourScore),
      const LeaderboardEntry(rank: 0, name: '小星星', score: 1740),
      const LeaderboardEntry(rank: 0, name: '光速答题王', score: 1695),
      const LeaderboardEntry(rank: 0, name: '跃迁少年', score: 1580),
      const LeaderboardEntry(rank: 0, name: '知识火箭', score: 1470),
    ];
    entries.sort((a, b) => b.score.compareTo(a.score));
    for (var i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }
    return entries.take(5).toList();
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
              final topics = ['全部', ...data.topics.map((t) => t.name)];
              final subTopics = _subTopicsFor(data, _selectedTopic);
              return ValueListenableBuilder<ArenaStats>(
                valueListenable: ArenaStatsStore.stats,
                builder: (context, stats, _) {
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
                                  data: data,
                                ),
                              ),
                            );
                          },
                          onDuel: () {
                            _openLanDuelSheet(context, data);
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
                            LeaderboardEntry(rank: 1, name: '星知战神', score: 2350),
                            LeaderboardEntry(rank: 2, name: '小小挑战王', score: 2190),
                            LeaderboardEntry(rank: 3, name: '知识飞船', score: 2045),
                            LeaderboardEntry(rank: 4, name: '星际飞手', score: 1980),
                            LeaderboardEntry(rank: 5, name: '闪电回答', score: 1920),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Reveal(
                        delay: 220,
                        child: LeaderboardCard(
                          title: '个人积分排行',
                          entries: _buildPersonalLeaderboard(stats.totalScore),
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
  final TextEditingController _relayController = TextEditingController(text: 'http://localhost:3001');
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
                  hintText: '中继地址（如 http://192.168.1.10:3001）',
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
                  Positioned.fill(child: LearningIllustration(item: item)),
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

class LearningIllustration extends StatelessWidget {
  const LearningIllustration({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.imageUrl.startsWith('assets/') && item.imageUrl.endsWith('.svg'))
          SvgPicture.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => Container(color: item.accent.withOpacity(0.3)),
          )
        else if (item.imageUrl.startsWith('assets/'))
          Image.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: item.accent.withOpacity(0.3),
            ),
          )
        else if (item.imageUrl.isNotEmpty)
          Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: item.accent.withOpacity(0.3),
            ),
          )
        else
          Container(color: item.accent.withOpacity(0.3)),
        Positioned(
          left: 12,
          bottom: 8,
          child: _DecorStar(color: Colors.white.withOpacity(0.6), size: 18),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DecorStar extends StatelessWidget {
  const _DecorStar({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, color: color, size: size);
  }
}

class ChatHistory extends StatelessWidget {
  const ChatHistory({super.key, required this.messages, required this.controller});

  final List<_ChatMessage> messages;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: messages[index]);
      },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    this.text,
    this.imageLabel,
    this.imageBytes,
    this.imageMime,
    this.isPending = false,
  });

  final bool isUser;
  final String? text;
  final String? imageLabel;
  final Uint8List? imageBytes;
  final String? imageMime;
  final bool isPending;
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
        child: message.imageBytes != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      message.imageBytes!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(message.imageLabel ?? '图片'),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(message.text ?? '')),
                  if (message.isPending)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickImage,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final bool sending;

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
            onPressed: onPickImage,
            icon: const Icon(Icons.image_rounded),
            color: const Color(0xFFFF9F1C),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: '输入问题或发送图片…',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFFFF8E6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sending ? const Color(0xFFFFD166) : const Color(0xFFFF9F1C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AiProxyClient {
  static Future<String?> request({
    required String baseUrl,
    required List<_ChatMessage> history,
  }) async {
    final uri = Uri.parse(_normalizeBaseUrl(baseUrl));
    final endpoint = uri.replace(path: '/chat');
    final messages = _buildMessages(history);
    if (messages.isEmpty) return null;
    try {
      final response = await http.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'hunyuan-turbos-latest',
          'messages': messages,
          'temperature': 0.6,
          'topP': 1.0,
          'stream': false,
        }),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reply'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 'http://localhost:3001';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  static List<Map<String, String>> _buildMessages(List<_ChatMessage> history) {
    final items = <Map<String, String>>[
      {
        'role': 'system',
        'content': '你是面向儿童的科普助手，回答要简短、温和、易懂。',
      }
    ];
    for (final msg in history.reversed.take(12).toList().reversed) {
      if (msg.text == null || msg.text!.trim().isEmpty) continue;
      if (msg.isPending) continue;
      items.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text!.trim(),
      });
    }
    return items;
  }

  static Future<String?> requestImage({
    required String baseUrl,
    required Uint8List imageBytes,
    required String imageMime,
    required String question,
  }) async {
    final uri = Uri.parse(_normalizeBaseUrl(baseUrl));
    final endpoint = uri.replace(path: '/chat');
    try {
      final response = await http.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageBase64': base64Encode(imageBytes),
          'imageMime': imageMime,
          'question': question,
          'stream': false,
        }),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reply'] as String?;
    } catch (_) {
      return null;
    }
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
  const CommunityComposer({super.key, required this.onCompose});

  final VoidCallback onCompose;

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
            onPressed: onCompose,
            child: const Text('发布'),
          ),
        ],
      ),
    );
  }
}

class CommunityMasonry extends StatelessWidget {
  const CommunityMasonry({super.key, required this.posts, required this.onTap});

  final List<CommunityPost> posts;
  final ValueChanged<CommunityPost> onTap;

  @override
  Widget build(BuildContext context) {
    final left = <CommunityPost>[];
    final right = <CommunityPost>[];
    for (var i = 0; i < posts.length; i++) {
      if (i.isEven) {
        left.add(posts[i]);
      } else {
        right.add(posts[i]);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TopicPostCard(
                      data: post,
                      onTap: () => onTap(post),
                    ),
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
                    child: TopicPostCard(
                      data: post,
                      onTap: () => onTap(post),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class TopicPostCard extends StatelessWidget {
  const TopicPostCard({super.key, required this.data, required this.onTap});

  final CommunityPost data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: data.accent.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: data.accent,
                  child: const Icon(Icons.face_rounded, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(data.timeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8370))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(data.summary),
            if (data.imageBase64 != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(data.imageBase64!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.local_offer_rounded, size: 18),
                Text(data.circle),
                const Icon(Icons.favorite_border_rounded, size: 18),
                Text('${data.likes}'),
                const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                Text('${data.comments}'),
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

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.circle,
    required this.author,
    required this.timeLabel,
    required this.likes,
    required this.comments,
    required this.accent,
    this.imageBase64,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String circle;
  final String author;
  final String timeLabel;
  final int likes;
  final int comments;
  final Color accent;
  final String? imageBase64;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      circle: json['circle'] as String? ?? '',
      author: json['author'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      accent: _parseColor(json['accent'] as String? ?? '#BFD7FF'),
      imageBase64: json['imageBase64'] as String?,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.author,
    required this.content,
    required this.timeLabel,
  });

  final String author;
  final String content;
  final String timeLabel;
}

class CommunityStore {
  static final ValueNotifier<List<CommunityPost>> posts =
      ValueNotifier<List<CommunityPost>>(_seedPosts());
  static final ValueNotifier<Map<String, List<CommunityComment>>> comments =
      ValueNotifier<Map<String, List<CommunityComment>>>(_seedComments());
  static bool _seededFromData = false;

  static void addPost({
    required String title,
    required String content,
    required String circle,
    String? imageBase64,
  }) {
    final summary = content.length > 28 ? '${content.substring(0, 28)}…' : content;
    final accent = _accentForCircle(circle);
    final item = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      summary: summary,
      content: content,
      circle: circle,
      author: ProfileStore.profile.value.name,
      timeLabel: '刚刚',
      likes: 0,
      comments: 0,
      accent: accent,
      imageBase64: imageBase64,
    );
    posts.value = [item, ...posts.value];
  }

  static void seedFromData(List<CommunityPost> data) {
    if (_seededFromData) return;
    _seededFromData = true;
    posts.value = data;
  }

  static void addComment(String postId, String content) {
    final list = List<CommunityComment>.from(comments.value[postId] ?? []);
    list.insert(
      0,
      CommunityComment(
        author: ProfileStore.profile.value.name,
        content: content,
        timeLabel: '刚刚',
      ),
    );
    comments.value = {...comments.value, postId: list};
  }

  static Color _accentForCircle(String circle) {
    switch (circle) {
      case '历史':
        return const Color(0xFF5DADE2);
      case '计算机':
        return const Color(0xFF2EC4B6);
      case '篮球':
        return const Color(0xFFFF9F1C);
      case '动物':
        return const Color(0xFF6DD3CE);
      case '科学':
        return const Color(0xFFB8F1E0);
      default:
        return const Color(0xFFBFD7FF);
    }
  }

  static List<CommunityPost> _seedPosts() {
    return const [
      CommunityPost(
        id: 'p1',
        title: '为什么猫咪爱晒太阳？',
        summary: '一起聊聊小动物的温暖秘密。',
        content: '你家的猫咪喜欢晒太阳吗？一起聊聊它们为什么总爱找暖暖的地方～',
        circle: '动物',
        author: '星知小记者',
        timeLabel: '2 小时前',
        likes: 128,
        comments: 36,
        accent: Color(0xFFBFD7FF),
      ),
      CommunityPost(
        id: 'p2',
        title: '你最喜欢的历史人物是谁？',
        summary: '留言区见～',
        content: '你最喜欢的历史人物是谁？他/她有哪些故事？欢迎分享～',
        circle: '历史',
        author: '唐宋小能手',
        timeLabel: '3 小时前',
        likes: 94,
        comments: 28,
        accent: Color(0xFFFFC857),
      ),
      CommunityPost(
        id: 'p3',
        title: '哪一刻让你爱上科学？',
        summary: '分享一个小实验～',
        content: '哪一刻让你爱上科学？写下一个小实验或小发现吧！',
        circle: '科学',
        author: '实验室小白',
        timeLabel: '5 小时前',
        likes: 86,
        comments: 19,
        accent: Color(0xFFB8F1E0),
      ),
      CommunityPost(
        id: 'p4',
        title: '篮球招式大揭秘',
        summary: '从三步上篮说起。',
        content: '你最常用的篮球招式是什么？从三步上篮说起～',
        circle: '篮球',
        author: '三分神投',
        timeLabel: '6 小时前',
        likes: 73,
        comments: 22,
        accent: Color(0xFF5DADE2),
      ),
      CommunityPost(
        id: 'p5',
        title: '我做了个小程序！',
        summary: '用 Scratch 做小游戏～',
        content: '用 Scratch 做了一个小游戏，想和大家交流一下做法～',
        circle: '计算机',
        author: '代码星',
        timeLabel: '昨天',
        likes: 61,
        comments: 12,
        accent: Color(0xFF9BDEAC),
      ),
      CommunityPost(
        id: 'p6',
        title: '长城到底有多长？',
        summary: '来聊聊历史建筑。',
        content: '长城到底有多长？不同资料说法不太一样，一起查查吧～',
        circle: '历史',
        author: '长城小导游',
        timeLabel: '昨天',
        likes: 52,
        comments: 10,
        accent: Color(0xFF5DADE2),
      ),
    ];
  }

  static Map<String, List<CommunityComment>> _seedComments() {
    return {
      'p1': const [
        CommunityComment(author: '小星星', content: '我家猫咪每天都要晒太阳！', timeLabel: '1 小时前'),
        CommunityComment(author: '小小动物迷', content: '因为太阳暖暖的～', timeLabel: '45 分钟前'),
      ],
      'p2': const [
        CommunityComment(author: '历史控', content: '我喜欢李白和杜甫！', timeLabel: '2 小时前'),
      ],
    };
  }
}

class CircleHomePage extends StatelessWidget {
  const CircleHomePage({super.key, required this.circle});

  final String circle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ValueListenableBuilder<List<CommunityPost>>(
              valueListenable: CommunityStore.posts,
              builder: (context, posts, _) {
                final circlePosts = posts.where((p) => p.circle == circle).toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Text('$circle 圈', style: Theme.of(context).textTheme.headlineLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TopicEditorPage(
                                  circles: [circle],
                                  presetCircle: circle,
                                ),
                              ),
                            );
                          },
                          child: const Text('发话题'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('这里是 $circle 圈的话题讨论区'),
                    const SizedBox(height: 16),
                    if (circlePosts.isEmpty)
                      const EmptyStateCard()
                    else
                      Column(
                        children: circlePosts
                            .map(
                              (post) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TopicPostCard(
                                  data: post,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => TopicDetailPage(post: post)),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TopicDetailPage extends StatelessWidget {
  const TopicDetailPage({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ValueListenableBuilder<Map<String, List<CommunityComment>>>(
              valueListenable: CommunityStore.comments,
              builder: (context, commentMap, _) {
                final list = commentMap[post.id] ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Text('话题详情', style: Theme.of(context).textTheme.headlineLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: post.accent.withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('来自 ${post.circle} 圈 · ${post.timeLabel}'),
                          const SizedBox(height: 12),
                          Text(post.content),
                          if (post.imageBase64 != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                base64Decode(post.imageBase64!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('评论', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (list.isEmpty)
                      const EmptyStateCard()
                    else
                      Column(
                        children: list
                            .map(
                              (comment) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE9E0C9)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: post.accent.withOpacity(0.3),
                                      child: const Icon(Icons.face_rounded, size: 18, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.author,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(comment.content),
                                          const SizedBox(height: 4),
                                          Text(comment.timeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8370))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9E0C9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('写评论', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: commentController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: '说点什么吧…',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                final text = commentController.text.trim();
                                if (text.isEmpty) return;
                                CommunityStore.addComment(post.id, text);
                                commentController.clear();
                              },
                              child: const Text('发布评论'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CircleHomePage(circle: post.circle)),
                            );
                          },
                          child: const Text('进入圈子'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TopicEditorPage extends StatefulWidget {
  const TopicEditorPage({super.key, required this.circles, this.presetCircle});

  final List<String> circles;
  final String? presetCircle;

  @override
  State<TopicEditorPage> createState() => _TopicEditorPageState();
}

class _TopicEditorPageState extends State<TopicEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late String _circle;
  Uint8List? _imageBytes;
  String? _imageMime;

  @override
  void initState() {
    super.initState();
    _circle = widget.presetCircle ?? (widget.circles.isNotEmpty ? widget.circles.first : '其他');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    final base64Image = _imageBytes == null ? null : base64Encode(_imageBytes!);
    CommunityStore.addPost(
      title: title,
      content: content,
      circle: _circle,
      imageBase64: base64Image,
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageMime = file.mimeType ?? 'image/jpeg';
    });
  }

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
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text('发布话题', style: Theme.of(context).textTheme.headlineLarge),
                    const Spacer(),
                    TextButton(onPressed: _submit, child: const Text('发布')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '话题标题',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '写下你的话题内容…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('添加图片'),
                    ),
                    const SizedBox(width: 12),
                    if (_imageBytes != null)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('选择圈子'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.circles.map((circle) {
                    final active = _circle == circle;
                    return ChoiceChip(
                      label: Text(circle),
                      selected: active,
                      onSelected: (_) => setState(() => _circle = circle),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class LeaderboardEntry {
  const LeaderboardEntry({required this.rank, required this.name, required this.score});

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
                  Text('${entry.score}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
  const ZoneLeaderboardRow({super.key, required this.topics, required this.stats});

  final List<String> topics;
  final ArenaStats stats;

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
    };
    return topics.take(4).map((topic) {
      final color = palette[topic] ?? const Color(0xFFFFC857);
      final best = stats.topicBest[topic] ?? 0;
      final detailEntries = _buildZoneLeaderboard(topic, best);
      return _ZoneEntry(
        topic: topic,
        leader: detailEntries.first.name,
        score: detailEntries.first.score,
        color: color,
        detailEntries: detailEntries,
      );
    }).toList();
  }

  List<LeaderboardEntry> _buildZoneLeaderboard(String topic, int yourBest) {
    final base = [
      const LeaderboardEntry(rank: 0, name: '星河小队', score: 1820),
      const LeaderboardEntry(rank: 0, name: '晨星', score: 1710),
      const LeaderboardEntry(rank: 0, name: '飞快答题', score: 1640),
      const LeaderboardEntry(rank: 0, name: '知识通关', score: 1550),
      const LeaderboardEntry(rank: 0, name: '探索者', score: 1470),
    ];
    if (yourBest > 0) {
      base.add(LeaderboardEntry(rank: 0, name: '你', score: yourBest));
    }
    base.sort((a, b) => b.score.compareTo(a.score));
    for (var i = 0; i < base.length; i++) {
      base[i] = base[i].copyWith(rank: i + 1);
    }
    return base.take(10).toList();
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
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFD166)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${entry.score}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
        builder: (_) => _AchievementPopup(names: newlyUnlocked),
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
                ValueListenableBuilder<ArenaStats>(
                  valueListenable: ArenaStatsStore.stats,
                  builder: (context, stats, _) {
                    final progress = _buildAchievementProgress(data, stats);
                    if (progress.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE9E0C9)),
                        ),
                        child: const Text('完成一次擂台挑战即可解锁成就～'),
                      );
                    }
                    return AchievementWall(items: progress);
                  },
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

List<String> _resolveBadges(DemoData data, ArenaStats stats) {
  final names = <String>[];
  for (final badge in data.achievements) {
    switch (badge.name) {
      case '闪亮新星':
        if (stats.matches >= 1) names.add(badge.name);
        break;
      case '连胜三场':
        if (stats.maxStreak >= 3) names.add(badge.name);
        break;
      case '探索家':
        if (stats.totalScore >= 300) names.add(badge.name);
        break;
      case '观察大师':
        if (stats.bestAccuracy >= 0.9) names.add(badge.name);
        break;
      case '历史小通':
        if ((stats.topicBest['历史'] ?? 0) >= 120) names.add(badge.name);
        break;
      case '篮球达人':
        if ((stats.topicBest['篮球'] ?? 0) >= 120) names.add(badge.name);
        break;
      default:
        break;
    }
  }
  return names;
}

class AchievementProgress {
  const AchievementProgress({
    required this.name,
    required this.description,
    required this.level,
    required this.progress,
    required this.nextTarget,
  });

  final String name;
  final String description;
  final int level;
  final double progress;
  final String nextTarget;
}

List<AchievementProgress> _buildAchievementProgress(DemoData data, ArenaStats stats) {
  final items = <AchievementProgress>[];
  for (final badge in data.achievements) {
    switch (badge.name) {
      case '闪亮新星':
        items.add(
          AchievementProgress(
            name: badge.name,
            description: '完成 1 次擂台挑战',
            level: stats.matches >= 1 ? 1 : 0,
            progress: (stats.matches >= 1) ? 1.0 : stats.matches / 1.0,
            nextTarget: '完成 1 次挑战',
          ),
        );
        break;
      case '连胜三场':
        items.add(
          AchievementProgress(
            name: badge.name,
            description: '连续答对 3 题',
            level: stats.maxStreak >= 3 ? 1 : 0,
            progress: (stats.maxStreak / 3.0).clamp(0.0, 1.0),
            nextTarget: '连击 3 题',
          ),
        );
        break;
      case '探索家':
        final thresholds = [300, 600, 1000];
        final level = thresholds.where((t) => stats.totalScore >= t).length;
        final next = level < thresholds.length ? thresholds[level] : thresholds.last;
        items.add(
          AchievementProgress(
            name: badge.name,
            description: '累计积分达到阶段目标',
            level: level,
            progress: (stats.totalScore / next).clamp(0.0, 1.0),
            nextTarget: '累计 $next 分',
          ),
        );
        break;
      case '观察大师':
        items.add(
          AchievementProgress(
            name: badge.name,
            description: '单局准确率达到 90%',
            level: stats.bestAccuracy >= 0.9 ? 1 : 0,
            progress: (stats.bestAccuracy / 0.9).clamp(0.0, 1.0),
            nextTarget: '准确率 ≥ 90%',
          ),
        );
        break;
      case '历史小通':
        final best = stats.topicBest['历史'] ?? 0;
        items.add(
          AchievementProgress(
            name: badge.name,
            description: '历史分区单局 ≥ 120',
            level: best >= 120 ? 1 : 0,
            progress: (best / 120.0).clamp(0.0, 1.0),
            nextTarget: '历史分区 120 分',
          ),
        );
        break;
      case '篮球达人':
        final best = stats.topicBest['篮球'] ?? 0;
        items.add(
          AchievementProgress(
            name: badge.name,
            description: '篮球分区单局 ≥ 120',
            level: best >= 120 ? 1 : 0,
            progress: (best / 120.0).clamp(0.0, 1.0),
            nextTarget: '篮球分区 120 分',
          ),
        );
        break;
      default:
        break;
    }
  }
  return items;
}

class AchievementWall extends StatelessWidget {
  const AchievementWall({super.key, required this.items});

  final List<AchievementProgress> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E0C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.level > 0 ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                        color: item.level > 0 ? const Color(0xFFFF9F1C) : const Color(0xFFB0AFA6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('Lv.${item.level}', style: const TextStyle(color: Color(0xFF6F6B60))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(color: Color(0xFF6F6B60))),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFFFF1D0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('下一目标：${item.nextTarget}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AchievementPopup extends StatelessWidget {
  const _AchievementPopup({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('新成就解锁', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...names.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF9F1C)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道啦'),
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
