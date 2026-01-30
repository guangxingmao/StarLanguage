import 'demo_data.dart';

/// 学习页数据（可由后端接口填充）
class LearningPageData {
  const LearningPageData({
    required this.topics,
    required this.contents,
  });

  final List<Topic> topics;
  final List<ContentItem> contents;

  factory LearningPageData.fromJson(Map<String, dynamic> json) {
    return LearningPageData(
      topics: (json['topics'] as List<dynamic>? ?? [])
          .map((t) => Topic.fromJson(t as Map<String, dynamic>))
          .toList(),
      contents: (json['contents'] as List<dynamic>? ?? [])
          .map((c) => ContentItem.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'topics': topics.map((t) => t.toJson()).toList(),
        'contents': contents.map((c) => c.toJson()).toList(),
      };

  static LearningPageData fallback() {
    final demo = DemoData.fallback();
    return LearningPageData(
      topics: demo.topics,
      contents: demo.contents,
    );
  }
}

/// 学习数据仓库：当前返回假数据，之后可改为从后端接口加载
class LearningDataRepository {
  static Future<LearningPageData> load() async {
    return Future.value(LearningPageData.fallback());
  }
}

final Future<LearningPageData> learningDataFuture = LearningDataRepository.load();
