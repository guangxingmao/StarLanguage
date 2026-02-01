import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/color_util.dart';
import 'ai_proxy.dart';
import 'profile.dart';

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
}

/// 成长数据仓库：已登录时调 GET /growth，未登录或失败时返回 null（由页面展示「暂无数据」）
class GrowthDataRepository {
  static Future<GrowthPageData?> load() async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/growth'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        if (data != null) return GrowthPageData.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// 更新某项每日任务完成状态（需登录）
  static Future<bool> setDailyTaskCompleted(String taskId, bool completed) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/growth/daily-tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'taskId': taskId, 'completed': completed}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 更新每日提醒设置（需登录）
  static Future<bool> updateReminder({String? reminderTime, String? message}) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return false;
    try {
      final body = <String, dynamic>{};
      if (reminderTime != null) body['reminderTime'] = reminderTime;
      if (message != null) body['message'] = message;
      final res = await http.patch(
        Uri.parse('$baseUrl/growth/reminder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 更新成长统计（需登录，擂台/学习完成后可调用）
  static Future<bool> updateStats({
    int? streakDays,
    int? accuracyPercent,
    int? badgeCount,
    int? weeklyDone,
    int? weeklyTotal,
  }) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return false;
    try {
      final body = <String, dynamic>{};
      if (streakDays != null) body['streakDays'] = streakDays;
      if (accuracyPercent != null) body['accuracyPercent'] = accuracyPercent;
      if (badgeCount != null) body['badgeCount'] = badgeCount;
      if (weeklyDone != null) body['weeklyDone'] = weeklyDone;
      if (weeklyTotal != null) body['weeklyTotal'] = weeklyTotal;
      if (body.isEmpty) return true;
      final res = await http.patch(
        Uri.parse('$baseUrl/growth/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// 成长页数据 Future（来自 GET /growth，未登录或失败时为 null）
final Future<GrowthPageData?> growthDataFuture = GrowthDataRepository.load();
