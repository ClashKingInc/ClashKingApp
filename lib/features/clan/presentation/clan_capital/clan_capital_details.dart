import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/utils/capital_raid_analytics.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:clashkingapp/common/widgets/summary_chips.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Per-district and per-opponent breakdown for the selected raid week,
/// switching between offense (attackLog) and defense (defenseLog) —
/// data that was already being fetched but never surfaced anywhere in
/// the app. Flat rows, no nested Card, matching the rest of the clan
/// detail tabs. Embedded directly under the raid summary card (not its
/// own tab) so nothing about the current week is hidden behind a tap.
class CapitalRaidBreakdown extends StatefulWidget {
  final CapitalHistoryItem raid;

  const CapitalRaidBreakdown({super.key, required this.raid});

  @override
  State<CapitalRaidBreakdown> createState() => _CapitalRaidBreakdownState();
}

class _CapitalRaidBreakdownState extends State<CapitalRaidBreakdown> {
  bool _showOffense = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final log = _showOffense
        ? widget.raid.attackLog ?? const []
        : widget.raid.defenseLog ?? const [];
    final districts = CapitalRaidAnalytics.districtStats(log);
    final opponents = CapitalRaidAnalytics.opponentStats(log);
    final efficiency = CapitalRaidAnalytics.attackEfficiency(log);
    final defenseDistricts = _showOffense
        ? const <DistrictDefenseStat>[]
        : CapitalRaidAnalytics.districtDefenseStats(log);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClanFilterRail(
            padding: EdgeInsets.zero,
            children: [
              ClanFilterChip(
                label: loc.capitalDetailsOffense,
                icon: Icons.arrow_outward_rounded,
                selected: _showOffense,
                onTap: () => setState(() => _showOffense = true),
              ),
              ClanFilterChip(
                label: loc.capitalDetailsDefense,
                icon: Icons.shield_rounded,
                selected: !_showOffense,
                color: StatColors.capitalAttack,
                onTap: () => setState(() => _showOffense = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClanSummaryChips(
            padding: EdgeInsets.zero,
            alignment: WrapAlignment.start,
            scrollable: false,
            children: [
              ClanSummaryChip(
                icon: Icons.bolt_rounded,
                value: efficiency.oneshots.toString(),
                label: loc.capitalRaidOneshots,
                color: StatColors.win,
              ),
              ClanSummaryChip(
                icon: Icons.close_rounded,
                value: efficiency.fails.toString(),
                label: loc.capitalRaidFails,
                color: StatColors.loss,
              ),
            ],
          ),
          if (!_showOffense && defenseDistricts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'District defense',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...defenseDistricts.map(
              (district) => _DefenseDistrictRow(district: district),
            ),
          ],
          if (districts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              loc.capitalDistrictsSection,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...districts.map((district) => _DistrictRow(district: district)),
          ],
          if (opponents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              loc.capitalOpponentsSection,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...opponents.map((opponent) => _OpponentRow(opponent: opponent)),
          ],
        ],
      ),
    );
  }
}

class _DefenseDistrictRow extends StatelessWidget {
  final DistrictDefenseStat district;

  const _DefenseDistrictRow({required this.district});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final heldColor = district.held > 0 ? StatColors.win : StatColors.loss;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: heldColor.withValues(
            alpha: district.held > 0 ? 0.38 : AppOpacity.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: heldColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, size: 18, color: heldColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${district.held} held / ${district.destroyed} destroyed  •  '
                  '${district.avgAttacksTaken.toStringAsFixed(1)} hits avg',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${district.avgDestruction.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                formatter.format(district.lootLost),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

class _DistrictRow extends StatelessWidget {
  final DistrictStat district;

  const _DistrictRow({required this.district});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: AppOpacity.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: AppOpacity.fillMuted,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.domain_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${district.destroyedCount}x  •  '
                  '${loc.capitalAvgAttacksPerDistrict}: ${district.avgAttacksPerDestroy.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (district.hitRates.length > 1) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: (district.hitRates.keys.toList()..sort())
                        .map(
                          (attackCount) => _HitRateChip(
                            attackCount: attackCount,
                            occurrences: district.hitRates[attackCount]!,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(district.loot),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${loc.capitalAvgLootPerAttack}: ${district.avgLootPerAttack.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

/// Compact hit-rate pill: how many districts of this type were destroyed
/// in exactly [attackCount] attacks.
class _HitRateChip extends StatelessWidget {
  final int attackCount;
  final int occurrences;

  const _HitRateChip({required this.attackCount, required this.occurrences});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: AppOpacity.fillMuted,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$occurrences× ${attackCount}atk',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Opponent row, expandable on tap to show which of our members attacked
/// each of their districts and with how much destruction — the attacker
/// list (`District.attacks`) was already being fetched but never shown.
class _OpponentRow extends StatefulWidget {
  final OpponentStat opponent;

  const _OpponentRow({required this.opponent});

  @override
  State<_OpponentRow> createState() => _OpponentRowState();
}

class _OpponentRowState extends State<_OpponentRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final opponent = widget.opponent;
    final fullyDestroyed =
        opponent.districtsDestroyed == opponent.districtCount;
    final attackedDistricts = opponent.districts
        .where((district) => district.attacks?.isNotEmpty == true)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fullyDestroyed
              ? StatColors.win.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: attackedDistricts.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                if (opponent.clan.badgeUrls['medium'] != null ||
                    opponent.clan.badgeUrls['small'] != null)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: MobileWebImage(
                      imageUrl:
                          opponent.clan.badgeUrls['medium'] ??
                          opponent.clan.badgeUrls['small']!,
                    ),
                  )
                else
                  Icon(
                    Icons.groups_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponent.clan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${opponent.attacks}x  •  '
                        '${opponent.districtsDestroyed}/${opponent.districtCount}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatter.format(opponent.loot),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (attackedDistricts.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: attackedDistricts
                    .map((district) => _DistrictAttacksRow(district: district))
                    .toList(),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _DistrictAttacksRow extends StatelessWidget {
  final District district;

  const _DistrictAttacksRow({required this.district});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${district.name} (${district.destructionPercent}%)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          ...?district.attacks?.map(
            (attack) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      attack.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: index < attack.stars
                            ? StatColors.warStarGold
                            : colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${attack.destructionPercent}%',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-week trends built entirely from the raid weeks already loaded for
/// this page (up to 10) — weekly averages plus the best/worst raid, none
/// of which the app previously surfaced anywhere.
class CapitalHistorySummary extends StatefulWidget {
  final List<CapitalHistoryItem> allRaids;
  final int clanCapitalPoints;
  final List<ClanMember> clanMembers;

  const CapitalHistorySummary({
    super.key,
    required this.allRaids,
    required this.clanCapitalPoints,
    this.clanMembers = const [],
  });

  @override
  State<CapitalHistorySummary> createState() => _CapitalHistorySummaryState();
}

class _CapitalHistorySummaryState extends State<CapitalHistorySummary> {
  bool _expanded = true;

  List<_RaidMemberTrend> _memberTrends(List<CapitalHistoryItem> raids) {
    final byTag = <String, _RaidMemberTrendAccumulator>{};
    final membersByTag = {
      for (final member in widget.clanMembers) _tagKey(member.tag): member,
    };
    for (final raid in raids) {
      for (final member in raid.members ?? const <RaidMember>[]) {
        final key = member.tag.isEmpty ? member.name : _tagKey(member.tag);
        final clanMember = membersByTag[key];
        final acc = byTag.putIfAbsent(
          key,
          () => _RaidMemberTrendAccumulator(
            member.name,
            member.tag,
            clanMember?.townHallLevel ?? 0,
          ),
        );
        acc.weeks += 1;
        acc.attacks += member.attacks;
        acc.loot += member.capitalResourcesLooted;
      }
    }

    final trends = byTag.values
        .map(
          (acc) => _RaidMemberTrend(
            name: acc.name,
            tag: acc.tag,
            townHallLevel: acc.townHallLevel,
            weeks: acc.weeks,
            attacks: acc.attacks,
            loot: acc.loot,
          ),
        )
        .toList();
    trends.sort((a, b) {
      final lootCompare = b.loot.compareTo(a.loot);
      if (lootCompare != 0) return lootCompare;
      return b.attacks.compareTo(a.attacks);
    });
    return trends;
  }

  String _tagKey(String tag) => tag.replaceAll('#', '').toUpperCase();

  List<DistrictDefenseStat> _defenseTrends(List<CapitalHistoryItem> raids) {
    final logs = raids
        .expand((raid) => raid.defenseLog ?? const <RaidAttackLog>[])
        .toList(growable: false);
    return CapitalRaidAnalytics.districtDefenseStats(logs);
  }

  @override
  Widget build(BuildContext context) {
    final summary = CapitalRaidAnalytics.summarizeHistory(widget.allRaids);
    if (summary.weeksCounted == 0) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final endedRaids = widget.allRaids
        .where((raid) => raid.state == 'ended')
        .toList(growable: false);
    final totalRewards = endedRaids.fold<int>(
      0,
      (sum, raid) => sum + summary.rewardOf(raid),
    );
    final avgRewards = summary.weeksCounted == 0
        ? 0
        : (totalRewards / summary.weeksCounted).round();
    final avgLootPerAttack = summary.totalAttacks == 0
        ? 0
        : (summary.totalLoot / summary.totalAttacks).round();
    final avgDistrictsPerWeek = summary.weeksCounted == 0
        ? 0
        : summary.totalDistrictsDestroyed / summary.weeksCounted;
    final memberTrends = _memberTrends(endedRaids);
    final defenseTrends = _defenseTrends(endedRaids);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: AppOpacity.border,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        loc.capitalHistorySection,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${summary.weeksCounted} ${loc.capitalHistoryWeeksTracked}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ClanSummaryChips(
              padding: EdgeInsets.zero,
              alignment: WrapAlignment.start,
              scrollable: false,
              children: [
                ClanSummaryChip(
                  icon: Icons.diamond_rounded,
                  value: formatter.format(summary.avgLootPerWeek.round()),
                  label: loc.capitalAvgLootPerWeek,
                  color: StatColors.capitalLoot,
                ),
                ClanSummaryChip(
                  icon: Icons.bolt_rounded,
                  value: formatter.format(summary.avgAttacksPerWeek.round()),
                  label: loc.capitalAvgAttacksPerWeek,
                  color: StatColors.capitalAttack,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  ClanSummaryChips(
                    padding: EdgeInsets.zero,
                    alignment: WrapAlignment.start,
                    scrollable: false,
                    children: [
                      ClanSummaryChip(
                        icon: Icons.emoji_events_rounded,
                        value: formatter.format(avgRewards),
                        label: loc.clanCapitalAvgRewards,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      ClanSummaryChip(
                        icon: Icons.savings_rounded,
                        value: formatter.format(avgLootPerAttack),
                        label: loc.capitalAvgLootPerAttack,
                        color: StatColors.capitalLoot,
                      ),
                      ClanSummaryChip(
                        icon: Icons.domain_rounded,
                        value: avgDistrictsPerWeek.toStringAsFixed(1),
                        label: loc.clanCapitalAvgDistrictsPerWeek,
                        color: StatColors.capitalDistrict,
                      ),
                      ClanSummaryChip(
                        icon: Icons.checklist_rounded,
                        value: formatter.format(summary.totalRaidsCompleted),
                        label: loc.raidsCompleted,
                      ),
                    ],
                  ),
                  if (memberTrends.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _HistorySubsectionTitle(
                      title: loc.clanCapitalTopAttackers,
                      subtitle: loc.clanCapitalPlayersTracked(
                        memberTrends.length,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...memberTrends
                        .take(5)
                        .map((member) => _RaidMemberTrendRow(member: member)),
                  ],
                  if (defenseTrends.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _HistorySubsectionTitle(
                      title: loc.clanCapitalDefenseOverTime,
                      subtitle: loc.clanCapitalDistrictsTracked(
                        defenseTrends.length,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...defenseTrends.map(
                      (district) =>
                          _DefenseDistrictTrendRow(district: district),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CapitalHistoryChart(
                    allRaids: widget.allRaids,
                    clanCapitalPoints: widget.clanCapitalPoints,
                  ),
                  if (summary.bestRaid != null) ...[
                    const SizedBox(height: 12),
                    _RaidHighlightRow(
                      raid: summary.bestRaid!,
                      reward: summary.rewardOf(summary.bestRaid!),
                      label: loc.capitalBestRaid,
                      icon: Icons.emoji_events_rounded,
                      color: StatColors.capitalLoot,
                    ),
                  ],
                  if (summary.worstRaid != null &&
                      summary.worstRaid != summary.bestRaid) ...[
                    const SizedBox(height: 8),
                    _RaidHighlightRow(
                      raid: summary.worstRaid!,
                      reward: summary.rewardOf(summary.worstRaid!),
                      label: loc.capitalWorstRaid,
                      icon: Icons.trending_down_rounded,
                      color: StatColors.loss,
                    ),
                  ],
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySubsectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HistorySubsectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RaidMemberTrendRow extends StatelessWidget {
  final _RaidMemberTrend member;

  const _RaidMemberTrendRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: AppOpacity.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: StatColors.capitalLoot.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: member.townHallLevel > 0
                ? Padding(
                    padding: const EdgeInsets.all(2),
                    child: MobileWebImage(
                      imageUrl: ImageAssets.townHall(member.townHallLevel),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: StatColors.capitalLoot,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.weeks} weeks  •  ${member.attacks} attacks'
                  '${member.townHallLevel > 0 ? '  •  TH${member.townHallLevel}' : ''}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(member.loot),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatter.format(member.avgLootPerWeek.round())}/week',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

class _DefenseDistrictTrendRow extends StatelessWidget {
  final DistrictDefenseStat district;

  const _DefenseDistrictTrendRow({required this.district});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final heldColor = district.held > 0 ? StatColors.win : StatColors.loss;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: AppOpacity.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: heldColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, size: 18, color: heldColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${district.held} held / ${district.destroyed} destroyed',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${district.avgDestruction.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                formatter.format(district.lootLost),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

class _RaidMemberTrend {
  final String name;
  final String tag;
  final int townHallLevel;
  final int weeks;
  final int attacks;
  final int loot;

  const _RaidMemberTrend({
    required this.name,
    required this.tag,
    required this.townHallLevel,
    required this.weeks,
    required this.attacks,
    required this.loot,
  });

  double get avgLootPerWeek => weeks == 0 ? 0 : loot / weeks;
}

class _RaidMemberTrendAccumulator {
  _RaidMemberTrendAccumulator(this.name, this.tag, this.townHallLevel);

  final String name;
  final String tag;
  final int townHallLevel;
  int weeks = 0;
  int attacks = 0;
  int loot = 0;
}

class _RaidHighlightRow extends StatelessWidget {
  final CapitalHistoryItem raid;
  final int reward;
  final String label;
  final IconData icon;
  final Color color;

  const _RaidHighlightRow({
    required this.raid,
    required this.reward,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: AppOpacity.borderStrong),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd(locale).format(raid.startTime),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(reward),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                formatter.format(raid.capitalTotalLoot),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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

/// Loot/rewards/trophy bar chart over the ended raids already loaded for
/// this page, so weekly trends are visible at a glance without adding a
/// heavy nested card stack.
class _CapitalHistoryChart extends StatefulWidget {
  final List<CapitalHistoryItem> allRaids;
  final int clanCapitalPoints;

  const _CapitalHistoryChart({
    required this.allRaids,
    required this.clanCapitalPoints,
  });

  @override
  State<_CapitalHistoryChart> createState() => _CapitalHistoryChartState();
}

enum _CapitalHistoryMetric { loot, rewards, trophies }

class _CapitalHistoryChartState extends State<_CapitalHistoryChart> {
  _CapitalHistoryMetric _metric = _CapitalHistoryMetric.loot;

  @override
  Widget build(BuildContext context) {
    final ended =
        widget.allRaids.where((raid) => raid.state == 'ended').toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    // A single point isn't a trend.
    if (ended.length < 2) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final trophyTrend = _estimatedTrophyTrend(ended, widget.clanCapitalPoints);
    final canShowTrophies = trophyTrend.length == ended.length;
    if (_metric == _CapitalHistoryMetric.trophies && !canShowTrophies) {
      _metric = _CapitalHistoryMetric.loot;
    }

    final metrics = [
      _HistoryMetricOption(
        metric: _CapitalHistoryMetric.loot,
        label: loc.capitalRaidLoot,
        imageUrl: ImageAssets.capitalGold,
        color: StatColors.capitalLoot,
      ),
      _HistoryMetricOption(
        metric: _CapitalHistoryMetric.rewards,
        label: loc.capitalRaidRewards,
        imageUrl: ImageAssets.raidMedal,
        color: colorScheme.primary,
      ),
      if (canShowTrophies)
        _HistoryMetricOption(
          metric: _CapitalHistoryMetric.trophies,
          label: loc.gameTrophies,
          imageUrl: ImageAssets.capitalTrophy,
          color: StatColors.capitalTrophy,
        ),
    ];
    final selectedMetric = metrics.firstWhere(
      (metric) => metric.metric == _metric,
      orElse: () => metrics.first,
    );

    double valueFor(int index) {
      final raid = ended[index];
      return switch (_metric) {
        _CapitalHistoryMetric.loot => raid.capitalTotalLoot.toDouble(),
        _CapitalHistoryMetric.rewards =>
          (6 * raid.offensiveReward + raid.defensiveReward).toDouble(),
        _CapitalHistoryMetric.trophies => trophyTrend[index].toDouble(),
      };
    }

    final values = [for (var i = 0; i < ended.length; i++) valueFor(i)];
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  loc.capitalHistoryChartTitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  for (final metric in metrics)
                    _HistoryMetricFlatStat(
                      metric: metric,
                      selected: metric.metric == _metric,
                      onTap: () => setState(() => _metric = metric.metric),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= ended.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat.Md(
                              locale,
                            ).format(ended[index].startTime),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < ended.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: selectedMetric.color.withValues(alpha: 0.86),
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxValue <= 0 ? 1 : maxValue * 1.2,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.26),
                          ),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        colorScheme.inverseSurface.withValues(alpha: 0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${selectedMetric.label}: ${formatter.format(rod.toY.round())}',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
          if (_metric == _CapitalHistoryMetric.trophies) ...[
            const SizedBox(height: 4),
            Text(
              loc.capitalRaidTrophyPredictionTooltip,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<int> _estimatedTrophyTrend(
    List<CapitalHistoryItem> ended,
    int currentCapitalPoints,
  ) {
    if (currentCapitalPoints <= 0 || ended.isEmpty) return const [];

    final values = List<int>.filled(ended.length, 0);
    var postRaidPoints = currentCapitalPoints;
    for (var i = ended.length - 1; i >= 0; i--) {
      values[i] = postRaidPoints;
      final performance = CapitalRaidAnalytics.trophyPerformance(ended[i]);
      final previous = ((postRaidPoints - performance * 0.2) / 0.8).round();
      postRaidPoints = previous < 0 ? 0 : previous;
    }
    return values;
  }
}

class _HistoryMetricOption {
  final _CapitalHistoryMetric metric;
  final String label;
  final String imageUrl;
  final Color color;

  const _HistoryMetricOption({
    required this.metric,
    required this.label,
    required this.imageUrl,
    required this.color,
  });
}

class _HistoryMetricFlatStat extends StatelessWidget {
  final _HistoryMetricOption metric;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryMetricFlatStat({
    required this.metric,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? metric.color.withValues(alpha: 0.10)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MobileWebImage(imageUrl: metric.imageUrl, width: 18, height: 18),
              const SizedBox(height: 4),
              Text(
                metric.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? metric.color : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
