import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/icons/excel_download_icon.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_members_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_rounds_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_teams_tab.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/common/widgets/navigation/scrollable_tab.dart';

class CwlScreen extends StatefulWidget {
  final WarCwl warCwl;
  final String clanTag;
  final CwlClan clanInfo;

  CwlScreen({
    super.key,
    required this.warCwl,
    required this.clanTag,
    required this.clanInfo,
  });

  @override
  CwlScreenState createState() => CwlScreenState();
}

class CwlScreenState extends State<CwlScreen> {
  @override
  Widget build(BuildContext context) {
    CwlClan clan = widget.warCwl.leagueInfo!.getClanDetails(widget.clanTag)!;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final imageHeight = MediaQuery.of(context).padding.top + 280;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
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
                        child: CachedNetworkImage(
                          imageUrl: ImageAssets.cwlPageBackground,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => ColoredBox(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.36),
                              Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.64),
                              Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.92),
                            ],
                          ),
                        ),
                      ),
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
                          const Spacer(),
                          _HeaderCustomButton(
                            tooltip:
                                AppLocalizations.of(context)?.downloadTooltip ??
                                'Download',
                            child: DownloadCwlExcelButton(
                              url:
                                  "${ApiService.apiUrlV2}/exports/war/cwl-summary?tag=${widget.clanTag.replaceAll('#', '!')}",
                              fileName:
                                  "cwl_summary_${widget.clanInfo.tag.replaceAll('#', '')}.xlsx",
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _Identity(clanInfo: widget.clanInfo),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: HeaderPanelBackground(
                              height: 200,
                              cornerRadius: 28,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: MetricChipGrid(
                              columns: 3,
                              chips: [
                                MetricChip(
                                  label:
                                      AppLocalizations.of(
                                        context,
                                      )?.cwlRankTitle ??
                                      'Rank',
                                  value: '#${clan.rank}',
                                  imageUrl: ImageAssets.podium,
                                  color: const Color(0xFFE8A524),
                                ),
                                MetricChip(
                                  label:
                                      AppLocalizations.of(
                                        context,
                                      )?.warStarsTitle ??
                                      'Stars',
                                  value: formatter.format(clan.stars),
                                  imageUrl: ImageAssets.builderBaseStar,
                                  color: const Color(0xFFE8A524),
                                ),
                                MetricChip(
                                  label:
                                      AppLocalizations.of(
                                        context,
                                      )?.warDestructionTitle ??
                                      'Destruction',
                                  value:
                                      '${clan.destructionPercentageInflicted.toStringAsFixed(0)}%',
                                  imageUrl: ImageAssets.hitrate,
                                  color: const Color(0xFF14A37F),
                                ),
                                MetricChip(
                                  label:
                                      AppLocalizations.of(
                                        context,
                                      )?.cwlWarsPlayedTitle ??
                                      'Wars played',
                                  value: formatter.format(clan.warsPlayed),
                                  imageUrl: ImageAssets.war,
                                ),
                                MetricChip(
                                  label:
                                      AppLocalizations.of(
                                        context,
                                      )?.warAttacksTitle ??
                                      'Attacks',
                                  value:
                                      '${clan.attackCount}/${widget.warCwl.teamSize * clan.warsPlayed}',
                                  imageUrl: ImageAssets.sword,
                                  color: const Color(0xFF8D63D9),
                                ),
                                MetricChip(
                                  label:
                                      AppLocalizations.of(
                                        context,
                                      )?.warAttacksMissed ??
                                      'Missed Attacks',
                                  value: formatter.format(clan.missedAttacks),
                                  imageUrl: ImageAssets.brokenSword,
                                  color: const Color(0xFFE35D4F),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ScrollableTab(
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {},
              tabs: [
                Tab(text: AppLocalizations.of(context)?.cwlRounds ?? 'Rounds'),
                Tab(
                  text: AppLocalizations.of(context)?.navigationTeam ?? 'Teams',
                ),
                Tab(
                  text: AppLocalizations.of(context)?.clanMembers ?? "Members",
                ),
              ],
              children: [
                CwlRoundsTab(warCwl: widget.warCwl),
                CwlTeamsTab(warCwl: widget.warCwl),
                CwlMembersTab(warCwl: widget.warCwl, clanTag: widget.clanTag),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final CwlClan clanInfo;

  const _Identity({required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: MobileWebImage(imageUrl: clanInfo.badgeUrls.medium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clanInfo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                clanInfo.tag,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.62),
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

/// Frosted circular slot for a custom action widget (e.g. a button with its
/// own internal loading state) — same real Liquid Glass recipe as
/// [HeaderIconButton] instead of a hand-rolled BackdropFilter blur.
class _HeaderCustomButton extends StatelessWidget {
  final Widget child;
  final String tooltip;

  const _HeaderCustomButton({required this.child, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    const radius = 19.0;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: size,
        width: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const NativeLiquidGlassBar(
                height: size,
                cornerRadius: radius,
                opacity: 0.72,
              ),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
