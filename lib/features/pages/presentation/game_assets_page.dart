import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/game_assets/data/game_asset_actions.dart';
import 'package:clashkingapp/features/game_assets/data/game_asset_manifest_service.dart';
import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:clashkingapp/features/game_assets/presentation/game_asset_image.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_search_field.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
    if (_loading && _manifest == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _GameAssetsHeader(
                category: null,
                refreshing: true,
                onRefresh: () => _load(forceRefresh: true),
                imageBuilder: widget.imageBuilder,
              ),
            ),
          ],
          body: _buildBody(context, loc),
        ),
      );
    }

    if (_error != null && _manifest == null || categories.isEmpty) {
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
        ],
        body: GameAssetCategoryPage(
          key: ValueKey('game-asset-subpage-${selectedCategory.id}'),
          category: selectedCategory,
          categories: categories,
          selectedCategoryId: selectedCategory.id,
          onCategorySelected: (id) => setState(() => _selectedCategoryID = id),
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
        children: const [_GameAssetsLoadingSkeleton()],
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
          AppEmptyState(
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

class _GameAssetsLoadingSkeleton extends StatelessWidget {
  const _GameAssetsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: SkeletonLoader(
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: SkeletonLoader(
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const SkeletonLoader(
              width: double.infinity,
              height: 44,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(height: 10),
            SkeletonLoader(width: 118, height: 12, borderRadius: radius),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: columns * 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 154,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) => const _GameAssetTileSkeleton(),
            ),
          ],
        );
      },
    );
  }
}

class _GameAssetTileSkeleton extends StatelessWidget {
  const _GameAssetTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Center(
                child: SkeletonLoader(
                  width: 70,
                  height: 70,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SkeletonLoader(
              width: double.infinity,
              height: 13,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            SkeletonLoader(
              width: 58,
              height: 11,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameAssetsHeader extends StatelessWidget {
  const _GameAssetsHeader({
    required this.category,
    required this.refreshing,
    required this.onRefresh,
    this.imageBuilder,
  });

  final GameAssetCategory? category;
  final bool refreshing;
  final VoidCallback onRefresh;
  final GameAssetImageBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final viewport = MediaQuery.sizeOf(context);
    final isDesktop = viewport.width >= 900;
    final isCompactLandscape = viewport.width >= 600 && viewport.height < 600;
    final height =
        MediaQuery.paddingOf(context).top +
        (isCompactLandscape ? 144 : (isDesktop ? 240 : 264));
    final maxWidth = isDesktop ? 1120.0 : double.infinity;
    final category = this.category;
    final imageCount = category == null
        ? null
        : formatGameAssetImageCount(
            loc,
            category.count,
            Localizations.localeOf(context),
          );
    final buildImage =
        imageBuilder ??
        (context, asset, fit) => GameAssetImage(asset: asset, fit: fit);
    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(
            imageUrl: ImageAssets.homeBaseBackground,
            height: height,
            additionalDarken: 0.08,
          ),
        ),
        SizedBox(
          key: const ValueKey('game-assets-header'),
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
                  SizedBox(
                    height: isCompactLandscape ? 0 : (isDesktop ? 4 : 8),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _GameAssetHeaderIdentity(
                        title: loc.sideGameAssetsTitle,
                        subtitle: loc.sideGameAssetsSubtitle,
                        imageCount: imageCount,
                        extensions: category?.extensions,
                        category: category,
                        buildImage: buildImage,
                        compact: isCompactLandscape,
                      ),
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

class _GameAssetHeaderIdentity extends StatelessWidget {
  const _GameAssetHeaderIdentity({
    required this.title,
    required this.subtitle,
    required this.imageCount,
    required this.extensions,
    required this.category,
    required this.buildImage,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final String? imageCount;
  final List<String>? extensions;
  final GameAssetCategory? category;
  final GameAssetImageBuilder buildImage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final imageCount = this.imageCount;
    final extensions = this.extensions ?? const <String>[];
    final extensionText = extensions.isEmpty
        ? loc.gameAssetsAllFormats
        : extensions.take(2).map((value) => value.toUpperCase()).join(' / ');
    final category = this.category;
    if (compact) {
      return _GameAssetCompactHeaderIdentity(
        title: title,
        subtitle: subtitle,
        imageCount: imageCount,
        extensionText: extensionText,
        category: category,
        buildImage: buildImage,
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            key: const ValueKey('game-assets-header-image'),
            width: 80,
            height: 80,
            child: category == null
                ? const Center(
                    child: SkeletonLoader(
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                  )
                : buildImage(
                    context,
                    category.representativeAsset,
                    BoxFit.contain,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (imageCount == null)
            const _GameAssetHeaderStatsSkeleton()
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: [
                _GameAssetHeaderStat(
                  icon: Icons.photo_library_rounded,
                  value: imageCount,
                ),
                _GameAssetHeaderStat(
                  icon: Icons.file_present_rounded,
                  value: extensionText,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GameAssetCompactHeaderIdentity extends StatelessWidget {
  const _GameAssetCompactHeaderIdentity({
    required this.title,
    required this.subtitle,
    required this.imageCount,
    required this.extensionText,
    required this.category,
    required this.buildImage,
  });

  final String title;
  final String subtitle;
  final String? imageCount;
  final String extensionText;
  final GameAssetCategory? category;
  final GameAssetImageBuilder buildImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          key: const ValueKey('game-assets-compact-header-image'),
          width: 56,
          height: 56,
          child: category == null
              ? const SkeletonLoader(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                )
              : buildImage(
                  context,
                  category!.representativeAsset,
                  BoxFit.contain,
                ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        if (imageCount == null)
          const _GameAssetHeaderStatsSkeleton()
        else
          Wrap(
            spacing: 7,
            children: [
              _GameAssetHeaderStat(
                icon: Icons.photo_library_rounded,
                value: imageCount!,
              ),
              _GameAssetHeaderStat(
                icon: Icons.file_present_rounded,
                value: extensionText,
              ),
            ],
          ),
      ],
    );
  }
}

class _GameAssetHeaderStatsSkeleton extends StatelessWidget {
  const _GameAssetHeaderStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        SkeletonLoader(
          width: 122,
          height: 31,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        SkeletonLoader(
          width: 82,
          height: 31,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ],
    );
  }
}

class _GameAssetHeaderStat extends StatelessWidget {
  const _GameAssetHeaderStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: colorScheme.onSurface),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameAssetCategoryPage extends StatefulWidget {
  const GameAssetCategoryPage({
    super.key,
    required this.category,
    this.categories = const [],
    this.selectedCategoryId,
    this.onCategorySelected,
    this.actions,
    this.imageBuilder,
    this.embedded = false,
  });

  final GameAssetCategory category;
  final List<GameAssetCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String>? onCategorySelected;
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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_query == _searchController.text) return;
    setState(() => _query = _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categoryName = formatGameAssetCategoryLocalized(
      loc,
      widget.category.id,
    );
    final buildImage =
        widget.imageBuilder ??
        (context, asset, fit) => GameAssetImage(asset: asset, fit: fit);
    final filteredAssets = filterGameAssets(
      widget.category.assets,
      query: _query,
      extension: _extension,
    );
    final content = _buildContent(loc, buildImage, filteredAssets);

    if (widget.embedded) {
      return _buildEmbeddedContent(content);
    }
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

  Widget _buildContent(
    AppLocalizations loc,
    GameAssetImageBuilder buildImage,
    List<GameAsset> filteredAssets,
  ) {
    final hasCategoryOptions = widget.categories.isNotEmpty;
    return Column(
      children: [
        _buildAssetControls(loc, buildImage, hasCategoryOptions),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 7),
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
                  child: AppEmptyState(
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
  }

  Widget _buildAssetControls(
    AppLocalizations loc,
    GameAssetImageBuilder buildImage,
    bool hasCategoryOptions,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopToolbar = constraints.maxWidth >= 600;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
          child: isDesktopToolbar
              ? _buildDesktopAssetControls(loc, buildImage, hasCategoryOptions)
              : _buildCompactAssetControls(
                  loc,
                  buildImage,
                  hasCategoryOptions,
                  constraints.maxWidth - 32,
                ),
        );
      },
    );
  }

  Widget _buildDesktopAssetControls(
    AppLocalizations loc,
    GameAssetImageBuilder buildImage,
    bool hasCategoryOptions,
  ) {
    return Row(
      key: const ValueKey('game-assets-desktop-toolbar'),
      children: [
        if (hasCategoryOptions) ...[
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) => FilterDropdown(
                sortBy: widget.selectedCategoryId ?? widget.category.id,
                updateSortBy: _selectCategory,
                sortByOptions: _categoryOptions(loc, buildImage),
                height: 44,
                maxWidth: constraints.maxWidth,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 190,
          child: FilterDropdown(
            sortBy: _extension,
            updateSortBy: _selectExtension,
            sortByOptions: _formatOptions(loc),
            height: 44,
            leadingIcon: Icons.file_present_rounded,
            maxWidth: 190,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: WarSearchField(
            key: const ValueKey('game-assets-search'),
            controller: _searchController,
            query: _query,
            hintText: loc.gameAssetsSearchHint,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAssetControls(
    AppLocalizations loc,
    GameAssetImageBuilder buildImage,
    bool hasCategoryOptions,
    double width,
  ) {
    final filterWidth = hasCategoryOptions ? (width - 8) / 2 : 164.0;
    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              if (hasCategoryOptions) ...[
                FilterDropdown(
                  sortBy: widget.selectedCategoryId ?? widget.category.id,
                  updateSortBy: _selectCategory,
                  sortByOptions: _categoryOptions(loc, buildImage),
                  height: 36,
                  maxWidth: filterWidth,
                ),
                const SizedBox(width: 8),
              ],
              FilterDropdown(
                sortBy: _extension,
                updateSortBy: _selectExtension,
                sortByOptions: _formatOptions(loc),
                height: 36,
                leadingIcon: Icons.file_present_rounded,
                maxWidth: filterWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        WarSearchField(
          key: const ValueKey('game-assets-search'),
          controller: _searchController,
          query: _query,
          hintText: loc.gameAssetsSearchHint,
        ),
      ],
    );
  }

  Map<List<Widget>, String> _categoryOptions(
    AppLocalizations loc,
    GameAssetImageBuilder buildImage,
  ) {
    return {
      for (final category in widget.categories)
        _gameAssetCategoryFilterLabel(context, loc, category, buildImage):
            category.id,
    };
  }

  Map<String, String> _formatOptions(AppLocalizations loc) {
    return {
      loc.gameAssetsAllFormats: '',
      for (final extension in widget.category.extensions)
        extension.toUpperCase(): extension,
    };
  }

  void _selectCategory(String value) {
    _searchController.clear();
    setState(() => _extension = '');
    widget.onCategorySelected?.call(value);
  }

  void _selectExtension(String value) => setState(() => _extension = value);

  Widget _buildEmbeddedContent(Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 1120
            ? 1120.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const ValueKey('game-assets-content-bound'),
            width: width,
            height: constraints.maxHeight,
            child: content,
          ),
        );
      },
    );
  }
}

List<Widget> _gameAssetCategoryFilterLabel(
  BuildContext context,
  AppLocalizations loc,
  GameAssetCategory category,
  GameAssetImageBuilder buildImage,
) {
  return [
    SizedBox.square(
      dimension: 22,
      child: buildImage(context, category.representativeAsset, BoxFit.contain),
    ),
    const SizedBox(width: 7),
    Expanded(
      child: Text(
        formatGameAssetCategoryLocalized(loc, category.id),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ];
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
                            ? const SkeletonActionIndicator(
                                width: 18,
                                height: 6,
                              )
                            : const Icon(Icons.ios_share_rounded),
                        label: Text(loc.gameAssetsShare),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SkeletonActionIndicator(
                                width: 18,
                                height: 6,
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

String formatGameAssetCategoryLocalized(AppLocalizations loc, String category) {
  return switch (category) {
    'buildings' => loc.gameAssetsCategoryBuildings,
    'capital_base' || 'capital-base' => loc.gameAssetsCategoryCapitalBase,
    'capital_house_parts' ||
    'capital-house-parts' ||
    'capital_house-parts' => loc.gameAssetsCategoryCapitalHouseParts,
    'chests' => loc.gameAssetsCategoryChests,
    'clan_labels' || 'clan-labels' => loc.gameAssetsCategoryClanLabels,
    'country_flags' || 'country-flags' => loc.gameAssetsCategoryCountryFlags,
    'decorations' => loc.gameAssetsCategoryDecorations,
    'equipment' => loc.gameAssetsCategoryEquipment,
    'guardians' => loc.gameAssetsCategoryGuardians,
    'heroes' => loc.gameAssetsCategoryHeroes,
    'pets' => loc.gameAssetsCategoryPets,
    'skins' => loc.gameAssetsCategorySkins,
    'spells' => loc.gameAssetsCategorySpells,
    'troops' => loc.gameAssetsCategoryTroops,
    _ => formatGameAssetCategory(category),
  };
}
