import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/widgets/account_verification_dialog.dart';
import 'package:clashkingapp/features/pages/widgets/account_visibility_option.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
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
    final l10n = AppLocalizations.of(context)!;
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final bottomPadding = isDesktopWeb
        ? 32.0
        : MediaQuery.paddingOf(context).bottom + 96;

    Widget buildRosterCard(BuildContext context, int index) {
      if (showingLinked) {
        final player = linkedPlayers[index];
        final link = cocService.getAccountLink(player.tag);
        final isVerified = link?.isVerified ?? false;
        return _PlayerDataCard(
          player: player,
          showActivity: true,
          isVerified: isVerified,
          hidden: link?.hidden ?? false,
          statusIcon: isVerified
              ? Icons.verified_user_rounded
              : Icons.warning_outlined,
          statusColor: isVerified
              ? Theme.of(context).colorScheme.primary
              : StatColors.capitalProjected,
          onVerifyAccount: isVerified
              ? null
              : () => _showVerificationDialog(context, player),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(selectedPlayer: player),
            ),
          ),
        );
      }

      final bookmark = bookmarkedPlayers[index];
      final hydratedPlayer = profilesByTag[_normalizeTag(bookmark.tag)];
      if (hydratedPlayer != null) {
        return _PlayerDataCard(
          player: hydratedPlayer,
          showActivity: false,
          statusIcon: Icons.bookmark_rounded,
          statusColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
        onTap: () =>
            _openBookmarkedPlayer(context, playerService, bookmark.tag),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = isDesktopWeb ? 1320.0 : 840.0;
        final horizontalPadding = ((constraints.maxWidth - maxContentWidth) / 2)
            .clamp(16.0, double.infinity)
            .toDouble();

        return Scaffold(
          body: CustomScrollView(
            scrollCacheExtent: const ScrollCacheExtent.pixels(800),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  14,
                ),
                sliver: SliverToBoxAdapter(
                  child: LiquidGlassSegmentedControl<_PlayerRosterMode>(
                    values: const [
                      _PlayerRosterMode.linked,
                      _PlayerRosterMode.bookmarked,
                    ],
                    labels: [l10n.playersLinked, l10n.playersBookmarked],
                    selected: _mode,
                    color: Theme.of(context).colorScheme.onSurface,
                    onChanged: (value) => setState(() => _mode = value),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  bottomPadding,
                ),
                sliver: itemCount == 0
                    ? SliverToBoxAdapter(
                        child: _EmptyRosterMessage(
                          title: showingLinked
                              ? AppLocalizations.of(
                                  context,
                                )!.dashboardNoLinkedAccountsTitle
                              : AppLocalizations.of(
                                  context,
                                )!.playersNoBookmarkedTitle,
                          subtitle: showingLinked
                              ? AppLocalizations.of(
                                  context,
                                )!.playersNoLinkedBody
                              : AppLocalizations.of(
                                  context,
                                )!.playersNoBookmarkedBody,
                          icon: showingLinked
                              ? Icons.account_circle_outlined
                              : Icons.bookmark_border_rounded,
                          actionLabel: showingLinked
                              ? l10n.drawerManageAccounts
                              : null,
                          onAction: showingLinked
                              ? () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AddCocAccountPage(
                                      refreshOnExit: false,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      )
                    : isDesktopWeb
                    ? SliverToBoxAdapter(
                        child: ResponsiveCardGrid(
                          itemCount: itemCount,
                          itemBuilder: buildRosterCard,
                        ),
                      )
                    : SliverList.separated(
                        itemCount: itemCount,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: buildRosterCard,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _hydrateBookmarkedPlayers(
    PlayerService playerService,
    List<String> tags,
  ) {
    return playerService.hydrateBookmarkedPlayers(tags);
  }

  Future<void> _openBookmarkedPlayer(
    BuildContext context,
    PlayerService playerService,
    String tag,
  ) async {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      useRootNavigator: false,
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bookmarkPlayerLoadFailed),
        ),
      );
    }
  }

  Future<void> _showVerificationDialog(
    BuildContext context,
    Player player,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AccountVerificationDialog(
        playerTag: player.tag,
        playerName: player.name,
        playerTownHall: player.townHallLevel,
      ),
    );
    if (result != true || !context.mounted) return;
    await context.read<CocAccountService>().fetchCocAccounts();
  }
}

class _PlayerDataCard extends StatefulWidget {
  const _PlayerDataCard({
    required this.player,
    required this.showActivity,
    this.isVerified,
    this.hidden,
    required this.statusIcon,
    required this.statusColor,
    this.onVerifyAccount,
    required this.onTap,
  });

  final Player player;
  final bool showActivity;
  final bool? isVerified;
  final bool? hidden;
  final IconData statusIcon;
  final Color statusColor;
  final VoidCallback? onVerifyAccount;
  final VoidCallback onTap;

  @override
  State<_PlayerDataCard> createState() => _PlayerDataCardState();
}

class _PlayerDataCardState extends State<_PlayerDataCard> {
  bool _optionsExpanded = false;
  bool _updatingVisibility = false;

  Future<void> _toggleVisibility() async {
    final hidden = widget.hidden;
    if (hidden == null) return;
    setState(() => _updatingVisibility = true);
    try {
      await context.read<CocAccountService>().updateAccountHidden(
        widget.player.tag,
        !hidden,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t update account visibility.')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingVisibility = false);
      }
    }
  }

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
      onStatusTap: widget.onVerifyAccount,
      onTap: widget.onTap,
      footer: _PlayerCardOptionsFooter(
        tag: player.tag,
        isVerified: widget.isVerified,
        hidden: widget.hidden,
        updatingVisibility: _updatingVisibility,
        onToggleVisibility: _toggleVisibility,
        onVerifyAccount: widget.onVerifyAccount,
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
    this.onStatusTap,
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
  final VoidCallback? onStatusTap;
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
                              child: MobileWebImage(
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
                          child: Tooltip(
                            message: onStatusTap == null
                                ? ''
                                : AppLocalizations.of(
                                    context,
                                  )!.homeVerifyAccountAction,
                            child: InkResponse(
                              onTap: onStatusTap,
                              radius: 18,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
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
          ?footer,
        ],
      ),
    );
  }
}

String _normalizeTag(String tag) => tag.trim().toUpperCase();

class _PlayerCardOptionsFooter extends StatelessWidget {
  const _PlayerCardOptionsFooter({
    required this.tag,
    required this.isVerified,
    required this.hidden,
    required this.updatingVisibility,
    required this.onToggleVisibility,
    required this.onVerifyAccount,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final String tag;
  final bool? isVerified;
  final bool? hidden;
  final bool updatingVisibility;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onVerifyAccount;
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
                        if (isVerified == false && onVerifyAccount != null)
                          _PlayerOptionAction(
                            icon: Icons.warning_amber_rounded,
                            title: AppLocalizations.of(
                              context,
                            )!.homeVerifyAccountAction,
                            subtitle: AppLocalizations.of(
                              context,
                            )!.playerOptionVerifyAccountBody,
                            color: StatColors.capitalProjected,
                            onTap: onVerifyAccount!,
                          ),
                        _PlayerOptionSwitch(
                          icon: Icons.notifications_outlined,
                          title: AppLocalizations.of(
                            context,
                          )!.playerOptionNotificationsTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.playerOptionNotificationsSubtitle,
                          value: options.notificationsEnabled,
                          onChanged: (value) =>
                              prefs.setNotificationsEnabled(tag, value),
                        ),
                        _PlayerOptionSwitch(
                          icon: Icons.fact_check_outlined,
                          title: AppLocalizations.of(
                            context,
                          )!.playerOptionShowTodoPageTitle,
                          subtitle: isVerified == true
                              ? AppLocalizations.of(
                                  context,
                                )!.playerOptionShowTodoPageSubtitle
                              : AppLocalizations.of(
                                  context,
                                )!.playerOptionShowTodoPageVerifyFirst,
                          value: options.showInTodoPage,
                          enabled: isVerified == true,
                          onChanged: (value) =>
                              prefs.setShowInTodoPage(tag, value),
                        ),
                        _PlayerOptionSwitch(
                          icon: Icons.construction_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.playerOptionShowUpgradeTrackerHomeTitle,
                          subtitle: isVerified == true
                              ? AppLocalizations.of(
                                  context,
                                )!.playerOptionShowUpgradeTrackerHomeSubtitle
                              : AppLocalizations.of(
                                  context,
                                )!.playerOptionShowUpgradeTrackerHomeVerifyFirst,
                          value: options.showUpgradeTrackerOnHome,
                          enabled: isVerified == true,
                          onChanged: (value) =>
                              prefs.setShowUpgradeTrackerOnHome(tag, value),
                        ),
                        _PlayerOptionSwitch(
                          icon: Icons.emoji_events_outlined,
                          title: AppLocalizations.of(
                            context,
                          )!.playerOptionShowRankedHomeTitle,
                          subtitle: isVerified == true
                              ? AppLocalizations.of(
                                  context,
                                )!.playerOptionShowRankedHomeSubtitle
                              : AppLocalizations.of(
                                  context,
                                )!.playerOptionShowRankedHomeVerifyFirst,
                          value: options.showRankedOnHome,
                          enabled: isVerified == true,
                          onChanged: (value) =>
                              prefs.setShowRankedOnHome(tag, value),
                        ),
                        _PlayerOptionSwitch(
                          icon: Icons.shield_moon_outlined,
                          title: AppLocalizations.of(
                            context,
                          )!.playerOptionShowWarTabTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.playerOptionShowWarTabSubtitle,
                          value: options.showInWarTab,
                          onChanged: (value) =>
                              prefs.setShowInWarTab(tag, value),
                        ),
                        if (isVerified != null && hidden != null)
                          AccountVisibilityOption(
                            hidden: hidden!,
                            verified: isVerified!,
                            updating: updatingVisibility,
                            onPressed: onToggleVisibility,
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

class _PlayerOptionAction extends StatelessWidget {
  const _PlayerOptionAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 30, child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
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
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
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
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(icon, size: 20, color: contentColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: enabled ? null : contentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: contentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.85,
              child: Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
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
              child: MobileWebImage(
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
  const _EmptyRosterMessage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      body: subtitle,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: EdgeInsets.zero,
    );
  }
}
