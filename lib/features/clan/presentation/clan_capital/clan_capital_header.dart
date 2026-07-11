import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Capital hero header: same backdrop/gradient/identity/stats-panel recipe
/// as the clan and CWL detail headers, so the three "clan family" screens
/// read as one visual system instead of the capital page's old flat
/// dark-overlay banner.
class ClanCapitalHeaderCard extends StatelessWidget {
  final Clan clanInfo;

  const ClanCapitalHeaderCard({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
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
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.50),
                  BlendMode.darken,
                ),
                child: MobileWebImage(
                  imageUrl: ImageAssets.clanCapitalPageBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              // Fixed black, not colorScheme.surface: keeps darkening the
              // photo toward the bottom in both themes — surface flips to
              // near-white in light mode, which un-darkens the image.
              // Lower peak alpha in light mode: still dark enough for
              // white text, but not dark mode's near-black wash.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? const [
                            Color.fromRGBO(0, 0, 0, 0.36),
                            Color.fromRGBO(0, 0, 0, 0.64),
                            Color.fromRGBO(0, 0, 0, 0.92),
                          ]
                        : const [
                            Color.fromRGBO(0, 0, 0, 0.20),
                            Color.fromRGBO(0, 0, 0, 0.40),
                            Color.fromRGBO(0, 0, 0, 0.65),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      iconColor: Colors.white,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onTap: () => Navigator.of(context).pop(),
                      showBackground: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _Identity(clanInfo: clanInfo),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 11, bottom: 8),
              child: _StatsPanel(clanInfo: clanInfo),
            ),
          ],
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  final Clan clanInfo;

  const _Identity({required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    final capitalHallLevel = clanInfo.clanCapital?.capitalHallLevel ?? 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 94,
                  child: MobileWebImage(
                    imageUrl: ImageAssets.capitalHall(capitalHallLevel),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clanInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  // Always white: the gradient scrim now fades to a fixed
                  // black in both themes, so this always sits on a
                  // darkened photo.
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clanInfo.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final Clan clanInfo;

  const _StatsPanel({required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final capitalHallLevel = clanInfo.clanCapital?.capitalHallLevel ?? 1;
    final districtCount = clanInfo.clanCapital?.districts.length ?? 0;
    final capitalLeague = clanInfo.capitalLeague;
    final capitalLeagueName = capitalLeague?.name ?? 'Unranked';
    final capitalLeagueUrl = capitalLeague == null
        ? ImageAssets.capitalTrophy
        : ImageAssets.getCapitalLeagueImage(capitalLeague.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CompactLeagueTile(
              leagueName: _compactLeagueName(capitalLeagueName),
              subtitle: formatter.format(clanInfo.clanCapitalPoints),
              subtitleIconUrl: ImageAssets.capitalTrophy,
              leagueUrl: capitalLeagueUrl,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CompactLeagueTile(
              leagueName: '${loc.clanCapitalHallTitle} $capitalHallLevel',
              subtitle: '$districtCount ${loc.clanDistrictsTitle}',
              leagueUrl: ImageAssets.capitalHall(capitalHallLevel),
            ),
          ),
        ],
      ),
    );
  }

  String _compactLeagueName(String leagueName) {
    return leagueName.replaceAll(' League', '').trim();
  }
}
