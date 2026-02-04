import 'package:flutter/material.dart';

import '../utils/color_util.dart';
import 'profile.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.circle,
    required this.author,
    required this.timeLabel,
    required this.likes,
    required this.comments,
    required this.accent,
    this.imageBase64,
    this.imageUrl,
    this.communityId,
    this.likedByMe = false,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String circle;
  final String author;
  final String timeLabel;
  final int likes;
  final int comments;
  final Color accent;
  final String? imageBase64;
  final String? imageUrl;
  /// 所属社群 id，用于跳转圈子页
  final String? communityId;
  /// 当前用户是否已点赞（依赖登录态）
  final bool likedByMe;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final circle = json['circle'] as String? ?? '';
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      circle: circle,
      author: json['author'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      accent: (json['accent'] is String && (json['accent'] as String).isNotEmpty)
          ? parseColor(json['accent'] as String)
          : CommunityStore.accentForCircle(circle),
      imageBase64: json['imageBase64'] as String?,
      imageUrl: json['imageUrl'] as String?,
      communityId: json['communityId'] as String?,
      likedByMe: json['likedByMe'] == true,
    );
  }

  CommunityPost copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? circle,
    String? author,
    String? timeLabel,
    int? likes,
    int? comments,
    Color? accent,
    String? imageBase64,
    String? imageUrl,
    String? communityId,
    bool? likedByMe,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      circle: circle ?? this.circle,
      author: author ?? this.author,
      timeLabel: timeLabel ?? this.timeLabel,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      accent: accent ?? this.accent,
      imageBase64: imageBase64 ?? this.imageBase64,
      imageUrl: imageUrl ?? this.imageUrl,
      communityId: communityId ?? this.communityId,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'content': content,
        'circle': circle,
        'author': author,
        'timeLabel': timeLabel,
        'likes': likes,
        'comments': comments,
        'accent': colorToHex(accent),
        if (imageBase64 != null) 'imageBase64': imageBase64,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (communityId != null) 'communityId': communityId,
        'likedByMe': likedByMe,
      };
}

class CommunityComment {
  const CommunityComment({
    required this.author,
    required this.content,
    required this.timeLabel,
  });

  final String author;
  final String content;
  final String timeLabel;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      author: json['author'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'author': author,
        'content': content,
        'timeLabel': timeLabel,
      };
}

class CommunityStore {
  static final ValueNotifier<List<CommunityPost>> posts =
      ValueNotifier<List<CommunityPost>>(seedPosts());
  static final ValueNotifier<Map<String, List<CommunityComment>>> comments =
      ValueNotifier<Map<String, List<CommunityComment>>>(_seedComments());
  static bool _seededFromData = false;

  static void addPost({
    required String title,
    required String content,
    required String circle,
    String? imageBase64,
  }) {
    final summary = content.length > 28 ? '${content.substring(0, 28)}…' : content;
    final accent = accentForCircle(circle);
    final item = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      summary: summary,
      content: content,
      circle: circle,
      author: ProfileStore.profile.value.name,
      timeLabel: '刚刚',
      likes: 0,
      comments: 0,
      accent: accent,
      imageBase64: imageBase64,
    );
    posts.value = [item, ...posts.value];
  }

  static void seedFromData(List<CommunityPost> data) {
    if (_seededFromData) return;
    _seededFromData = true;
    posts.value = data;
  }

  static bool _seededCommentsFromData = false;
  static void seedCommentsFromData(Map<String, List<CommunityComment>> data) {
    if (_seededCommentsFromData) return;
    _seededCommentsFromData = true;
    comments.value = data;
  }

  static void addComment(String postId, String content) {
    final list = List<CommunityComment>.from(comments.value[postId] ?? []);
    list.insert(
      0,
      CommunityComment(
        author: ProfileStore.profile.value.name,
        content: content,
        timeLabel: '刚刚',
      ),
    );
    comments.value = {...comments.value, postId: list};
  }

  static Color accentForCircle(String circle) {
    switch (circle) {
      case '历史':
        return const Color(0xFF5DADE2);
      case '计算机':
        return const Color(0xFF2EC4B6);
      case '篮球':
        return const Color(0xFFFF9F1C);
      case '动物':
        return const Color(0xFF6DD3CE);
      case '科学':
        return const Color(0xFFB8F1E0);
      default:
        return const Color(0xFFBFD7FF);
    }
  }

  static List<CommunityPost> seedPosts() {
    return const [
      CommunityPost(
        id: 'p1',
        title: '为什么猫咪爱晒太阳？',
        summary: '一起聊聊小动物的温暖秘密。',
        content: '你家的猫咪喜欢晒太阳吗？一起聊聊它们为什么总爱找暖暖的地方～',
        circle: '动物',
        author: '星知小记者',
        timeLabel: '2 小时前',
        likes: 128,
        comments: 36,
        accent: Color(0xFFBFD7FF),
      ),
      CommunityPost(
        id: 'p2',
        title: '你最喜欢的历史人物是谁？',
        summary: '留言区见～',
        content: '你最喜欢的历史人物是谁？他/她有哪些故事？欢迎分享～',
        circle: '历史',
        author: '唐宋小能手',
        timeLabel: '3 小时前',
        likes: 94,
        comments: 28,
        accent: Color(0xFFFFC857),
      ),
      CommunityPost(
        id: 'p3',
        title: '哪一刻让你爱上科学？',
        summary: '分享一个小实验～',
        content: '哪一刻让你爱上科学？写下一个小实验或小发现吧！',
        circle: '科学',
        author: '实验室小白',
        timeLabel: '5 小时前',
        likes: 86,
        comments: 19,
        accent: Color(0xFFB8F1E0),
      ),
      CommunityPost(
        id: 'p4',
        title: '篮球招式大揭秘',
        summary: '从三步上篮说起。',
        content: '你最常用的篮球招式是什么？从三步上篮说起～',
        circle: '篮球',
        author: '三分神投',
        timeLabel: '6 小时前',
        likes: 73,
        comments: 22,
        accent: Color(0xFF5DADE2),
      ),
      CommunityPost(
        id: 'p5',
        title: '我做了个小程序！',
        summary: '用 Scratch 做小游戏～',
        content: '用 Scratch 做了一个小游戏，想和大家交流一下做法～',
        circle: '计算机',
        author: '代码星',
        timeLabel: '昨天',
        likes: 61,
        comments: 12,
        accent: Color(0xFF9BDEAC),
      ),
      CommunityPost(
        id: 'p6',
        title: '长城到底有多长？',
        summary: '来聊聊历史建筑。',
        content: '长城到底有多长？不同资料说法不太一样，一起查查吧～',
        circle: '历史',
        author: '长城小导游',
        timeLabel: '昨天',
        likes: 52,
        comments: 10,
        accent: Color(0xFF5DADE2),
      ),
    ];
  }

  static Map<String, List<CommunityComment>> seedComments() {
    return {
      'p1': const [
        CommunityComment(author: '小星星', content: '我家猫咪每天都要晒太阳！', timeLabel: '1 小时前'),
        CommunityComment(author: '小小动物迷', content: '因为太阳暖暖的～', timeLabel: '45 分钟前'),
      ],
      'p2': const [
        CommunityComment(author: '历史控', content: '我喜欢李白和杜甫！', timeLabel: '2 小时前'),
      ],
    };
  }

  static Map<String, List<CommunityComment>> _seedComments() => seedComments();
}
