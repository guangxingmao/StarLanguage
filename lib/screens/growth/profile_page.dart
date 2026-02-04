import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/achievement_data.dart';
import '../../utils/achievement_badges.dart';
import '../../data/arena_data.dart';
import '../../data/demo_data.dart';
import '../../data/growth_data.dart';
import '../../data/profile.dart';
import '../../data/social_data.dart';
import '../../widgets/starry_background.dart';
import 'profile_card.dart';

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
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE9E0C9)),
                            ),
                            child: const Text('暂无成就数据'),
                          );
                        }
                        return Column(
                          children: wall.achievements.map((a) {
                            final unlocked = wall.isUnlocked(a.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: unlocked
                                      ? const Color(0xFFFFD166)
                                      : const Color(0xFFE9E0C9),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: SvgPicture.asset(
                                      AchievementBadges.assetPath(a.iconKey),
                                      width: 40,
                                      height: 40,
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
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18,
                                        color: const Color(0xFFB0AFA6),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2B2B2B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          a.description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6F6B60),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (unlocked)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF2EC4B6),
                                      size: 22,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
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
