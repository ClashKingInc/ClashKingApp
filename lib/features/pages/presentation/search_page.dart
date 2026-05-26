import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/pages/widgets/clan_search_filters_dialog.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum _SearchMode { players, clans }

enum _RecentSearchType { player, clan }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const int _recentLimit = 5;
  static const String _recentKey = 'clashking_recent_search_results';

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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final items =
        prefs
            .getStringList(_recentKey)
            ?.map((value) => _RecentSearchItem.tryDecode(value))
            .whereType<_RecentSearchItem>()
            .toList() ??
        [];
    if (!mounted) return;
    setState(() => _recentItems = items);
  }

  Future<void> _saveRecent(_RecentSearchItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final next = [
      item,
      ..._recentItems.where((recent) => recent.tag != item.tag),
    ].take(_recentLimit).toList();
    await prefs.setStringList(
      _recentKey,
      next.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (!mounted) return;
    setState(() => _recentItems = next);
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
    final normalizedTag = query.replaceFirst('#', '');
    final isTag = RegExp(r'^[PYLQGRJCUV0289]{3,9}$').hasMatch(normalizedTag);
    final Uri uri;

    if (isTag) {
      uri = Uri.parse(
        '${ApiService.proxyUrl}/players/${Uri.encodeComponent('#$normalizedTag')}',
      );
    } else {
      uri = Uri.parse(
        '${ApiService.apiUrlV1}/player/full-search/${Uri.encodeComponent(query)}',
      );
    }

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
    final response = await http
        .get(
          Uri.parse(
            '${ApiService.proxyUrl}/clans?$searchQuery$_clanFilters&limit=20&memberList=false',
          ),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(utf8.decode(response.bodyBytes));
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final selectedPlayer = await PlayerService().getPlayerAndClanData(
        player['tag'],
      );
      await _saveRecent(_RecentSearchItem.fromPlayer(player));
      if (!mounted) return;
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(selectedPlayer: selectedPlayer),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load player data.')),
      );
    }
  }

  Future<void> _openClan(dynamic rawClan) async {
    final clan = rawClan as Map<String, dynamic>;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clanInfo = await _loadClanForResult(clan);
      await _saveRecent(_RecentSearchItem.fromClan(clan));
      if (!mounted) return;
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ClanInfoScreen(clanInfo: clanInfo),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load clan data.')),
      );
    }
  }

  Future<Clan> _loadClanForResult(Map<String, dynamic> clan) async {
    final tag = clan['tag']?.toString() ?? '';
    final clanService = ClanService();

    try {
      return await clanService.getClanAndWarData(tag);
    } catch (_) {
      final response = await http
          .get(
            Uri.parse(
              '${ApiService.proxyUrl}/clans/${Uri.encodeComponent(tag)}',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to load clan data');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid clan response');
      }
      return Clan.fromJson(data);
    }
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
    final hint = _mode == _SearchMode.players
        ? AppLocalizations.of(context)?.playerSearchPlaceholder ??
              "Player name or tag"
        : AppLocalizations.of(context)?.clanSearchPlaceholder ?? "Clan name";
    final showRecents =
        _recentItems.isNotEmpty && _controller.text.trim().isEmpty;

    return Scaffold(
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _ModeSelector(mode: _mode, onChanged: _setMode),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_mode == _SearchMode.clans)
                    IconButton(
                      tooltip: 'Filters',
                      onPressed: _showClanFilters,
                      icon: Icon(
                        Icons.filter_list,
                        color: _clanFilters.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
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
                      tooltip: 'Clear',
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                          _lastQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
              ),
            ),
          ),
          if (showRecents) ...[
            const SizedBox(height: 18),
            Text('Recent', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ..._recentItems
                .take(_recentLimit)
                .map(
                  (item) => _RecentResultTile(
                    item: item,
                    onTap: () => _openRecent(item),
                  ),
                ),
          ],
          const SizedBox(height: 14),
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
                onTap: () => _mode == _SearchMode.players
                    ? _openPlayer(result)
                    : _openClan(result),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final _SearchMode mode;
  final ValueChanged<_SearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;
          final selectedLeft = mode == _SearchMode.players
              ? 5.0
              : segmentWidth + 5.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              const NativeLiquidGlassBar(
                height: 52,
                cornerRadius: 26,
                borderOpacity: 0.28,
                shadowOpacity: 0.08,
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: selectedLeft,
                top: 5,
                width: segmentWidth - 10,
                height: 42,
                child: const NativeLiquidGlassBar(
                  height: 42,
                  cornerRadius: 21,
                  interactive: true,
                  selected: true,
                  borderOpacity: 0.46,
                  shadowOpacity: 0.12,
                ),
              ),
              Row(
                children: [
                  _ModeButton(
                    icon: Icons.person_search,
                    label: 'Players',
                    selected: mode == _SearchMode.players,
                    colorScheme: colorScheme,
                    onTap: () => onChanged(_SearchMode.players),
                  ),
                  _ModeButton(
                    icon: Icons.shield_outlined,
                    label: 'Clans',
                    selected: mode == _SearchMode.clans,
                    colorScheme: colorScheme,
                    onTap: () => onChanged(_SearchMode.clans),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
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
    required this.onTap,
  });

  final Map<String, dynamic> result;
  final _SearchMode mode;
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
  const _RecentResultTile({required this.item, required this.onTap});

  final _RecentSearchItem item;
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
    required this.onTap,
  });

  final String name;
  final String tag;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(dimension: 54, child: leading),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
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
                      const SizedBox(height: 6),
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
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
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

    return CachedNetworkImage(
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
    this.imageUrl,
  });

  final _RecentSearchType type;
  final String name;
  final String tag;
  final String subtitle;
  final String? imageUrl;

  factory _RecentSearchItem.fromPlayer(Map<String, dynamic> player) {
    final clanData = player['clan'];
    final clan = clanData is Map ? clanData['name'] : player['clan_name'];
    return _RecentSearchItem(
      type: _RecentSearchType.player,
      name: player['name']?.toString() ?? 'Player',
      tag: player['tag']?.toString() ?? '',
      subtitle: clan?.toString() ?? 'Player',
      imageUrl: ImageAssets.townHall(
        player['townHallLevel'] ?? player['townhall'] ?? 1,
      ),
    );
  }

  factory _RecentSearchItem.fromClan(Map<String, dynamic> clan) {
    final badgeUrls = clan['badgeUrls'];
    final badgeUrl = badgeUrls is Map<String, dynamic>
        ? badgeUrls['medium'] ?? badgeUrls['small']
        : null;
    return _RecentSearchItem(
      type: _RecentSearchType.clan,
      name: clan['name']?.toString() ?? 'Clan',
      tag: clan['tag']?.toString() ?? '',
      subtitle: '${clan['members'] ?? 0} members',
      imageUrl: badgeUrl?.toString(),
    );
  }

  static _RecentSearchItem? tryDecode(String value) {
    try {
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic>) return null;
      return _RecentSearchItem(
        type: json['type'] == 'clan'
            ? _RecentSearchType.clan
            : _RecentSearchType.player,
        name: json['name']?.toString() ?? '',
        tag: json['tag']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == _RecentSearchType.clan ? 'clan' : 'player',
      'name': name,
      'tag': tag,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
    };
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
