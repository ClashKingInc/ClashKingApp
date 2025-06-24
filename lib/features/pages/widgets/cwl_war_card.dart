import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CurrentWarInfoCard extends StatelessWidget {
  const CurrentWarInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final warCwlService = context.watch<WarCwlService>();

    final clanTag = playerService.getSelectedProfile(cocService)?.clanTag;
    if (clanTag == null || clanTag.isEmpty) {
      return const SizedBox.shrink();
    }

    final warCwl = warCwlService.getWarCwlByTag(clanTag);
    final currentWarInfo = warCwl?.getActiveWarByTag(clanTag);
    final state = currentWarInfo?.state;

    if (currentWarInfo == null || state == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: () {
          switch (state) {
            case 'preparation':
              return _preparationState(context, currentWarInfo);
            case 'inWar':
              return _inWarState(context, currentWarInfo);
            case 'warEnded':
              return _warEnded(context, currentWarInfo, clanTag);
            default:
              return const Text('Clan state unknown');
          }
        }(),
      ),
    );
  }

  Widget _warEnded(
      BuildContext context, WarInfo currentWarInfo, String clanTag) {
    final isVictory = _isVictory(currentWarInfo, clanTag);
    final isDefeat = _isDefeat(currentWarInfo, clanTag);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildClanColumn(context, currentWarInfo.clan!),
        _buildCenterColumn(context, currentWarInfo, isVictory, isDefeat),
        _buildClanColumn(context, currentWarInfo.opponent!),
      ],
    );
  }

  Widget _preparationState(BuildContext context, WarInfo currentWarInfo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClanColumn(context, currentWarInfo.clan!),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)?.timeStartsAt(
                      DateFormat('HH:mm')
                          .format(currentWarInfo.startTime!.toLocal()),
                    ) ??
                    '',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)?.warPreparation ?? 'Preparation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
        _buildClanColumn(context, currentWarInfo.opponent!),
      ],
    );
  }

  Widget _inWarState(BuildContext context, WarInfo currentWarInfo) {
    return Row(
      children: [
        _buildClanColumn(context, currentWarInfo.clan!),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)?.timeEndsAt(
                      DateFormat('HH:mm')
                          .format(currentWarInfo.endTime!.toLocal()),
                    ) ??
                    '',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              Text(
                '${currentWarInfo.clan!.stars} - ${currentWarInfo.opponent!.stars}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${currentWarInfo.clan!.destructionPercentage.toStringAsFixed(1)}%    ${currentWarInfo.opponent!.destructionPercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _buildClanColumn(context, currentWarInfo.opponent!),
      ],
    );
  }

  Widget _buildClanColumn(BuildContext context, WarClan clan) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: clan.badgeUrls.large,
              fit: BoxFit.cover,
            ),
          ),
          Text(clan.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCenterColumn(BuildContext context, WarInfo currentWarInfo,
      bool isVictory, bool isDefeat) {
    return Expanded(
      flex: 4,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)?.warEnded ?? 'War ended',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (isVictory)
            Text(
              AppLocalizations.of(context)?.warVictory ?? 'Victory',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            )
          else if (isDefeat)
            Text(
              AppLocalizations.of(context)?.warDefeat ?? 'Defeat',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            )
          else
            Text(
              AppLocalizations.of(context)?.warDraw ?? 'Draw',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          Text(
            '${currentWarInfo.clan!.stars} - ${currentWarInfo.opponent!.stars}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${currentWarInfo.clan!.destructionPercentage.toStringAsFixed(1)}%    ${currentWarInfo.opponent!.destructionPercentage.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  bool _isVictory(WarInfo war, String tag) {
    final isOurClan = war.clan!.tag == tag;
    return (isOurClan && war.clan!.stars > war.opponent!.stars) ||
        (!isOurClan && war.opponent!.stars > war.clan!.stars) ||
        (isOurClan &&
            war.clan!.stars == war.opponent!.stars &&
            war.clan!.destructionPercentage >
                war.opponent!.destructionPercentage) ||
        (!isOurClan &&
            war.opponent!.stars == war.clan!.stars &&
            war.opponent!.destructionPercentage >
                war.clan!.destructionPercentage);
  }

  bool _isDefeat(WarInfo war, String tag) {
    final isOurClan = war.clan!.tag == tag;
    return (isOurClan && war.clan!.stars < war.opponent!.stars) ||
        (!isOurClan && war.opponent!.stars < war.clan!.stars) ||
        (isOurClan &&
            war.clan!.stars == war.opponent!.stars &&
            war.clan!.destructionPercentage <
                war.opponent!.destructionPercentage) ||
        (!isOurClan &&
            war.opponent!.stars == war.clan!.stars &&
            war.opponent!.destructionPercentage <
                war.clan!.destructionPercentage);
  }
}
