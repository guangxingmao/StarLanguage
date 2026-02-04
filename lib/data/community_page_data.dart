import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_proxy.dart';
import 'community_data.dart';
import 'demo_data.dart';
import 'profile.dart';

/// 社群页数据（由后端接口填充）
class CommunityPageData {
  const CommunityPageData({
    required this.joinedCommunities,
    required this.hotPosts,
    this.error,
  });

  /// 用户已加入的社群（对应「已加入」一行）
  final List<Topic> joinedCommunities;
  /// 今日热门话题（来自 GET /topics/hot）
  final List<CommunityPost> hotPosts;
  /// 若接口失败或未登录时的提示
  final String? error;

  factory CommunityPageData.fromJson(Map<String, dynamic> json) {
    return CommunityPageData(
      joinedCommunities: (json['joinedCommunities'] as List<dynamic>? ?? [])
          .map((t) => Topic.fromJson(t as Map<String, dynamic>))
          .toList(),
      hotPosts: (json['hotPosts'] as List<dynamic>? ?? [])
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'joinedCommunities': joinedCommunities.map((t) => t.toJson()).toList(),
        'hotPosts': hotPosts.map((p) => p.toJson()).toList(),
        if (error != null) 'error': error,
      };

  static CommunityPageData fallback({String? error}) {
    return CommunityPageData(
      joinedCommunities: [],
      hotPosts: [],
      error: error,
    );
  }
}

/// 社群数据仓库：从后端 GET /communities/joined、GET /topics/hot 加载
class CommunityDataRepository {
  static Future<CommunityPageData> load() async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;

    List<Topic> joined = [];
    List<CommunityPost> hotPosts = [];

    // 今日热门话题（带 token 时返回 likedByMe）
    try {
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final resHot = await http.get(
        Uri.parse('$baseUrl/topics/hot'),
        headers: headers.isEmpty ? null : headers,
      );
      if (resHot.statusCode == 200) {
        final data = jsonDecode(resHot.body);
        if (data is List) {
          hotPosts = (data as List)
              .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    // 已加入社群（需登录）
    if (token != null && token.isNotEmpty) {
      try {
        final resJoined = await http.get(
          Uri.parse('$baseUrl/communities/joined'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (resJoined.statusCode == 200) {
          final data = jsonDecode(resJoined.body);
          if (data is List) {
            joined = (data as List)
                .map((e) => Topic.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {}
    }

    return CommunityPageData(
      joinedCommunities: joined,
      hotPosts: hotPosts,
      error: null,
    );
  }

  /// 全部社群（按热度排序），可选 q 按 name 包含搜索；带 token 时后端会排除已加入的社群
  static Future<List<Topic>> loadAllCommunities({String? q}) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    try {
      final uri = q != null && q.isNotEmpty
          ? Uri.parse('$baseUrl/communities').replace(queryParameters: {'q': q})
          : Uri.parse('$baseUrl/communities');
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(uri, headers: headers.isEmpty ? null : headers);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data is! List) return [];
      return (data as List)
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 加入社群（需登录）
  static Future<bool> joinCommunity(String communityId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/communities/$communityId/join'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 发布话题（需登录）。成功返回 post，失败返回 null 且 [createTopicLastError] 为原因
  static String? createTopicLastError;

  /// 发布话题（需登录）
  static Future<CommunityPost?> createTopic({
    required String communityId,
    required String title,
    required String content,
    String? summary,
    String? imageUrl,
  }) async {
    createTopicLastError = null;
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) {
      createTopicLastError = 'no_token';
      return null;
    }
    try {
      final body = <String, dynamic>{
        'communityId': communityId,
        'title': title,
        'content': content,
      };
      if (summary != null && summary.isNotEmpty) body['summary'] = summary;
      if (imageUrl != null && imageUrl.isNotEmpty) body['imageUrl'] = imageUrl;
      final res = await http.post(
        Uri.parse('$baseUrl/topics'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        return data != null ? CommunityPost.fromJson(data) : null;
      }
      if (res.statusCode == 401) {
        createTopicLastError = 'unauthorized';
        return null;
      }
      createTopicLastError = 'server_error';
      return null;
    } catch (_) {
      createTopicLastError = 'server_error';
      return null;
    }
  }

  /// 指定圈子下的所有话题（带 token 时返回 likedByMe）
  static Future<List<CommunityPost>> loadCommunityTopics(String communityId) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    try {
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(
        Uri.parse('$baseUrl/communities/$communityId/topics'),
        headers: headers.isEmpty ? null : headers,
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data is! List) return [];
      return (data as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 话题详情（含评论列表与 likedByMe）
  static Future<TopicDetailResult?> loadTopicDetail(String topicId) async {
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    final token = ProfileStore.authToken;
    try {
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(
        Uri.parse('$baseUrl/topics/$topicId'),
        headers: headers.isEmpty ? null : headers,
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (data == null) return null;
      // 详情接口返回评论列表为 commentList，避免与话题的 comments 数量字段冲突
      final commentsRaw = data['commentList'] ?? data['comments'];
      final List<CommunityComment> comments = [];
      if (commentsRaw is List) {
        for (final item in commentsRaw) {
          if (item is! Map<String, dynamic>) continue;
          try {
            comments.add(CommunityComment.fromJson(item));
          } catch (_) {
            // 单条解析失败则跳过，不影响其余评论展示
          }
        }
      }
      final post = CommunityPost.fromJson(data);
      return TopicDetailResult(post: post, comments: comments);
    } catch (_) {
      return null;
    }
  }

  /// 点赞话题（需登录）。成功返回最新 likes 数，失败返回 null
  static Future<int?> likeTopic(String topicId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/topics/$topicId/like'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final likes = data?['likes'];
      if (likes is num) return likes.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 取消点赞（需登录）。成功返回最新 likes 数，失败返回 null
  static Future<int?> unlikeTopic(String topicId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/topics/$topicId/like'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final likes = data?['likes'];
      if (likes is num) return likes.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 发表评论或回复（需登录）。parentId/replyToAuthor 为二级回复时传
  static Future<CommunityComment?> addTopicComment(
    String topicId,
    String content, {
    int? parentId,
    String? replyToAuthor,
  }) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return null;
    try {
      final body = <String, dynamic>{'content': content};
      if (parentId != null) body['parentId'] = parentId;
      if (replyToAuthor != null && replyToAuthor.isNotEmpty) body['replyToAuthor'] = replyToAuthor;
      final res = await http.post(
        Uri.parse('$baseUrl/topics/$topicId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode != 201) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data != null ? CommunityComment.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// 编辑话题（仅作者）。成功返回更新后的话题，失败返回 null
  static Future<CommunityPost?> updateTopic(
    String topicId, {
    required String title,
    required String content,
    String? summary,
    String? imageUrl,
  }) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return null;
    try {
      final body = <String, dynamic>{'title': title, 'content': content};
      if (summary != null) body['summary'] = summary;
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      final res = await http.put(
        Uri.parse('$baseUrl/topics/$topicId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data != null ? CommunityPost.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// 删除话题（仅作者）。成功返回 true
  static Future<bool> deleteTopic(String topicId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/topics/$topicId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// 编辑评论（仅作者）。成功返回更新后的评论，失败返回 null
  static Future<CommunityComment?> updateComment(
    String topicId,
    int commentId, {
    required String content,
  }) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/topics/$topicId/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data != null ? CommunityComment.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// 删除评论（仅作者）。成功返回 true
  static Future<bool> deleteComment(String topicId, int commentId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/topics/$topicId/comments/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// 本圈内「别人给我的评论」（我发的话题下、别人发的评论，需登录）
  static Future<List<ReceivedComment>> loadReceivedComments(String communityId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/communities/$communityId/received-comments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data is! List) return [];
      return (data as List)
          .map((e) => ReceivedComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 本圈内「我对别人的评论」（我在别人话题下的评论，需登录）
  static Future<List<ReceivedComment>> loadMyComments(String communityId) async {
    final token = ProfileStore.authToken;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/communities/$communityId/my-comments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data is! List) return [];
      return (data as List)
          .map((e) => ReceivedComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// 别人在我的话题下的评论（用于「我的」- 别人给我的评论）
class ReceivedComment {
  const ReceivedComment({
    required this.commentId,
    required this.topicId,
    required this.topicTitle,
    required this.author,
    required this.content,
    required this.timeLabel,
    this.replyToAuthor,
  });

  final int commentId;
  final int topicId;
  final String topicTitle;
  final String author;
  final String content;
  final String timeLabel;
  final String? replyToAuthor;

  factory ReceivedComment.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return ReceivedComment(
      commentId: toInt(json['commentId']),
      topicId: toInt(json['topicId']),
      topicTitle: json['topicTitle'] as String? ?? '',
      author: json['author'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      replyToAuthor: json['replyToAuthor'] as String?,
    );
  }
}

/// 话题详情接口返回：帖子 + 评论列表
class TopicDetailResult {
  const TopicDetailResult({required this.post, required this.comments});
  final CommunityPost post;
  final List<CommunityComment> comments;
}
