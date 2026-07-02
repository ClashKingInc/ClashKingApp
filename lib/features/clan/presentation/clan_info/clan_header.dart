import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_page.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClanInfoHeaderCard extends StatelessWidget {
  final Clan clanInfo;

  const ClanInfoHeaderCard({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    return _buildHero(context);
  }

  /// Hero header: backdrop image with scrim, floating actions, identity
  /// row and a content-sized stats card straddling the image edge — same
  /// pattern as the player page.
  Widget _buildHero(BuildContext context) {
    // The stats card height varies (chips + description), so the image
    // stops at a fixed distance from the top instead of tracking the
    // column bottom: it ends partway through the card.
    final imageHeight = MediaQuery.of(context).padding.top + 280;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: ImageAssets.clanPageBackground,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    ColoredBox(color: Theme.of(context).colorScheme.surface),
              ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.62)),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildTopActions(context),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildIdentity(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildStatsPanel(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopActions(BuildContext context) {
    final warCwl = clanInfo.warCwl;
    final hasDiscord =
        clanInfo.description.contains("discord.gg") ||
        clanInfo.description.contains("discord.com");

    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        // One war entry point: CWL wins over regular war since the CWL
        // screen also exposes the current round's war.
        if (warCwl != null && warCwl.isInCwl) ...[
          HeaderIconButton(
            imageUrl: ImageAssets.cwlSwordsNoBorder,
            tooltip: AppLocalizations.of(context)!.cwlOngoing,
            onTap: () => _openCwl(context),
          ),
          const SizedBox(width: 8),
        ] else if (warCwl != null && warCwl.isInWar) ...[
          HeaderIconButton(
            imageUrl: ImageAssets.war,
            tooltip: AppLocalizations.of(context)!.warOngoing,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WarScreen(war: warCwl.warInfo),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (hasDiscord) ...[
          HeaderIconButton(
            icon: Icons.discord,
            tooltip: 'Discord',
            onTap: () => _openDiscord(context),
          ),
          const SizedBox(width: 8),
        ],
        HeaderIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: AppLocalizations.of(context)!.generalStats,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClanWarStatsScreen(clan: clanInfo),
            ),
          ),
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          icon: Icons.open_in_new_rounded,
          tooltip: 'Open in game',
          onTap: () {
            final lang = Localizations.localeOf(context).languageCode;
            final url = Uri.https('link.clashofclans.com', '/$lang', {
              'action': 'OpenClanProfile',
              'tag': clanInfo.tag,
            });
            showDialog(
              context: context,
              builder: (_) => OpenClashDialog(url: url),
            );
          },
        ),
        const SizedBox(width: 8),
        Consumer<BookmarkService>(
          builder: (context, bookmarks, child) {
            final bookmarked = bookmarks.isClanBookmarked(clanInfo.tag);
            return HeaderIconButton(
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark clan',
              onTap: () => bookmarks.toggleClan(clanInfo),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIdentity(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 82,
          child: Column(
            children: [
              CachedNetworkImage(
                imageUrl: clanInfo.badgeUrls.large,
                width: 76,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level ${clanInfo.clanLevel}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clanInfo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Always white: sits on the darkened backdrop image.
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  FlutterClipboard.copy(clanInfo.tag).then((_) {
                    if (context.mounted) {
                      showClipboardSnackbar(
                        context,
                        AppLocalizations.of(context)!.generalCopiedToClipboard,
                      );
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    clanInfo.tag,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (clanInfo.location?.name != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (clanInfo.location?.countryCode != null) ...[
                        MobileWebImage(
                          imageUrl: ImageAssets.flag(
                            clanInfo.location!.countryCode!,
                          ),
                          width: 15,
                          height: 15,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          clanInfo.location!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final warLeagueName = clanInfo.warLeague?.name ?? 'Unranked';
    final typeLabel = switch (clanInfo.type) {
      'inviteOnly' => loc.clanInviteOnly,
      'open' => loc.clanOpened,
      'closed' => loc.generalClosed,
      _ => clanInfo.type,
    };
    final warFrequencyLabel = switch (clanInfo.warFrequency) {
      'always' => loc.clanWarFrequencyAlways,
      'never' => loc.clanWarFrequencyNever,
      'oncePerWeek' => loc.clanWarFrequencyOncePerWeek,
      'moreThanOncePerWeek' => loc.clanWarFrequencyMoreThanOncePerWeek,
      'lessThanOncePerWeek' => loc.clanWarFrequencyRarely,
      _ => loc.generalUnknown,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (theme.cardTheme.color ?? colorScheme.surface).withValues(
          alpha: 0.94,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: MobileWebImage(
                      imageUrl: ImageAssets.getWarLeagueImage(warLeagueName),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warLeagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const MobileWebImage(
                          imageUrl: ImageAssets.trophies,
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatter.format(clanInfo.clanPoints),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${clanInfo.members}/50',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  if (clanInfo.isWarLogPublic) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${clanInfo.warWins}W · ${clanInfo.warTies}T · ${clanInfo.warLosses}L',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Same icon + label + colored value language as the metric
          // bars, laid out two per row at equal width so a variable
          // chip count (some are conditional) doesn't wrap raggedly.
          MetricChipGrid(
            columns: 3,
            chips: [
              MetricChip(
                label: 'War wins',
                value: formatter.format(clanInfo.warWins),
                imageUrl: ImageAssets.war,
                color: const Color(0xFFE8A524),
              ),
              MetricChip(
                label: 'Win streak',
                value: formatter.format(clanInfo.warWinStreak),
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFE35D4F),
              ),
              MetricChip(
                label: 'Capital',
                value: formatter.format(clanInfo.clanCapitalPoints),
                imageUrl: ImageAssets.capitalTrophy,
                color: const Color(0xFF8D63D9),
              ),
              MetricChip(
                label: 'Builder base',
                value: formatter.format(clanInfo.clanBuilderBasePoints),
                imageUrl: ImageAssets.builderBaseStar,
                color: const Color(0xFF2A9FD6),
              ),
              MetricChip(
                label: 'Type',
                value: typeLabel,
                icon: Icons.mail_rounded,
              ),
              MetricChip(
                label: 'Wars',
                value: warFrequencyLabel,
                icon: Icons.event_repeat_rounded,
              ),
              if (clanInfo.requiredTownhallLevel > 0)
                MetricChip(
                  label: 'Min. TH',
                  value: '${clanInfo.requiredTownhallLevel}+',
                  imageUrl: ImageAssets.townHall(
                    clanInfo.requiredTownhallLevel,
                  ),
                ),
              if (clanInfo.requiredTrophies > 0)
                MetricChip(
                  label: 'Min. trophies',
                  value: NumberFormat.compact().format(
                    clanInfo.requiredTrophies,
                  ),
                  imageUrl: ImageAssets.trophies,
                ),
            ],
          ),
          if (clanInfo.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Text(
                clanInfo.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openCwl(BuildContext context) {
    final warCwl = clanInfo.warCwl;
    final leagueInfo = warCwl?.leagueInfo;
    if (warCwl == null || leagueInfo == null || leagueInfo.clans.isEmpty) {
      return;
    }
    final cwlClanInfo = leagueInfo.clans.firstWhere(
      (clan) => clan.tag == clanInfo.tag,
      orElse: () => leagueInfo.clans.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CwlScreen(
          warCwl: warCwl,
          clanTag: clanInfo.tag,
          clanInfo: cwlClanInfo,
        ),
      ),
    );
  }

  Future<void> _openDiscord(BuildContext context) async {
    try {
      final code = _extractDiscordCode(clanInfo.description);
      if (code == null) return;
      final url = Uri.parse('https://discord.gg/$code');
      if (!await launchUrl(url) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorCannotOpenLink),
          ),
        );
      }
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
  }

  String? _extractDiscordCode(String description) {
    final cleaned = description.replaceAll(RegExp(r'[\s\n\r]'), ' ');
    final RegExp discordPattern = RegExp(
      r"(?:https?:\/\/)?(?:discord\.com\/invite\/|discord\.gg\/)([a-zA-Z0-9]+)",
    );
    final match = discordPattern.firstMatch(cleaned);
    return match?.group(1);
  }
}
