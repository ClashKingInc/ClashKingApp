import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClanCapitalHeader extends StatelessWidget {
  final List<String> user;
  final Clan? clanInfo;

  const ClanCapitalHeader({
    super.key,
    required this.user,
    required this.clanInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final imageHeight = MediaQuery.of(context).padding.top + 200;
    final capitalHallLevel = clanInfo?.clanCapital?.capitalHallLevel ?? 1;
    final districtCount = clanInfo?.clanCapital?.districts.length ?? 0;

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
                imageUrl: ImageAssets.clanCapitalPageBackground,
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: MobileWebImage(
                      imageUrl: ImageAssets.capitalHall(capitalHallLevel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clanInfo?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          clanInfo?.tag ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                child: MetricChipGrid(
                  columns: 3,
                  chips: [
                    MetricChip(
                      label: 'Capital',
                      value: formatter.format(clanInfo?.clanCapitalPoints ?? 0),
                      imageUrl: ImageAssets.capitalTrophy,
                      color: const Color(0xFF8D63D9),
                    ),
                    MetricChip(
                      label: 'Capital Hall',
                      value: capitalHallLevel.toString(),
                      imageUrl: ImageAssets.capitalHall(capitalHallLevel),
                    ),
                    MetricChip(
                      label: 'Districts',
                      value: districtCount.toString(),
                      icon: Icons.location_city_rounded,
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
}
