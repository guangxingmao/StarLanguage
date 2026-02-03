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
    setState(() => _dataFuture = CommunityDataRepository.load());
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
                            MaterialPageRoute(builder: (_) => TopicDetailPage(post: post)),
                          );
                        },
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
  const CommunityMasonry({super.key, required this.posts, required this.onTap});

  final List<CommunityPost> posts;
  final ValueChanged<CommunityPost> onTap;

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
  const TopicPostCard({super.key, required this.data, required this.onTap});

  final CommunityPost data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: data.accent.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: data.accent,
                  child: const Icon(Icons.face_rounded, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(data.timeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8370))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(data.summary),
            if (data.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  data.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                ),
              ),
            ] else if (data.imageBase64 != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(data.imageBase64!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.local_offer_rounded, size: 18),
                Text(data.circle),
                const Icon(Icons.favorite_border_rounded, size: 18),
                Text('${data.likes}'),
                const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                Text('${data.comments}'),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showCommentSheet(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('评论'),
              ),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _topicsFuture = CommunityDataRepository.loadCommunityTopics(widget.circleId);
  }

  void _refreshTopics() {
    setState(() => _topicsFuture = CommunityDataRepository.loadCommunityTopics(widget.circleId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: FutureBuilder<List<CommunityPost>>(
              future: _topicsFuture,
              builder: (context, snapshot) {
                final circlePosts = snapshot.data ?? [];
                final loading = snapshot.connectionState == ConnectionState.waiting;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Text('${widget.circleName} 圈', style: Theme.of(context).textTheme.headlineLarge),
                        const Spacer(),
                        TextButton(
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
                          child: const Text('发话题'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('这里是 ${widget.circleName} 圈的话题讨论区'),
                    const SizedBox(height: 16),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (circlePosts.isEmpty)
                      const EmptyStateCard()
                    else
                      Column(
                        children: circlePosts
                            .map(
                              (post) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TopicPostCard(
                                  data: post,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => TopicDetailPage(post: post)),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
}

class TopicDetailPage extends StatelessWidget {
  const TopicDetailPage({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ValueListenableBuilder<Map<String, List<CommunityComment>>>(
              valueListenable: CommunityStore.comments,
              builder: (context, commentMap, _) {
                final list = commentMap[post.id] ?? const [];
                return ListView(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: post.accent.withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('来自 ${post.circle} 圈 · ${post.timeLabel}'),
                          const SizedBox(height: 12),
                          Text(post.content),
                          if (post.imageBase64 != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                base64Decode(post.imageBase64!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('评论', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (list.isEmpty)
                      const EmptyStateCard()
                    else
                      Column(
                        children: list
                            .map(
                              (comment) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE9E0C9)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: post.accent.withOpacity(0.3),
                                      child: const Icon(Icons.face_rounded, size: 18, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.author,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(comment.content),
                                          const SizedBox(height: 4),
                                          Text(comment.timeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8370))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9E0C9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('写评论', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: commentController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: '说点什么吧…',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                final text = commentController.text.trim();
                                if (text.isEmpty) return;
                                CommunityStore.addComment(post.id, text);
                                commentController.clear();
                              },
                              child: const Text('发布评论'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            final cid = post.communityId ?? '';
                            if (cid.isEmpty) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CircleHomePage(
                                  circleId: cid,
                                  circleName: post.circle,
                                ),
                              ),
                            );
                          },
                          child: const Text('进入圈子'),
                        ),
                      ],
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
}

class TopicEditorPage extends StatefulWidget {
  const TopicEditorPage({super.key, required this.communities, this.presetCircleName});

  /// 可选社群列表（含 id、name），用于选择发布到哪个圈子
  final List<Topic> communities;
  final String? presetCircleName;

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

  @override
  void initState() {
    super.initState();
    if (widget.communities.isEmpty) {
      _selectedTopic = const Topic(id: 'other', name: '其他');
      return;
    }
    final preset = widget.presetCircleName;
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
    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text('发布话题', style: Theme.of(context).textTheme.headlineLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('发布'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '话题标题',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '写下你的话题内容…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('添加图片'),
                    ),
                    const SizedBox(width: 12),
                    if (_imageBytes != null)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('选择圈子'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.communities.map((topic) {
                    final active = _selectedTopic.id == topic.id;
                    return ChoiceChip(
                      label: Text(topic.name),
                      selected: active,
                      onSelected: (_) => setState(() => _selectedTopic = topic),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
