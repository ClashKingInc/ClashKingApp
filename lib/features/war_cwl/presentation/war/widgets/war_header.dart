import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show timeLeft;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageHeight = MediaQuery.of(context).padding.top + 260;

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
                imageUrl: ImageAssets.warPageBackground,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    ColoredBox(color: colorScheme.surface),
              ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (theme.cardTheme.color ?? colorScheme.surface)
                      .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                child: Column(
                  children: [
                    timeLeft(
                      widget.warInfo,
                      context,
                      theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildClanColumn(
                          context,
                          widget.warInfo.clan,
                          isLeft: true,
                        ),
                        Text(
                          "${widget.warInfo.clan?.stars ?? 0} - ${widget.warInfo.opponent?.stars ?? 0}",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _buildClanColumn(
                          context,
                          widget.warInfo.opponent,
                          isLeft: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClanColumn(
    BuildContext context,
    WarClan? clan, {
    required bool isLeft,
  }) {
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
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
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
            child: MobileWebImage(imageUrl: clan.badgeUrls.large, width: 90),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              clan.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            "${clan.destructionPercentage.toStringAsFixed(2)}%",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
