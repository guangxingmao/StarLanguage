import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/arena_data.dart';
import '../../data/demo_data.dart';
import '../../data/profile.dart';
import '../../widgets/starry_background.dart';
import 'profile_card.dart';

/// 个人主页
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
                const ProfileCard(),
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
                        offset: const Offset(0, 8),
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
                        child: const Text('今天学会了"为什么天空是蓝色的"～'),
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
