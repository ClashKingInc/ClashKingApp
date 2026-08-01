import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/features/pages/data/announcement_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_webview_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktopWeb = kIsWeb && constraints.maxWidth >= 900;
          final horizontalPadding = ((constraints.maxWidth - 1200) / 2)
              .clamp(16.0, double.infinity)
              .toDouble();
          return RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
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
                        _PostsLoadingSkeleton(isGrid: isDesktopWeb)
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
                        if (isDesktopWeb)
                          ResponsiveCardGrid(
                            itemCount: _posts.length,
                            minItemWidth: 360,
                            maxColumns: 2,
                            spacing: 16,
                            itemBuilder: (_, index) =>
                                _PostArchiveCard(post: _posts[index]),
                          )
                        else
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
                                _loading
                                    ? loc.generalLoading
                                    : loc.postsLoadMore,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostsLoadingSkeleton extends StatelessWidget {
  const _PostsLoadingSkeleton({required this.isGrid});

  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return ResponsiveCardGrid(
        itemCount: 4,
        minItemWidth: 360,
        maxColumns: 2,
        spacing: 16,
        itemBuilder: (_, index) => _PostSkeletonCard(showImage: index.isEven),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < 3; index++) ...[
          _PostSkeletonCard(showImage: index == 0),
          if (index != 2) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _PostSkeletonCard extends StatelessWidget {
  const _PostSkeletonCard({required this.showImage});

  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.chip);
    final lineRadius = BorderRadius.circular(6);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showImage)
              SkeletonLoader(
                width: double.infinity,
                height: 188,
                borderRadius: BorderRadius.zero,
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, showImage ? 14 : 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLoader(
                              width: double.infinity,
                              height: 24,
                              borderRadius: lineRadius,
                            ),
                            const SizedBox(height: 8),
                            SkeletonLoader(
                              width: 180,
                              height: 24,
                              borderRadius: lineRadius,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SkeletonLoader(
                        width: 30,
                        height: 30,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SkeletonLoader(
                    width: 108,
                    height: 14,
                    borderRadius: lineRadius,
                  ),
                  const SizedBox(height: 12),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 16,
                    borderRadius: lineRadius,
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 220,
                    height: 16,
                    borderRadius: lineRadius,
                  ),
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
      await openAnnouncementStory(context, announcement: post);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _PostArticlePage(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final publishedAt = post.publishedAt;
    final dateLabel = publishedAt == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(publishedAt.toLocal());
    final hasImage = post.bannerImageUrl?.isNotEmpty == true;
    final showLabels = post.isCurrent || post.isStory || post.pinnedOnHome;

    return Material(
      color: Theme.of(context).cardTheme.color ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              MobileWebImage(
                imageUrl: post.bannerImageUrl!,
                width: double.infinity,
                height: 188,
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: const SizedBox.expand(),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, hasImage ? 14 : 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PostOpenIndicator(color: colors.onSurfaceVariant),
                    ],
                  ),
                  if (dateLabel != null) ...[
                    const SizedBox(height: 8),
                    _PostDateLabel(dateLabel: dateLabel),
                  ],
                  if (post.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.subtitle,
                      maxLines: hasImage ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (showLabels) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (post.isCurrent)
                          _PostDotLabel(
                            label: loc.postsCurrent,
                            color: colors.primary,
                          ),
                        if (post.isStory)
                          _PostDotLabel(
                            label: loc.postsStory,
                            color: colors.tertiary,
                          ),
                        if (post.pinnedOnHome)
                          _PostDotLabel(
                            label: loc.postsPinned,
                            color: colors.secondary,
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

class _PostOpenIndicator extends StatelessWidget {
  const _PostOpenIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Icon(Icons.chevron_right_rounded, size: 30, color: color),
    );
  }
}

class _PostArticlePage extends StatelessWidget {
  const _PostArticlePage({required this.post});

  final AppAnnouncement post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final publishedAt = post.publishedAt;
    final dateLabel = publishedAt == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatFullDate(publishedAt.toLocal());
    final hasImage = post.bannerImageUrl?.isNotEmpty == true;
    final articleHtml = _postArticleHtml(post.body, stripHeroImage: hasImage);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: hasImage ? colors.surfaceContainer : colors.surface,
              border: hasImage
                  ? Border(bottom: BorderSide(color: colors.outlineVariant))
                  : null,
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasImage)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(AppRadius.chip),
                          ),
                          child: MobileWebImage(
                            imageUrl: post.bannerImageUrl!,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => ColoredBox(
                              color: colors.surfaceContainerHighest,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          hasImage ? 18 : 8,
                          20,
                          hasImage ? 20 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style:
                                  (hasImage
                                          ? textTheme.headlineSmall
                                          : textTheme.titleLarge)
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: hasImage ? 1.08 : 1.14,
                                      ),
                            ),
                            if (dateLabel != null) ...[
                              const SizedBox(height: 10),
                              _PostDateLabel(dateLabel: dateLabel),
                            ],
                            if (post.subtitle.isNotEmpty) ...[
                              SizedBox(height: hasImage ? 14 : 10),
                              Text(
                                post.subtitle,
                                style:
                                    (hasImage
                                            ? textTheme.titleMedium
                                            : textTheme.bodyLarge)
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: AnnouncementWebView(
                  html: articleHtml,
                  url: articleHtml == null || articleHtml.trim().isEmpty
                      ? post.htmlUrl
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _postArticleHtml(String? html, {required bool stripHeroImage}) {
  if (!stripHeroImage || html == null || html.isEmpty) return html;
  return html.replaceFirst(
    RegExp(r'<img class="hero" src="[^"]*" alt="">'),
    '',
  );
}

class _PostDateLabel extends StatelessWidget {
  const _PostDateLabel({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 15,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PostDotLabel extends StatelessWidget {
  const _PostDotLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
