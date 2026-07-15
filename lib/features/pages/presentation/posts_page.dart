import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/pages/data/announcement_service.dart';
import 'package:clashkingapp/features/pages/data/announcement_story_cache_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_webview_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final AnnouncementService _service = AnnouncementService();
  final List<AppAnnouncement> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _posts.clear();
        _nextOffset = 0;
        _hasMore = true;
      }
    });
    try {
      final page = await _service.getPublishedPosts(offset: _nextOffset);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.items);
        _nextOffset = page.nextOffset;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.postsTitle)),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              sliver: SliverList.list(
                children: [
                  Text(
                    loc.postsDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_posts.isEmpty && _loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_posts.isEmpty && _error != null)
                    _PostsMessage(
                      icon: Icons.cloud_off_rounded,
                      title: loc.postsLoadFailed,
                      actionLabel: loc.generalRetry,
                      onAction: () => _load(reset: true),
                    )
                  else if (_posts.isEmpty)
                    _PostsMessage(
                      icon: Icons.article_outlined,
                      title: loc.postsEmpty,
                    )
                  else ...[
                    for (final post in _posts) ...[
                      _PostArchiveCard(post: post),
                      const SizedBox(height: 14),
                    ],
                    if (_error != null)
                      _PostsMessage(
                        icon: Icons.sync_problem_rounded,
                        title: loc.postsLoadFailed,
                        actionLabel: loc.generalRetry,
                        onAction: _load,
                      )
                    else if (_hasMore)
                      Center(
                        child: FilledButton.tonal(
                          onPressed: _loading ? null : _load,
                          child: Text(
                            _loading ? loc.generalLoading : loc.postsLoadMore,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostArchiveCard extends StatelessWidget {
  const _PostArchiveCard({required this.post});

  final AppAnnouncement post;

  Future<void> _open(BuildContext context) async {
    if (post.isStory) {
      final path = await AnnouncementStoryCacheService().prepare(post);
      if (!context.mounted || path == null) return;
      await showAnnouncementStoryDialog(
        context,
        announcement: post,
        preparedFilePath: path,
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnnouncementWebViewPage(
          title: post.title,
          html: post.body,
          url: post.htmlUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final publishedAt = post.publishedAt;
    final dateLabel = publishedAt == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(publishedAt.toLocal());

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.bannerImageUrl?.isNotEmpty == true)
              MobileWebImage(
                imageUrl: post.bannerImageUrl!,
                width: double.infinity,
                height: 156,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PostChip(
                        label: post.isCurrent
                            ? loc.postsCurrent
                            : loc.postsPast,
                        color: post.isCurrent
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      if (post.isStory)
                        _PostChip(
                          label: loc.postsStory,
                          color: colors.tertiary,
                        ),
                      if (post.pinnedOnHome)
                        _PostChip(
                          label: loc.postsPinned,
                          color: colors.secondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (dateLabel != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostChip extends StatelessWidget {
  const _PostChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PostsMessage extends StatelessWidget {
  const _PostsMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
