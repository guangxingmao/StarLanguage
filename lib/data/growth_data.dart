import 'package:flutter/material.dart';

import '../utils/color_util.dart';

// ==================== 成长页实体（供后端接口填充） ====================

/// 每日提醒
class ReminderData {
  const ReminderData({
    required this.reminderTime,
    required this.message,
    required this.progress,
    this.remainingCount,
  });

  /// 提醒时间，如 "20:00"
  final String reminderTime;
  /// 提示文案，如 "今天还差 3 项打卡，加油！"
  final String message;
  /// 打卡进度 0.0～1.0
  final double progress;
  /// 剩余未完成项数（可选，用于展示）
  final int? remainingCount;

  factory ReminderData.fromJson(Map<String, dynamic> json) {
    return ReminderData(
      reminderTime: json['reminderTime'] as String? ?? '20:00',
      message: json['message'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0,
      remainingCount: (json['remainingCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reminderTime': reminderTime,
        'message': message,
        'progress': progress,
        if (remainingCount != null) 'remainingCount': remainingCount,
      };

  static ReminderData fallback() {
    return const ReminderData(
      reminderTime: '20:00',
      message: '今天还差 3 项打卡，加油！',
      progress: 0.25,
      remainingCount: 3,
    );
  }
}

/// 成长统计：连续天数、正确率、徽章数
class GrowthStatsData {
  const GrowthStatsData({
    required this.streakDays,
    required this.accuracyPercent,
    required this.badgeCount,
  });

  final int streakDays;
  final int accuracyPercent;
  final int badgeCount;

  factory GrowthStatsData.fromJson(Map<String, dynamic> json) {
    return GrowthStatsData(
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      accuracyPercent: (json['accuracyPercent'] as num?)?.toInt() ?? 0,
      badgeCount: (json['badgeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'accuracyPercent': accuracyPercent,
        'badgeCount': badgeCount,
      };

  static GrowthStatsData fallback() {
    return const GrowthStatsData(
      streakDays: 7,
      accuracyPercent: 86,
      badgeCount: 9,
    );
  }
}

/// 每日任务项（iconKey 与 UI 图标映射见 [DailyTask.iconKeyToIcon]）
class DailyTask {
  const DailyTask({
    this.id,
    required this.iconKey,
    required this.label,
    this.completed = false,
  });

  final String? id;
  /// 图标键：school / video / arena / forum 等，用于后端与 UI 映射
  final String iconKey;
  final String label;
  final bool completed;

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as String?,
      iconKey: json['iconKey'] as String? ?? 'school',
      label: json['label'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'iconKey': iconKey,
        'label': label,
        'completed': completed,
      };

  static List<DailyTask> fallbackTasks() {
    return const [
      DailyTask(iconKey: 'school', label: '学习一个新知识点', completed: true),
      DailyTask(iconKey: 'video', label: '观看一个视频或图文', completed: false),
      DailyTask(iconKey: 'arena', label: '参与一次擂台', completed: false),
      DailyTask(iconKey: 'forum', label: '参与一次社群讨论', completed: false),
    ];
  }
}

/// 今日学习推荐
class TodayLearningData {
  const TodayLearningData({
    required this.title,
    this.contentId,
    this.summary,
  });

  final String title;
  final String? contentId;
  final String? summary;

  factory TodayLearningData.fromJson(Map<String, dynamic> json) {
    return TodayLearningData(
      title: json['title'] as String? ?? '还没有学习内容',
      contentId: json['contentId'] as String?,
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        if (contentId != null) 'contentId': contentId,
        if (summary != null) 'summary': summary,
      };

  static TodayLearningData fallback() {
    return const TodayLearningData(title: '还没有学习内容');
  }
}

/// 成长双卡行中的一项（如「连续学习」「本周挑战」）
class GrowthCardItem {
  const GrowthCardItem({
    required this.title,
    required this.value,
    this.colorHex = '#FFD166',
  });

  final String title;
  final String value;
  final String colorHex;

  Color get color => parseColor(colorHex);

  factory GrowthCardItem.fromJson(Map<String, dynamic> json) {
    return GrowthCardItem(
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#FFD166',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'colorHex': colorHex,
      };

  static List<GrowthCardItem> fallbackCards() {
    return const [
      GrowthCardItem(title: '连续学习', value: '7 天', colorHex: '#FFD166'),
      GrowthCardItem(title: '本周挑战', value: '3 / 5', colorHex: '#B8F1E0'),
    ];
  }
}

/// 成长页整页数据（可由后端一次性返回）
class GrowthPageData {
  const GrowthPageData({
    required this.reminder,
    required this.stats,
    required this.dailyTasks,
    required this.todayLearning,
    this.growthCards,
  });

  final ReminderData reminder;
  final GrowthStatsData stats;
  final List<DailyTask> dailyTasks;
  final TodayLearningData todayLearning;
  final List<GrowthCardItem>? growthCards;

  factory GrowthPageData.fromJson(Map<String, dynamic> json) {
    return GrowthPageData(
      reminder: ReminderData.fromJson(
        json['reminder'] as Map<String, dynamic>? ?? {},
      ),
      stats: GrowthStatsData.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      dailyTasks: (json['dailyTasks'] as List<dynamic>? ?? [])
          .map((e) => DailyTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      todayLearning: TodayLearningData.fromJson(
        json['todayLearning'] as Map<String, dynamic>? ?? {},
      ),
      growthCards: (json['growthCards'] as List<dynamic>?)
          ?.map((e) => GrowthCardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reminder': reminder.toJson(),
        'stats': stats.toJson(),
        'dailyTasks': dailyTasks.map((e) => e.toJson()).toList(),
        'todayLearning': todayLearning.toJson(),
        if (growthCards != null)
          'growthCards': growthCards!.map((e) => e.toJson()).toList(),
      };

  static GrowthPageData fallback() {
    return GrowthPageData(
      reminder: ReminderData.fallback(),
      stats: GrowthStatsData.fallback(),
      dailyTasks: DailyTask.fallbackTasks(),
      todayLearning: TodayLearningData.fallback(),
      growthCards: GrowthCardItem.fallbackCards(),
    );
  }
}

/// 成长数据仓库：当前返回假数据，之后可改为从后端接口加载
class GrowthDataRepository {
  static Future<GrowthPageData> load() async {
    // TODO: 替换为后端接口，例如：
    // final response = await http.get(Uri.parse('$baseUrl/growth'));
    // return GrowthPageData.fromJson(jsonDecode(response.body));
    return Future.value(GrowthPageData.fallback());
  }
}

/// 成长页数据 Future，与 demoDataFuture 类似，之后可改为 API
final Future<GrowthPageData> growthDataFuture = GrowthDataRepository.load();
