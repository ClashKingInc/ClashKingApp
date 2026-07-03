import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _PlayerRosterMode { linked, bookmarked }

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  _PlayerRosterMode _mode = _PlayerRosterMode.linked;
  final Set<String> _requestedBookmarkPlayerTags = {};

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final bookmarkService = context.watch<BookmarkService>();
    final linkedTags = cocService
        .getAccountTags()
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final profilesByTag = {
      for (final player in playerService.profiles)
        _normalizeTag(player.tag): player,
    };
    final linkedPlayers = linkedTags
        .map((tag) => profilesByTag[tag])
        .whereType<Player>()
        .toList(growable: false);
    final bookmarkedPlayers = bookmarkService.players
        .where((bookmark) => !linkedTags.contains(_normalizeTag(bookmark.tag)))
        .toList(growable: false);
    final missingBookmarkPlayerTags = bookmarkedPlayers
        .where(
          (bookmark) =>
              !profilesByTag.containsKey(_normalizeTag(bookmark.tag)) &&
              !_requestedBookmarkPlayerTags.contains(
                _normalizeTag(bookmark.tag),
              ),
        )
        .map((bookmark) => bookmark.tag)
        .toList(growable: false);
    if (missingBookmarkPlayerTags.isNotEmpty) {
      _requestedBookmarkPlayerTags.addAll(
        missingBookmarkPlayerTags.map(_normalizeTag),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          _hydrateBookmarkedPlayers(playerService, missingBookmarkPlayerTags),
        );
      });
    }
    final showingLinked = _mode == _PlayerRosterMode.linked;
    final itemCount = showingLinked
        ? linkedPlayers.length
        : bookmarkedPlayers.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            sliver: SliverToBoxAdapter(
              child: NativeLiquidGlassSegmentedControl<_PlayerRosterMode>(
                values: const [
                  _PlayerRosterMode.linked,
                  _PlayerRosterMode.bookmarked,
                ],
                labels: const ['Linked', 'Bookmarked'],
                selected: _mode,
                onChanged: (value) => setState(() => _mode = value),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.paddingOf(context).bottom + 96,
            ),
            sliver: itemCount == 0
                ? SliverToBoxAdapter(
                    child: _EmptyRosterMessage(
                      title: showingLinked
                          ? 'No linked accounts'
                          : 'No bookmarked players yet',
                      subtitle: showingLinked
                          ? 'Manage accounts from the account setup screen.'
                          : 'Open a player profile and save it for later.',
                    ),
                  )
                : SliverList.separated(
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (showingLinked) {
                        final player = linkedPlayers[index];
                        return _PlayerDataCard(
                          player: player,
                          showActivity: true,
                          statusIcon: Icons.verified_user_rounded,
                          statusColor: Theme.of(context).colorScheme.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlayerScreen(selectedPlayer: player),
                            ),
                          ),
                        );
                      }

                      final bookmark = bookmarkedPlayers[index];
                      final hydratedPlayer =
                          profilesByTag[_normalizeTag(bookmark.tag)];
                      if (hydratedPlayer != null) {
                        return _PlayerDataCard(
                          player: hydratedPlayer,
                          showActivity: false,
                          statusIcon: Icons.bookmark_rounded,
                          statusColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlayerScreen(selectedPlayer: hydratedPlayer),
                            ),
                          ),
                        );
                      }

                      return _BookmarkedPlayerCard(
                        player: bookmark,
                        onTap: () => _openBookmarkedPlayer(
                          context,
                          playerService,
                          bookmark.tag,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _hydrateBookmarkedPlayers(
    PlayerService playerService,
    List<String> tags,
  ) async {
    for (final tag in tags) {
      try {
        await playerService.getPlayerAndClanData(tag);
      } catch (_) {
        // Keep the local bookmark snapshot visible if the full profile cannot load.
      }
    }
  }

  Future<void> _openBookmarkedPlayer(
    BuildContext context,
    PlayerService playerService,
    String tag,
  ) async {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final player = await playerService.getPlayerAndClanData(tag);
      navigator.pop();
      if (!context.mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(selectedPlayer: player),
        ),
      );
    } catch (_) {
      navigator.pop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load bookmarked player.')),
      );
    }
  }
}

class _PlayerDataCard extends StatefulWidget {
  const _PlayerDataCard({
    required this.player,
    required this.showActivity,
    required this.statusIcon,
    required this.statusColor,
    required this.onTap,
  });

  final Player player;
  final bool showActivity;
  final IconData statusIcon;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  State<_PlayerDataCard> createState() => _PlayerDataCardState();
}

class _PlayerDataCardState extends State<_PlayerDataCard> {
  bool _optionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    return _PlayerCardShell(
      imageUrl: player.townHallPic,
      imageCaption: widget.showActivity
          ? player.getLastOnlineText(context)
          : null,
      title: player.name,
      tag: player.tag,
      statusIcon: widget.statusIcon,
      statusColor: widget.statusColor,
      onTap: widget.onTap,
      footer: _PlayerCardOptionsFooter(
        tag: player.tag,
        expanded: _optionsExpanded,
        onToggleExpanded: () =>
            setState(() => _optionsExpanded = !_optionsExpanded),
      ),
      chips: [
        _InfoChipData(
          imageUrl: player.clan?.badgeUrls.small ?? ImageAssets.clanCastle,
          label:
              player.clan?.name ??
              (player.clanOverview.name.isNotEmpty
                  ? player.clanOverview.name
                  : 'No clan'),
        ),
        _InfoChipData(
          imageUrl: player.leagueUrl.isNotEmpty
              ? player.leagueUrl
              : ImageAssets.getLeagueImage(player.league),
          label: player.trophies.toString(),
        ),
      ],
    );
  }
}

class _BookmarkedPlayerCard extends StatelessWidget {
  const _BookmarkedPlayerCard({required this.player, required this.onTap});

  final BookmarkedPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PlayerCardShell(
      imageUrl: player.townHallPic.isNotEmpty
          ? player.townHallPic
          : ImageAssets.townHall(player.townHallLevel),
      imageCaption: null,
      title: player.name,
      tag: player.tag,
      statusIcon: Icons.bookmark_rounded,
      statusColor: Theme.of(context).colorScheme.onSurfaceVariant,
      onTap: onTap,
      chips: [
        _InfoChipData(
          imageUrl: ImageAssets.clanCastle,
          label: player.clanName.isNotEmpty ? player.clanName : 'No clan',
        ),
        if (player.trophies > 0)
          _InfoChipData(
            imageUrl: player.leagueUrl.isNotEmpty
                ? player.leagueUrl
                : ImageAssets.getLeagueImage(player.league),
            label: player.trophies.toString(),
          ),
      ],
    );
  }
}

class _PlayerCardShell extends StatelessWidget {
  const _PlayerCardShell({
    required this.imageUrl,
    required this.imageCaption,
    required this.title,
    required this.tag,
    required this.statusIcon,
    required this.statusColor,
    required this.chips,
    required this.onTap,
    this.footer,
  });

  final String imageUrl;
  final String? imageCaption;
  final String title;
  final String tag;
  final IconData statusIcon;
  final Color statusColor;
  final List<_InfoChipData> chips;
  final VoidCallback onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 66,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            SizedBox.square(
                              dimension: 62,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.shield_outlined),
                              ),
                            ),
                            if (imageCaption != null &&
                                imageCaption!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _wrapActivityCaption(imageCaption!),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      height: 1.05,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        Positioned(
                          right: -1,
                          top: 42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                statusIcon,
                                size: 14,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        Text(
                          tag,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: chips
                              .map((chip) => _InfoChip(data: chip))
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

String _normalizeTag(String tag) => tag.trim().toUpperCase();

class _PlayerCardOptionsFooter extends StatelessWidget {
  const _PlayerCardOptionsFooter({
    required this.tag,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final String tag;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final prefs = context.watch<PlayerCardPreferencesService>();
    final options = prefs.optionsFor(tag);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        InkWell(
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            alignment: Alignment.topCenter,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Column(
                      children: [
                        _PlayerOptionSwitch(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Get alerts for this account.',
                          value: options.notificationsEnabled,
                          onChanged: (value) =>
                              prefs.setNotificationsEnabled(tag, value),
                        ),
                        _PlayerOptionSwitch(
                          icon: Icons.checklist_rounded,
                          title: 'Show to-do on home',
                          subtitle:
                              "Pin this account's to-do card to the home tab.",
                          value: options.showTodoOnHome,
                          onChanged: (value) =>
                              prefs.setShowTodoOnHome(tag, value),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ),
      ],
    );
  }
}

class _PlayerOptionSwitch extends StatelessWidget {
  const _PlayerOptionSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.85,
              child: Switch.adaptive(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChipData {
  const _InfoChipData({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;
}

String _wrapActivityCaption(String value) {
  final trimmed = value.trim();
  final lastSpace = trimmed.lastIndexOf(' ');
  if (lastSpace <= 0) return trimmed;
  return '${trimmed.substring(0, lastSpace)}\n${trimmed.substring(lastSpace + 1)}';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.data});

  final _InfoChipData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CachedNetworkImage(
                imageUrl: data.imageUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.shield_outlined, size: 14),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              data.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRosterMessage extends StatelessWidget {
  const _EmptyRosterMessage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
