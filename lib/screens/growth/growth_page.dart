import 'package:flutter/material.dart';

import '../../data/growth_data.dart';
import '../../data/profile.dart';
import '../../widgets/reveal.dart';
import '../../widgets/starry_background.dart';
import 'growth_cards.dart';
import 'profile_page.dart';

/// 成长页：我的、每日提醒、打卡、今日学习（数据来自 GET /growth 接口）
class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key, this.selectedTabIndex, this.onSwitchToTab});

  /// 当前选中的底部 Tab 下标，0 表示本页。传入后切回本 Tab 时会自动重新请求接口以展示最新数据。
  final int? selectedTabIndex;
  /// 切换到指定 Tab（如 1=社群、3=擂台、4=学习），用于每日任务跳转
  final void Function(int index)? onSwitchToTab;

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  late Future<GrowthPageData?> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = GrowthDataRepository.load();
  }

  @override
  void didUpdateWidget(covariant GrowthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idx = widget.selectedTabIndex;
    final wasOther = oldWidget.selectedTabIndex != null && oldWidget.selectedTabIndex != 0;
    if (idx == 0 && wasOther) {
      _refreshData();
    }
  }

  void _refreshData() {
    setState(() {
      _dataFuture = GrowthDataRepository.load();
    });
  }

  /// 每日任务点击：学习/视频→学习页(4)，擂台→擂台(3)，社群→社群(1)
  void _onDailyTaskTap(BuildContext context, DailyTask task) {
    final onSwitchToTab = widget.onSwitchToTab;
    if (onSwitchToTab == null) return;
    switch (task.id) {
      case 'school':
      case 'video':
        onSwitchToTab(4);
        break;
      case 'arena':
        onSwitchToTab(3);
        break;
      case 'forum':
        onSwitchToTab(1);
        break;
      default:
        break;
    }
  }

  /// 解析 "HH:mm" 为 TimeOfDay，无效则默认 20:00
  TimeOfDay _parseReminderTime(String reminderTime) {
    final parts = reminderTime.split(':');
    final hour = (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 20;
    final minute = (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  /// 打开每日提醒时间选择，保存后刷新
  Future<void> _openReminderTimePicker(BuildContext context, String currentTime) async {
    final initial = _parseReminderTime(currentTime);
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
    if (ok && mounted) _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<GrowthPageData?>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data;
              if (data == null) {
                return RefreshIndicator(
                  onRefresh: () async {
                    _refreshData();
                    await _dataFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(
                        child: Text('暂无数据，请登录后刷新'),
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                  await _dataFuture;
                },
                child: ListView(
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
                  const SizedBox(height: 20),
                  Text(
                    '每日提醒与打卡进度',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF6F6B60),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 60,
                    child: ReminderBar(
                      data: data.reminder,
                      onEditTime: () => _openReminderTimePicker(context, data.reminder.reminderTime),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Reveal(
                    delay: 120,
                    child: GrowthStats(data: data.stats),
                  ),
                  const SizedBox(height: 18),
                  Text('每日任务', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 180,
                    child: DailyTasksCard(
                      tasks: data.dailyTasks,
                      onTaskTap: widget.onSwitchToTab != null
                          ? (task) => _onDailyTaskTap(context, task)
                          : null,
                    ),
                  ),
                  if (data.growthCards!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('学习与挑战', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: 200,
                      child: GrowthCardRow(cards: data.growthCards!),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('今日学习', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 220,
                    child: TodayLearningCard(
                      data: data.todayLearning,
                      onTap: widget.onSwitchToTab != null
                          ? () => widget.onSwitchToTab!(4)
                          : null,
                    ),
                  ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
