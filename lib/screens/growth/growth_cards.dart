import 'package:flutter/material.dart';

/// 每日提醒条
class ReminderBar extends StatelessWidget {
  const ReminderBar({super.key});

  @override
  Widget build(BuildContext context) {
    const reminderColor = Color(0xFFFF9F1C);
    const bgColor = Color(0xFFFFF8ED);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Text('20:00', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF9F1C), fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '今天还差 3 项打卡，加油！',
            style: TextStyle(color: Color(0xFF6F6B60), fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.25,
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
  const GrowthStats({super.key});

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
        children: const [
          Expanded(child: _StatItem(icon: Icons.local_fire_department_rounded, value: '7', label: '连续天数', color: Color(0xFFE65C4D))),
          Expanded(child: _StatItem(icon: Icons.track_changes_rounded, value: '86%', label: '正确率', color: Color(0xFF2EC4B6))),
          Expanded(child: _StatItem(icon: Icons.emoji_events_rounded, value: '9', label: '徽章', color: Color(0xFFFFB84D))),
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
  const DailyTasksCard({super.key});

  static const _tasks = [
    (icon: Icons.school_rounded, label: '学习一个新知识点'),
    (icon: Icons.play_circle_outline_rounded, label: '观看一个视频或图文'),
    (icon: Icons.emoji_events_rounded, label: '参与一次擂台'),
    (icon: Icons.forum_rounded, label: '参与一次社群讨论'),
  ];

  @override
  Widget build(BuildContext context) {
    const completedCount = 1;
    final progress = completedCount / _tasks.length;
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
                  '$completedCount/${_tasks.length}',
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
          ...List.generate(_tasks.length, (i) {
            final task = _tasks[i];
            final done = i < completedCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFFFF9F1C) : const Color(0xFFF6F1E3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      task.icon,
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
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 今日学习推荐卡片
class TodayLearningCard extends StatelessWidget {
  const TodayLearningCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('去学习：$title'), behavior: SnackBarBehavior.floating),
          );
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
                      title,
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

/// 成长数据双卡行（连续学习 / 本周挑战）
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
