part of '../side_tabs_pages.dart';

class PopularPage extends StatelessWidget {
  const PopularPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkService>();
    final players = context.watch<PlayerService>().profiles;
    final clans = context.watch<ClanService>().clans.values.toList();
    final wars = context.watch<WarCwlService>().summaries.values.toList();

    final popularPlayers = _popularPlayers(players, bookmarks.players);
    final popularClans = _popularClans(clans, bookmarks.clans);
    final popularWars = _popularWars(wars, bookmarks.clans);
    final hasPopular =
        popularPlayers.isNotEmpty ||
        popularClans.isNotEmpty ||
        popularWars.isNotEmpty;

    final sections = <Widget>[
      if (popularPlayers.isNotEmpty)
        _PopularSection(
          icon: Icons.person_rounded,
          title: 'Players',
          count: popularPlayers.length,
          children: popularPlayers.map(_PopularRow.player).toList(),
        ),
      if (popularClans.isNotEmpty)
        _PopularSection(
          icon: Icons.shield_rounded,
          title: 'Clans',
          count: popularClans.length,
          children: popularClans.map(_PopularRow.clan).toList(),
        ),
      if (popularWars.isNotEmpty)
        _PopularSection(
          icon: Icons.sports_martial_arts_rounded,
          title: 'Wars & CWL',
          count: popularWars.length,
          children: popularWars.map(_PopularRow.war).toList(),
        ),
    ];

    return _SidePageScaffold(
      title: 'Popular',
      subtitle: 'Bookmarks, linked accounts, and active wars.',
      child: ListView(
        padding: _pagePadding,
        children: [
          _PopularSummaryChips(
            playerCount: popularPlayers.length,
            clanCount: popularClans.length,
            warCount: popularWars.length,
          ),
          const SizedBox(height: 16),
          if (hasPopular)
            for (var index = 0; index < sections.length; index++) ...[
              sections[index],
              if (index < sections.length - 1) const SizedBox(height: 14),
            ]
          else
            const _EmptyState(
              icon: Icons.trending_up_rounded,
              title: 'No popular items yet',
              body: 'Bookmark players and clans or link accounts to seed this.',
            ),
        ],
      ),
    );
  }

  List<_PopularItem> _popularPlayers(
    List<Player> players,
    List<BookmarkedPlayer> bookmarks,
  ) {
    final byTag = <String, _PopularItem>{};
    for (final player in players) {
      byTag[player.tag] = _PopularItem(
        title: player.name,
        subtitle: '${player.tag} · TH${player.townHallLevel}',
        metric: player.trophies,
        displayMetric: player.trophies,
        metricLabel: 'trophies',
        metricImageUrl: player.leagueUrl.isNotEmpty
            ? player.leagueUrl
            : ImageAssets.trophies,
        imageUrl: ImageAssets.townHall(player.townHallLevel),
      );
    }
    for (final bookmark in bookmarks) {
      final existing = byTag[bookmark.tag];
      byTag[bookmark.tag] = _PopularItem(
        title: bookmark.name,
        subtitle: '${bookmark.tag} · bookmarked',
        metric: (existing?.metric ?? bookmark.trophies) + 500,
        displayMetric: existing?.displayMetric ?? bookmark.trophies,
        metricLabel: 'trophies',
        metricImageUrl: bookmark.leagueUrl.isNotEmpty
            ? bookmark.leagueUrl
            : ImageAssets.trophies,
        imageUrl: ImageAssets.townHall(bookmark.townHallLevel),
      );
    }
    return byTag.values.toList()..sort((a, b) => b.metric.compareTo(a.metric));
  }

  List<_PopularItem> _popularClans(
    List<Clan> clans,
    List<BookmarkedClan> bookmarks,
  ) {
    final byTag = <String, _PopularItem>{};
    for (final clan in clans) {
      byTag[clan.tag] = _PopularItem(
        title: clan.name,
        subtitle: '${clan.tag} · level ${clan.clanLevel}',
        metric: clan.clanPoints,
        metricLabel: 'points',
        metricImageUrl: ImageAssets.trophies,
        imageUrl: clan.badgeUrls.medium,
      );
    }
    for (final bookmark in bookmarks) {
      final existing = byTag[bookmark.tag];
      byTag[bookmark.tag] = _PopularItem(
        title: bookmark.name,
        subtitle: '${bookmark.tag} · ${bookmark.memberCount} members',
        metric: (existing?.metric ?? bookmark.clanLevel * 100) + 500,
        metricLabel: 'interest',
        metricIcon: Icons.bookmark_rounded,
        imageUrl: bookmark.badgeUrl,
      );
    }
    return byTag.values.toList()..sort((a, b) => b.metric.compareTo(a.metric));
  }

  List<_PopularItem> _popularWars(
    Iterable<WarCwl> wars,
    List<BookmarkedClan> bookmarks,
  ) {
    final bookmarkedTags = bookmarks.map((clan) => clan.tag).toSet();
    final items = wars.map((war) {
      final active = war.isInWar || war.isInCwl;
      final score = (active ? 1000 : 0) + war.teamSize;
      return _PopularItem(
        title: war.tag,
        subtitle: war.isInCwl
            ? 'CWL · ${war.teamSize}v${war.teamSize}'
            : active
            ? 'War · ${war.teamSize}v${war.teamSize}'
            : 'No active war',
        metric: bookmarkedTags.contains(war.tag) ? score + 500 : score,
        metricLabel: active ? 'active' : 'tracked',
        metricIcon: active
            ? Icons.local_fire_department_rounded
            : Icons.visibility_rounded,
        imageUrl: war.isInCwl ? ImageAssets.cwlSwordsNoBorder : ImageAssets.war,
      );
    }).toList();
    return items..sort((a, b) => b.metric.compareTo(a.metric));
  }
}
