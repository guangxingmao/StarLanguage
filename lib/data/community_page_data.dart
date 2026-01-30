import 'community_data.dart';
import 'demo_data.dart';

/// 社群页数据（可由后端接口填充）
class CommunityPageData {
  const CommunityPageData({
    required this.topics,
    required this.posts,
    this.comments = const {},
  });

  final List<Topic> topics;
  final List<CommunityPost> posts;
  final Map<String, List<CommunityComment>> comments;

  factory CommunityPageData.fromJson(Map<String, dynamic> json) {
    final commentsRaw = json['comments'] as Map<String, dynamic>? ?? {};
    final comments = <String, List<CommunityComment>>{};
    for (final e in commentsRaw.entries) {
      comments[e.key as String] = (e.value as List<dynamic>)
          .map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return CommunityPageData(
      topics: (json['topics'] as List<dynamic>? ?? [])
          .map((t) => Topic.fromJson(t as Map<String, dynamic>))
          .toList(),
      posts: (json['posts'] as List<dynamic>? ?? [])
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList(),
      comments: comments,
    );
  }

  Map<String, dynamic> toJson() => {
        'topics': topics.map((t) => t.toJson()).toList(),
        'posts': posts.map((p) => p.toJson()).toList(),
        'comments': comments.map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
      };

  static CommunityPageData fallback() {
    return CommunityPageData(
      topics: DemoData.fallback().topics,
      posts: CommunityStore.seedPosts(),
      comments: CommunityStore.seedComments(),
    );
  }
}

/// 社群数据仓库：当前返回假数据，之后可改为从后端接口加载
class CommunityDataRepository {
  static Future<CommunityPageData> load() async {
    return Future.value(CommunityPageData.fallback());
  }
}

final Future<CommunityPageData> communityDataFuture = CommunityDataRepository.load();
