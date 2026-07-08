import 'dart:async';
import 'dart:convert';

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/pages/widgets/clan_search_filters_dialog.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

enum _SearchMode { players, clans }

enum _RecentSearchType { player, clan }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.overlay = false, this.autofocus = false});

  final bool overlay;
  final bool autofocus;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const int _recentLimit = 10;
  static final RegExp _tagRegExp = RegExp(r'^[PYLQGRJCUV0289]{3,9}$');

  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  _SearchMode _mode = _SearchMode.players;
  List<dynamic> _results = [];
  List<_RecentSearchItem> _recentItems = [];
  String _lastQuery = '';
  String _clanFilters = '';
  bool _isSearching = false;
  bool _hasSearched = false;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_queueSearch);
    _loadRecents();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.overlay) {
          Future.delayed(const Duration(milliseconds: 180), () {
            if (mounted) _focusNode.requestFocus();
          });
        } else if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final userId = _currentSearchUserId();
    if (userId == null) {
      if (!mounted) return;
      setState(() => _recentItems = []);
      return;
    }

    final items = <_RecentSearchItem>[];
    try {
      final encodedUserId = Uri.encodeComponent(userId);
      final response = await _apiService.getResponse(
        '/links/$encodedUserId/searches',
        requiresAuth: true,
      );

      items.addAll(_decodeRecentItems(response));
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      items.clear();
    }

    if (!mounted) return;
    setState(() => _recentItems = items.take(_recentLimit).toList());
  }

  List<_RecentSearchItem> _decodeRecentItems(http.Response response) {
    if (response.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) return [];

    final items = <_RecentSearchItem>[];
    items.addAll(_decodeRecentGroup(data['players'], _RecentSearchType.player));
    items.addAll(_decodeRecentGroup(data['clans'], _RecentSearchType.clan));
    return items;
  }

  List<_RecentSearchItem> _decodeRecentGroup(
    Object? rawItems,
    _RecentSearchType type,
  ) {
    if (rawItems is! List) return [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => _RecentSearchItem.fromApiJson(item, type))
        .whereType<_RecentSearchItem>()
        .toList();
  }

  String? _currentSearchUserId() {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.userId.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  Map<String, String>? _searchTrackingHeaders() {
    final userId = _currentSearchUserId();
    if (userId == null) return null;
    return {'x-ck-user-id': userId};
  }

  void _queueSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runSearch);
    setState(() {});
  }

  void _setMode(_SearchMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _results = [];
      _lastQuery = '';
      _hasSearched = false;
      _clanFilters = '';
    });
    _queueSearch();
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query == _lastQuery && _hasSearched) return;

    _lastQuery = query;
    final version = ++_searchVersion;
    if (query.length < 3) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = false;
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = _mode == _SearchMode.players
          ? await _searchPlayers(query)
          : await _searchClans(query);
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  Future<List<dynamic>> _searchPlayers(String query) async {
    const timeout = Duration(seconds: 10);
    final normalizedTag = query.replaceFirst('#', '').toUpperCase();
    final isTag = _tagRegExp.hasMatch(normalizedTag);
    if (isTag) {
      final response = await _apiService.proxyGet(
        '/players/${Uri.encodeComponent('#$normalizedTag')}',
        timeout: timeout,
        extraHeaders: _searchTrackingHeaders(),
      );
      if (response.statusCode != 200) return [];

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic> && data['items'] is List) {
        return data['items'] as List<dynamic>;
      }
      return [data];
    }

    final uri = Uri.parse(
      '${ApiService.apiUrlV1}/player/full-search/${Uri.encodeComponent(query)}',
    );
    final response = await http.get(uri).timeout(timeout);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic> && data['items'] is List) {
      return data['items'] as List<dynamic>;
    }
    return [data];
  }

  Future<List<dynamic>> _searchClans(String query) async {
    final searchQuery = 'name=${Uri.encodeQueryComponent(query)}';
    final response = await _apiService.proxyGet(
      '/clans?$searchQuery$_clanFilters&limit=20&memberList=false',
      timeout: const Duration(seconds: 10),
    );
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(body);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return data['items'] as List<dynamic>;
    }
    return [];
  }

  Future<void> _showClanFilters() async {
    final filters = await showDialog<String>(
      context: context,
      builder: (context) => ClanSearchFilters(),
    );
    if (!mounted) return;
    if (filters == null) return;
    setState(() {
      _clanFilters = filters;
      _lastQuery = '';
    });
    await _runSearch();
  }

  Future<void> _openPlayer(dynamic rawPlayer) async {
    final player = rawPlayer as Map<String, dynamic>;
    final navigator = Navigator.of(context);
    final playerService = context.read<PlayerService>();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final selectedPlayer = await playerService.getPlayerAndClanData(
        player['tag'],
      );
      await _recordPlayerRecent(player['tag']?.toString() ?? '');
      unawaited(_loadRecents());
      navigator.pop();
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(selectedPlayer: selectedPlayer),
        ),
      );
    } catch (_) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.searchErrorPlayerLoadFailed ?? 'Failed to load player data.',
          ),
        ),
      );
    }
  }

  Future<void> _openClan(dynamic rawClan) async {
    final clan = rawClan as Map<String, dynamic>;
    final navigator = Navigator.of(context);
    final clanService = context.read<ClanService>();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _recordClanRecent(clan['tag']?.toString() ?? '');
      final clanInfo = await _loadClanForResult(clan, clanService);
      unawaited(_loadRecents());
      navigator.pop();
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ClanInfoScreen(clanInfo: clanInfo),
        ),
      );
    } catch (_) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.searchErrorClanLoadFailed ?? 'Failed to load clan data.',
          ),
        ),
      );
    }
  }

  Future<Clan> _loadClanForResult(
    Map<String, dynamic> clan,
    ClanService clanService,
  ) async {
    final tag = clan['tag']?.toString() ?? '';

    try {
      return await clanService.getClanAndWarData(tag);
    } catch (_) {
      final response = await _apiService.proxyGet(
        '/clans/${Uri.encodeComponent(tag)}',
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load clan data');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid clan response');
      }
      final loadedClan = Clan.fromJson(data);
      await clanService.loadJoinLeaveForClan(loadedClan);
      return loadedClan;
    }
  }

  Future<void> _recordPlayerRecent(String tag) async {
    if (tag.isEmpty || _currentSearchUserId() == null) return;
    try {
      await _apiService.proxyGet(
        '/players/${Uri.encodeComponent(tag)}',
        extraHeaders: _searchTrackingHeaders(),
      );
    } catch (_) {}
  }

  Future<void> _recordClanRecent(String tag) async {
    if (tag.isEmpty || _currentSearchUserId() == null) return;
    try {
      await _apiService.proxyGet(
        '/clans/${Uri.encodeComponent(tag)}',
        extraHeaders: _searchTrackingHeaders(),
      );
    } catch (_) {}
  }

  Future<void> _openRecent(_RecentSearchItem item) async {
    if (item.type == _RecentSearchType.player) {
      await _openPlayer(item.toPlayerResult());
    } else {
      await _openClan(item.toClanResult());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hint = _mode == _SearchMode.players
        ? l10n?.playerSearchPlaceholder ?? 'Player name or tag'
        : l10n?.clanSearchPlaceholder ?? 'Clan name';
    final showRecents =
        _recentItems.isNotEmpty && _controller.text.trim().isEmpty;

    Widget searchField({required bool overlay}) {
      return SizedBox(
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NativeLiquidGlassBar(
              height: 48,
              cornerRadius: 24,
              interactive: true,
              borderOpacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.30,
              shadowOpacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.08,
            ),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 48,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_mode == _SearchMode.clans)
                      IconButton(
                        tooltip: l10n?.searchFilters ?? 'Filters',
                        onPressed: _showClanFilters,
                        splashRadius: 18,
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: _clanFilters.isEmpty
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                      ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_controller.text.isNotEmpty)
                      IconButton(
                        tooltip: l10n?.searchClear ?? 'Clear',
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                            _lastQuery = '';
                          });
                        },
                        splashRadius: 18,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                suffixIconConstraints: const BoxConstraints(minHeight: 48),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ],
        ),
      );
    }

    final resultChildren = <Widget>[
      if (showRecents) ...[
        Padding(
          padding: EdgeInsets.only(top: widget.overlay ? 4 : 18),
          child: Text(
            l10n?.searchRecent ?? 'Recent',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: widget.overlay
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._recentItems
            .take(_recentLimit)
            .map(
              (item) => _RecentResultTile(
                item: item,
                overlay: widget.overlay,
                onTap: () => _openRecent(item),
              ),
            ),
      ],
      if (!showRecents) SizedBox(height: widget.overlay ? 2 : 14),
      if (_hasSearched && !_isSearching && _results.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: Text(
              AppLocalizations.of(context)?.searchNoResult ?? 'No result.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        ..._results.map(
          (result) => _SearchResultTile(
            result: result as Map<String, dynamic>,
            mode: _mode,
            overlay: widget.overlay,
            onTap: () => _mode == _SearchMode.players
                ? _openPlayer(result)
                : _openClan(result),
          ),
        ),
    ];

    if (widget.overlay) {
      return Material(
        color: colorScheme.surface,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
                child: Row(
                  children: [
                    Expanded(child: searchField(overlay: true)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(60, 40),
                        textStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: _ModeSelector(
                  mode: _mode,
                  onChanged: _setMode,
                  useNativeLiquidGlass: false,
                  compact: true,
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    MediaQuery.paddingOf(context).bottom + 20,
                  ),
                  children: resultChildren,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final content = ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _ModeSelector(
          mode: _mode,
          onChanged: _setMode,
          useNativeLiquidGlass: true,
        ),
        const SizedBox(height: 12),
        searchField(overlay: false),
        ...resultChildren,
      ],
    );

    return Scaffold(body: content);
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.onChanged,
    this.useNativeLiquidGlass = true,
    this.compact = false,
  });

  final _SearchMode mode;
  final ValueChanged<_SearchMode> onChanged;
  final bool useNativeLiquidGlass;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final height = compact ? 40.0 : 52.0;
    final inset = compact ? 4.0 : 5.0;
    final selectedHeight = height - (inset * 2);
    final selectedRadius = selectedHeight / 2;

    Widget fallbackControl(BuildContext context) => SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;
          final selectedLeft = mode == _SearchMode.players
              ? inset
              : segmentWidth + inset;

          return Stack(
            fit: StackFit.expand,
            children: [
              _ModeSegmentChrome(
                height: height,
                cornerRadius: height / 2,
                native: useNativeLiquidGlass,
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: selectedLeft,
                top: inset,
                width: segmentWidth - (inset * 2),
                height: selectedHeight,
                child: _ModeSegmentChrome(
                  height: selectedHeight,
                  cornerRadius: selectedRadius,
                  selected: true,
                  native: useNativeLiquidGlass,
                ),
              ),
              Row(
                children: [
                  _ModeButton(
                    icon: Icons.person_search,
                    label: l10n?.searchTabPlayers ?? 'Players',
                    selected: mode == _SearchMode.players,
                    colorScheme: colorScheme,
                    compact: compact,
                    onTap: () => onChanged(_SearchMode.players),
                  ),
                  _ModeButton(
                    icon: Icons.shield_outlined,
                    label: l10n?.searchTabClans ?? 'Clans',
                    selected: mode == _SearchMode.clans,
                    colorScheme: colorScheme,
                    compact: compact,
                    onTap: () => onChanged(_SearchMode.clans),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (!useNativeLiquidGlass) {
      return fallbackControl(context);
    }

    return NativeLiquidGlassSegmentedControl<_SearchMode>(
      height: height,
      values: const [_SearchMode.players, _SearchMode.clans],
      labels: [
        l10n?.searchTabPlayers ?? 'Players',
        l10n?.searchTabClans ?? 'Clans',
      ],
      selected: mode,
      color: colorScheme.primary,
      onChanged: onChanged,
      fallbackBuilder: fallbackControl,
    );
  }
}

class _ModeSegmentChrome extends StatelessWidget {
  const _ModeSegmentChrome({
    required this.height,
    required this.cornerRadius,
    required this.native,
    this.selected = false,
  });

  final double height;
  final double cornerRadius;
  final bool native;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (native) {
      return NativeLiquidGlassBar(
        height: height,
        cornerRadius: cornerRadius,
        interactive: selected,
        selected: selected,
        borderOpacity: selected ? 0.46 : 0.28,
        shadowOpacity: selected ? 0.12 : 0.08,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.surface.withValues(alpha: 0.92)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: selected ? 0.34 : 0.22,
          ),
        ),
      ),
      child: SizedBox(height: height),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  SizedBox(width: compact ? 6 : 8),
                  Text(
                    label,
                    style:
                        (compact
                                ? Theme.of(context).textTheme.labelMedium
                                : Theme.of(context).textTheme.labelLarge)
                            ?.copyWith(
                              color: color,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.mode,
    required this.overlay,
    required this.onTap,
  });

  final Map<String, dynamic> result;
  final _SearchMode mode;
  final bool overlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlayer = mode == _SearchMode.players;
    final name = result['name']?.toString() ?? '';
    final tag = result['tag']?.toString() ?? '';
    final subtitle = isPlayer
        ? _playerSubtitle(result)
        : '${result['members'] ?? 0} members';

    return _EntityTile(
      name: name,
      tag: tag,
      subtitle: subtitle,
      leading: isPlayer
          ? MobileWebImage(imageUrl: _townHallImage(result))
          : _ClanBadge(imageUrl: _clanBadge(result)),
      overlay: overlay,
      onTap: onTap,
    );
  }

  String _playerSubtitle(Map<String, dynamic> player) {
    final clanData = player['clan'];
    final leagueData = player['league'];
    final clan = clanData is Map ? clanData['name'] : player['clan_name'];
    final league = leagueData is Map ? leagueData['name'] : player['league'];
    return [if (clan != null) clan, if (league != null) league].join(' • ');
  }

  String _townHallImage(Map<String, dynamic> player) {
    return ImageAssets.townHall(
      player['townHallLevel'] ?? player['townhall'] ?? 1,
    );
  }

  String? _clanBadge(Map<String, dynamic> clan) {
    final badgeUrls = clan['badgeUrls'];
    if (badgeUrls is Map<String, dynamic>) {
      return badgeUrls['medium'] ?? badgeUrls['small'];
    }
    return null;
  }
}

class _RecentResultTile extends StatelessWidget {
  const _RecentResultTile({
    required this.item,
    required this.overlay,
    required this.onTap,
  });

  final _RecentSearchItem item;
  final bool overlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _EntityTile(
      name: item.name,
      tag: item.tag,
      subtitle: item.subtitle,
      leading: item.type == _RecentSearchType.player
          ? MobileWebImage(imageUrl: item.imageUrl ?? ImageAssets.townHall(1))
          : _ClanBadge(imageUrl: item.imageUrl),
      overlay: overlay,
      onTap: onTap,
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({
    required this.name,
    required this.tag,
    required this.subtitle,
    required this.leading,
    required this.overlay,
    required this.onTap,
  });

  final String name;
  final String tag;
  final String subtitle;
  final Widget leading;
  final bool overlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileContent = Row(
      children: [
        SizedBox.square(dimension: overlay ? 48 : 54, child: leading),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: overlay ? FontWeight.w700 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          overlay ? Icons.north_west_rounded : Icons.chevron_right,
          color: overlay ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ],
    );

    if (overlay) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: tileContent,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: tileContent),
      ),
    );
  }
}

class _ClanBadge extends StatelessWidget {
  const _ClanBadge({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const Icon(Icons.shield_outlined, size: 40);
    }

    return MobileWebImage(
      imageUrl: imageUrl!,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) =>
          const Icon(Icons.shield_outlined, size: 40),
    );
  }
}

class _RecentSearchItem {
  const _RecentSearchItem({
    required this.type,
    required this.name,
    required this.tag,
    required this.subtitle,
    required this.createdAt,
    this.imageUrl,
  });

  final _RecentSearchType type;
  final String name;
  final String tag;
  final String subtitle;
  final DateTime createdAt;
  final String? imageUrl;

  static _RecentSearchItem? fromApiJson(
    Map<String, dynamic> json,
    _RecentSearchType fallbackType,
  ) {
    final type = fallbackType;
    final source = json;
    final tag = source['tag']?.toString() ?? '';
    if (tag.isEmpty) return null;

    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    if (type == _RecentSearchType.clan) {
      final badgeUrls = source['badgeUrls'];
      final badgeUrl = badgeUrls is Map<String, dynamic>
          ? badgeUrls['large']?.toString()
          : null;
      return _RecentSearchItem(
        type: type,
        name: source['name']?.toString() ?? tag,
        tag: tag,
        subtitle: '${source['members'] ?? 0} members',
        createdAt: createdAt,
        imageUrl: badgeUrl,
      );
    }

    final clanData = source['clan'];
    final leagueData = source['league'];
    final clan = clanData is Map<String, dynamic> ? clanData['name'] : null;
    final league = leagueData is Map<String, dynamic>
        ? leagueData['name']
        : null;
    return _RecentSearchItem(
      type: type,
      name: source['name']?.toString() ?? tag,
      tag: tag,
      subtitle: [
        if (clan != null) clan.toString(),
        if (league != null) league.toString(),
      ].join(' • '),
      createdAt: createdAt,
      imageUrl: ImageAssets.townHall(source['townHallLevel'] ?? 1),
    );
  }

  Map<String, dynamic> toPlayerResult() {
    return {'name': name, 'tag': tag, 'clan_name': subtitle, 'townhall': 1};
  }

  Map<String, dynamic> toClanResult() {
    return {
      'name': name,
      'tag': tag,
      'members': subtitle.split(' ').first,
      'badgeUrls': {'medium': imageUrl ?? ''},
    };
  }
}
