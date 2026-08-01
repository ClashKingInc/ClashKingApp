import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
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
  static const _customSetupId = 'custom';
  static const _quickSetupOrder = [
    'zap-quake',
    'fireball-quake',
    'giant-arrow',
    'flame-flinger',
  ];
  static const _quickSetupCountsById = {
    'zap-quake': {
      DamageSourceKind.lightning: 5,
      DamageSourceKind.earthquake: 1,
    },
    'fireball-quake': {
      DamageSourceKind.fireball: 1,
      DamageSourceKind.earthquake: 1,
    },
    'giant-arrow': {DamageSourceKind.giantArrow: 1},
    'flame-flinger': {DamageSourceKind.flameFlinger: 1},
  };

  late final DamageCatalog _catalog;
  late final DamageCalculatorSession _session;
  List<DamageAccountPreset> _accountPresets = const [];
  bool _readProviders = false;
  bool _showAllSources = false;
  String? _selectedQuickSetupId;

  @override
  void initState() {
    super.initState();
    _catalog =
        widget.catalog ?? DamageCatalog.fromBundle(GameDataService.bundleData);
    _session = DamageCalculatorSession(_catalog);
    _selectedQuickSetupId = _customSetupId;
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
        title: loc.damageCalculatorTitle,
        child: AppEmptyState(
          icon: Icons.cloud_off_rounded,
          title: loc.damageNoStaticDataTitle,
          body: loc.damageNoStaticDataBody,
        ),
      );
    }

    final targets = _session.resolvedTargets();
    final stack = _session.resolvedStack();
    final results = _engine.evaluateAll(targets, stack);

    final resultByTargetId = {
      for (final result in results) result.target.id: result,
    };
    final quickSetups = _quickSetups(loc);
    final selectedSetup = _selectedQuickSetup(quickSetups);
    final selectedSourceKinds =
        selectedSetup?.counts.keys.toSet() ?? <DamageSourceKind>{};
    final availableSources = _session.availableSources;
    final hasSelectedAttackMethod = selectedSetup != null;
    final primarySources = availableSources
        .where(
          (source) =>
              selectedSourceKinds.contains(source.kind) ||
              (_session.sources[source.kind]?.count ?? 0) > 0,
        )
        .toList(growable: false);
    final visiblePrimarySources = selectedSetup?.id == _customSetupId
        ? availableSources
        : hasSelectedAttackMethod
        ? primarySources
        : const <DamageSourceDefinition>[];
    final visiblePrimaryKinds = visiblePrimarySources
        .map((source) => source.kind)
        .toSet();
    final extraSources = selectedSetup?.id == _customSetupId
        ? const <DamageSourceDefinition>[]
        : hasSelectedAttackMethod
        ? availableSources
              .where((source) => !visiblePrimaryKinds.contains(source.kind))
              .toList(growable: false)
        : const <DamageSourceDefinition>[];
    final visibleExtraSources = _showAllSources
        ? extraSources
        : const <DamageSourceDefinition>[];
    final showZapQuakeOptimizer =
        selectedSetup?.id == 'zap-quake' && targets.isNotEmpty;

    return SidePageScaffold(
      title: loc.damageCalculatorTitle,
      child: ListView(
        key: const ValueKey('damage-calculator-scroll'),
        padding: sidePagePadding,
        children: [
          SidePageSectionHeader(title: loc.damageTargetSectionTitle),
          if (targets.isEmpty)
            _TargetEmptyPanel(onChoose: _showBuildingPicker)
          else ...[
            for (final target in targets) ...[
              _TargetCard(
                key: ValueKey('target-${target.id}'),
                target: target,
                availableLevels: target.building.levelsForTownHall(
                  _session.townHall,
                ),
                result: resultByTargetId[target.id],
                onLevelChanged: (level) =>
                    setState(() => _session.setTargetLevel(target.id, level)),
                onRemove: () =>
                    setState(() => _session.removeTarget(target.id)),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                key: const ValueKey('add-building'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: AppOpacity.borderStrong),
                  ),
                ),
                onPressed: _session.availableBuildings.length == targets.length
                    ? null
                    : _showBuildingPicker,
                icon: const Icon(Icons.add_rounded),
                label: Text(loc.damageAddBuilding),
              ),
            ),
          ],

          const SizedBox(height: 22),
          SidePageSectionHeader(title: loc.damageAttackStack),
          _QuickSetupPanel(
            setups: quickSetups,
            selectedId: selectedSetup?.id,
            onSelected: _applyQuickSetup,
          ),
          const SizedBox(height: 14),
          _AccountSelectorPanel(
            accountPresets: _accountPresets,
            selectedAccountTag: _session.selectedAccountTag,
            onAccountChanged: (tag) {
              setState(() {
                if (tag == null) {
                  _session.selectedAccountTag = null;
                  _session.setTownHall(_catalog.maxTownHall);
                } else {
                  final preset = _accountPresets.firstWhere(
                    (candidate) => candidate.tag == tag,
                  );
                  _session.applyPreset(preset);
                }
                _repairSelectedQuickSetup();
              });
            },
          ),
          const SizedBox(height: 14),
          if (selectedSetup == null)
            _InlineEmpty(message: loc.damageNoActiveSources)
          else if (_session.availableSources.isEmpty)
            _InlineEmpty(message: loc.damageNoSourcesForTownHall)
          else ...[
            for (final source in visiblePrimarySources) ...[
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
            if (extraSources.isNotEmpty) ...[
              if (_showAllSources)
                _InlineSectionLabel(title: loc.damageOtherSources),
              for (final source in visibleExtraSources) ...[
                _SourceRow(
                  key: ValueKey('source-${source.kind.name}'),
                  source: source,
                  selection: _session.sources[source.kind]!,
                  townHall: _session.townHall,
                  onLevelChanged: (level) => setState(
                    () => _session.setSourceLevel(source.kind, level),
                  ),
                  onCountChanged: (count) => setState(
                    () => _session.setSourceCount(source.kind, count),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showAllSources = !_showAllSources),
                  icon: Icon(
                    _showAllSources
                        ? Icons.expand_less_rounded
                        : Icons.add_rounded,
                  ),
                  label: Text(
                    _showAllSources
                        ? loc.damageShowFewerSources
                        : loc.damageShowAllSources,
                  ),
                ),
              ),
            ],
          ],

          if (showZapQuakeOptimizer) ...[
            const SizedBox(height: 22),
            SidePageSectionHeader(title: loc.damageZapQuakeOptimizer),
            _ZapQuakePanel(
              session: _session,
              engine: _engine,
              targets: targets,
              onCapacityChanged: (capacity) =>
                  setState(() => _session.setSpellCapacity(capacity)),
            ),
          ],
        ],
      ),
    );
  }

  List<_QuickSetup> _quickSetups(AppLocalizations loc) => [
    _QuickSetup(
      id: _customSetupId,
      label: loc.damageQuickSetupCustom,
      counts: const {},
    ),
    ..._quickSetupOrder
        .map((id) {
          final counts =
              _quickSetupCountsById[id] ?? const <DamageSourceKind, int>{};
          return _QuickSetup(
            id: id,
            label: _quickSetupLabel(loc, id),
            counts: counts,
          );
        })
        .where(
          (setup) => setup.counts.keys.every(_session.sources.containsKey),
        ),
  ];

  _QuickSetup? _selectedQuickSetup(List<_QuickSetup> setups) {
    final selectedId = _selectedQuickSetupId;
    if (selectedId == null) return null;
    for (final setup in setups) {
      if (setup.id == selectedId) return setup;
    }
    return null;
  }

  void _selectQuickSetup(String? id) {
    _selectedQuickSetupId = id;
    _setAttackStack(
      id == null ? const {} : _quickSetupCountsById[id] ?? const {},
    );
    _showAllSources = false;
  }

  void _applyQuickSetup(_QuickSetup setup) {
    setState(() => _selectQuickSetup(setup.id));
  }

  void _setAttackStack(Map<DamageSourceKind, int> counts) {
    for (final kind in _session.sources.keys.toList(growable: false)) {
      _session.setSourceCount(kind, counts[kind] ?? 0);
    }
  }

  void _repairSelectedQuickSetup() {
    final selectedId = _selectedQuickSetupId;
    if (selectedId == null) {
      _setAttackStack(const {});
      return;
    }
    if (selectedId == _customSetupId) return;
    final counts = _quickSetupCountsById[selectedId] ?? const {};
    if (!counts.keys.every(_session.sources.containsKey)) {
      _selectedQuickSetupId = null;
      _setAttackStack(const {});
      return;
    }
    _setAttackStack(counts);
    _showAllSources = false;
  }

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

class _QuickSetup {
  const _QuickSetup({
    required this.id,
    required this.label,
    required this.counts,
  });

  final String id;
  final String label;
  final Map<DamageSourceKind, int> counts;
}

class _QuickSetupPanel extends StatelessWidget {
  const _QuickSetupPanel({
    required this.setups,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_QuickSetup> setups;
  final String? selectedId;
  final ValueChanged<_QuickSetup> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedSetup = setups.firstWhere(
      (setup) => setup.id == selectedId,
      orElse: () => setups.first,
    );
    return SidePageHorizontalSelector<_QuickSetup>(
      values: setups,
      selected: selectedSetup,
      labelBuilder: (setup) => setup.label,
      onSelected: onSelected,
    );
  }
}

class _AccountSelectorPanel extends StatelessWidget {
  const _AccountSelectorPanel({
    required this.accountPresets,
    required this.selectedAccountTag,
    required this.onAccountChanged,
  });

  final List<DamageAccountPreset> accountPresets;
  final String? selectedAccountTag;
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SidePagePanel(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(14),
      child: accountPresets.isEmpty
          ? Row(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.damageNoAccountsAvailable,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.damageAccountPresetShort,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SidePageInlineSelector<String>(
                  selected: selectedAccountTag ?? _noAccountPreset,
                  options: {
                    _noAccountPreset: loc.damageChooseAccount,
                    for (final preset in accountPresets)
                      preset.tag:
                          '${preset.name} · ${loc.gameTownHallShortLevel(preset.townHall)}',
                  },
                  onSelected: (tag) {
                    onAccountChanged(tag == _noAccountPreset ? null : tag);
                  },
                  minWidth: double.infinity,
                  maxWidth: double.infinity,
                  height: 46,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.damageAccountSelectorHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

const _noAccountPreset = '__none__';

class _TargetEmptyPanel extends StatelessWidget {
  const _TargetEmptyPanel({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SidePagePanel(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.damageNoTargetTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.damageNoTargetBody,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              key: const ValueKey('choose-building'),
              onPressed: onChoose,
              icon: const Icon(Icons.add_rounded),
              label: Text(loc.damageChooseTarget),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
            ),
          ),
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
    required this.result,
    required this.onLevelChanged,
    required this.onRemove,
  });

  final DamageTarget target;
  final List<BuildingLevelDefinition> availableLevels;
  final DamageResult? result;
  final ValueChanged<int> onLevelChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final resolvedResult = result;
    return SidePagePanel(
      radius: AppRadius.card,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MobileWebImage(
                imageUrl: ImageAssets.getHomeVillageBuildingImage(
                  target.building.imageName,
                  target.level.level,
                ),
                width: 56,
                height: 56,
                errorWidget: (_, _, _) => const Icon(Icons.home_work_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildingDisplayName(loc, target.building.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              IconButton(
                tooltip: loc.damageRemoveBuilding,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.damageTargetLevelLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SidePageInlineSelector<int>(
                selected: target.level.level,
                options: {
                  for (final level in availableLevels)
                    level.level: loc.sideLevel(level.level),
                },
                onSelected: onLevelChanged,
                minWidth: 132,
                maxWidth: 160,
                height: 44,
              ),
            ],
          ),
          if (resolvedResult != null) ...[
            const SizedBox(height: 14),
            _TargetResultSummary(result: resolvedResult),
          ],
        ],
      ),
    );
  }
}

class _TargetResultSummary extends StatelessWidget {
  const _TargetResultSummary({required this.result});

  final DamageResult result;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = result.destroyed ? StatColors.win : colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.damageResults,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      result.destroyed
                          ? Icons.check_circle_outline_rounded
                          : Icons.shield_outlined,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      result.destroyed
                          ? loc.damageDestroyed
                          : loc.damageSurvives,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final levels = source.levelsForTownHall(townHall);
    final damageLevel = source.level(selection.level)!;
    final damageText = source.kind == DamageSourceKind.earthquake
        ? loc.damageEarthquakePercent(
            _formatNumber(damageLevel.earthquakePercent ?? 0),
          )
        : loc.damagePerUse(
            formatSidePageInt((damageLevel.damage ?? 0).round()),
          );
    final isActive = selection.count > 0;
    return SidePagePanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderColor: isActive
          ? colorScheme.secondary.withValues(alpha: AppOpacity.borderStrong)
          : null,
      child: Row(
        children: [
          MobileWebImage(
            imageUrl: source.imageUrl,
            width: 42,
            height: 42,
            errorWidget: (_, _, _) => const Icon(Icons.bolt_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sourceLabel(loc, source),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  damageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SidePageInlineSelector<int>(
                selected: selection.level,
                options: {
                  for (final level in levels)
                    level.level: loc.sideLevel(level.level),
                },
                onSelected: onLevelChanged,
                minWidth: 108,
                maxWidth: 124,
                height: 34,
              ),
              const SizedBox(height: 6),
              SidePageStepper(
                value: selection.count,
                compact: true,
                onDecrease: selection.count == 0
                    ? null
                    : () => onCountChanged(selection.count - 1),
                onIncrease: () => onCountChanged(selection.count + 1),
              ),
            ],
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

    return SidePagePanel(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.damageSpellCapacity,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              SidePageStepper(
                value: session.spellCapacity,
                onDecrease: session.spellCapacity <= 1
                    ? null
                    : () => onCapacityChanged(session.spellCapacity - 1),
                onIncrease: () => onCapacityChanged(session.spellCapacity + 1),
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
  static const _commonBuildingNames = [
    'Town Hall',
    'Inferno Tower',
    'Eagle Artillery',
    'Scattershot',
    'X-Bow',
    'Air Defense',
  ];

  String _query = '';

  List<BuildingDefinition> _commonBuildings() {
    final buildingsByName = {
      for (final building in widget.buildings) building.name: building,
    };
    return _commonBuildingNames
        .map((name) => buildingsByName[name])
        .whereType<BuildingDefinition>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final filtered = widget.buildings
        .where(
          (building) =>
              building.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList(growable: false);
    final hasQuery = _query.trim().isNotEmpty;
    final commonBuildings = hasQuery
        ? const <BuildingDefinition>[]
        : _commonBuildings();
    final commonIds = commonBuildings.map((building) => building.id).toSet();
    final remainingBuildings = hasQuery
        ? filtered
        : widget.buildings
              .where((building) => !commonIds.contains(building.id))
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
              child:
                  (hasQuery
                          ? filtered
                          : [...commonBuildings, ...remainingBuildings])
                      .isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: loc.damageNoBuildingsFound,
                      body: loc.damageTryAnotherSearch,
                    )
                  : ListView(
                      controller: controller,
                      children: [
                        if (commonBuildings.isNotEmpty) ...[
                          _PickerSectionLabel(title: loc.damageCommonBuildings),
                          for (final building in commonBuildings)
                            _buildingTile(context, building),
                        ],
                        if (remainingBuildings.isNotEmpty && !hasQuery) ...[
                          _PickerSectionLabel(title: loc.damageAllBuildings),
                          for (final building in remainingBuildings)
                            _buildingTile(context, building),
                        ],
                        if (hasQuery)
                          for (final building in filtered)
                            _buildingTile(context, building),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildingTile(BuildContext context, BuildingDefinition building) {
    final loc = AppLocalizations.of(context)!;
    final level = building.levelsForTownHall(widget.townHall).last;
    final selected = widget.selectedIds.contains(building.id);
    return ListTile(
      enabled: !selected,
      leading: MobileWebImage(
        imageUrl: ImageAssets.getHomeVillageBuildingImage(
          building.imageName,
          level.level,
        ),
        width: 44,
        height: 44,
        errorWidget: (_, _, _) => const Icon(Icons.home_work_rounded),
      ),
      title: Text(building.name),
      subtitle: Text(
        '${loc.sideLevel(level.level)} · ${loc.damageHitpoints(formatSidePageInt(level.hitpoints))}',
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded)
          : const Icon(Icons.add_rounded),
      onTap: selected ? null : () => Navigator.pop(context, building.id),
    );
  }
}

class _PickerSectionLabel extends StatelessWidget {
  const _PickerSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InlineSectionLabel extends StatelessWidget {
  const _InlineSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => SidePagePanel(
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

String _buildingDisplayName(AppLocalizations loc, String name) {
  if (name == 'Town Hall') return loc.damageTownHall;
  return name;
}

String _quickSetupLabel(AppLocalizations loc, String id) => switch (id) {
  'zap-quake' => loc.damageQuickSetupZapQuake,
  'fireball-quake' => loc.damageQuickSetupFireballQuake,
  'giant-arrow' => loc.damageQuickSetupGiantArrow,
  'flame-flinger' => loc.damageQuickSetupFlameFlinger,
  _ => loc.damageSummaryAttack,
};

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
