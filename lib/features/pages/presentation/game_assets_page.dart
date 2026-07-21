import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/game_assets/data/game_asset_actions.dart';
import 'package:clashkingapp/features/game_assets/data/game_asset_manifest_service.dart';
import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:clashkingapp/features/game_assets/presentation/game_asset_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'side_page_components.dart';

class GameAssetsPage extends StatefulWidget {
  const GameAssetsPage({
    super.key,
    this.repository,
    this.actions,
    this.imageBuilder,
  });

  final GameAssetManifestRepository? repository;
  final GameAssetActions? actions;
  final GameAssetImageBuilder? imageBuilder;

  @override
  State<GameAssetsPage> createState() => _GameAssetsPageState();
}

class _GameAssetsPageState extends State<GameAssetsPage> {
  late GameAssetManifestRepository _repository;
  GameAssetManifest? _manifest;
  Object? _error;
  var _loading = true;
  String? _selectedCategoryID;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? GameAssetManifestService.shared;
    _load();
  }

  @override
  void didUpdateWidget(GameAssetsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repository != oldWidget.repository) {
      _repository = widget.repository ?? GameAssetManifestService.shared;
      _manifest = null;
      _load(forceRefresh: true);
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final manifest = await _repository.load(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _manifest = manifest;
        final categories = manifest.categories;
        if (categories.isNotEmpty &&
            !categories.any((category) => category.id == _selectedCategoryID)) {
          _selectedCategoryID = categories.first.id;
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categories = _manifest?.categories ?? const <GameAssetCategory>[];
    if (_loading && _manifest == null ||
        _error != null && _manifest == null ||
        categories.isEmpty) {
      return SidePageScaffold(
        title: loc.sideGameAssetsTitle,
        subtitle: loc.sideGameAssetsSubtitle,
        child: _buildBody(context, loc),
      );
    }

    final selectedIndex = categories
        .indexWhere((category) => category.id == _selectedCategoryID)
        .clamp(0, categories.length - 1);
    final selectedCategory = categories[selectedIndex];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _GameAssetsHeader(
              category: selectedCategory,
              refreshing: _loading,
              onRefresh: () => _load(forceRefresh: true),
              imageBuilder: widget.imageBuilder,
            ),
          ),
          SliverToBoxAdapter(
            child: InfoProfileTabs(
              selectedIndex: selectedIndex,
              alwaysScrollable: true,
              onTabSelected: (index) =>
                  setState(() => _selectedCategoryID = categories[index].id),
              tabs: [
                for (final category in categories)
                  InfoProfileTabData(
                    label: formatGameAssetCategory(category.id),
                    imageUrl: category.representativeAsset.url.toString(),
                  ),
              ],
            ),
          ),
        ],
        body: GameAssetCategoryPage(
          key: ValueKey('game-asset-subpage-${selectedCategory.id}'),
          category: selectedCategory,
          actions: widget.actions,
          imageBuilder: widget.imageBuilder,
          embedded: true,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations loc) {
    if (_loading && _manifest == null) {
      return ListView(
        key: const ValueKey('game-assets-loading'),
        padding: sidePagePadding,
        children: [
          Text(loc.generalLoading),
          const SizedBox(height: 14),
          const SidePageLoadingRows(),
        ],
      );
    }

    if (_error != null && _manifest == null) {
      return ListView(
        key: const ValueKey('game-assets-error'),
        padding: sidePagePadding,
        children: [
          SidePageErrorPanel(
            message: loc.gameAssetsLoadError,
            detail: _error.toString(),
            onRetry: () => _load(forceRefresh: true),
          ),
        ],
      );
    }

    final categories = _manifest?.categories ?? const <GameAssetCategory>[];
    if (categories.isEmpty) {
      return ListView(
        key: const ValueKey('game-assets-empty'),
        padding: sidePagePadding,
        children: [
          SidePageEmptyState(
            icon: Icons.inventory_2_outlined,
            title: loc.gameAssetsEmptyTitle,
            body: loc.gameAssetsEmptyBody,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _GameAssetsHeader extends StatelessWidget {
  const _GameAssetsHeader({
    required this.category,
    required this.refreshing,
    required this.onRefresh,
    this.imageBuilder,
  });

  final GameAssetCategory category;
  final bool refreshing;
  final VoidCallback onRefresh;
  final GameAssetImageBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final height = MediaQuery.paddingOf(context).top + (isDesktop ? 184 : 204);
    final buildImage =
        imageBuilder ??
        (context, asset, fit) => GameAssetImage(asset: asset, fit: fit);
    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(
            imageUrl: ImageAssets.homeBaseBackground,
            height: height,
          ),
        ),
        SizedBox(
          height: height,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 12,
                0,
                isDesktop ? 24 : 12,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        iconColor: Colors.white,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onTap: () => Navigator.of(context).pop(),
                        showBackground: false,
                      ),
                      const Spacer(),
                      HeaderIconButton(
                        icon: refreshing
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                        iconColor: Colors.white,
                        tooltip: loc.sideRefresh,
                        onTap: refreshing ? () {} : onRefresh,
                        showBackground: false,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          key: const ValueKey('game-assets-header-image'),
                          dimension: 54,
                          child: buildImage(
                            context,
                            category.representativeAsset,
                            BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          loc.sideGameAssetsTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          loc.sideGameAssetsSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GameAssetCategoryPage extends StatefulWidget {
  const GameAssetCategoryPage({
    super.key,
    required this.category,
    this.actions,
    this.imageBuilder,
    this.embedded = false,
  });

  final GameAssetCategory category;
  final GameAssetActions? actions;
  final GameAssetImageBuilder? imageBuilder;
  final bool embedded;

  @override
  State<GameAssetCategoryPage> createState() => _GameAssetCategoryPageState();
}

class _GameAssetCategoryPageState extends State<GameAssetCategoryPage> {
  final _searchController = TextEditingController();
  late final GameAssetActions _actions;
  var _query = '';
  var _extension = '';

  @override
  void initState() {
    super.initState();
    _actions = widget.actions ?? PlatformGameAssetActions.shared;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categoryName = formatGameAssetCategory(widget.category.id);
    final filteredAssets = filterGameAssets(
      widget.category.assets,
      query: _query,
      extension: _extension,
    );

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  key: const ValueKey('game-assets-search'),
                  controller: _searchController,
                  query: _query,
                  hintText: loc.gameAssetsSearchHint,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(width: 10),
              FilterDropdown(
                sortBy: _extension,
                updateSortBy: (value) => setState(() => _extension = value),
                sortByOptions: {
                  loc.gameAssetsAllFormats: '',
                  for (final extension in widget.category.extensions)
                    extension.toUpperCase(): extension,
                },
                maxWidth: 132,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatGameAssetResultCount(
                loc,
                filteredAssets.length,
                Localizations.localeOf(context),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredAssets.isEmpty
              ? SingleChildScrollView(
                  child: SidePageEmptyState(
                    icon: Icons.search_off_rounded,
                    title: loc.gameAssetsNoResultsTitle,
                    body: loc.gameAssetsNoResultsBody,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    key: const ValueKey('game-assets-grid'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 600 ? 4 : 3,
                      mainAxisExtent: 154,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: filteredAssets.length,
                    itemBuilder: (context, index) => _GameAssetTile(
                      asset: filteredAssets[index],
                      actions: _actions,
                      imageBuilder: widget.imageBuilder,
                    ),
                  ),
                ),
        ),
      ],
    );

    if (widget.embedded) return content;
    return SidePageScaffold(
      title: categoryName,
      subtitle: formatGameAssetImageCount(
        loc,
        widget.category.count,
        Localizations.localeOf(context),
      ),
      child: content,
    );
  }
}

class _GameAssetTile extends StatelessWidget {
  const _GameAssetTile({
    required this.asset,
    required this.actions,
    this.imageBuilder,
  });

  final GameAsset asset;
  final GameAssetActions actions;
  final GameAssetImageBuilder? imageBuilder;

  Future<void> _copyUrl(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await actions.copy(asset.url.toString());
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.gameAssetsUrlCopied)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.gameAssetsCopyError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buildImage =
        imageBuilder ??
        (context, asset, fit) => GameAssetImage(asset: asset, fit: fit);

    return Semantics(
      button: true,
      hint: AppLocalizations.of(context)!.gameAssetsLongPressHint,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('game-asset-${asset.path}'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameAssetPreviewPage(
                asset: asset,
                actions: actions,
                imageBuilder: imageBuilder,
              ),
            ),
          ),
          onLongPress: () => _copyUrl(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: buildImage(context, asset, BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  asset.tileDisplayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameAssetPreviewPage extends StatefulWidget {
  const GameAssetPreviewPage({
    super.key,
    required this.asset,
    this.actions,
    this.imageBuilder,
  });

  final GameAsset asset;
  final GameAssetActions? actions;
  final GameAssetImageBuilder? imageBuilder;

  @override
  State<GameAssetPreviewPage> createState() => _GameAssetPreviewPageState();
}

class _GameAssetPreviewPageState extends State<GameAssetPreviewPage> {
  late final GameAssetActions _actions;
  var _sharing = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _actions = widget.actions ?? PlatformGameAssetActions.shared;
  }

  Future<void> _copy(String value, String confirmation) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await _actions.copy(value);
      if (!mounted) return;
      _showSnack(confirmation);
    } catch (_) {
      if (!mounted) return;
      _showSnack(loc.gameAssetsCopyError);
    }
  }

  Future<void> _share() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      await _actions.share(
        widget.asset,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) _showSnack(loc.gameAssetsShareError);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final savedPath = await _actions.save(widget.asset);
      if (!mounted) return;
      _showSnack(
        savedPath.isEmpty
            ? loc.gameAssetsSaved
            : loc.gameAssetsSavedTo(savedPath),
      );
    } catch (_) {
      if (mounted) _showSnack(loc.gameAssetsSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final buildImage =
        widget.imageBuilder ??
        (context, asset, fit) => GameAssetImage(asset: asset, fit: fit);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset.displayName),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.34,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Center(
                    child: buildImage(context, widget.asset, BoxFit.contain),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    widget.asset.path,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.asset.extension.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copy(
                          widget.asset.url.toString(),
                          loc.gameAssetsUrlCopied,
                        ),
                        icon: const Icon(Icons.link_rounded),
                        label: Text(loc.gameAssetsCopyUrl),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _copy(widget.asset.path, loc.gameAssetsPathCopied),
                        icon: const Icon(Icons.content_copy_rounded),
                        label: Text(loc.gameAssetsCopyPath),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _sharing ? null : _share,
                        icon: _sharing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded),
                        label: Text(loc.gameAssetsShare),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          _saving ? loc.gameAssetsSaving : loc.gameAssetsSave,
                        ),
                      ),
                    ],
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

String formatGameAssetCount(int count, Locale locale) {
  return NumberFormat.decimalPattern(locale.toString()).format(count);
}

String formatGameAssetImageCount(
  AppLocalizations loc,
  int count,
  Locale locale,
) {
  return count == 1
      ? loc.gameAssetsOneImage
      : loc.gameAssetsImageCount(formatGameAssetCount(count, locale));
}

String formatGameAssetResultCount(
  AppLocalizations loc,
  int count,
  Locale locale,
) {
  return count == 1
      ? loc.gameAssetsOneResult
      : loc.gameAssetsResultCount(formatGameAssetCount(count, locale));
}
