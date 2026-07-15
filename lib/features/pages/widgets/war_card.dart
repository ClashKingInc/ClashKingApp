import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:intl/intl.dart';

class WarCard extends StatelessWidget {
  const WarCard({
    super.key,
    required this.currentWarInfo,
    required this.clanTag,
    this.footer,
    this.centerHeader,
    this.cwlBanner,
    this.onTapBanner,
    this.onTap,
  });

  final WarInfo currentWarInfo;
  final String clanTag;
  final Widget? footer;
  final Widget? centerHeader;
  final Widget? cwlBanner;
  final VoidCallback? onTapBanner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          () {
            switch (currentWarInfo.state) {
              case 'preparation':
                return _preparationState(context);
              case 'inWar':
                return _inWarState(context);
              case 'warEnded':
                return _warEnded(context, clanTag);
              default:
                return Text(AppLocalizations.of(context)!.generalUnknown);
            }
          }(),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: cwlBanner == null
          ? (onTap == null ? body : InkWell(onTap: onTap, child: body))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(onTap: onTapBanner, child: cwlBanner),
                InkWell(onTap: onTap, child: body),
              ],
            ),
    );
  }

  Widget _clanBadge(String imageUrl, String name, BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 70,
          height: 70,
          child: MobileWebImage(
            errorWidget: (context, url, error) => const Icon(Icons.error),
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Fixed-width columns either side of the separator so the two
  /// scores land on the same baseline regardless of digit count -
  /// replaces the old space-padded-string trick, which doesn't
  /// actually align in a proportional font.
  Widget _starsRow(
    int clanStars,
    int opponentStars, {
    Color? clanColor,
    Color? opponentColor,
    FontWeight? clanWeight,
    FontWeight? opponentWeight,
    required TextStyle? style,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$clanStars',
            textAlign: TextAlign.right,
            style: style?.copyWith(color: clanColor, fontWeight: clanWeight),
          ),
        ),
        Text(' - ', style: style),
        SizedBox(
          width: 28,
          child: Text(
            '$opponentStars',
            textAlign: TextAlign.left,
            style: style?.copyWith(
              color: opponentColor,
              fontWeight: opponentWeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _destructionRow(
    double clanPercentage,
    double opponentPercentage,
    TextStyle? style,
  ) {
    String format(double value) {
      final rounded = value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
      return '$rounded%';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            format(clanPercentage),
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(
            format(opponentPercentage),
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _warEnded(BuildContext context, String clanTag) {
    final clan = currentWarInfo.clan!;
    final opponent = currentWarInfo.opponent!;
    final theme = Theme.of(context);

    final clanIsUs = clan.tag == clanTag;
    final usStars = clanIsUs ? clan.stars : opponent.stars;
    final themStars = clanIsUs ? opponent.stars : clan.stars;
    final usDestruction = clanIsUs
        ? clan.destructionPercentage
        : opponent.destructionPercentage;
    final themDestruction = clanIsUs
        ? opponent.destructionPercentage
        : clan.destructionPercentage;

    final weWon =
        usStars > themStars ||
        (usStars == themStars && usDestruction > themDestruction);
    final weLost =
        usStars < themStars ||
        (usStars == themStars && usDestruction < themDestruction);

    final resultLabel = weWon
        ? (AppLocalizations.of(context)?.warVictory ?? 'Victory')
        : weLost
        ? (AppLocalizations.of(context)?.warDefeat ?? 'Defeat')
        : (AppLocalizations.of(context)?.warDraw ?? 'Draw');
    final resultTint = weWon
        ? StatColors.win
        : weLost
        ? StatColors.loss
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: _clanBadge(clan.badgeUrls.large, clan.name, context),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 108,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)?.warEnded ?? 'War ended',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    resultLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: resultTint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _starsRow(
                    clan.stars,
                    opponent.stars,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _destructionRow(
                    clan.destructionPercentage,
                    opponent.destructionPercentage,
                    theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _clanBadge(opponent.badgeUrls.large, opponent.name, context),
        ),
      ],
    );
  }

  Widget _preparationState(BuildContext context) {
    final clan = currentWarInfo.clan!;
    final opponent = currentWarInfo.opponent!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: _clanBadge(clan.badgeUrls.large, clan.name, context),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: centerHeader == null ? 96 : 124,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (centerHeader != null) ...[
                    centerHeader!,
                    const SizedBox(height: 6),
                  ],
                  Text(
                    '${AppLocalizations.of(context)?.timeStartsAt(DateFormat('HH:mm').format(currentWarInfo.startTime!.toLocal()))}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)?.warPreparation ??
                        'Preparation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _clanBadge(opponent.badgeUrls.large, opponent.name, context),
        ),
      ],
    );
  }

  Widget _inWarState(BuildContext context) {
    final clan = currentWarInfo.clan!;
    final opponent = currentWarInfo.opponent!;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: _clanBadge(clan.badgeUrls.large, clan.name, context),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: centerHeader == null ? 108 : 136,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (centerHeader != null) ...[
                    centerHeader!,
                    const SizedBox(height: 6),
                  ],
                  Text(
                    "${AppLocalizations.of(context)?.timeEndsAt(DateFormat('HH:mm').format(currentWarInfo.endTime!.toLocal()))}",
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  _starsRow(
                    clan.stars,
                    opponent.stars,
                    style: theme.textTheme.titleMedium,
                  ),
                  _destructionRow(
                    clan.destructionPercentage,
                    opponent.destructionPercentage,
                    theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _clanBadge(opponent.badgeUrls.large, opponent.name, context),
        ),
      ],
    );
  }
}
