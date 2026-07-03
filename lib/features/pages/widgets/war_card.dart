import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarCard extends StatelessWidget {
  const WarCard({
    super.key,
    required this.currentWarInfo,
    required this.clanTag,
    this.footer,
    this.centerHeader,
  });

  final WarInfo currentWarInfo;
  final String clanTag;
  final Widget? footer;
  final Widget? centerHeader;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
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
                  return Text('Clan state unknown');
              }
            }(),
            if (footer != null) ...[const SizedBox(height: 8), footer!],
          ],
        ),
      ),
    );
  }

  Widget _warEnded(BuildContext context, String clanTag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.clan!.badgeUrls.large,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                currentWarInfo.clan!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                AppLocalizations.of(context)?.warEnded ?? 'War ended',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ((currentWarInfo.clan!.tag == clanTag &&
                          currentWarInfo.clan!.stars >
                              currentWarInfo.opponent!.stars) ||
                      (currentWarInfo.opponent!.tag == clanTag &&
                          currentWarInfo.clan!.stars <
                              currentWarInfo.opponent!.stars) ||
                      (currentWarInfo.clan!.tag == clanTag &&
                          currentWarInfo.clan!.destructionPercentage >
                              currentWarInfo.opponent!.destructionPercentage) ||
                      (currentWarInfo.opponent!.tag == clanTag &&
                          currentWarInfo.clan!.destructionPercentage <
                              currentWarInfo.opponent!.destructionPercentage))
                  ? Text(
                      AppLocalizations.of(context)?.warVictory ?? 'Victory',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  : ((currentWarInfo.clan!.tag == clanTag &&
                            currentWarInfo.clan!.stars <
                                currentWarInfo.opponent!.stars) ||
                        (currentWarInfo.opponent!.tag == clanTag &&
                            currentWarInfo.clan!.stars >
                                currentWarInfo.opponent!.stars) ||
                        (currentWarInfo.clan!.tag == clanTag &&
                            currentWarInfo.clan!.destructionPercentage <
                                currentWarInfo
                                    .opponent!
                                    .destructionPercentage) ||
                        (currentWarInfo.opponent!.tag == clanTag &&
                            currentWarInfo.clan!.destructionPercentage >
                                currentWarInfo.opponent!.destructionPercentage))
                  ? Text(
                      AppLocalizations.of(context)?.warDefeat ?? 'Defeat',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)?.warDraw ?? 'Draw',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              _WarScoreBlock(
                leftStars: currentWarInfo.clan!.stars,
                rightStars: currentWarInfo.opponent!.stars,
                leftDestruction: currentWarInfo.clan!.destructionPercentage,
                rightDestruction:
                    currentWarInfo.opponent!.destructionPercentage,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.opponent!.badgeUrls.large,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                currentWarInfo.opponent!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preparationState(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.clan!.badgeUrls.large,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                currentWarInfo.clan!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (centerHeader != null) ...[
                    centerHeader!,
                    const SizedBox(height: 6),
                  ],
                  Text(
                    _relativeWarTime(
                      prefix: 'Starts',
                      time: currentWarInfo.startTime!,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 7),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.opponent!.badgeUrls.large,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                currentWarInfo.opponent!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inWarState(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.clan!.badgeUrls.large,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                currentWarInfo.clan!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (centerHeader != null) ...[
                    centerHeader!,
                    const SizedBox(height: 6),
                  ],
                  Text(
                    _relativeWarTime(
                      prefix: 'Ends',
                      time: currentWarInfo.endTime!,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  _WarScoreBlock(
                    leftStars: currentWarInfo.clan!.stars,
                    rightStars: currentWarInfo.opponent!.stars,
                    leftDestruction: currentWarInfo.clan!.destructionPercentage,
                    rightDestruction:
                        currentWarInfo.opponent!.destructionPercentage,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.opponent!.badgeUrls.large,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                currentWarInfo.opponent!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarScoreBlock extends StatelessWidget {
  const _WarScoreBlock({
    required this.leftStars,
    required this.rightStars,
    required this.leftDestruction,
    required this.rightDestruction,
  });

  final int leftStars;
  final int rightStars;
  final double leftDestruction;
  final double rightDestruction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$leftStars - $rightStars',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatPercent(leftDestruction),
                maxLines: 1,
                textAlign: TextAlign.right,
                style: percentStyle,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                _formatPercent(rightDestruction),
                maxLines: 1,
                textAlign: TextAlign.left,
                style: percentStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _relativeWarTime({required String prefix, required DateTime time}) {
  final now = DateTime.now();
  final target = time.toLocal();
  final difference = target.difference(now);
  if (difference.isNegative) {
    return '$prefix now';
  }

  final hours = difference.inHours;
  final minutes = difference.inMinutes.remainder(60);
  if (hours > 0) {
    return '$prefix in ${hours}h ${minutes}m';
  }
  final safeMinutes = minutes <= 0 ? 1 : minutes;
  return '$prefix in ${safeMinutes}m';
}

String _formatPercent(double value) {
  return '${value.toStringAsFixed(2)}%';
}
