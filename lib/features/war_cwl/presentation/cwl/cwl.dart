import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
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
  final String? warLeagueName;

  CwlScreen({
    super.key,
    required this.warCwl,
    required this.clanTag,
    required this.clanInfo,
    this.warLeagueName,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.warLeagueName != null) ...[
                                  _CwlLeagueSummaryTile(
                                    warLeagueName: widget.warLeagueName!,
                                    rank: clan.rank,
                                    stars: clan.stars,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                MetricChipGrid(
                                  columns: 3,
                                  chips: [
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
                                      value: formatter.format(
                                        clan.missedAttacks,
                                      ),
                                      imageUrl: ImageAssets.brokenSword,
                                      color: const Color(0xFFE35D4F),
                                    ),
                                    MetricChip(
                                      label:
                                          AppLocalizations.of(
                                            context,
                                          )?.warStarsThree ??
                                          '3 stars',
                                      value: formatter.format(
                                        clan.totalThreeStars,
                                      ),
                                      imageUrl: ImageAssets.attackStar,
                                      color: StatColors.win,
                                    ),
                                    MetricChip(
                                      label:
                                          AppLocalizations.of(
                                            context,
                                          )?.warStarsTwo ??
                                          '2 stars',
                                      value: formatter.format(
                                        clan.totalTwoStars,
                                      ),
                                      imageUrl: ImageAssets.attackStar,
                                      color: StatColors.warStarGold,
                                    ),
                                    MetricChip(
                                      label:
                                          AppLocalizations.of(
                                            context,
                                          )?.warStarsOne ??
                                          '1 star',
                                      value: formatter.format(
                                        clan.totalOneStar,
                                      ),
                                      imageUrl: ImageAssets.attackStar,
                                      color: const Color(0xFFE8963D),
                                    ),
                                    MetricChip(
                                      label:
                                          AppLocalizations.of(
                                            context,
                                          )?.warStarsZero ??
                                          '0 Star',
                                      value: formatter.format(
                                        clan.totalZeroStar,
                                      ),
                                      imageUrl: ImageAssets.attackStar,
                                      color: StatColors.loss,
                                    ),
                                  ],
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

/// Featured war-league tile — same recipe as the clan/player headers'
/// league tile: a floating glass card tinted with the dominant color
/// sampled from the war league badge, rank as the headline number,
/// stars as the secondary metric.
class _CwlLeagueSummaryTile extends StatefulWidget {
  final String warLeagueName;
  final int rank;
  final int stars;

  const _CwlLeagueSummaryTile({
    required this.warLeagueName,
    required this.rank,
    required this.stars,
  });

  @override
  State<_CwlLeagueSummaryTile> createState() => _CwlLeagueSummaryTileState();
}

class _CwlLeagueSummaryTileState extends State<_CwlLeagueSummaryTile> {
  static final Map<String, Color> _tintCache = {};
  Color? _tint;

  String get _leagueUrl => ImageAssets.getWarLeagueImage(widget.warLeagueName);

  @override
  void initState() {
    super.initState();
    _loadTint();
  }

  @override
  void didUpdateWidget(covariant _CwlLeagueSummaryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warLeagueName != widget.warLeagueName) {
      _loadTint();
    }
  }

  Future<void> _loadTint() async {
    final leagueUrl = _leagueUrl;

    final cachedTint = _tintCache[leagueUrl];
    if (cachedTint != null) {
      if (mounted) setState(() => _tint = cachedTint);
      return;
    }

    if (mounted) setState(() => _tint = null);

    try {
      final provider = CachedNetworkImageProvider(leagueUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      final completer = Completer<ImageInfo>();

      listener = ImageStreamListener(
        (imageInfo, synchronousCall) {
          if (!completer.isCompleted) completer.complete(imageInfo);
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final imageInfo = await completer.future;
      final tint = await dominantTintFromImage(imageInfo.image);
      if (tint == null) return;

      _tintCache[leagueUrl] = tint;
      if (mounted && _leagueUrl == leagueUrl) {
        setState(() => _tint = tint);
      }
    } catch (_) {
      // Keep the glass neutral if the remote badge cannot be sampled.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return GlassPanel(
      width: double.infinity,
      height: 75,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      tint: _tint,
      child: Row(
        children: [
          MobileWebImage(imageUrl: _leagueUrl, width: 46, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.warLeagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${widget.rank}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MobileWebImage(
                    imageUrl: ImageAssets.builderBaseStar,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.stars.toString(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc?.warStarsTitle ?? 'Stars',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
