import 'package:flutter/material.dart';

import '../../data/growth_data.dart';
import '../../data/profile.dart';
import '../../widgets/reveal.dart';
import '../../widgets/starry_background.dart';
import 'growth_cards.dart';
import 'profile_card.dart';
import 'profile_page.dart';

/// 成长页：我的、每日提醒、打卡、今日学习（数据来自 [GrowthPageData]，可后端接口填充）
class GrowthPage extends StatelessWidget {
  const GrowthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<GrowthPageData>(
            future: growthDataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? GrowthPageData.fallback();
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
                  const SizedBox(height: 16),
                  const ProfileCard(),
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
                    child: ReminderBar(data: data.reminder),
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
                    child: DailyTasksCard(tasks: data.dailyTasks),
                  ),
                  if (data.growthCards != null && data.growthCards!.isNotEmpty) ...[
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
                    child: TodayLearningCard(data: data.todayLearning),
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
