import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_session.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'side_page_components.dart';

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key, this.catalog, this.accountPresets});

  final DamageCatalog? catalog;
  final List<DamageAccountPreset>? accountPresets;

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage> {
  static const _engine = DamageCalculatorEngine();
  late final DamageCatalog _catalog;
  late final DamageCalculatorSession _session;
  List<DamageAccountPreset> _accountPresets = const [];
  bool _readProviders = false;

  @override
  void initState() {
    super.initState();
    _catalog =
        widget.catalog ?? DamageCatalog.fromBundle(GameDataService.bundleData);
    _session = DamageCalculatorSession(_catalog);
    _accountPresets = widget.accountPresets ?? const [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readProviders || widget.accountPresets != null) return;
    _readProviders = true;
    try {
      _accountPresets = _verifiedAccountPresets(
        context.read<CocAccountService>(),
        context.read<PlayerService>(),
      );
    } on ProviderNotFoundException {
      _accountPresets = const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_catalog.buildings.isEmpty || _catalog.sources.isEmpty) {
      return SidePageScaffold(
        title: loc.calculatorsTitle,
        subtitle: loc.damageCalculatorSubtitle,
        child: SidePageEmptyState(
          icon: Icons.cloud_off_rounded,
          title: loc.damageNoStaticDataTitle,
          body: loc.damageNoStaticDataBody,
        ),
      );
    }

    final targets = _session.resolvedTargets();
    final stack = _session.resolvedStack();
    final results = _engine.evaluateAll(targets, stack);

    return SidePageScaffold(
      title: loc.calculatorsTitle,
      subtitle: loc.damageCalculatorSubtitle,
      child: ListView(
        key: const ValueKey('damage-calculator-scroll'),
        padding: sidePagePadding,
        children: [
          _SetupCard(
            townHall: _session.townHall,
            maxTownHall: _catalog.maxTownHall,
            accountPresets: _accountPresets,
            selectedAccountTag: _session.selectedAccountTag,
            onTownHallChanged: (value) => setState(() {
              _session.selectedAccountTag = null;
              _session.setTownHall(value);
            }),
            onAccountChanged: (tag) {
              if (tag == null) return;
              final preset = _accountPresets.firstWhere(
                (candidate) => candidate.tag == tag,
              );
              setState(() => _session.applyPreset(preset));
            },
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, loc.damageTargets),
          for (final target in targets) ...[
            _TargetCard(
              key: ValueKey('target-${target.id}'),
              target: target,
              availableLevels: target.building.levelsForTownHall(
                _session.townHall,
              ),
              onLevelChanged: (level) =>
                  setState(() => _session.setTargetLevel(target.id, level)),
              onRemove: () => setState(() => _session.removeTarget(target.id)),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            key: const ValueKey('add-building'),
            onPressed: _session.availableBuildings.length == targets.length
                ? null
                : _showBuildingPicker,
            icon: const Icon(Icons.add_rounded),
            label: Text(loc.damageAddBuilding),
          ),
          if (targets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                loc.damageNoTargetsBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 22),
          _sectionTitle(context, loc.damageAttackStack),
          if (_session.availableSources.isEmpty)
            _InlineEmpty(message: loc.damageNoSourcesForTownHall)
          else
            for (final source in _session.availableSources) ...[
              _SourceRow(
                key: ValueKey('source-${source.kind.name}'),
                source: source,
                selection: _session.sources[source.kind]!,
                townHall: _session.townHall,
                onLevelChanged: (level) =>
                    setState(() => _session.setSourceLevel(source.kind, level)),
                onCountChanged: (count) =>
                    setState(() => _session.setSourceCount(source.kind, count)),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 22),
          _sectionTitle(context, loc.damageResults),
          if (targets.isEmpty)
            _InlineEmpty(message: loc.damageNoTargetsBody)
          else
            for (final result in results) ...[
              _ResultCard(
                key: ValueKey('result-${result.target.id}'),
                result: result,
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 22),
          _sectionTitle(context, loc.damageZapQuakeOptimizer),
          _ZapQuakePanel(
            session: _session,
            engine: _engine,
            targets: targets,
            onCapacityChanged: (capacity) =>
                setState(() => _session.setSpellCapacity(capacity)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    ),
  );

  Future<void> _showBuildingPicker() async {
    final selectedIds = _session.targets
        .map((target) => target.buildingId)
        .toSet();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _BuildingPicker(
        buildings: _session.availableBuildings,
        selectedIds: selectedIds,
        townHall: _session.townHall,
      ),
    );
    if (result != null && mounted) {
      setState(() => _session.addTarget(result));
    }
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.townHall,
    required this.maxTownHall,
    required this.accountPresets,
    required this.selectedAccountTag,
    required this.onTownHallChanged,
    required this.onAccountChanged,
  });

  final int townHall;
  final int maxTownHall;
  final List<DamageAccountPreset> accountPresets;
  final String? selectedAccountTag;
  final ValueChanged<int> onTownHallChanged;
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              MobileWebImage(
                imageUrl: ImageAssets.townHall(townHall),
                width: 64,
                height: 64,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.castle_rounded, size: 48),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('town-hall-$townHall'),
                  initialValue: townHall,
                  decoration: InputDecoration(labelText: loc.damageTownHall),
                  items: [
                    for (var level = 1; level <= maxTownHall; level++)
                      DropdownMenuItem(
                        value: level,
                        child: Text(loc.gameTownHallShortLevel(level)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onTownHallChanged(value);
                  },
                ),
              ),
            ],
          ),
          if (accountPresets.isNotEmpty) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('account-${selectedAccountTag ?? 'none'}'),
              initialValue: selectedAccountTag,
              decoration: InputDecoration(
                labelText: loc.damageVerifiedAccountPrefill,
                helperText: loc.damageOverridesStayLocal,
              ),
              items: accountPresets
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset.tag,
                      child: Text(
                        '${preset.name} · ${loc.gameTownHallShortLevel(preset.townHall)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onAccountChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    super.key,
    required this.target,
    required this.availableLevels,
    required this.onLevelChanged,
    required this.onRemove,
  });

  final DamageTarget target;
  final List<BuildingLevelDefinition> availableLevels;
  final ValueChanged<int> onLevelChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _Panel(
      child: Row(
        children: [
          MobileWebImage(
            imageUrl: ImageAssets.getHomeVillageBuildingImage(
              target.building.imageName,
              target.level.level,
            ),
            width: 58,
            height: 58,
            errorWidget: (_, _, _) => const Icon(Icons.home_work_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.building.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  loc.damageHitpoints(formatSidePageInt(target.hitpoints)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<int>(
            key: ValueKey('${target.id}-level-${target.level.level}'),
            value: target.level.level,
            items: availableLevels
                .map(
                  (level) => DropdownMenuItem(
                    value: level.level,
                    child: Text(loc.sideLevel(level.level)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) onLevelChanged(value);
            },
          ),
          IconButton(
            tooltip: loc.damageRemoveBuilding,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    super.key,
    required this.source,
    required this.selection,
    required this.townHall,
    required this.onLevelChanged,
    required this.onCountChanged,
  });

  final DamageSourceDefinition source;
  final SelectedDamageSource selection;
  final int townHall;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<int> onCountChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final levels = source.levelsForTownHall(townHall);
    final damageLevel = source.level(selection.level)!;
    final damageText = source.kind == DamageSourceKind.earthquake
        ? loc.damageEarthquakePercent(
            _formatNumber(damageLevel.earthquakePercent ?? 0),
          )
        : loc.damagePerUse(
            formatSidePageInt((damageLevel.damage ?? 0).round()),
          );
    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              MobileWebImage(
                imageUrl: source.imageUrl,
                width: 48,
                height: 48,
                errorWidget: (_, _, _) => const Icon(Icons.bolt_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sourceLabel(loc, source),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      damageText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<int>(
                key: ValueKey('${source.kind.name}-level-${selection.level}'),
                value: selection.level,
                items: levels
                    .map(
                      (level) => DropdownMenuItem(
                        value: level.level,
                        child: Text(loc.sideLevel(level.level)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) onLevelChanged(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(loc.damageCount)),
              IconButton(
                tooltip: loc.sideDecrease,
                onPressed: selection.count == 0
                    ? null
                    : () => onCountChanged(selection.count - 1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${selection.count}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: loc.sideIncrease,
                onPressed: () => onCountChanged(selection.count + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.result});

  final DamageResult result;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = result.destroyed ? StatColors.win : colorScheme.primary;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.target.building.name} · ${loc.sideLevel(result.target.level.level)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    result.destroyed ? loc.damageDestroyed : loc.damageSurvives,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: result.percentDestroyed / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: accent,
          ),
          const SizedBox(height: 8),
          Text(
            loc.damageResultSummary(
              formatSidePageInt(result.totalDamage.round()),
              formatSidePageInt(result.remainingHitpoints.ceil()),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZapQuakePanel extends StatelessWidget {
  const _ZapQuakePanel({
    required this.session,
    required this.engine,
    required this.targets,
    required this.onCapacityChanged,
  });

  final DamageCalculatorSession session;
  final DamageCalculatorEngine engine;
  final List<DamageTarget> targets;
  final ValueChanged<int> onCapacityChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lightningSource = session.catalog.source(DamageSourceKind.lightning);
    final earthquakeSource = session.catalog.source(
      DamageSourceKind.earthquake,
    );
    final lightningSelection = session.sources[DamageSourceKind.lightning];
    final earthquakeSelection = session.sources[DamageSourceKind.earthquake];
    if (lightningSource == null ||
        earthquakeSource == null ||
        lightningSelection == null ||
        earthquakeSelection == null) {
      return _InlineEmpty(message: loc.damageZapQuakeUnavailable);
    }
    final lightning = lightningSource.level(lightningSelection.level)!;
    final earthquake = earthquakeSource.level(earthquakeSelection.level)!;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(loc.damageSpellCapacity)),
              IconButton(
                tooltip: loc.sideDecrease,
                onPressed: session.spellCapacity <= 1
                    ? null
                    : () => onCapacityChanged(session.spellCapacity - 1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${session.spellCapacity}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: loc.sideIncrease,
                onPressed: () => onCapacityChanged(session.spellCapacity + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          Text(
            loc.damageZapQuakeUsesSelectedLevels(
              lightning.level,
              earthquake.level,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (targets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(loc.damageNoTargetsBody),
            )
          else
            for (final target in targets) ...[
              const SizedBox(height: 16),
              Text(
                '${target.building.name} · ${loc.sideLevel(target.level.level)}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _combinationList(
                context,
                target,
                engine.validZapQuakeCombinations(
                  target: target,
                  lightning: lightning,
                  earthquake: earthquake,
                  capacity: session.spellCapacity,
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _combinationList(
    BuildContext context,
    DamageTarget target,
    List<ZapQuakeCombination> combinations,
  ) {
    final loc = AppLocalizations.of(context)!;
    if (!target.building.zapQuakeEligible) {
      return Text(loc.damageZapQuakeIneligible);
    }
    if (combinations.isEmpty) return Text(loc.damageNoValidZapQuake);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: combinations
          .map(
            (combo) => Chip(
              avatar: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                loc.damageZapQuakeCombination(
                  combo.lightningCount,
                  combo.earthquakeCount,
                  combo.capacityUsed,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _BuildingPicker extends StatefulWidget {
  const _BuildingPicker({
    required this.buildings,
    required this.selectedIds,
    required this.townHall,
  });

  final List<BuildingDefinition> buildings;
  final Set<String> selectedIds;
  final int townHall;

  @override
  State<_BuildingPicker> createState() => _BuildingPickerState();
}

class _BuildingPickerState extends State<_BuildingPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final filtered = widget.buildings
        .where(
          (building) =>
              building.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList(growable: false);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('building-search'),
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.damageSearchBuildings,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: loc.generalClearSearch,
                        onPressed: () => setState(() => _query = ''),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? SidePageEmptyState(
                      icon: Icons.search_off_rounded,
                      title: loc.damageNoBuildingsFound,
                      body: loc.damageTryAnotherSearch,
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final building = filtered[index];
                        final level = building
                            .levelsForTownHall(widget.townHall)
                            .last;
                        final selected = widget.selectedIds.contains(
                          building.id,
                        );
                        return ListTile(
                          enabled: !selected,
                          leading: MobileWebImage(
                            imageUrl: ImageAssets.getHomeVillageBuildingImage(
                              building.imageName,
                              level.level,
                            ),
                            width: 44,
                            height: 44,
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.home_work_rounded),
                          ),
                          title: Text(building.name),
                          subtitle: Text(
                            '${loc.sideLevel(level.level)} · ${loc.damageHitpoints(formatSidePageInt(level.hitpoints))}',
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_rounded)
                              : const Icon(Icons.add_rounded),
                          onTap: selected
                              ? null
                              : () => Navigator.pop(context, building.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: AppOpacity.border,
          ),
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

List<DamageAccountPreset> _verifiedAccountPresets(
  CocAccountService accounts,
  PlayerService players,
) {
  final profiles = {
    for (final player in players.profiles) _normalizeTag(player.tag): player,
  };
  final presets = <DamageAccountPreset>[];
  for (final raw in accounts.cocAccounts) {
    if (raw['is_verified'] != true) continue;
    final tag = raw['player_tag']?.toString() ?? raw['tag']?.toString() ?? '';
    final player = profiles[_normalizeTag(tag)];
    if (player == null) continue;
    presets.add(
      DamageAccountPreset(
        tag: tag,
        name: player.name,
        townHall: player.townHallLevel,
        ownedLevels: _ownedDamageLevels(player),
      ),
    );
  }
  return presets;
}

Map<DamageSourceKind, int> _ownedDamageLevels(Player player) {
  final levels = <DamageSourceKind, int>{};
  void add(DamageSourceKind kind, Iterable<dynamic> items, String name) {
    for (final item in items) {
      if (item.name == name && item.level > 0) {
        levels[kind] = item.level;
        return;
      }
    }
  }

  add(DamageSourceKind.lightning, player.spells, 'Lightning Spell');
  add(DamageSourceKind.earthquake, player.spells, 'Earthquake Spell');
  add(DamageSourceKind.giantArrow, player.equipments, 'Giant Arrow');
  add(DamageSourceKind.fireball, player.equipments, 'Fireball');
  add(DamageSourceKind.flameFlinger, player.siegeMachines, 'Flame Flinger');
  add(DamageSourceKind.balloonDeath, player.troops, 'Balloon');
  add(
    DamageSourceKind.rocketBalloonDeath,
    player.superTroops,
    'Rocket Balloon',
  );
  return levels;
}

String _normalizeTag(String value) =>
    value.trim().toUpperCase().replaceAll('#', '');

String _sourceLabel(AppLocalizations loc, DamageSourceDefinition source) =>
    switch (source.kind) {
      DamageSourceKind.lightning => loc.damageSourceLightning,
      DamageSourceKind.earthquake => loc.damageSourceEarthquake,
      DamageSourceKind.giantArrow => loc.damageSourceGiantArrow,
      DamageSourceKind.fireball => loc.damageSourceFireball,
      DamageSourceKind.flameFlinger => loc.damageSourceFlameFlinger,
      DamageSourceKind.balloonDeath => loc.damageSourceBalloonDeath,
      DamageSourceKind.rocketBalloonDeath => loc.damageSourceRocketBalloonDeath,
    };

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
