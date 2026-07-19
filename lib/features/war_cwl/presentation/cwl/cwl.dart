import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/icons/excel_download_icon.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_members_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_rounds_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_teams_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CwlScreen extends StatefulWidget {
  final WarCwl warCwl;
  final String clanTag;
  final CwlClan clanInfo;
  final String? warLeagueName;

  const CwlScreen({
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
  int selectedTab = 0;

  void _selectTab(int index) {
    final bounded = index.clamp(0, 2);
    if (bounded == selectedTab) return;
    setState(() => selectedTab = bounded);
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    if (velocity < 0) {
      _selectTab(selectedTab + 1);
    } else {
      _selectTab(selectedTab - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clan = widget.warCwl.leagueInfo!.getClanDetails(widget.clanTag)!;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _CwlHeaderCard(
                warCwl: widget.warCwl,
                clanTag: widget.clanTag,
                clanInfo: clan,
                warLeagueName: widget.warLeagueName,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _CwlProfileTabs(
                    selectedIndex: selectedTab,
                    onTabSelected: _selectTab,
                  ),
                ],
              ),
            ),
          ],
          body: KeyedSubtree(
            key: ValueKey(selectedTab),
            child: _buildSelectedTab(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab(BuildContext context) {
    if (selectedTab == 2) {
      return CwlMembersTab(warCwl: widget.warCwl, clanTag: widget.clanTag);
    }

    final content = selectedTab == 0
        ? CwlRoundsTab(warCwl: widget.warCwl)
        : CwlTeamsTab(warCwl: widget.warCwl);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: content,
    );
  }
}

class _CwlHeaderCard extends StatelessWidget {
  final WarCwl warCwl;
  final String clanTag;
  final CwlClan clanInfo;
  final String? warLeagueName;

  const _CwlHeaderCard({
    required this.warCwl,
    required this.clanTag,
    required this.clanInfo,
    required this.warLeagueName,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).padding.top + 500;

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
                  imageUrl: ImageAssets.cwlPageBackground,
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
              child: _CwlHeaderActions(clanTag: clanTag, clanInfo: clanInfo),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _Identity(clanInfo: clanInfo),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 11, bottom: 8),
              child: _CwlStatsPanel(
                warCwl: warCwl,
                clanInfo: clanInfo,
                warLeagueName: warLeagueName,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CwlHeaderActions extends StatelessWidget {
  final String clanTag;
  final CwlClan clanInfo;

  const _CwlHeaderActions({required this.clanTag, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeaderIconButton(
            icon: Icons.arrow_back_rounded,
            iconColor: Colors.white,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.of(context).pop(),
            showBackground: false,
          ),
          const Spacer(),
          _HeaderCustomButton(
            tooltip: loc?.downloadTooltip ?? 'Download',
            child: DownloadCwlExcelButton(
              url:
                  "${ApiService.apiUrlV2}/exports/war/cwl-summary?tag=${clanTag.replaceAll('#', '!')}",
              fileName: "cwl_summary_${clanInfo.tag.replaceAll('#', '')}.xlsx",
            ),
          ),
        ],
      ),
    );
  }
}

class _CwlStatsPanel extends StatelessWidget {
  final WarCwl warCwl;
  final CwlClan clanInfo;
  final String? warLeagueName;

  const _CwlStatsPanel({
    required this.warCwl,
    required this.clanInfo,
    required this.warLeagueName,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final leagueName = warLeagueName?.trim().isNotEmpty == true
        ? warLeagueName!.trim()
        : 'Unranked';
    final leagueInfo = warCwl.leagueInfo;
    final leagueUrl = ImageAssets.getWarLeagueImage(leagueName);
    final compactLeagueName = _compactLeagueName(leagueName);
    final totalPossibleAttacks = warCwl.teamSize * clanInfo.warsPlayed;
    final clanCount = leagueInfo?.clans.length ?? 0;
    final rankValue = clanCount > 0
        ? '#${clanInfo.rank}/$clanCount'
        : '#${clanInfo.rank}';
    final destructionValue =
        '${formatter.format(clanInfo.destructionPercentageInflicted.round())}%';
    final rankSubtitle =
        '${formatter.format(clanInfo.stars)}  •  $destructionValue';
    final totalRounds = leagueInfo?.rounds.length ?? 0;
    final currentRoundNumber = totalRounds > 0
        ? leagueInfo!.getCurrentRounds().roundNumber
        : clanInfo.warsPlayed;
    final seasonSubtitle = _seasonSubtitle(loc, leagueInfo?.season, locale);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CompactLeagueTile(
                  leagueName: compactLeagueName,
                  subtitle: seasonSubtitle,
                  leagueUrl: leagueUrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactLeagueTile(
                  leagueName: '${loc.cwlRankTitle} $rankValue',
                  subtitle: rankSubtitle,
                  subtitleIconUrl: ImageAssets.builderBaseStar,
                  leagueUrl: ImageAssets.cwlSwordsNoBorder,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _CwlChipRows(
            children: [
              _CwlQuickChip(
                label: loc.warAttacksTitle,
                value: '${clanInfo.attackCount}/$totalPossibleAttacks',
                imageUrl: ImageAssets.sword,
              ),
              _CwlQuickChip(
                label: loc.warAttacksMissedShort,
                value: formatter.format(clanInfo.missedAttacks),
                imageUrl: ImageAssets.brokenSword,
              ),
              if (totalRounds > 0)
                _CwlQuickChip(
                  label: loc.cwlRounds,
                  value: loc.cwlRoundNumber(currentRoundNumber),
                  imageUrl: ImageAssets.war,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _compactLeagueName(String leagueName) {
    return leagueName.replaceAll(' League', '').trim();
  }

  String _seasonSubtitle(AppLocalizations loc, String? season, String locale) {
    final trimmed = season?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'unknown') {
      return loc.cwlTitle;
    }

    final parts = trimmed.split('-');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null && month >= 1 && month <= 12) {
        final formatted = DateFormat.yMMMM(
          locale,
        ).format(DateTime(year, month));
        return loc.statsSeasonDate(formatted);
      }
    }

    return loc.statsSeasonDate(trimmed);
  }
}

class _CwlChipRows extends StatelessWidget {
  final List<_CwlQuickChip> children;

  const _CwlChipRows({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 7.0;
        final widths = children
            .map((child) => child.estimatedWidth(context))
            .toList(growable: false);
        final rowPlans = _candidatePlans(children.length);

        for (final plan in rowPlans) {
          if (_planFits(plan, widths, spacing, constraints.maxWidth)) {
            return Column(children: _buildRows(plan, spacing));
          }
        }

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: 7,
          children: children,
        );
      },
    );
  }

  List<List<int>> _candidatePlans(int count) {
    return switch (count) {
      7 => const [
        [4, 3],
        [3, 4],
        [3, 2, 2],
        [2, 3, 2],
      ],
      6 => const [
        [4, 2],
        [3, 3],
        [2, 2, 2],
      ],
      5 => const [
        [3, 2],
        [2, 3],
      ],
      4 => const [
        [4],
        [2, 2],
      ],
      3 => const [
        [3],
      ],
      2 => const [
        [2],
      ],
      _ => [
        [count],
      ],
    };
  }

  bool _planFits(
    List<int> plan,
    List<double> widths,
    double spacing,
    double maxWidth,
  ) {
    var start = 0;
    for (final rowLength in plan) {
      final rowWidth =
          widths.skip(start).take(rowLength).fold<double>(0, (a, b) => a + b) +
          spacing * (rowLength - 1);
      if (rowWidth > maxWidth) return false;
      start += rowLength;
    }
    return start == widths.length;
  }

  List<Widget> _buildRows(List<int> plan, double spacing) {
    final rows = <Widget>[];
    var start = 0;

    for (var i = 0; i < plan.length; i++) {
      final rowLength = plan[i];
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children.skip(start).take(rowLength).expand((child) sync* {
            if (child != children[start]) {
              yield SizedBox(width: spacing);
            }
            yield child;
          }).toList(),
        ),
      );
      if (i != plan.length - 1) {
        rows.add(const SizedBox(height: 7));
      }
      start += rowLength;
    }

    return rows;
  }
}

class _CwlQuickChip extends StatelessWidget {
  final String label;
  final String value;
  final String? imageUrl;

  const _CwlQuickChip({
    required this.label,
    required this.value,
    this.imageUrl,
  });

  double estimatedWidth(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, height: 1);
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return 20 + 19 + 5 + painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: [label, value].join(': '),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              MobileWebImage(imageUrl: imageUrl!, width: 19, height: 19)
            else
              Icon(Icons.info_rounded, size: 19, color: colorScheme.onSurface),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 154),
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
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
    final loc = AppLocalizations.of(context)!;
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final badgeSize = isDesktopWeb ? 116.0 : 94.0;

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
                  dimension: badgeSize,
                  child: MobileWebImage(imageUrl: clanInfo.badgeUrls.large),
                ),
                const SizedBox(height: 2),
                Text(
                  clanInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
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
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        '|',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.30),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        loc.cwlClanWarLeague,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: size,
        width: size,
        child: IconTheme(
          data: const IconThemeData(color: Colors.white, size: 25),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Same tab strip recipe as the clan detail page's _ClanProfileTabs:
/// glass background, icon+label tabs, external TabController driven by
/// the parent's selectedTab so content can crossfade via AnimatedSwitcher
/// instead of TabBarView.
class _CwlProfileTabs extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _CwlProfileTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_CwlProfileTabs> createState() => _CwlProfileTabsState();
}

class _CwlProfileTabsState extends State<_CwlProfileTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );
  }

  @override
  void didUpdateWidget(covariant _CwlProfileTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _tabController.index != widget.selectedIndex) {
      _tabController.animateTo(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: SizedBox(
        height: 50,
        child: TabBar(
          controller: _tabController,
          // 3 short tabs always fit — unlike the clan page's 6, which
          // need isScrollable+start to avoid cramming. Filling here
          // keeps them evenly spread instead of clumped on the left.
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurface,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: widget.onTabSelected,
          tabs: [
            _CwlTab(
              label: loc.cwlRounds,
              icon: Icons.calendar_month_rounded,
              selected: widget.selectedIndex == 0,
            ),
            _CwlTab(
              label: loc.navigationTeam,
              icon: Icons.leaderboard_rounded,
              selected: widget.selectedIndex == 1,
            ),
            _CwlTab(
              label: loc.clanMembers,
              icon: Icons.groups_rounded,
              selected: widget.selectedIndex == 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _CwlTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _CwlTab({
    required this.label,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.58);

    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
