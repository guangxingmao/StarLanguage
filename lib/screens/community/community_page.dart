import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_route_observer.dart';
import '../../data/community_data.dart';
import '../../data/community_page_data.dart';
import '../../data/demo_data.dart';
import '../../data/profile.dart';
import '../../widgets/reveal.dart';
import '../../widgets/starry_background.dart';
import '../learning/learning_page.dart';

/// 社群 Tab 页（数据来自 [CommunityPageData]）；切回本 tab 时会重新拉取已加入与今日热门
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.selectedTabIndex = 0});

  /// 当前底部选中的 tab 索引，用于在切回社群 tab 时刷新数据
  final int selectedTabIndex;

  static const int communityTabIndex = 1;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with RouteAware {
  late Future<CommunityPageData> _dataFuture;
  ModalRoute<void>? _subscribedRoute;

  void _refresh() {
    setState(() {
      _dataFuture = CommunityDataRepository.load();
    });
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = CommunityDataRepository.load();
  }

  @override
  void didUpdateWidget(CommunityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTabIndex != CommunityPage.communityTabIndex &&
        widget.selectedTabIndex == CommunityPage.communityTabIndex) {
      _refresh();
    }
    if (widget.selectedTabIndex == CommunityPage.communityTabIndex) {
      _subscribeRoute();
    } else {
      _unsubscribeRoute();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.selectedTabIndex == CommunityPage.communityTabIndex) {
      _subscribeRoute();
    }
  }

  void _subscribeRoute() {
    if (_subscribedRoute != null) return;
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      _subscribedRoute = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  void _unsubscribeRoute() {
    if (_subscribedRoute == null) return;
    appRouteObserver.unsubscribe(this);
    _subscribedRoute = null;
  }

  @override
  void dispose() {
    _unsubscribeRoute();
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<CommunityPageData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final pageData = snapshot.data ?? CommunityPageData.fallback();
              final joined = pageData.joinedCommunities;
              final hotPosts = pageData.hotPosts;
              final circles = joined.map((t) => t.name).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Row(
                    children: [
                      Text('兴趣社群', style: Theme.of(context).textTheme.headlineLarge),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const JoinCommunityPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE9E0C9)),
                          ),
                          child: const Icon(Icons.add_rounded, color: Color(0xFFFF9F1C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('和同好一起探索'),
                  const SizedBox(height: 18),
                  CommunityComposer(
                    onCompose: () {
                      final list = joined.isNotEmpty ? joined : [const Topic(id: 'other', name: '其他')];
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicEditorPage(
                            communities: list,
                            presetCircleName: null,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('已加入', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: joined.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final topic = joined[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CircleHomePage(
                                  circleId: topic.id,
                                  circleName: topic.name,
                                ),
                              ),
                            );
                          },
                          child: TopicChip(label: '${topic.name}圈'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('今日热门话题', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (pageData.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(pageData.error!, style: const TextStyle(color: Color(0xFF8A8370))),
                    )
                  else if (hotPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('暂无今日热门话题', style: TextStyle(color: Color(0xFF8A8370))),
                    )
                  else
                    Reveal(
                      delay: 140,
                      child: CommunityMasonry(
                        posts: hotPosts,
                        onTap: (post) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TopicDetailPage(post: post, showEnterCircle: true),
                            ),
                          );
                        },
                        showLikeAndComment: false,
                      ),
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

// ==================== 社群组件 ====================

class CommunityHero extends StatelessWidget {
  const CommunityHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFB8F1E0), Color(0xFF2EC4B6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.group_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('加入兴趣圈', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('和同好一起闯关'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('去看看'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityComposer extends StatelessWidget {
  const CommunityComposer({super.key, required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E0C9)),
      ),
      child: Row(
        children: [
          buildAvatar(ProfileStore.profile.value.avatarIndex,
              base64Image: ProfileStore.profile.value.avatarBase64, size: 36),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '说点什么吧…',
              style: TextStyle(color: Color(0xFF9A8F77)),
            ),
          ),
          TextButton(
            onPressed: onCompose,
            child: const Text('发布'),
          ),
        ],
      ),
    );
  }
}

class CommunityMasonry extends StatelessWidget {
  const CommunityMasonry({
    super.key,
    required this.posts,
    required this.onTap,
    this.onLikeSuccess,
    /// 为 true 时仅展示，不显示点赞/评论按钮（用于今日热门）
    this.showLikeAndComment = true,
  });

  final List<CommunityPost> posts;
  final ValueChanged<CommunityPost> onTap;
  /// 点赞/取消点赞成功后回调（如刷新列表）
  final VoidCallback? onLikeSuccess;
  final bool showLikeAndComment;

  @override
  Widget build(BuildContext context) {
    final left = <CommunityPost>[];
    final right = <CommunityPost>[];
    for (var i = 0; i < posts.length; i++) {
      if (i.isEven) {
        left.add(posts[i]);
      } else {
        right.add(posts[i]);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TopicPostCard(
                      data: post,
                      onTap: () => onTap(post),
                      onLikePressed: showLikeAndComment ? onLikeSuccess : null,
                      showLikeAndComment: showLikeAndComment,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: right
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TopicPostCard(
                      data: post,
                      onTap: () => onTap(post),
                      onLikePressed: showLikeAndComment ? onLikeSuccess : null,
                      showLikeAndComment: showLikeAndComment,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class TopicPostCard extends StatelessWidget {
  const TopicPostCard({
    super.key,
    required this.data,
    required this.onTap,
    this.onLikePressed,
    /// 为 false 时仅展示，不显示点赞/评论按钮（今日热门用）
    this.showLikeAndComment = true,
    /// 为 true 时表示在圈子内列表，隐藏圈子标签、可显示「我的」角标
    this.isInCircle = false,
  });

  final CommunityPost data;
  final VoidCallback onTap;
  /// 点赞/取消点赞成功后调用（用于刷新列表）
  final VoidCallback? onLikePressed;
  final bool showLikeAndComment;
  final bool isInCircle;

  Future<void> _onLikeTap(BuildContext context) async {
    if (ProfileStore.authToken == null || ProfileStore.authToken!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录后再点赞')),
        );
      }
      return;
    }
    final newCount = data.likedByMe
        ? await CommunityDataRepository.unlikeTopic(data.id)
        : await CommunityDataRepository.likeTopic(data.id);
    if (newCount != null && context.mounted) {
      onLikePressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: data.accent.withOpacity(0.2),
                    child: Text(
                      data.author.isNotEmpty ? data.author[0] : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: data.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.author,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isInCircle && data.isMine)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '我的',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else if (!isInCircle) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.tag_rounded, size: 14, color: theme.colorScheme.outline),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  data.circle,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.timeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                data.summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (data.imageUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 140),
                  ),
                ),
              ] else if (data.imageBase64 != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(data.imageBase64!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (showLikeAndComment)
                    GestureDetector(
                      onTap: () => _onLikeTap(context),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              data.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 18,
                              color: data.likedByMe ? Colors.red : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data.likes}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 18, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${data.likes}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline_rounded, size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${data.comments}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCommentSheet(BuildContext context) async {
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('发表评论', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '说点什么吧…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('评论已发布（本地演示）')),
                  );
                },
                child: const Text('发布'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ==================== 加入新社群页 ====================

class JoinCommunityPage extends StatefulWidget {
  const JoinCommunityPage({super.key});

  @override
  State<JoinCommunityPage> createState() => _JoinCommunityPageState();
}

class _JoinCommunityPageState extends State<JoinCommunityPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Topic> _list = [];
  bool _loading = false;
  int _loadSequence = 0;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAll();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) return;
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        _loadAll();
        return;
      }
      _loadSearch(query);
    });
  }

  /// 初始加载全部社群（不传 q）
  Future<void> _loadAll() async {
    final seq = ++_loadSequence;
    setState(() => _loading = true);
    final list = await CommunityDataRepository.loadAllCommunities(q: null);
    if (!mounted || seq != _loadSequence) return;
    setState(() { _list = list; _loading = false; });
  }

  /// 仅在有输入时调用：按关键词搜索，无结果时接口返回空数组
  Future<void> _loadSearch(String query) async {
    if (query.isEmpty) return;
    final seq = ++_loadSequence;
    setState(() => _loading = true);
    final list = await CommunityDataRepository.loadAllCommunities(q: query);
    if (!mounted || seq != _loadSequence) return;
    setState(() { _list = list; _loading = false; });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _join(Topic topic) async {
    final ok = await CommunityDataRepository.joinCommunity(topic.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加入失败，请先登录')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已加入 ${topic.name} 圈')),
    );
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CircleHomePage(
          circleId: topic.id,
          circleName: topic.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text('加入新社群', style: Theme.of(context).textTheme.headlineLarge),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索社群名称…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) {
                      final q = _searchController.text.trim();
                      if (q.isEmpty) _loadAll(); else _loadSearch(q);
                    },
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _list.isEmpty
                          ? const Center(child: Text('暂无社群', style: TextStyle(color: Color(0xFF8A8370))))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: _list.length,
                              itemBuilder: (context, index) {
                                final topic = _list[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE9E0C9)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              topic.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            if (topic.description != null && topic.description!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                topic.description!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF8A8370),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (topic.memberCount != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${topic.memberCount} 人已加入',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8370)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      FilledButton(
                                        onPressed: () => _join(topic),
                                        child: const Text('加入'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 圈子 / 话题页 ====================

class CircleHomePage extends StatefulWidget {
  const CircleHomePage({super.key, required this.circleId, required this.circleName});

  final String circleId;
  final String circleName;

  @override
  State<CircleHomePage> createState() => _CircleHomePageState();
}

class _CircleHomePageState extends State<CircleHomePage> {
  late Future<List<CommunityPost>> _topicsFuture;
  late Future<List<ReceivedComment>> _receivedCommentsFuture;
  late Future<List<ReceivedComment>> _myCommentsFuture;
  /// true = 只显示「我的」内容（Tab 切换）
  bool _showMineOnly = false;
  /// 0=我的话题 1=我的评论 2=用户对我的评论
  int _mineTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _topicsFuture = CommunityDataRepository.loadCommunityTopics(widget.circleId);
    _receivedCommentsFuture = CommunityDataRepository.loadReceivedComments(widget.circleId);
    _myCommentsFuture = CommunityDataRepository.loadMyComments(widget.circleId);
  }

  void _refreshTopics() {
    setState(() {
      _topicsFuture = CommunityDataRepository.loadCommunityTopics(widget.circleId);
      _receivedCommentsFuture = CommunityDataRepository.loadReceivedComments(widget.circleId);
      _myCommentsFuture = CommunityDataRepository.loadMyComments(widget.circleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => TopicEditorPage(
                communities: [Topic(id: widget.circleId, name: widget.circleName)],
                presetCircleName: widget.circleName,
              ),
            ),
          );
          if (result == true && mounted) _refreshTopics();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('发话题'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: FutureBuilder<List<CommunityPost>>(
              future: _topicsFuture,
              builder: (context, snapshot) {
                final allPosts = snapshot.data ?? [];
                final loading = snapshot.connectionState == ConnectionState.waiting;
                final circlePosts = _showMineOnly
                    ? allPosts.where((p) => p.isMine).toList()
                    : allPosts;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${widget.circleName} 圈',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '话题讨论区',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: _showMineOnly
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () => setState(() => _showMineOnly = !_showMineOnly),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _showMineOnly ? Icons.person_rounded : Icons.person_outline_rounded,
                                            size: 18,
                                            color: _showMineOnly
                                                ? theme.colorScheme.onPrimaryContainer
                                                : theme.colorScheme.outline,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '我的',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: _showMineOnly
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (loading && !_showMineOnly)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (!_showMineOnly && circlePosts.isEmpty)
                      const SliverFillRemaining(child: EmptyStateCard())
                    else if (_showMineOnly)
                      ..._buildMineSlivers(theme, circlePosts)
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = circlePosts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TopicPostCard(
                                  data: post,
                                  isInCircle: true,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TopicDetailPage(post: post, showEnterCircle: false),
                                    ),
                                  ),
                                  onLikePressed: _refreshTopics,
                                ),
                              );
                            },
                            childCount: circlePosts.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 「我的」下：Tab 切换（话题 / 我的评论 / 收到的评论），只显示当前一类
  List<Widget> _buildMineSlivers(ThemeData theme, List<CommunityPost> myPosts) {
    const tabs = [
      (Icons.article_outlined, '话题'),
      (Icons.chat_bubble_outline_rounded, '我的评论'),
      (Icons.inbox_rounded, '收到的'),
    ];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            children: [
              for (int i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: _mineTabIndex == i
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: () => setState(() => _mineTabIndex = i),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[i].$1,
                              size: 18,
                              color: _mineTabIndex == i
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tabs[i].$2,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: _mineTabIndex == i ? FontWeight.w600 : FontWeight.w500,
                                color: _mineTabIndex == i
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (_mineTabIndex == 0) ..._buildMyTopicsSlivers(theme, myPosts),
      if (_mineTabIndex == 1) ..._buildMyCommentsSlivers(theme),
      if (_mineTabIndex == 2) ..._buildReceivedCommentsSlivers(theme),
      SliverToBoxAdapter(child: const SizedBox(height: 80)),
    ];
  }

  List<Widget> _buildMyTopicsSlivers(ThemeData theme, List<CommunityPost> myPosts) {
    if (myPosts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    '还没在本圈发过话题',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '点击左下角「发话题」发布第一条',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = myPosts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TopicPostCard(
                  data: post,
                  isInCircle: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TopicDetailPage(post: post, showEnterCircle: false),
                    ),
                  ),
                  onLikePressed: _refreshTopics,
                ),
              );
            },
            childCount: myPosts.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMyCommentsSlivers(ThemeData theme) {
    return [
      FutureBuilder<List<ReceivedComment>>(
        future: _myCommentsFuture,
        builder: (context, cs) => _commentListSliver(
          theme,
          cs,
          (t, c) => _buildMyCommentTile(t, c),
          emptyStateIcon: Icons.chat_bubble_outline_rounded,
          emptyStateTitle: '还没有评论过',
          emptyStateSubtitle: '在话题下留言会显示在这里',
        ),
      ),
    ];
  }

  List<Widget> _buildReceivedCommentsSlivers(ThemeData theme) {
    return [
      FutureBuilder<List<ReceivedComment>>(
        future: _receivedCommentsFuture,
        builder: (context, cs) => _commentListSliver(
          theme,
          cs,
          _buildReceivedCommentTile,
          emptyStateIcon: Icons.inbox_rounded,
          emptyStateTitle: '还没有收到评论',
          emptyStateSubtitle: '别人在你话题下的评论会显示在这里',
        ),
      ),
    ];
  }

  Widget _commentListSliver(
    ThemeData theme,
    AsyncSnapshot<List<ReceivedComment>> snapshot,
    Widget Function(ThemeData, ReceivedComment) tileBuilder, {
    IconData? emptyStateIcon,
    String? emptyStateTitle,
    String? emptyStateSubtitle,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }
    final list = snapshot.data ?? [];
    if (list.isEmpty) {
      if (emptyStateIcon != null && emptyStateTitle != null) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(emptyStateIcon, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    emptyStateTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                  if (emptyStateSubtitle != null && emptyStateSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      emptyStateSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            '暂无',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => tileBuilder(theme, list[index]),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildMyCommentTile(ThemeData theme, ReceivedComment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openTopicFromComment(c),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '我',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.content,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '在《${c.topicTitle.length > 14 ? "${c.topicTitle.substring(0, 14)}…" : c.topicTitle}》下',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopicFromComment(ReceivedComment c) {
    final post = CommunityPost(
      id: c.topicId.toString(),
      title: c.topicTitle,
      summary: '',
      content: '',
      circle: widget.circleName,
      author: '',
      timeLabel: '',
      likes: 0,
      comments: 0,
      accent: CommunityStore.accentForCircle(widget.circleName),
      communityId: widget.circleId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(post: post, showEnterCircle: false),
      ),
    );
  }

  Widget _buildReceivedCommentTile(ThemeData theme, ReceivedComment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openTopicFromComment(c),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.author,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.content,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '在《${c.topicTitle.length > 12 ? "${c.topicTitle.substring(0, 12)}…" : c.topicTitle}》下',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopicDetailPage extends StatefulWidget {
  const TopicDetailPage({super.key, required this.post, this.showEnterCircle = true});

  final CommunityPost post;
  /// 为 true 时右上角显示「进入圈子」（从今日热门进入时显示；从圈子内进入时不显示）
  final bool showEnterCircle;

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  CommunityPost get post => _post;
  late CommunityPost _post;
  List<CommunityComment> _comments = [];
  bool _loading = true;
  bool _sendingComment = false;
  final TextEditingController _commentController = TextEditingController();
  /// 当前正在回复的评论（id, author），为 null 表示发一级评论
  CommunityComment? _replyingTo;
  /// 已展开回复的一级评论 id（默认收起）
  final Set<String> _expandedReplyIds = {};

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final result = await CommunityDataRepository.loadTopicDetail(_post.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result != null) {
        _post = result.post;
        _comments = result.comments;
      }
    });
  }

  Future<void> _onLikeTap() async {
    if (ProfileStore.authToken == null || ProfileStore.authToken!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录后再点赞')),
        );
      }
      return;
    }
    final newCount = _post.likedByMe
        ? await CommunityDataRepository.unlikeTopic(_post.id)
        : await CommunityDataRepository.likeTopic(_post.id);
    if (newCount != null && mounted) {
      setState(() {
        _post = _post.copyWith(
          likes: newCount,
          likedByMe: !_post.likedByMe,
        );
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (ProfileStore.authToken == null || ProfileStore.authToken!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录后再评论')),
        );
      }
      return;
    }
    setState(() => _sendingComment = true);
    final newComment = await CommunityDataRepository.addTopicComment(
      _post.id,
      text,
      parentId: _replyingTo?.id,
      replyToAuthor: _replyingTo?.author,
    );
    if (!mounted) return;
    setState(() {
      _sendingComment = false;
      _replyingTo = null;
    });
    if (newComment != null) {
      _commentController.clear();
      _insertComment(newComment);
    }
  }

  List<CommunityComment> _insertReplyInto(List<CommunityComment> list, CommunityComment newComment) {
    return list.map((c) {
      if (c.id == newComment.parentId) {
        return CommunityComment(
          id: c.id,
          author: c.author,
          content: c.content,
          timeLabel: c.timeLabel,
          parentId: c.parentId,
          replyToAuthor: c.replyToAuthor,
          replies: [...c.replies, newComment],
        );
      }
      return CommunityComment(
        id: c.id,
        author: c.author,
        content: c.content,
        timeLabel: c.timeLabel,
        parentId: c.parentId,
        replyToAuthor: c.replyToAuthor,
        replies: _insertReplyInto(c.replies, newComment),
      );
    }).toList();
  }

  void _insertComment(CommunityComment newComment) {
    if (newComment.parentId == null) {
      setState(() {
        _comments = [newComment, ..._comments];
        _post = _post.copyWith(comments: _post.comments + 1);
      });
      return;
    }
    setState(() {
      _comments = _insertReplyInto(_comments, newComment);
      _post = _post.copyWith(comments: _post.comments + 1);
    });
  }

  bool _isRepliesExpanded(CommunityComment comment) =>
      comment.id != null && _expandedReplyIds.contains('${comment.id}');

  void _toggleReplies(CommunityComment comment) {
    if (comment.id == null) return;
    setState(() {
      final key = '${comment.id}';
      if (_expandedReplyIds.contains(key)) {
        _expandedReplyIds.remove(key);
      } else {
        _expandedReplyIds.add(key);
      }
    });
  }

  Widget _buildCommentTile(CommunityComment comment, {bool isReply = false}) {
    final theme = Theme.of(context);
    final isExpanded = comment.replies.isNotEmpty && _isRepliesExpanded(comment);
    final hasReplies = comment.replies.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 6 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: isReply
                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(isReply ? 12 : 14, 12, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isReply) ...[
                      Container(
                        width: 3,
                        margin: const EdgeInsets.only(right: 10, top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: _post.accent.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ] else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _post.accent.withOpacity(0.25),
                        child: Text(
                          comment.author.isNotEmpty ? comment.author[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _post.accent,
                          ),
                        ),
                      ),
                    if (!isReply) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.author,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (comment.replyToAuthor != null && comment.replyToAuthor!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '回复 ${comment.replyToAuthor}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                comment.timeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              // 只能回复别人的评论：自己的评论不展示“回复”
                              if (comment.id != null && !comment.isMine) ...[
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () => setState(() => _replyingTo = comment),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    child: Text(
                                      '回复',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: _post.accent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (comment.isMine && comment.id != null) ...[
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _editComment(comment),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    child: Text(
                                      '编辑',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _deleteComment(comment),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    child: Text(
                                      '删除',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasReplies)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _toggleReplies(comment),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpanded ? '收起回复' : '展开 ${comment.replies.length} 条回复',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 6),
                    ...comment.replies.map((r) => _buildCommentTile(r, isReply: true)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editComment(CommunityComment comment) async {
    if (comment.id == null) return;
    final controller = TextEditingController(text: comment.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑评论'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '评论内容',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (newContent == null || newContent.isEmpty || !mounted) return;
    final updated = await CommunityDataRepository.updateComment(
      _post.id,
      comment.id!,
      content: newContent,
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _comments = _replaceCommentInList(_comments, comment.id!, updated.copyWith(replies: comment.replies, isMine: true));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论已更新')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新失败，请重试')));
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    if (comment.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await CommunityDataRepository.deleteComment(_post.id, comment.id!);
    if (!mounted) return;
    if (success) {
      setState(() {
        _comments = _removeCommentFromList(_comments, comment.id!);
        _post = _post.copyWith(comments: _post.comments - 1);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论已删除')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
    }
  }

  List<CommunityComment> _replaceCommentInList(List<CommunityComment> list, int id, CommunityComment replacement) {
    return list.map((c) {
      if (c.id == id) return replacement;
      return c.copyWith(replies: _replaceCommentInList(c.replies, id, replacement));
    }).toList();
  }

  List<CommunityComment> _removeCommentFromList(List<CommunityComment> list, int id) {
    final result = <CommunityComment>[];
    for (final c in list) {
      if (c.id == id) continue;
      result.add(c.copyWith(replies: _removeCommentFromList(c.replies, id)));
    }
    return result;
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除话题'),
        content: const Text('确定要删除这条话题吗？删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await CommunityDataRepository.deleteTopic(_post.id);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 6),
                          Text('话题详情', style: Theme.of(context).textTheme.headlineLarge),
                          const Spacer(),
                          if (widget.showEnterCircle && _post.communityId != null && _post.communityId!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CircleHomePage(
                                        circleId: _post.communityId!,
                                        circleName: _post.circle,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.group_rounded, size: 18),
                                label: const Text('进入圈子'),
                              ),
                            ),
                          if (_post.isMine)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final updated = await Navigator.of(context).push<CommunityPost>(
                                    MaterialPageRoute(
                                      builder: (_) => TopicEditorPage(
                                        communities: [Topic(id: _post.communityId ?? '', name: _post.circle)],
                                        presetCircleName: _post.circle,
                                        initialTopic: _post,
                                      ),
                                    ),
                                  );
                                  if (updated != null && mounted) setState(() => _post = updated);
                                } else if (value == 'delete') {
                                  _confirmDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _post.accent.withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(_post.title, style: Theme.of(context).textTheme.titleLarge),
                                ),
                                if (_post.isMine)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _post.accent.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('我的', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('来自 ${_post.circle} 圈 · ${_post.timeLabel}'),
                            const SizedBox(height: 12),
                            Text(_post.content),
                            if (_post.imageUrl != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _post.imageUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(height: 160),
                                ),
                              ),
                            ] else if (_post.imageBase64 != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(_post.imageBase64!),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _onLikeTap,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 20,
                                      color: _post.likedByMe ? Colors.red : null,
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${_post.likes}'),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                    const SizedBox(width: 6),
                                    Text('${_post.comments}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('评论', style: Theme.of(context).textTheme.titleLarge),
                          if (_post.comments > 0) ...[
                            const SizedBox(width: 8),
                            Text('(${_post.comments})', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.outline)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_comments.isEmpty)
                        _post.comments > 0
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    const Text('评论加载异常或暂无评论', style: TextStyle(color: Color(0xFF8A8370))),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () async {
                                        setState(() => _loading = true);
                                        await _loadDetail();
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: const Text('重新加载评论'),
                                    ),
                                  ],
                                ),
                              )
                            : const EmptyStateCard()
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _comments.map((comment) => _buildCommentTile(comment)).toList(),
                        ),
                      const SizedBox(height: 16),
                      if (_replyingTo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Material(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.reply_rounded, size: 16, color: theme.colorScheme.onPrimaryContainer),
                                      const SizedBox(width: 6),
                                      Text(
                                        '回复 ${_replyingTo!.author}',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => setState(() => _replyingTo = null),
                                child: Text('取消', style: TextStyle(color: theme.colorScheme.outline)),
                              ),
                            ],
                          ),
                        ),
                      Material(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _replyingTo != null ? Icons.reply_rounded : Icons.chat_bubble_outline_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _replyingTo != null ? '回复 ${_replyingTo!.author}' : '写评论',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _commentController,
                                minLines: 2,
                                maxLines: 4,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: _replyingTo != null ? '说点什么…' : '说点什么吧…',
                                  hintStyle: TextStyle(color: theme.colorScheme.outline),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: _sendingComment ? null : _submitComment,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _sendingComment
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded, size: 18),
                                  label: Text(_sendingComment ? '发送中…' : '发布评论'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class TopicEditorPage extends StatefulWidget {
  const TopicEditorPage({
    super.key,
    required this.communities,
    this.presetCircleName,
    this.initialTopic,
  });

  /// 可选社群列表（含 id、name），用于选择发布到哪个圈子
  final List<Topic> communities;
  final String? presetCircleName;
  /// 编辑时传入原话题，预填标题与内容并提交时调用更新接口
  final CommunityPost? initialTopic;

  @override
  State<TopicEditorPage> createState() => _TopicEditorPageState();
}

class _TopicEditorPageState extends State<TopicEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late Topic _selectedTopic;
  Uint8List? _imageBytes;
  String? _imageMime;
  bool _submitting = false;
  bool get _isEditMode => widget.initialTopic != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null) {
      _titleController.text = widget.initialTopic!.title;
      _contentController.text = widget.initialTopic!.content;
    }
    if (widget.communities.isEmpty) {
      _selectedTopic = const Topic(id: 'other', name: '其他');
      return;
    }
    final preset = widget.presetCircleName ?? widget.initialTopic?.circle;
    _selectedTopic = preset != null
        ? widget.communities.firstWhere(
            (t) => t.name == preset,
            orElse: () => widget.communities.first,
          )
        : widget.communities.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题和内容')),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final summary = content.length > 500 ? '${content.substring(0, 500)}…' : content;
    if (_isEditMode && widget.initialTopic != null) {
      final updated = await CommunityDataRepository.updateTopic(
        widget.initialTopic!.id,
        title: title,
        content: content,
        summary: summary,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败，请重试')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
      Navigator.of(context).pop(updated);
      return;
    }
    final post = await CommunityDataRepository.createTopic(
      communityId: _selectedTopic.id,
      title: title,
      content: content,
      summary: summary,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (post == null) {
      final err = CommunityDataRepository.createTopicLastError;
      String msg = '发布失败，请重试';
      if (err == 'no_token') msg = '请先登录后再发布';
      else if (err == 'unauthorized') msg = '登录已过期，请重新登录';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发布成功')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageMime = file.mimeType ?? 'image/jpeg';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditMode ? '编辑话题' : '发布话题',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditMode ? '保存' : '发布'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '标题',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          style: theme.textTheme.titleMedium,
                          decoration: InputDecoration(
                            hintText: '写一个吸引人的标题',
                            hintStyle: TextStyle(color: theme.colorScheme.outline),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '内容',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentController,
                          minLines: 5,
                          maxLines: 10,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: '写下你的想法、问题或分享…',
                            hintStyle: TextStyle(color: theme.colorScheme.outline),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '图片',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                              label: const Text('添加图片'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (_imageBytes != null) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _imageBytes!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!_isEditMode && widget.communities.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            '选择圈子',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: widget.communities.map((topic) {
                              final active = _selectedTopic.id == topic.id;
                              return FilterChip(
                                label: Text(topic.name),
                                selected: active,
                                onSelected: (_) => setState(() => _selectedTopic = topic),
                                selectedColor: theme.colorScheme.primaryContainer,
                                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
