import 'package:flutter/material.dart';

import '../../data/growth_data.dart';

/// iconKey（后端）与 Flutter IconData 的映射
IconData _iconForKey(String key) {
  switch (key) {
    case 'school':
      return Icons.school_rounded;
    case 'video':
      return Icons.play_circle_outline_rounded;
    case 'arena':
      return Icons.emoji_events_rounded;
    case 'forum':
      return Icons.forum_rounded;
    default:
      return Icons.check_circle_outline_rounded;
  }
}

/// 每日提醒条（支持点击时间修改提醒时间）
class ReminderBar extends StatelessWidget {
  const ReminderBar({super.key, required this.data, this.onEditTime});

  final ReminderData data;
  /// 点击提醒时间时回调，用于弹出时间选择并保存
  final VoidCallback? onEditTime;

  @override
  Widget build(BuildContext context) {
    const reminderColor = Color(0xFFFF9F1C);
    const bgColor = Color(0xFFFFF8ED);
    final timeChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.reminderTime,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF9F1C), fontSize: 15),
          ),
          if (onEditTime != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded, size: 16, color: reminderColor.withOpacity(0.8)),
          ],
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, const Color(0xFFFFF1D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: reminderColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: reminderColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: reminderColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '每日提醒',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2B2B)),
                ),
              ),
              if (onEditTime != null)
                GestureDetector(
                  onTap: onEditTime,
                  child: timeChip,
                )
              else
                timeChip,
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.message,
            style: const TextStyle(color: Color(0xFF6F6B60), fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: data.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFFFEAC0),
              valueColor: const AlwaysStoppedAnimation<Color>(reminderColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// 成长数据：连续天数、正确率、徽章
class GrowthStats extends StatelessWidget {
  const GrowthStats({super.key, required this.data});

  final GrowthStatsData data;

  static const _streakColor = Color(0xFFE65C4D);
  static const _accuracyColor = Color(0xFF2EC4B6);
  static const _badgeColor = Color(0xFFFFB84D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFFF9F1C).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.local_fire_department_rounded,
              value: '${data.streakDays}',
              label: '连续天数',
              color: _streakColor,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.track_changes_rounded,
              value: '${data.accuracyPercent}%',
              label: '正确率',
              color: _accuracyColor,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.emoji_events_rounded,
              value: '${data.badgeCount}',
              label: '徽章',
              color: _badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF2B2B2B)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF6F6B60), fontSize: 13)),
      ],
    );
  }
}

/// 每日任务打卡卡片
class DailyTasksCard extends StatelessWidget {
  const DailyTasksCard({super.key, required this.tasks, this.onTaskTap});

  final List<DailyTask> tasks;
  /// 点击某项任务时回调（用于跳转到学习/擂台/社群），null 则不响应点击
  final void Function(DailyTask task)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    final completedCount = tasks.where((t) => t.completed).length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F1C).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.today_rounded, color: Color(0xFFFF9F1C), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '今日打卡进度',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2B2B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2CC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$completedCount/${tasks.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF9F1C), fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFFFEAC0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
            ),
          ),
          const SizedBox(height: 16),
          ...tasks.map((task) {
            final done = task.completed;
            final icon = _iconForKey(task.iconKey);
            final row = Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: done ? const Color(0xFFFF9F1C) : const Color(0xFFF6F1E3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: done ? Colors.white : const Color(0xFF9A8F77),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: done ? const Color(0xFF6F6B60) : const Color(0xFF2B2B2B),
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF9A8F77),
                    ),
                  ),
                ),
                if (done) const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6), size: 22),
              ],
            );
            if (onTaskTap != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onTaskTap!(task),
                  borderRadius: BorderRadius.circular(10),
                  child: row,
                ),
              );
            }
            return Padding(padding: const EdgeInsets.only(bottom: 12), child: row);
          }),
        ],
      ),
    );
  }
}

/// 今日学习推荐卡片
class TodayLearningCard extends StatelessWidget {
  const TodayLearningCard({super.key, required this.data, this.onTap});

  final TodayLearningData data;
  /// 点击时回调（如跳转到学习 Tab）；若为 null 则仅显示 SnackBar
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('去学习：${data.title}'), behavior: SnackBarBehavior.floating),
            );
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F4FF), Color(0xFFF0F7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFBFD7FF).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBFD7FF).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7BA3E8), Color(0xFFBFD7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7BA3E8).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今天要学',
                      style: TextStyle(color: Color(0xFF6F6B60), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2B2B2B),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7BA3E8), size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 成长数据双卡行（连续学习 / 本周挑战等）
class GrowthCardRow extends StatelessWidget {
  const GrowthCardRow({super.key, required this.cards});

  final List<GrowthCardItem> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _GrowthCard(
              title: cards[i].title,
              value: cards[i].value,
              color: cards[i].color,
            ),
          ),
        ],
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
