import 'package:flutter/foundation.dart';

/// 从其他页面跳转到百晓通并带入的问题（如擂台答题记录里「问百晓通」）
/// Shell 监听并切换到百晓通 tab；百晓通页监听并填入输入框后清空
final ValueNotifier<String?> assistantInitialQuestion = ValueNotifier<String?>(null);
