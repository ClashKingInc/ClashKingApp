import 'dart:ui';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart' show timeLeft;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarHeader extends StatelessWidget {
  final WarInfo warInfo;

  const WarHeader({
    super.key,
    required this.warInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          height: 240,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
              child: CachedNetworkImage(
                imageUrl: "https://assets.clashk.ing/landscape/war-landscape.jpg",
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              timeLeft(
                warInfo,
                context,
                Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildClanColumn(context, warInfo.clan, isLeft: true),
                  Text(
                    "${warInfo.clan?.stars ?? 0} - ${warInfo.opponent?.stars ?? 0}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  _buildClanColumn(context, warInfo.opponent, isLeft: false),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildClanColumn(BuildContext context, WarClan? clan, {required bool isLeft}) {
    if (clan == null) return const SizedBox.shrink();

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final Clan clanInfo = await ClanService().loadClanData(clan.tag);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClanInfoScreen(clanInfo: clanInfo),
                  ),
                );
              }
            },
            child: CachedNetworkImage(
              imageUrl: clan.badgeUrls.large,
              width: 90,
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              clan.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          Text(
            "${clan.destructionPercentage.toStringAsFixed(2)}%",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }
}
