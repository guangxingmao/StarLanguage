import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/achievement_data.dart';
import '../../data/arena_data.dart';
import '../../data/demo_data.dart' hide Achievement;
import '../../data/growth_data.dart';
import '../../data/profile.dart';
import '../../data/social_data.dart';
import '../../widgets/starry_background.dart';
import 'profile_card.dart';

/// 成就墙使用的插图 SVG 列表（按成就 id 稳定分配）
const List<String> _achievementIllustrationPaths = [
  'assets/illustrations/ill_01.svg', 'assets/illustrations/ill_02.svg', 'assets/illustrations/ill_03.svg',
  'assets/illustrations/ill_04.svg', 'assets/illustrations/ill_05.svg', 'assets/illustrations/ill_06.svg',
  'assets/illustrations/ill_07.svg', 'assets/illustrations/ill_08.svg', 'assets/illustrations/ill_09.svg',
  'assets/illustrations/ill_10.svg', 'assets/illustrations/ill_11.svg', 'assets/illustrations/ill_12.svg',
  'assets/illustrations/ill_13.svg', 'assets/illustrations/ill_14.svg', 'assets/illustrations/ill_15.svg',
  'assets/illustrations/ill_16.svg', 'assets/illustrations/ill_17.svg', 'assets/illustrations/ill_18.svg',
  'assets/illustrations/ill_19.svg', 'assets/illustrations/ill_20.svg', 'assets/illustrations/ill_21.svg',
  'assets/illustrations/ill_22.svg', 'assets/illustrations/ill_23.svg', 'assets/illustrations/ill_24.svg',
  'assets/illustrations/ill_25.svg', 'assets/illustrations/ill_26.svg', 'assets/illustrations/ill_27.svg',
  'assets/illustrations/ill_28.svg', 'assets/illustrations/ill_29.svg', 'assets/illustrations/ill_30.svg',
];

String _achievementIllustrationPath(Achievement a) {
  return _achievementIllustrationPaths[a.id.hashCode.abs() % _achievementIllustrationPaths.length];
}

/// 个人主页（等级、基础信息、成就墙、个人圈、交友、设置均来自接口）
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<void> _meFuture;
  late Future<AchievementWallData> _achievementWallFuture;
  late Future<List<FeedItem>> _feedFuture;
  static const int _levelExpMax = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _meFuture = ProfileStore.fetchMe();
    _achievementWallFuture = AchievementRepository.loadWall();
    _feedFuture = SocialFeedRepository.load();
  }

  Future<void> _openReminderTimePicker(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final hour = (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 20;
    final minute = (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0;
    final initial = TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFFFF9F1C)),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    final newTime =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final ok = await GrowthDataRepository.updateReminder(reminderTime: newTime);
    if (ok && mounted) {
      await ProfileStore.fetchMe();
      setState(() {});
    }
  }

  String _privacyLabel(String privacy) {
    if (privacy == 'default') return '默认';
    return privacy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: FutureBuilder<void>(
              future: _meFuture,
              builder: (context, meSnap) {
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
                        Text('个人主页', style: Theme.of(context).textTheme.headlineLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: () => showEditProfileSheet(context),
                          child: const Text('编辑资料'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ProfileCard(),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<UserProfile>(
                      valueListenable: ProfileStore.profile,
                      builder: (context, profile, _) {
                        final levelTitle = profile.levelTitle?.isNotEmpty == true
                            ? profile.levelTitle!
                            : '星光探索者';
                        final progress = _levelExpMax > 0
                            ? (profile.levelExp / _levelExpMax).clamp(0.0, 1.0)
                            : 0.0;
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
                              const Text('等级'),
                              const SizedBox(height: 6),
                              Text(
                                'Lv.${profile.level} · $levelTitle',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFFFEAC0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<UserProfile>(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('基础信息', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              _InfoRow(label: '昵称', value: profile.name),
                              _InfoRow(label: '年龄', value: profile.age ?? '—'),
                              _InfoRow(label: '兴趣', value: profile.interests ?? '—'),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('成就墙', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    FutureBuilder<AchievementWallData>(
                      future: _achievementWallFuture,
                      builder: (context, snap) {
                        final wall = snap.data;
                        if (wall == null || wall.achievements.isEmpty) {
                          return _AchievementSectionPreview(
                            latest: const [],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AchievementWallPage(),
                              ),
                            ),
                          );
                        }
                        final latestIds = wall.unlockedIds.reversed.take(5).toList();
                        final byId = {for (final a in wall.achievements) a.id: a};
                        final latest = latestIds
                            .map((id) => byId[id])
                            .whereType<Achievement>()
                            .toList();
                        return _AchievementSectionPreview(
                          latest: latest,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AchievementWallPage(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<FeedItem>>(
                      future: _feedFuture,
                      builder: (context, snap) {
                        final items = snap.data ?? [];
                        return Container(
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
                              if (items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('暂无动态，快去学习并发布吧～'),
                                )
                              else
                                ...items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8E6),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(item.content),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.favorite_border_rounded, size: 18),
                                            const SizedBox(width: 6),
                                            Text('${item.likeCount}'),
                                            const SizedBox(width: 16),
                                            Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                            const SizedBox(width: 6),
                                            Text('${item.commentCount}'),
                                            const Spacer(),
                                            const Text(
                                              '发布动态',
                                              style: TextStyle(color: Color(0xFFFF9F1C)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<UserProfile>(
                      valueListenable: ProfileStore.profile,
                      builder: (context, profile, _) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE9E0C9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('交友', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              const _SettingRow(label: '添加好友', value: '搜索或扫码'),
                              _SettingRow(
                                label: '好友申请',
                                value: profile.pendingRequestCount > 0
                                    ? '${profile.pendingRequestCount} 条新申请'
                                    : '暂无',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<UserProfile>(
                      valueListenable: ProfileStore.profile,
                      builder: (context, profile, _) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE9E0C9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('设置', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _openReminderTimePicker(
                                  context,
                                  profile.reminderTime,
                                ),
                                child: _SettingRow(
                                  label: '学习提醒',
                                  value: profile.reminderTime,
                                ),
                              ),
                              _SettingRow(
                                label: '隐私',
                                value: _privacyLabel(profile.privacy),
                              ),
                              const _SettingRow(label: '账户绑定', value: '未绑定'),
                            ],
                          ),
                        );
                      },
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

/// 成就进度项
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
                  children: List.generate(avatarColors.length, (index) {
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

/// 个人主页成就墙预览：仅显示最近 5 个已完成的成就，点击进入成就墙全页
class _AchievementSectionPreview extends StatelessWidget {
  const _AchievementSectionPreview({
    required this.latest,
    required this.onTap,
  });

  final List<Achievement> latest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E0C9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (latest.isEmpty)
                const Text('暂无成就，点击查看全部成就')
              else
                ...latest.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: SvgPicture.asset(
                            _achievementIllustrationPath(a),
                            width: 36,
                            height: 36,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2B2B2B),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                a.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F6B60),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '查看全部成就',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 成就墙全页：全部成就，2 列网格，已完成的高亮显示（无打钩）
class AchievementWallPage extends StatefulWidget {
  const AchievementWallPage({super.key});

  @override
  State<AchievementWallPage> createState() => _AchievementWallPageState();
}

class _AchievementWallPageState extends State<AchievementWallPage> {
  late Future<AchievementWallData> _wallFuture;

  @override
  void initState() {
    super.initState();
    _wallFuture = AchievementRepository.loadWall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成就墙'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: FutureBuilder<AchievementWallData>(
              future: _wallFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final wall = snap.data;
                if (wall == null || wall.achievements.isEmpty) {
                  return const Center(child: Text('暂无成就数据'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: wall.achievements.length,
                  itemBuilder: (context, index) {
                    final a = wall.achievements[index];
                    final unlocked = wall.isUnlocked(a.id);
                    return _AchievementGridCard(
                      achievement: a,
                      unlocked: unlocked,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 成就墙网格单卡：已完成高亮（无打钩），未完成灰显
class _AchievementGridCard extends StatelessWidget {
  const _AchievementGridCard({
    required this.achievement,
    required this.unlocked,
  });

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFFFFF8ED)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? const Color(0xFFFFD166) : const Color(0xFFE9E0C9),
          width: unlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: SvgPicture.asset(
              _achievementIllustrationPath(achievement),
              width: 48,
              height: 48,
              colorFilter: unlocked
                  ? null
                  : ColorFilter.mode(
                      const Color(0xFFB0AFA6),
                      BlendMode.saturation,
                    ),
            ),
          ),
          if (!unlocked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: const Color(0xFFB0AFA6),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: unlocked ? const Color(0xFF2B2B2B) : const Color(0xFF9A8F77),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6F6B60),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 徽章墙（用于个人页/TA的主页等）
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

/// 新成就解锁弹层（擂台结果页等共用）
class AchievementUnlockPopup extends StatelessWidget {
  const AchievementUnlockPopup({super.key, required this.names});

  final List<String> names;

  /// 成就列表最大高度，避免小屏或成就过多时溢出
  static const double _maxListHeight = 280;

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
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxListHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: names.map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF9F1C), size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name)),
                      ],
                    ),
                  ),
                ).toList(),
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
