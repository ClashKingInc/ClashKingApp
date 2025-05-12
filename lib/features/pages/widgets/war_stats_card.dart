import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class WarStatsCard extends StatefulWidget {
  final Clan clan;
  WarStatsCard({super.key, required this.clan});

  @override
  WarStatsCardState createState() => WarStatsCardState();
}

class WarStatsCardState extends State<WarStatsCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClanWarStatsScreen(clan: widget.clan),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: MobileWebImage(
                  imageUrl: ImageAssets.warClan,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.warStats,
                        style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
