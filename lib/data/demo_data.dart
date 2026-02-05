import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/color_util.dart';
import 'community_data.dart';

class Topic {
  const Topic({
    required this.id,
    required this.name,
    this.description,
    this.memberCount,
  });

  final String id;
  final String name;
  final String? description;
  final int? memberCount;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (memberCount != null) 'memberCount': memberCount,
      };
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.topic,
    required this.title,
    required this.summary,
    required this.tag,
    required this.videoLabel,
    required this.accent,
    required this.type,
    required this.source,
    required this.url,
    required this.imageUrl,
  });

  final String id;
  final String topic;
  final String title;
  final String summary;
  final String tag;
  final String videoLabel;
  final Color accent;
  final String type;
  final String source;
  final String url;
  final String imageUrl;

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final accentHex = json['accent'] as String? ?? '#FFC857';
    return ContentItem(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? '历史',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      videoLabel: json['videoLabel'] as String? ?? '',
      accent: parseColor(accentHex),
      type: json['type'] as String? ?? 'video',
      source: json['source'] as String? ?? '来源',
      url: json['url'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'title': title,
        'summary': summary,
        'tag': tag,
        'videoLabel': videoLabel,
        'accent': colorToHex(accent),
        'type': type,
        'source': source,
        'url': url,
        'imageUrl': imageUrl,
      };

  ContentItem copyWith({String? imageUrl}) => ContentItem(
        id: id,
        topic: topic,
        title: title,
        summary: summary,
        tag: tag,
        videoLabel: videoLabel,
        accent: accent,
        type: type,
        source: source,
        url: url,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

class Question {
  const Question({
    required this.id,
    required this.title,
    required this.options,
    required this.answer,
    required this.topic,
    required this.subtopic,
  });

  final String id;
  final String title;
  final List<String> options;
  final String answer;
  final String topic;
  final String subtopic;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      answer: json['answer'] as String? ?? '',
      topic: json['topic'] as String? ?? '全部',
      subtopic: json['subtopic'] as String? ?? '综合知识',
    );
  }
}

class Achievement {
  const Achievement({required this.id, required this.name});

  final String id;
  final String name;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class DemoData {
  DemoData({
    required this.topics,
    required this.contents,
    required this.questions,
    required this.achievements,
    required this.communityPosts,
  });

  final List<Topic> topics;
  final List<ContentItem> contents;
  final List<Question> questions;
  final List<Achievement> achievements;
  final List<CommunityPost> communityPosts;

  factory DemoData.fromJson(Map<String, dynamic> json) {
    return DemoData(
      topics: (json['topics'] as List<dynamic>? ?? [])
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList(),
      contents: (json['contents'] as List<dynamic>? ?? [])
          .map((item) => ContentItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
      communityPosts: (json['communityPosts'] as List<dynamic>? ?? [])
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static DemoData fallback() {
    return DemoData(
      topics: const [
        Topic(id: 'basketball', name: '篮球'),
        Topic(id: 'history', name: '历史'),
        Topic(id: 'nature', name: '自然'),
        Topic(id: 'geography', name: '地理'),
        Topic(id: 'science', name: '科学'),
      ],
      contents: const [
        ContentItem(
          id: 'c1',
          topic: '篮球',
          title: '篮球为什么是五个人？',
          summary: '从战术分工到场地尺寸，三分钟搞懂。',
          tag: '篮球小百科',
          videoLabel: '抖音 · 2:30',
          accent: Color(0xFFFFC857),
          type: 'video',
          source: '抖音',
          url: 'https://www.douyin.com/search/%E7%AF%AE%E7%90%83%E4%B8%BA%E4%BB%80%E4%B9%88%E5%88%86%E4%BA%94%E4%B8%AA%E4%BD%8D%E7%BD%AE?modal_id=7460904865921879350&type=general',
          imageUrl: '',
        ),
        ContentItem(
          id: 'c2',
          topic: '历史',
          title: '唐朝有多开放？',
          summary: '从服饰、音乐到城市生活，看看大唐风。',
          tag: '历史故事',
          videoLabel: 'B 站 · 6:45',
          accent: Color(0xFF5DADE2),
          type: 'video',
          source: 'B站',
          url: 'https://www.bilibili.com/video/BV1Fv411Y7f1/',
          imageUrl: 'assets/images/tang_img.jpg',
        ),
        ContentItem(
          id: 'c3',
          topic: '科学',
          title: '为什么星星会闪烁？',
          summary: '空气折射让星光跳舞。',
          tag: '自然科学',
          videoLabel: '小红书 · 图文',
          accent: Color(0xFFB784F8),
          type: 'article',
          source: '小红书',
          url: '',
          imageUrl: '',
        ),
        ContentItem(
          id: 'c4',
          topic: '动物',
          title: '熊猫为什么爱竹子？',
          summary: '挑食还是进化选择？',
          tag: '动物观察',
          videoLabel: '百科 · 图文',
          accent: Color(0xFF6DD3CE),
          type: 'article',
          source: '科普站点',
          url: '',
          imageUrl: '',
        ),
      ],
      questions: const [
        Question(
          id: 'q1',
          title: '"丝绸之路"最繁盛的时期是？',
          options: ['A. 唐朝', 'B. 汉朝', 'C. 明朝', 'D. 清朝'],
          answer: 'A',
          topic: '历史',
          subtopic: '朝代故事',
        ),
      ],
      achievements: const [
        Achievement(id: 'a1', name: '闪亮新星'),
        Achievement(id: 'a2', name: '连胜三场'),
        Achievement(id: 'a3', name: '探索家'),
        Achievement(id: 'a4', name: '观察大师'),
        Achievement(id: 'a5', name: '历史小通'),
        Achievement(id: 'a6', name: '篮球达人'),
      ],
      communityPosts: CommunityStore.seedPosts(),
    );
  }
}

class DemoRepository {
  static Future<DemoData> load() async {
    final raw = await rootBundle.loadString('assets/data/demo.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DemoData.fromJson(map);
  }
}

final Future<DemoData> demoDataFuture = DemoRepository.load();
