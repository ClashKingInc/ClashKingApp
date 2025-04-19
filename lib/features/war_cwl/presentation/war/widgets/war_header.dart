import 'dart:async';
import 'dart:ui';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart' show timeLeft;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';

class WarHeader extends StatefulWidget {
  final WarInfo warInfo;

  const WarHeader({super.key, required this.warInfo});

  @override
  State<WarHeader> createState() => _WarHeaderState();
}

class _WarHeaderState extends State<WarHeader> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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
                Colors.black.withValues(alpha: 0.5),
                BlendMode.darken,
              ),
              child: MobileWebImage(
                imageUrl: ImageAssets.warPageBackground,
                width: double.infinity,
                fit: BoxFit.cover
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              timeLeft(
                widget.warInfo,
                context,
                Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildClanColumn(context, widget.warInfo.clan, isLeft: true),
                  Text(
                    "${widget.warInfo.clan?.stars ?? 0} - ${widget.warInfo.opponent?.stars ?? 0}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  _buildClanColumn(context, widget.warInfo.opponent, isLeft: false),
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
            child: MobileWebImage(
              imageUrl: clan.badgeUrls.large,
              width: 90
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              clan.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
          ),
          Text(
            "${clan.destructionPercentage.toStringAsFixed(2)}%",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
