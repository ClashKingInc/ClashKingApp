import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_header.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum _TodoAccountFilter { all, mine, needsAction, done, bookmarked }

extension _TodoAccountFilterValue on _TodoAccountFilter {
  String get value => switch (this) {
    _TodoAccountFilter.all => 'all',
    _TodoAccountFilter.mine => 'mine',
    _TodoAccountFilter.needsAction => 'needs_action',
    _TodoAccountFilter.done => 'done',
    _TodoAccountFilter.bookmarked => 'bookmarked',
  };

  static _TodoAccountFilter fromValue(String value) {
    return switch (value) {
      'mine' => _TodoAccountFilter.mine,
      'needs_action' => _TodoAccountFilter.needsAction,
      'done' => _TodoAccountFilter.done,
      'bookmarked' => _TodoAccountFilter.bookmarked,
      _ => _TodoAccountFilter.all,
    };
  }
}

class PlayerToDoScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;

  const PlayerToDoScreen({
    super.key,
    required this.players,
    required this.memberPresenceMap,
  });

  @override
  PlayerToDoScreenState createState() => PlayerToDoScreenState();
}

class PlayerToDoScreenState extends State<PlayerToDoScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  _TodoAccountFilter _filter = _TodoAccountFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkService>();
    final cocService = context.watch<CocAccountService>();
    final playerPrefs = context.watch<PlayerCardPreferencesService>();
    final myAccountTags = cocService
        .getAccountTags()
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final bookmarkedTags = bookmarks.players
        .map((bookmark) => _normalizeTag(bookmark.tag))
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final todoPagePlayers = widget.players
        .where((player) {
          final tag = _normalizeTag(player.tag);
          final isCurrentAccount =
              myAccountTags.contains(tag) || bookmarkedTags.contains(tag);
          return isCurrentAccount && playerPrefs.isShownInTodoPage(player.tag);
        })
        .toList(growable: false);
    final searchedPlayers = todoPagePlayers
        .where(_matchesSearch)
        .toList(growable: false);
    final filteredPlayers =
        searchedPlayers
            .where(
              (player) => _matchesFilter(
                player,
                widget.memberPresenceMap,
                bookmarks,
                myAccountTags,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.lastOnline.compareTo(a.lastOnline));
    final filterCounts = _TodoFilterCounts.fromPlayers(
      searchedPlayers,
      widget.memberPresenceMap,
      bookmarks,
      myAccountTags,
    );

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          PlayerToDoHeader(
            players: searchedPlayers,
            memberPresenceMap: widget.memberPresenceMap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                _TodoControls(
                  controller: _searchController,
                  query: _query,
                  filter: _filter,
                  counts: filterCounts,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onClearQuery: _query.isEmpty
                      ? null
                      : () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                  onFilterChanged: (value) => setState(() => _filter = value),
                ),
                PlayerToDoBody(
                  players: filteredPlayers,
                  memberPresenceMap: widget.memberPresenceMap,
                  emptyText: _emptyText(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(Player player) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final clanName = player.clan?.name.isNotEmpty == true
        ? player.clan!.name
        : player.clanOverview.name;
    final searchable = [
      player.name,
      player.tag,
      player.tag.replaceAll('#', ''),
      clanName,
    ].join(' ').toLowerCase();
    return searchable.contains(normalizedQuery);
  }

  bool _matchesFilter(
    Player player,
    Map<String, WarMemberPresence> memberPresenceMap,
    BookmarkService bookmarks,
    Set<String> myAccountTags,
  ) {
    if (_filter == _TodoAccountFilter.all) return true;
    if (_filter == _TodoAccountFilter.mine) {
      return myAccountTags.contains(_normalizeTag(player.tag));
    }
    if (_filter == _TodoAccountFilter.bookmarked) {
      return bookmarks.isPlayerBookmarked(player.tag);
    }
    final member = memberPresenceMap[player.tag] ?? WarMemberPresence.empty();
    final hasOpenTodo = player.getTodoProgressRatio(memberCwl: member) < 1;
    return _filter == _TodoAccountFilter.needsAction
        ? hasOpenTodo
        : !hasOpenTodo;
  }

  String _emptyText() {
    final loc = AppLocalizations.of(context)!;
    if (_query.trim().isNotEmpty) {
      return loc.todoNoMatchingAccounts;
    }
    return switch (_filter) {
      _TodoAccountFilter.all => loc.todoNoConfiguredAccounts,
      _TodoAccountFilter.mine => loc.todoNoLinkedAccounts,
      _TodoAccountFilter.needsAction => loc.todoNoAccountsNeedAction,
      _TodoAccountFilter.done => loc.todoNoCompletedAccounts,
      _TodoAccountFilter.bookmarked => loc.todoNoBookmarkedAccounts,
    };
  }
}

class _TodoFilterCounts {
  const _TodoFilterCounts({
    required this.all,
    required this.mine,
    required this.needsAction,
    required this.done,
    required this.bookmarked,
  });

  final int all;
  final int mine;
  final int needsAction;
  final int done;
  final int bookmarked;

  factory _TodoFilterCounts.fromPlayers(
    List<Player> players,
    Map<String, WarMemberPresence> memberPresenceMap,
    BookmarkService bookmarks,
    Set<String> myAccountTags,
  ) {
    var mine = 0;
    var needsAction = 0;
    var done = 0;
    var bookmarked = 0;

    for (final player in players) {
      final member = memberPresenceMap[player.tag] ?? WarMemberPresence.empty();
      if (myAccountTags.contains(_normalizeTag(player.tag))) {
        mine++;
      }
      final hasOpenTodo = player.getTodoProgressRatio(memberCwl: member) < 1;
      if (hasOpenTodo) {
        needsAction++;
      } else {
        done++;
      }
      if (bookmarks.isPlayerBookmarked(player.tag)) {
        bookmarked++;
      }
    }

    return _TodoFilterCounts(
      all: players.length,
      mine: mine,
      needsAction: needsAction,
      done: done,
      bookmarked: bookmarked,
    );
  }
}

class _TodoControls extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final _TodoAccountFilter filter;
  final _TodoFilterCounts counts;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onClearQuery;
  final ValueChanged<_TodoAccountFilter> onFilterChanged;

  const _TodoControls({
    required this.controller,
    required this.query,
    required this.filter,
    required this.counts,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _TodoSearchField(
            controller: controller,
            query: query,
            onChanged: onQueryChanged,
            onClear: onClearQuery,
          ),
        ),
        const SizedBox(width: 10),
        FilterDropdown(
          sortBy: filter.value,
          updateSortBy: (value) =>
              onFilterChanged(_TodoAccountFilterValue.fromValue(value)),
          sortByOptions: {
            'All accounts (${counts.all})': _TodoAccountFilter.all.value,
            'My accounts (${counts.mine})': _TodoAccountFilter.mine.value,
            'To do (${counts.needsAction})':
                _TodoAccountFilter.needsAction.value,
            'Completed (${counts.done})': _TodoAccountFilter.done.value,
            'Bookmarked (${counts.bookmarked})':
                _TodoAccountFilter.bookmarked.value,
          },
          maxWidth: 140,
        ),
      ],
    );
  }
}

String _normalizeTag(String tag) =>
    tag.replaceAll('#', '').trim().toUpperCase();

class _TodoSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const _TodoSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LiquidGlassBar(
            height: 44,
            cornerRadius: 22,
            borderOpacity: Theme.of(context).brightness == Brightness.dark
                ? 0.22
                : 0.30,
            shadowOpacity: Theme.of(context).brightness == Brightness.dark
                ? 0.22
                : 0.08,
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.todoSearchAccountsHint,
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
                minWidth: 40,
                minHeight: 44,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      tooltip: AppLocalizations.of(context)!.generalClearSearch,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
