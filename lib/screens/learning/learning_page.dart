import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo_data.dart';
import '../../data/learning_data.dart';
import '../../widgets/starry_background.dart';
import '../../widgets/reveal.dart';

/// 学习页：搜索、筛选、精选内容瀑布流
class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _typeFilter = '全部';
  String _sourceFilter = '全部';
  Set<String> _topicFilters = {'全部'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContentItem> _filterContents(List<ContentItem> items) {
    final q = _query.trim();
    return items.where((item) {
      final matchesQuery = q.isEmpty ||
          item.title.contains(q) ||
          item.summary.contains(q) ||
          item.tag.contains(q) ||
          item.topic.contains(q) ||
          item.source.contains(q);
      final matchesType = _typeFilter == '全部' || item.type == _typeFilter;
      final matchesSource = _sourceFilter == '全部' || item.source == _sourceFilter;
      final activeTopics = _topicFilters.contains('全部') ? <String>{} : _topicFilters;
      final matchesTopic = activeTopics.isEmpty || activeTopics.contains(item.topic);
      return matchesQuery && matchesType && matchesSource && matchesTopic;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StarryBackground(),
        SafeArea(
          child: FutureBuilder<LearningPageData>(
            future: learningDataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? LearningPageData.fallback();
              final sources = [
                '全部',
                ...{...data.contents.map((c) => c.source)}
              ];
              final tags = [
                '全部',
                ...data.topics.map((t) => t.name)
              ];
              final filtered = _filterContents(data.contents);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Text('学习', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  SearchBarCard(
                    controller: _searchController,
                    onSubmitted: (value) => setState(() => _query = value),
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: 18),
                  FilterRow(
                    typeValue: _typeFilter,
                    sourceValue: _sourceFilter,
                    sources: sources,
                    topics: tags,
                    onTypeChanged: (value) => setState(() => _typeFilter = value),
                    onSourceChanged: (value) => setState(() => _sourceFilter = value),
                    topicValues: _topicFilters,
                    onTopicsChanged: (values) => setState(() => _topicFilters = values),
                  ),
                  const SizedBox(height: 16),
                  Text('精选内容', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: 120,
                    child: filtered.isEmpty
                        ? const EmptyStateCard()
                        : ContentMasonry(contents: filtered),
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

// ==================== 学习相关卡片 ====================

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC857), Color(0xFFFF9F1C)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F1C).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 识图小助手',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  '拍一拍，马上知道。',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '开始识图',
                    style: TextStyle(color: Color(0xFFFF9F1C), fontWeight: FontWeight.w700),
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

/// 主题/圈子标签芯片，学习页与社群页共用
class TopicChip extends StatelessWidget {
  const TopicChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class SearchBarCard extends StatelessWidget {
  const SearchBarCard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E0C9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9A8F77)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: '搜索你感兴趣的知识',
                hintStyle: TextStyle(color: Color(0xFF9A8F77)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF9A8F77),
            )
          else
            const Icon(Icons.tune_rounded, color: Color(0xFF9A8F77)),
        ],
      ),
    );
  }
}

/// 空状态卡片，学习页及其他列表页共用
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E0C9)),
      ),
      child: const Text('没有找到相关内容，换个关键词试试吧。'),
    );
  }
}

class FilterRow extends StatelessWidget {
  const FilterRow({
    super.key,
    required this.typeValue,
    required this.sourceValue,
    required this.sources,
    required this.topics,
    required this.onTypeChanged,
    required this.onSourceChanged,
    required this.topicValues,
    required this.onTopicsChanged,
  });

  final String typeValue;
  final String sourceValue;
  final Set<String> topicValues;
  final List<String> sources;
  final List<String> topics;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<Set<String>> onTopicsChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChip(
          label: '类型',
          value: typeValue,
          options: const ['全部', 'video', 'article'],
          onSelected: onTypeChanged,
          display: const {'video': '视频', 'article': '图文'},
        ),
        _FilterChip(
          label: '平台',
          value: sourceValue,
          options: sources,
          onSelected: onSourceChanged,
        ),
        _MultiFilterChip(
          label: '主题',
          values: topicValues,
          options: topics,
          onSelected: onTopicsChanged,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.display = const {},
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final Map<String, String> display;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (opt) => ListTile(
                    title: Text(display[opt] ?? opt),
                    trailing: opt == value ? const Icon(Icons.check_rounded) : null,
                    onTap: () {
                      onSelected(opt);
                      Navigator.of(context).pop();
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9E0C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ${display[value] ?? value}'),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MultiFilterChip extends StatelessWidget {
  const _MultiFilterChip({
    required this.label,
    required this.values,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final Set<String> values;
  final List<String> options;
  final ValueChanged<Set<String>> onSelected;

  @override
  Widget build(BuildContext context) {
    final display = values.contains('全部')
        ? '全部'
        : values.isEmpty
            ? '全部'
            : values.join(' / ');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final current = Set<String>.from(values);
          return StatefulBuilder(
            builder: (context, setState) {
              return ListView(
                shrinkWrap: true,
                children: options.map((opt) {
                  final checked = current.contains(opt);
                  return CheckboxListTile(
                    title: Text(opt),
                    value: checked,
                    onChanged: (value) {
                      setState(() {
                        if (opt == '全部') {
                          current
                            ..clear()
                            ..add('全部');
                        } else {
                          current.remove('全部');
                          if (value == true) {
                            current.add(opt);
                          } else {
                            current.remove(opt);
                          }
                          if (current.isEmpty) {
                            current.add('全部');
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9E0C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: $display'),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class ContentMasonry extends StatelessWidget {
  const ContentMasonry({super.key, required this.contents});

  final List<ContentItem> contents;

  @override
  Widget build(BuildContext context) {
    final left = <ContentItem>[];
    final right = <ContentItem>[];
    for (var i = 0; i < contents.length; i++) {
      if (i.isEven) {
        left.add(contents[i]);
      } else {
        right.add(contents[i]);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ContentCard(item: item),
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
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ContentCard(item: item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final mediaHeight = item.type == 'video' ? 120.0 : 150.0;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        if (item.url.isNotEmpty) {
          final uri = Uri.tryParse(item.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.url.isEmpty ? '将跳转到 ${item.source} 查看内容' : '无法打开链接，稍后再试',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: item.accent.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: mediaHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF6F1E3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: LearningIllustration(item: item)),
                  if (item.type == 'video')
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF9F1C)),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(item.type == 'video' ? '视频' : '图文'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Text(item.tag, style: TextStyle(color: item.accent, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(item.source, style: const TextStyle(fontSize: 12, color: Color(0xFF6F6B60))),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(item.summary, style: const TextStyle(color: Color(0xFF6F6B60))),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F1E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.videoLabel, style: const TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                const Icon(Icons.open_in_new_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LearningIllustration extends StatelessWidget {
  const LearningIllustration({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.imageUrl.startsWith('assets/') && item.imageUrl.endsWith('.svg'))
          SvgPicture.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => Container(color: item.accent.withOpacity(0.3)),
          )
        else if (item.imageUrl.startsWith('assets/'))
          Image.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: item.accent.withOpacity(0.3),
            ),
          )
        else if (item.imageUrl.isNotEmpty)
          Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: item.accent.withOpacity(0.3),
            ),
          )
        else
          Container(color: item.accent.withOpacity(0.3)),
        Positioned(
          left: 12,
          bottom: 8,
          child: _DecorStar(color: Colors.white.withOpacity(0.6), size: 18),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DecorStar extends StatelessWidget {
  const _DecorStar({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, color: color, size: size);
  }
}
