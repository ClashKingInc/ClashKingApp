import 'package:clashkingapp/common/widgets/buttons/info_button.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Hero header for the Legend League screen — same shell as the clan and
/// player pages: fixed-height backdrop image, glass action buttons, an
/// identity row (badge beside name/tag), then a floating stats card
/// straddling the image edge.
class LegendHeaderCard extends StatelessWidget {
  final Player player;

  const LegendHeaderCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
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
              MobileWebImage(
                imageUrl: ImageAssets.legendPageBackground,
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
              child: _TopActions(player: player),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Identity(player: player),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _StatsPanel(player: player),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopActions extends StatelessWidget {
  final Player player;

  const _TopActions({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        HeaderIconButton(
          icon: Icons.open_in_new_rounded,
          tooltip: 'Open in game',
          onTap: () => _openInGame(context, player),
        ),
        const SizedBox(width: 8),
        Consumer<BookmarkService>(
          builder: (context, bookmarks, child) {
            final bookmarked = bookmarks.isPlayerBookmarked(player.tag);
            return HeaderIconButton(
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              tooltip: bookmarked
                  ? 'Remove player bookmark'
                  : 'Bookmark player',
              onTap: () => bookmarks.togglePlayer(player),
            );
          },
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          icon: Icons.info_outline_rounded,
          tooltip: AppLocalizations.of(context)!.legendsInaccurateTitle,
          onTap: () => _showInfo(context),
        ),
      ],
    );
  }

  void _openInGame(BuildContext context, Player player) {
    final languageCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final url = Uri.https('link.clashofclans.com', '/$languageCode', {
      'action': 'OpenPlayerProfile',
      'tag': player.tag,
    });
    showDialog(
      context: context,
      builder: (context) => OpenClashDialog(url: url),
    );
  }

  void _showInfo(BuildContext context) {
    showInfoPopup(
      context,
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: "${AppLocalizations.of(context)!.legendsInaccurateIntro}\n",
          ),
          TextSpan(
            text:
                "${AppLocalizations.of(context)!.legendsInaccurateApiDelayTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text:
                "${AppLocalizations.of(context)!.legendsInaccurateApiDelayBody}\n",
          ),
          TextSpan(
            text: AppLocalizations.of(
              context,
            )!.legendsInaccurateConcurrentTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: AppLocalizations.of(
              context,
            )!.legendsInaccurateMultipleAttacksTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: AppLocalizations.of(
              context,
            )!.legendsInaccurateMultipleAttacksBody,
          ),
          TextSpan(
            text: AppLocalizations.of(
              context,
            )!.legendsInaccurateSimultaneousTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text:
                "${AppLocalizations.of(context)!.legendsInaccurateSimultaneousBody}\n",
          ),
          TextSpan(
            text:
                "${AppLocalizations.of(context)!.legendsInaccurateNetGainTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text:
                "${AppLocalizations.of(context)!.legendsInaccurateNetGainBody}\n\n",
          ),
          TextSpan(
            text: AppLocalizations.of(context)!.legendsInaccurateConclusion,
          ),
        ],
      ),
      AppLocalizations.of(context)!.legendsInaccurateTitle,
    );
  }
}

class _Identity extends StatelessWidget {
  final Player player;

  const _Identity({required this.player});

  @override
  Widget build(BuildContext context) {
    final inLegends =
        (player.legendsBySeason?.currentSeason?.endTrophies ?? 0) > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: MobileWebImage(
            imageUrl: inLegends
                ? ImageAssets.legendBlazon
                : ImageAssets.legendBlazonBorders,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                player.tag,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final Player player;

  const _StatsPanel({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final currentSeason = player.legendsBySeason?.currentSeason;
    final currentTrophies = currentSeason?.endTrophies ?? 0;
    final inLegends = currentTrophies > 0;
    final diffTrophies = currentTrophies - 5000;
    final rankings = player.rankings;
    final hasCountry =
        rankings?.countryCode != null && rankings!.countryCode!.isNotEmpty;

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
                      imageUrl: inLegends
                          ? ImageAssets.legendBlazonNoPadding
                          : ImageAssets.legendBlazonBordersNoPadding,
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
                      AppLocalizations.of(context)?.legendsTitle ??
                          'Legend League',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    inLegends
                        ? Text(
                            formatter.format(currentTrophies),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.legendsNotInLeague,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ],
                ),
              ),
              if (inLegends) ...[
                const SizedBox(width: 10),
                Text(
                  "${diffTrophies >= 0 ? '+' : ''}$diffTrophies",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: diffTrophies >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          MetricChipGrid(
            columns: 3,
            chips: [
              if (hasCountry)
                MetricChip(
                  label:
                      AppLocalizations.of(context)?.legendsCountryTitle ??
                      'Country',
                  value: rankings.countryName ?? '',
                  imageUrl: ImageAssets.flag(rankings.countryCode!),
                ),
              if (hasCountry)
                MetricChip(
                  label:
                      AppLocalizations.of(context)?.legendsLocalRankTitle ??
                      'Local rank',
                  value: (rankings.localRank ?? 0) != 0
                      ? '#${rankings.localRank}'
                      : AppLocalizations.of(context)?.legendsNoRank ??
                            'No rank',
                  imageUrl: ImageAssets.flag(rankings.countryCode!),
                ),
              MetricChip(
                label:
                    AppLocalizations.of(context)?.legendsGlobalRankTitle ??
                    'Global rank',
                value: (rankings?.globalRank ?? 0) != 0
                    ? '#${formatter.format(rankings!.globalRank)}'
                    : AppLocalizations.of(context)?.legendsNoRank ?? 'No rank',
                imageUrl: ImageAssets.planet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
