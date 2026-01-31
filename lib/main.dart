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

import 'data/profile.dart';
import 'data/demo_data.dart';
import 'data/community_data.dart';
import 'data/ai_proxy.dart';
import 'screens/arena/arena_page.dart';
import 'screens/community/community_page.dart';
import 'screens/growth/growth_page.dart';
import 'screens/growth/profile_page.dart' show AchievementUnlockPopup, BadgeWall;
import 'screens/learning/learning_page.dart';
import 'widgets/starry_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AiProxyStore.init();
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
        duration: const Duration(milliseconds: 0),
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
                    hintText: 'http://localhost:3002',
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

// ==================== 登录注册页面 ====================
// ==================== "我的"卡片组件 ====================

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
    if (trimmed.isEmpty) return 'http://localhost:3002';
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

