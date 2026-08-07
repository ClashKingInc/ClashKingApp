import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/compact_filter_chip.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_session.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_repository.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/features/upgrade_tracker/presentation/upgrade_tracker_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'side_page_components.dart';

enum _CalculatorMode { damage, farmGoal }

const _customSetupId = 'custom';
const _zapQuakeSetupId = 'zap-quake';
const _fireballQuakeSetupId = 'fireball-quake';
const _giantArrowSetupId = 'giant-arrow';
const _flameFlingerSetupId = 'flame-flinger';
const _townHallBuildingName = 'Town Hall';
const _lightningSpellName = 'Lightning Spell';
const _darkElixirResourceName = 'dark elixir';
const _defaultFarmPerfectLoot = 1013000;
const _defaultFarmDarkElixirLoot = 10250;
const _calculatorDesktopMaxWidth = 1120.0;

EdgeInsets _calculatorPagePadding(BuildContext context) {
  if (!isSidePageDesktop(context)) return sidePagePadding;
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width > _calculatorDesktopMaxWidth + 40
      ? (width - _calculatorDesktopMaxWidth) / 2
      : 20.0;
  return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32);
}

ButtonStyle _calculatorSecondaryActionStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return OutlinedButton.styleFrom(
    foregroundColor: colorScheme.onSurface,
    minimumSize: const Size(0, 44),
    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.72)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
  );
}

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({
    super.key,
    this.catalog,
    this.accountPresets,
    this.initialTrackerSnapshot,
  });

  final DamageCatalog? catalog;
  final List<DamageAccountPreset>? accountPresets;
  final UpgradeTrackerSnapshot? initialTrackerSnapshot;

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage> {
  static const _engine = DamageCalculatorEngine();
  static const _quickSetupOrder = [
    _zapQuakeSetupId,
    _fireballQuakeSetupId,
    _giantArrowSetupId,
    _flameFlingerSetupId,
  ];
  static const _quickSetupCountsById = {
    _zapQuakeSetupId: {
      DamageSourceKind.lightning: 5,
      DamageSourceKind.earthquake: 1,
    },
    _fireballQuakeSetupId: {
      DamageSourceKind.fireball: 1,
      DamageSourceKind.earthquake: 1,
    },
    _giantArrowSetupId: {DamageSourceKind.giantArrow: 1},
    _flameFlingerSetupId: {DamageSourceKind.flameFlinger: 1},
  };

  late final DamageCatalog _catalog;
  late final DamageCalculatorSession _session;
  List<DamageAccountPreset> _accountPresets = const [];
  bool _readProviders = false;
  bool _showAllSources = false;
  String? _selectedQuickSetupId;
  _CalculatorMode _calculatorMode = _CalculatorMode.damage;
  String? _farmAccountTag;
  String? _farmBuildingId;
  int? _farmBuildingLevel;
  UpgradeTrackerSnapshot? _farmTrackerSnapshot;
  String? _farmTrackerSnapshotTag;
  UpgradePlanPreferences _farmTrackerPlanPreferences =
      const UpgradePlanPreferences();
  int _farmTrackerGoldPassPercent = 0;
  bool _farmTrackerLoading = false;
  String? _farmTrackerLoadTag;
  late final TextEditingController _farmAverageLootController;

  @override
  void initState() {
    super.initState();
    _catalog =
        widget.catalog ?? DamageCatalog.fromBundle(GameDataService.bundleData);
    _session = DamageCalculatorSession(_catalog);
    _selectedQuickSetupId = _customSetupId;
    _accountPresets = widget.accountPresets ?? const [];
    _farmAverageLootController = TextEditingController(
      text: _defaultFarmPerfectLoot.toString(),
    );
    _selectInitialAccount();
    _setFarmLootSuggestion();
  }

  @override
  void dispose() {
    _farmAverageLootController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_readProviders) {
      _readProviders = true;
      if (widget.accountPresets == null) {
        try {
          final accounts = context.read<CocAccountService>();
          _accountPresets = _verifiedAccountPresets(
            accounts,
            context.read<PlayerService>(),
          );
          _selectInitialAccount(preferredTag: accounts.selectedTag);
          _setFarmLootSuggestion();
        } on ProviderNotFoundException {
          _accountPresets = const [];
        }
      }
    }
    _startFarmTrackerLoad(_farmAccountTag);
  }

  @override
  Widget build(BuildContext context) {
    if (_calculatorMode == _CalculatorMode.farmGoal) {
      return _buildFarmGoalScaffold();
    }
    if (_catalog.buildings.isEmpty || _catalog.sources.isEmpty) {
      return _buildMissingDataScaffold(context);
    }

    return _buildDamageScaffold(context);
  }

  Widget _buildFarmGoalScaffold() {
    final farmPreset = _farmSelectedPreset;
    final farmTownHall = farmPreset?.townHall ?? _catalog.maxTownHall;
    final farmBuildings = _catalog.buildingsForTownHall(farmTownHall);
    final trackerTargets = _farmTrackerTargets(farmBuildings);
    final selectableFarmBuildings = _farmSelectableBuildings(farmBuildings);
    final farmBuilding = _farmSelectedBuilding(selectableFarmBuildings);
    final farmLevels = _farmTargetLevels(farmBuilding, farmTownHall);

    return _CalculatorScaffold(
      selectedMode: _calculatorMode,
      onModeChanged: _selectCalculatorMode,
      child: ListView(
        key: const ValueKey('farm-goal-scroll'),
        padding: _calculatorPagePadding(context),
        children: [
          _FarmGoalView(
            accountPresets: _accountPresets,
            selectedAccount: farmPreset,
            onOpenAccountPicker: () => _showAccountPicker(forFarmGoal: true),
            onOpenBuildingPicker: () => _showFarmBuildingPicker(
              buildings: selectableFarmBuildings,
              townHall: farmTownHall,
              trackerTargets: trackerTargets,
            ),
            selectedBuilding: farmBuilding,
            levels: farmLevels,
            selectedLevel: _farmSelectedLevel(farmLevels),
            trackerSuggestion: trackerTargets.firstOrNull,
            trackerLoading: _farmTrackerLoading,
            trackerDataMissing:
                farmPreset != null &&
                !_farmTrackerLoading &&
                _farmTrackerSnapshot == null,
            trackerPlanComplete:
                farmPreset != null &&
                !_farmTrackerLoading &&
                _farmTrackerSnapshot != null &&
                trackerTargets.isEmpty,
            onOpenUpgradeTracker: _openUpgradeTracker,
            onUseTrackerSuggestion: _useFarmTrackerSuggestion,
            onLevelChanged: _selectFarmBuildingLevel,
            averageLootController: _farmAverageLootController,
            onLootChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingDataScaffold(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _CalculatorScaffold(
      selectedMode: _calculatorMode,
      onModeChanged: _selectCalculatorMode,
      child: ListView(
        key: const ValueKey('calculators-scroll'),
        padding: _calculatorPagePadding(context),
        children: [
          AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: loc.damageNoStaticDataTitle,
            body: loc.damageNoStaticDataBody,
          ),
        ],
      ),
    );
  }

  Widget _buildDamageScaffold(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final targets = _session.resolvedTargets();
    final stack = _session.resolvedStack();
    final results = _engine.evaluateAll(targets, stack);
    final resultByTargetId = {
      for (final result in results) result.target.id: result,
    };
    final quickSetups = _quickSetups(loc);
    final selectedSetup = _selectedQuickSetup(quickSetups);
    final sourceVisibility = _damageSourceVisibility(selectedSetup);
    final showZapQuakeOptimizer =
        selectedSetup?.id == _zapQuakeSetupId && targets.isNotEmpty;

    return _CalculatorScaffold(
      selectedMode: _calculatorMode,
      onModeChanged: _selectCalculatorMode,
      child: ListView(
        key: const ValueKey('damage-calculator-scroll'),
        padding: _calculatorPagePadding(context),
        children: [
          SidePageSectionHeader(title: loc.damageAccountPresetShort),
          _AccountSelectorPanel(
            accountPresets: _accountPresets,
            selectedAccount: _accountPreset(_session.selectedAccountTag),
            onOpenAccountPicker: () => _showAccountPicker(forFarmGoal: false),
            showHeading: false,
          ),
          const SizedBox(height: 22),
          ..._targetSectionWidgets(context, loc, targets, resultByTargetId),
          ..._attackStackSectionWidgets(
            loc,
            quickSetups: quickSetups,
            selectedSetup: selectedSetup,
            sourceVisibility: sourceVisibility,
          ),
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

  List<Widget> _targetSectionWidgets(
    BuildContext context,
    AppLocalizations loc,
    List<DamageTarget> targets,
    Map<String, DamageResult> resultByTargetId,
  ) {
    return [
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
            onRemove: () => setState(() => _session.removeTarget(target.id)),
          ),
          const SizedBox(height: 10),
        ],
        _AddBuildingButton(
          enabled: _session.availableBuildings.length != targets.length,
          onPressed: _showBuildingPicker,
        ),
      ],
    ];
  }

  List<Widget> _attackStackSectionWidgets(
    AppLocalizations loc, {
    required List<_QuickSetup> quickSetups,
    required _QuickSetup? selectedSetup,
    required _DamageSourceVisibility sourceVisibility,
  }) {
    return [
      const SizedBox(height: 22),
      SidePageSectionHeader(title: loc.damageAttackStack),
      _QuickSetupPanel(
        setups: quickSetups,
        selectedId: selectedSetup?.id,
        onSelected: _applyQuickSetup,
      ),
      const SizedBox(height: 14),
      ..._sourceSectionWidgets(loc, selectedSetup, sourceVisibility),
    ];
  }

  List<Widget> _sourceSectionWidgets(
    AppLocalizations loc,
    _QuickSetup? selectedSetup,
    _DamageSourceVisibility sourceVisibility,
  ) {
    if (selectedSetup == null) {
      return [_InlineEmpty(message: loc.damageNoActiveSources)];
    }
    if (_session.availableSources.isEmpty) {
      return [_InlineEmpty(message: loc.damageNoSourcesForTownHall)];
    }

    return [
      ..._sourceRows(sourceVisibility.primarySources),
      if (sourceVisibility.extraSources.isNotEmpty) ...[
        if (_showAllSources) _InlineSectionLabel(title: loc.damageOtherSources),
        ..._sourceRows(sourceVisibility.visibleExtraSources),
        _ShowAllSourcesButton(
          expanded: _showAllSources,
          onPressed: () => setState(() => _showAllSources = !_showAllSources),
        ),
      ],
    ];
  }

  List<Widget> _sourceRows(List<DamageSourceDefinition> sources) => [
    for (final source in sources) ...[
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
  ];

  void _applyAccountPresetTag(String? tag) {
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
  }

  void _selectInitialAccount({String? preferredTag}) {
    final preferredPreset = _accountPreset(preferredTag);
    final preset = preferredPreset ?? _accountPresets.firstOrNull;
    _farmAccountTag = preset?.tag;
    if (preset == null) return;

    _session.applyPreset(preset);
    _repairSelectedQuickSetup();
  }

  _DamageSourceVisibility _damageSourceVisibility(_QuickSetup? selectedSetup) {
    final availableSources = _session.availableSources;
    if (selectedSetup == null) return const _DamageSourceVisibility();
    if (selectedSetup.id == _customSetupId) {
      return _DamageSourceVisibility(primarySources: availableSources);
    }

    final selectedSourceKinds = selectedSetup.counts.keys.toSet();
    final primarySources = availableSources
        .where(
          (source) =>
              selectedSourceKinds.contains(source.kind) ||
              (_session.sources[source.kind]?.count ?? 0) > 0,
        )
        .toList(growable: false);
    final visiblePrimaryKinds = primarySources.map((source) => source.kind);
    final extraSources = availableSources
        .where((source) => !visiblePrimaryKinds.contains(source.kind))
        .toList(growable: false);

    return _DamageSourceVisibility(
      primarySources: primarySources,
      extraSources: extraSources,
      visibleExtraSources: _showAllSources
          ? extraSources
          : const <DamageSourceDefinition>[],
    );
  }

  void _selectCalculatorMode(_CalculatorMode mode) {
    if (mode == _calculatorMode) return;
    setState(() => _calculatorMode = mode);
  }

  DamageAccountPreset? get _farmSelectedPreset {
    final tag = _farmAccountTag;
    if (tag == null) return null;
    for (final preset in _accountPresets) {
      if (preset.tag == tag) return preset;
    }
    return null;
  }

  BuildingDefinition? _farmSelectedBuilding(
    List<BuildingDefinition> buildings,
  ) {
    final selectedId = _farmBuildingId;
    if (selectedId == null) return null;
    for (final building in buildings) {
      if (building.id == selectedId) return building;
    }
    return null;
  }

  BuildingLevelDefinition? _farmSelectedLevel(
    List<BuildingLevelDefinition> levels,
  ) {
    if (levels.isEmpty) return null;
    final selectedLevel = _farmBuildingLevel;
    if (selectedLevel != null) {
      for (final level in levels) {
        if (level.level == selectedLevel) return level;
      }
    }
    return levels.last;
  }

  void _selectFarmAccount(String? tag) {
    if (tag == _farmAccountTag) return;

    setState(() {
      _farmAccountTag = tag;
      _farmBuildingId = null;
      _farmBuildingLevel = null;
      _farmTrackerSnapshot = null;
      _farmTrackerSnapshotTag = null;
      _farmTrackerPlanPreferences = const UpgradePlanPreferences();
      _farmTrackerGoldPassPercent = 0;
      _farmTrackerLoading = false;
      _setFarmLootSuggestion();
    });
    _startFarmTrackerLoad(tag);
  }

  DamageAccountPreset? _accountPreset(String? tag) {
    if (tag == null) return null;
    return _accountPresets.where((preset) => preset.tag == tag).firstOrNull;
  }

  void _startFarmTrackerLoad(String? tag) {
    if (tag == null || tag.isEmpty) {
      _farmTrackerLoadTag = tag;
      _farmTrackerSnapshot = null;
      _farmTrackerSnapshotTag = null;
      _farmTrackerPlanPreferences = const UpgradePlanPreferences();
      _farmTrackerGoldPassPercent = 0;
      _farmTrackerLoading = false;
      return;
    }
    final initialSnapshot = widget.initialTrackerSnapshot;
    if (initialSnapshot != null) {
      _farmTrackerLoadTag = tag;
      _farmTrackerSnapshot = initialSnapshot;
      _farmTrackerSnapshotTag = tag;
      _farmTrackerLoading = false;
      _repairFarmSelectionAfterTrackerLoad();
      return;
    }
    if (tag == _farmTrackerLoadTag &&
        (_farmTrackerLoading || _farmTrackerSnapshotTag == tag)) {
      return;
    }
    _farmTrackerLoadTag = tag;
    _farmTrackerSnapshot = null;
    _farmTrackerSnapshotTag = null;
    final cached = UpgradeTrackerRepository.shared.peekCached(tag);
    if (cached != null) {
      _farmTrackerSnapshot = cached;
      _farmTrackerSnapshotTag = tag;
      _farmTrackerLoading = false;
      _repairFarmSelectionAfterTrackerLoad();
      unawaited(_loadFarmTrackerPreferences(tag, cached));
      return;
    }
    // Injected presets are used by isolated screens/tests and do not carry
    // the authenticated tracker configuration. Avoid starting an auxiliary
    // SharedPreferences/network load in that mode; a warmed shared snapshot
    // is still used above when one exists.
    if (widget.accountPresets != null) {
      _farmTrackerLoadTag = null;
      _farmTrackerLoading = false;
      return;
    }
    _farmTrackerLoading = true;
    unawaited(_loadFarmTrackerSnapshot(tag));
  }

  Future<void> _loadFarmTrackerSnapshot(String tag) async {
    try {
      final snapshot = await UpgradeTrackerRepository.shared.load(tag);
      if (!mounted || tag != _farmAccountTag) return;
      final draft = snapshot == null
          ? null
          : await UpgradeTrackerRepository.shared.loadPlanPreferences(tag);
      if (!mounted || tag != _farmAccountTag) return;
      setState(() {
        _farmTrackerSnapshot = snapshot;
        _farmTrackerSnapshotTag = snapshot == null ? null : tag;
        _farmTrackerLoadTag = snapshot == null ? null : tag;
        _farmTrackerLoading = false;
        _applyFarmTrackerPreferences(snapshot, draft);
        _repairFarmSelectionAfterTrackerLoad();
      });
    } catch (_) {
      if (!mounted || tag != _farmAccountTag) return;
      setState(() {
        _farmTrackerSnapshot = null;
        _farmTrackerSnapshotTag = null;
        _farmTrackerLoadTag = null;
        _farmTrackerLoading = false;
      });
    }
  }

  Future<void> _loadFarmTrackerPreferences(
    String tag,
    UpgradeTrackerSnapshot snapshot,
  ) async {
    try {
      final draft = await UpgradeTrackerRepository.shared.loadPlanPreferences(
        tag,
      );
      if (!mounted || tag != _farmAccountTag) return;
      setState(() => _applyFarmTrackerPreferences(snapshot, draft));
    } catch (_) {
      // The snapshot still provides a useful recommendation with defaults.
    }
  }

  void _applyFarmTrackerPreferences(
    UpgradeTrackerSnapshot? snapshot,
    Map<String, dynamic>? draft,
  ) {
    _farmTrackerPlanPreferences = UpgradePlanPreferences.fromJson(
      draft?['heuristics'] is Map
          ? Map<String, dynamic>.from(draft!['heuristics'] as Map)
          : null,
    );
    final detectedGoldPass = snapshot == null
        ? 0
        : [
            snapshot.boosts.builderCostReductionPercent,
            snapshot.boosts.builderTimeReductionPercent,
            snapshot.boosts.labCostReductionPercent,
            snapshot.boosts.labTimeReductionPercent,
          ].reduce((a, b) => a > b ? a : b);
    final savedGoldPass = draft?['gold_pass_percent'];
    final parsedGoldPass = savedGoldPass is num
        ? savedGoldPass.toInt()
        : int.tryParse(savedGoldPass?.toString() ?? '');
    _farmTrackerGoldPassPercent = (parsedGoldPass ?? detectedGoldPass).clamp(
      0,
      100,
    );
  }

  List<_FarmTrackerTarget> _farmTrackerTargets(
    List<BuildingDefinition> buildings,
  ) {
    final snapshot = _farmTrackerSnapshot;
    if (snapshot == null || _farmTrackerSnapshotTag != _farmAccountTag) {
      return const [];
    }
    final townHall = _farmSelectedPreset?.townHall ?? _catalog.maxTownHall;
    final buildingsByName = {
      for (final building in buildings)
        building.name.trim().toLowerCase(): building,
    };
    final ordered = <_FarmTrackerTarget>[];
    final seen = <String>{};

    final now = DateTime.now();
    final planned =
        snapshot
            .buildPlan(
              queue: UpgradeQueue.builders,
              strategy: UpgradePlanStrategy.balanced,
              village: UpgradeVillage.home,
              startsAt: now,
              goldPassPercent: _farmTrackerGoldPassPercent,
              preferences: normalizeUpgradePlanPreferencesForQueue(
                snapshot,
                _farmTrackerPlanPreferences,
                UpgradeVillage.home,
                UpgradeQueue.builders,
              ),
            )
            .expand((lane) => lane.upgrades)
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    for (final upgrade in planned) {
      final target = _resolveFarmTrackerTarget(
        upgrade.item,
        plannedStep: upgrade.step,
        plannedCosts: upgrade.costs,
        buildingsByName: buildingsByName,
        seen: seen,
        townHall: townHall,
      );
      if (target != null) ordered.add(target);
    }
    for (final item in snapshot.itemsFor(
      village: UpgradeVillage.home,
      queue: UpgradeQueue.builders,
      remainingOnly: true,
    )) {
      if (snapshot.remainingActiveSeconds(item, now: now) > 0) continue;
      final target = _resolveFarmTrackerTarget(
        item,
        buildingsByName: buildingsByName,
        seen: seen,
        townHall: townHall,
      );
      if (target != null) ordered.add(target);
    }
    return ordered;
  }

  _FarmTrackerTarget? _resolveFarmTrackerTarget(
    UpgradeTrackerItem item, {
    UpgradeStep? plannedStep,
    List<UpgradeCost>? plannedCosts,
    required Map<String, BuildingDefinition> buildingsByName,
    required Set<String> seen,
    required int townHall,
  }) {
    if (item.isComplete || item.steps.isEmpty) return null;
    final validSteps = item.steps.where(
      (candidate) => candidate.targetLevel > item.currentLevel,
    );
    final resolvedStep =
        plannedStep != null && plannedStep.targetLevel > item.currentLevel
        ? plannedStep
        : validSteps.firstOrNull;
    if (resolvedStep == null) return null;

    final name = item.name.trim().toLowerCase();
    final building = buildingsByName[name];
    if (building == null) return null;
    final levelIsAvailable = _farmTargetLevels(
      building,
      townHall,
    ).any((level) => level.level == resolvedStep.targetLevel);
    if (!levelIsAvailable || !seen.add(name)) return null;

    return _FarmTrackerTarget(
      item: item,
      plannedStep: resolvedStep,
      plannedCosts: identical(resolvedStep, plannedStep) ? plannedCosts : null,
    );
  }

  List<BuildingDefinition> _farmSelectableBuildings(
    List<BuildingDefinition> buildings,
  ) {
    final snapshot = _farmTrackerSnapshot;
    if (snapshot == null || _farmTrackerSnapshotTag != _farmAccountTag) {
      return buildings;
    }
    final trackerItemsByName = <String, List<UpgradeTrackerItem>>{};
    for (final item in snapshot.itemsFor(
      village: UpgradeVillage.home,
      queue: UpgradeQueue.builders,
    )) {
      trackerItemsByName
          .putIfAbsent(item.name.trim().toLowerCase(), () => [])
          .add(item);
    }
    final now = DateTime.now();
    return buildings
        .where((building) {
          final matching =
              trackerItemsByName[building.name.trim().toLowerCase()];
          if (matching == null || matching.isEmpty) return true;
          return matching.any(
            (item) => _hasUnpaidFarmUpgrade(snapshot, item, now),
          );
        })
        .toList(growable: false);
  }

  bool _hasUnpaidFarmUpgrade(
    UpgradeTrackerSnapshot snapshot,
    UpgradeTrackerItem item,
    DateTime now,
  ) {
    if (item.isComplete) return false;
    final isActive = snapshot.remainingActiveSeconds(item, now: now) > 0;
    final unpaidSteps = isActive ? item.steps.skip(1) : item.steps;
    return unpaidSteps.any((step) => step.targetLevel > item.currentLevel);
  }

  void _repairFarmSelectionAfterTrackerLoad() {
    final selectedId = _farmBuildingId;
    if (selectedId == null) return;
    final townHall = _farmSelectedPreset?.townHall ?? _catalog.maxTownHall;
    final selectableBuildings = _farmSelectableBuildings(
      _catalog.buildingsForTownHall(townHall),
    );
    if (selectableBuildings.any((building) => building.id == selectedId)) {
      return;
    }
    _farmBuildingId = null;
    _farmBuildingLevel = null;
    _setFarmLootSuggestion();
  }

  void _useFarmTrackerSuggestion(_FarmTrackerTarget target) {
    final item = target.item;
    final building = _catalog.buildings
        .where(
          (candidate) =>
              candidate.name.trim().toLowerCase() ==
              item.name.trim().toLowerCase(),
        )
        .firstOrNull;
    if (building == null) return;
    final farmTownHall = _farmSelectedPreset?.townHall ?? _catalog.maxTownHall;
    final levels = _farmTargetLevels(building, farmTownHall);
    final targetLevel = target.targetLevel ?? item.steps.first.targetLevel;
    final matchingLevel = levels
        .where((level) => level.level == targetLevel)
        .firstOrNull;
    if (matchingLevel == null) return;
    setState(() {
      _farmBuildingId = building.id;
      _farmBuildingLevel = matchingLevel.level;
      _setFarmLootSuggestion();
    });
  }

  Future<void> _openUpgradeTracker() async {
    final tag = _farmAccountTag;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => UpgradeTrackerPage(initialTag: tag)),
    );
    if (!mounted) return;
    _farmTrackerLoadTag = null;
    _startFarmTrackerLoad(tag);
  }

  Future<void> _showAccountPicker({required bool forFarmGoal}) async {
    if (_accountPresets.isEmpty) return;
    final selectedTag = forFarmGoal
        ? _farmAccountTag
        : _session.selectedAccountTag;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CalculatorAccountPickerSheet(
        accountPresets: _accountPresets,
        selectedTag: selectedTag,
        allowCustom: true,
      ),
    );
    if (!mounted || result == null) return;
    final accountTag = result == _accountlessPresetTag ? null : result;
    if (forFarmGoal) {
      _selectFarmAccount(accountTag);
    } else {
      _applyAccountPresetTag(accountTag);
    }
  }

  void _selectFarmBuilding(String buildingId) {
    final farmPreset = _farmSelectedPreset;
    final townHall = farmPreset?.townHall ?? _catalog.maxTownHall;
    final building = _catalog
        .buildingsForTownHall(townHall)
        .firstWhere((candidate) => candidate.id == buildingId);
    final levels = _farmTargetLevels(building, townHall);
    setState(() {
      _farmBuildingId = buildingId;
      _farmBuildingLevel = levels.isEmpty ? null : levels.last.level;
      _setFarmLootSuggestion();
    });
  }

  void _selectFarmBuildingLevel(int level) {
    setState(() {
      _farmBuildingLevel = level;
      _setFarmLootSuggestion();
    });
  }

  void _setFarmLootSuggestion() {
    final farmPreset = _farmSelectedPreset;
    final farmTownHall = farmPreset?.townHall ?? _catalog.maxTownHall;
    final building = _farmSelectedBuilding(
      _catalog.buildingsForTownHall(farmTownHall),
    );
    final levels = _farmTargetLevels(building, farmTownHall);
    final level = _farmSelectedLevel(levels);
    final resource = level?.upgradeResource ?? 'Gold';
    _farmAverageLootController.text = _farmDefaultVillageLoot(
      resource: resource,
    ).toString();
  }

  List<BuildingLevelDefinition> _farmTargetLevels(
    BuildingDefinition? building,
    int townHall,
  ) {
    if (building == null) return const <BuildingLevelDefinition>[];
    final targetTownHall =
        building.name == _townHallBuildingName &&
            townHall < _catalog.maxTownHall
        ? townHall + 1
        : townHall;
    return building.levelsForTownHall(targetTownHall);
  }

  String? _quickSetupImageUrl(Map<DamageSourceKind, int> counts) {
    for (final kind in counts.keys) {
      final imageUrl = _session.catalog.source(kind)?.imageUrl.trim();
      if (imageUrl?.isNotEmpty == true) return imageUrl;
    }
    return null;
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
            imageUrl: _quickSetupImageUrl(counts),
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
      _selectedQuickSetupId = _customSetupId;
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
    final result = await showModalBottomSheet<_BuildingPickerSelection>(
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
      setState(() => _session.addTarget(result.buildingId));
    }
  }

  Future<void> _showFarmBuildingPicker({
    required List<BuildingDefinition> buildings,
    required int townHall,
    required List<_FarmTrackerTarget> trackerTargets,
  }) async {
    final result = await showModalBottomSheet<_BuildingPickerSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _BuildingPicker(
        buildings: buildings,
        selectedIds: const {},
        townHall: townHall,
        trackerTargets: trackerTargets.take(1).toList(growable: false),
      ),
    );
    if (result == null || !mounted) return;
    final trackerTarget = result.trackerTarget;
    if (trackerTarget != null) {
      _useFarmTrackerSuggestion(trackerTarget);
    } else {
      _selectFarmBuilding(result.buildingId);
    }
  }
}

class _DamageSourceVisibility {
  const _DamageSourceVisibility({
    this.primarySources = const <DamageSourceDefinition>[],
    this.extraSources = const <DamageSourceDefinition>[],
    this.visibleExtraSources = const <DamageSourceDefinition>[],
  });

  final List<DamageSourceDefinition> primarySources;
  final List<DamageSourceDefinition> extraSources;
  final List<DamageSourceDefinition> visibleExtraSources;
}

class _CalculatorScaffold extends StatelessWidget {
  const _CalculatorScaffold({
    required this.selectedMode,
    required this.onModeChanged,
    required this.child,
  });

  final _CalculatorMode selectedMode;
  final ValueChanged<_CalculatorMode> onModeChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: InfoProfileTabScaffold(
        key: const ValueKey('calculator-tabs'),
        header: _CalculatorHeader(selectedMode: selectedMode),
        selectedIndex: selectedMode.index,
        onTabSelected: (index) => onModeChanged(
          _CalculatorMode.values[index.clamp(
            0,
            _CalculatorMode.values.length - 1,
          )],
        ),
        tabs: [
          InfoProfileTabData(
            label: loc.calculatorsModeDamage,
            imageUrl: ImageAssets.getSpellImage(_lightningSpellName),
          ),
          InfoProfileTabData(
            label: loc.calculatorsModeFarmGoal,
            imageUrl: ImageAssets.lootCart,
          ),
        ],
        body: child,
      ),
    );
  }
}

class _CalculatorHeader extends StatelessWidget {
  const _CalculatorHeader({required this.selectedMode});

  final _CalculatorMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopWeb = isSidePageDesktop(context);
    final scaledBodyHeight = media.textScaler.scale(16);
    final mobileTextScaleAllowance = ((scaledBodyHeight - 16) * 1.5).clamp(
      0.0,
      72.0,
    );
    final imageHeight =
        media.padding.top +
        (isDesktopWeb ? 292 : 332 + mobileTextScaleAllowance);
    final loc = AppLocalizations.of(context)!;
    final isDamage = selectedMode == _CalculatorMode.damage;
    final backgroundImageUrl = isDamage
        ? ImageAssets.playerWarStatsPageBackground
        : ImageAssets.homeBaseBackground;
    final artworkUrl = isDamage
        ? ImageAssets.getSpellImage(_lightningSpellName)
        : ImageAssets.lootCart;
    final fallbackIcon = isDamage
        ? Icons.bolt_rounded
        : Icons.home_work_rounded;
    final subtitle = isDamage
        ? loc.damageCalculatorSubtitle
        : loc.farmGoalFormTitle;

    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(
            imageUrl: backgroundImageUrl,
            fallbackImageUrls: const [
              ImageAssets.homeBaseBackground,
              ImageAssets.builderBaseBackground,
            ],
            height: imageHeight,
          ),
        ),
        SizedBox(
          height: imageHeight,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktopWeb ? 20 : 12,
                0,
                isDesktopWeb ? 20 : 12,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        iconColor: Colors.white,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onTap: () => Navigator.of(context).maybePop(),
                        showBackground: false,
                      ),
                      const Spacer(),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _calculatorDesktopMaxWidth,
                        ),
                        child: _CalculatorHeroIdentity(
                          imageUrl: artworkUrl,
                          fallbackIcon: fallbackIcon,
                          title: loc.calculatorsTitle,
                          subtitle: subtitle,
                          horizontal: isDesktopWeb,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktopWeb ? CKSpacing.lg : CKSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalculatorHeroIdentity extends StatelessWidget {
  const _CalculatorHeroIdentity({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.horizontal,
  });

  final String imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final artwork = ExcludeSemantics(
      child: SizedBox.square(
        key: const ValueKey('calculator-hero-artwork'),
        dimension: horizontal ? 104 : 112,
        child: MobileWebImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) =>
              Icon(fallbackIcon, color: Colors.white, size: 42),
        ),
      ),
    );
    final copy = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: horizontal ? 520 : 330),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: horizontal
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: horizontal ? TextAlign.start : TextAlign.center,
            style: CKTypography.of(
              context,
              CKTextRole.screenTitle,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: CKSpacing.sm),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: horizontal ? TextAlign.start : TextAlign.center,
            style: CKTypography.of(
              context,
              CKTextRole.body,
            ).copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          artwork,
          const SizedBox(width: CKSpacing.xl),
          copy,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        artwork,
        const SizedBox(height: CKSpacing.md),
        copy,
      ],
    );
  }
}

class _QuickSetup {
  const _QuickSetup({
    required this.id,
    required this.label,
    required this.counts,
    this.imageUrl,
  });

  final String id;
  final String label;
  final Map<DamageSourceKind, int> counts;
  final String? imageUrl;
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
    return Wrap(
      key: const ValueKey('calculator-quick-setups'),
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final setup in setups)
          CompactFilterChip(
            label: setup.label,
            icon: _quickSetupIcon(setup.id),
            imageUrl: setup.imageUrl,
            selected: setup.id == selectedSetup.id,
            onTap: () => onSelected(setup),
          ),
      ],
    );
  }
}

class _FarmTrackerTarget {
  const _FarmTrackerTarget({
    required this.item,
    this.plannedStep,
    this.plannedCosts,
  });

  final UpgradeTrackerItem item;
  final UpgradeStep? plannedStep;
  final List<UpgradeCost>? plannedCosts;

  int? get targetLevel => plannedStep?.targetLevel;
  List<UpgradeCost> get costs => plannedCosts ?? plannedStep?.costs ?? const [];
}

class _FarmTargetPanelData {
  const _FarmTargetPanelData({
    required this.resourceLabel,
    required this.upgradeCost,
    required this.trackerSuggestion,
    required this.trackerLoading,
    required this.trackerDataMissing,
    required this.trackerPlanComplete,
    required this.onOpenUpgradeTracker,
  });

  final String resourceLabel;
  final int? upgradeCost;
  final _FarmTrackerTarget? trackerSuggestion;
  final bool trackerLoading;
  final bool trackerDataMissing;
  final bool trackerPlanComplete;
  final VoidCallback onOpenUpgradeTracker;
}

class _FarmGoalView extends StatelessWidget {
  const _FarmGoalView({
    required this.accountPresets,
    required this.selectedAccount,
    required this.onOpenAccountPicker,
    required this.onOpenBuildingPicker,
    required this.selectedBuilding,
    required this.levels,
    required this.selectedLevel,
    required this.trackerSuggestion,
    required this.trackerLoading,
    required this.trackerDataMissing,
    required this.trackerPlanComplete,
    required this.onOpenUpgradeTracker,
    required this.onUseTrackerSuggestion,
    required this.onLevelChanged,
    required this.averageLootController,
    required this.onLootChanged,
  });

  final List<DamageAccountPreset> accountPresets;
  final DamageAccountPreset? selectedAccount;
  final VoidCallback onOpenAccountPicker;
  final VoidCallback onOpenBuildingPicker;
  final BuildingDefinition? selectedBuilding;
  final List<BuildingLevelDefinition> levels;
  final BuildingLevelDefinition? selectedLevel;
  final _FarmTrackerTarget? trackerSuggestion;
  final bool trackerLoading;
  final bool trackerDataMissing;
  final bool trackerPlanComplete;
  final VoidCallback onOpenUpgradeTracker;
  final ValueChanged<_FarmTrackerTarget> onUseTrackerSuggestion;
  final ValueChanged<int> onLevelChanged;
  final TextEditingController averageLootController;
  final VoidCallback onLootChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final villageLoot = _parseFarmAmount(averageLootController.text);
    final trackerCost = _trackerCostForSelection(
      trackerSuggestion,
      selectedBuilding,
      selectedLevel,
    );
    final selectedResource =
        trackerCost?.resource ?? selectedLevel?.upgradeResource ?? 'Gold';
    final resourceLabel = _upgradeResourceLabel(loc, selectedResource) ?? '';
    final upgradeCost =
        trackerCost?.amount.round() ?? selectedLevel?.upgradeCost;
    final leagueEstimate = _farmLeagueLootEstimate(
      league: selectedAccount?.league,
      townHall: selectedAccount?.townHall ?? 0,
      resource: selectedResource,
    );
    final perfectLoot = villageLoot + (leagueEstimate?.loot ?? 0);
    final scenarios = _farmAttackScenarios(
      upgradeCost: upgradeCost,
      perfectLoot: perfectLoot,
    );
    final suggestedTarget = trackerSuggestion;
    final trackerSuggestionIsSelected =
        suggestedTarget != null &&
        selectedBuilding != null &&
        selectedLevel != null &&
        suggestedTarget.item.name.trim().toLowerCase() ==
            selectedBuilding!.name.trim().toLowerCase() &&
        suggestedTarget.targetLevel == selectedLevel!.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SidePageSectionHeader(title: loc.farmGoalAccountTitle),
        _AccountSelectorPanel(
          accountPresets: accountPresets,
          selectedAccount: selectedAccount,
          onOpenAccountPicker: onOpenAccountPicker,
          hint: loc.farmGoalAccountHint,
          showHeading: false,
        ),
        const SizedBox(height: 22),
        SidePageSectionHeader(title: loc.farmGoalTargetTitle),
        _buildTargetPanel(
          context,
          loc,
          _FarmTargetPanelData(
            resourceLabel: resourceLabel,
            upgradeCost: upgradeCost,
            trackerSuggestion: trackerSuggestionIsSelected
                ? null
                : trackerSuggestion,
            trackerLoading: trackerLoading,
            trackerDataMissing: trackerDataMissing,
            trackerPlanComplete: trackerPlanComplete,
            onOpenUpgradeTracker: onOpenUpgradeTracker,
          ),
        ),
        const SizedBox(height: 22),
        SidePageSectionHeader(title: loc.farmGoalLootTitle),
        _buildLootPanel(
          context,
          loc,
          resource: selectedResource,
          resourceLabel: resourceLabel,
          leagueEstimate: leagueEstimate,
        ),
        const SizedBox(height: 16),
        if (scenarios.isEmpty)
          _InlineEmpty(
            message: _farmMissingMessage(
              loc,
              upgradeCost: upgradeCost,
              resourceLabel: resourceLabel,
            ),
          )
        else
          _FarmGoalResultPanel(
            scenarios: scenarios,
            upgradeCost: upgradeCost!,
            resourceLabel: resourceLabel,
            perfectLoot: perfectLoot,
          ),
      ],
    );
  }

  List<_FarmAttackScenario> _farmAttackScenarios({
    required int? upgradeCost,
    required int perfectLoot,
  }) {
    if (upgradeCost == null || upgradeCost <= 0 || perfectLoot <= 0) {
      return const [];
    }
    return [100, 80, 60]
        .map((percent) {
          final lootPerAttack = (perfectLoot * percent / 100).round();
          return _FarmAttackScenario(
            destructionPercent: percent,
            lootPerAttack: lootPerAttack,
            attacks: (upgradeCost / lootPerAttack).ceil(),
          );
        })
        .toList(growable: false);
  }

  String _farmMissingMessage(
    AppLocalizations loc, {
    required int? upgradeCost,
    required String resourceLabel,
  }) {
    if (selectedBuilding == null) return loc.farmGoalMissingTarget;
    if (upgradeCost == null || resourceLabel.isEmpty) {
      return loc.farmGoalCostUnavailable;
    }
    return loc.farmGoalMissingValues;
  }

  Widget _buildTargetPanel(
    BuildContext context,
    AppLocalizations loc,
    _FarmTargetPanelData data,
  ) {
    final trackerSuggestion = data.trackerSuggestion;
    return CKSectionPanel(
      key: const ValueKey('farm-goal-target'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.trackerLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(
                height: 44,
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
              ),
            )
          else if (trackerSuggestion != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.farmGoalTrackerNextTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CKUpgradeRow(
                    key: const ValueKey('farm-goal-tracker-suggestion'),
                    leading: MobileWebImage(
                      imageUrl: ImageAssets.getHomeVillageBuildingImage(
                        trackerSuggestion.item.name,
                        trackerSuggestion.targetLevel ??
                            trackerSuggestion
                                .item
                                .steps
                                .firstOrNull
                                ?.targetLevel ??
                            1,
                      ),
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => Icon(
                        Icons.construction_rounded,
                        size: 28,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: _buildingDisplayName(
                      loc,
                      trackerSuggestion.item.name,
                    ),
                    subtitle: [
                      if (trackerSuggestion.targetLevel != null)
                        '${loc.sideLevel(trackerSuggestion.item.currentLevel)} → ${loc.sideLevel(trackerSuggestion.targetLevel!)}',
                      ...trackerSuggestion.costs.map((cost) {
                        final resource =
                            _upgradeResourceLabel(loc, cost.resource) ??
                            cost.resource;
                        return '${formatSidePageInt(cost.amount.round())} $resource';
                      }),
                    ].join(' · '),
                    accentColor: Colors.transparent,
                    trailing: Icon(
                      Icons.arrow_forward_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => onUseTrackerSuggestion(trackerSuggestion),
                  ),
                ],
              ),
            ),
          if (data.trackerDataMissing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UpgradeTrackerImportPrompt(
                onOpenUpgradeTracker: data.onOpenUpgradeTracker,
              ),
            ),
          if (data.trackerPlanComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.farmGoalTrackerPlanComplete,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (selectedBuilding == null || selectedLevel == null)
            _BuildingEmptyContent(
              title: loc.farmGoalNoTargetTitle,
              body: loc.farmGoalNoTargetBody,
              actionLabel: loc.farmGoalChooseBuilding,
              buttonKey: const ValueKey('farm-goal-building'),
              onChoose: onOpenBuildingPicker,
            )
          else ...[
            _FarmGoalTargetSummary(
              building: selectedBuilding!,
              level: selectedLevel!,
              upgradeCost: data.upgradeCost,
              resourceLabel: data.resourceLabel,
            ),
            const SizedBox(height: 16),
            _FarmGoalLevelSelector(
              levels: levels,
              selectedLevel: selectedLevel!,
              onLevelChanged: onLevelChanged,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                key: const ValueKey('farm-goal-building'),
                onPressed: onOpenBuildingPicker,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(loc.farmGoalChangeBuilding),
                style: _calculatorSecondaryActionStyle(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLootPanel(
    BuildContext context,
    AppLocalizations loc, {
    required String? resource,
    required String resourceLabel,
    required _FarmLeagueLootEstimate? leagueEstimate,
  }) {
    final league = selectedAccount?.league;
    final resourceImageUrl = _farmResourceImage(resource);
    final hint =
        league == null || leagueEstimate?.loot == null || resourceLabel.isEmpty
        ? loc.farmGoalNoLeagueLoot
        : loc.farmGoalLeagueEstimate(
            league,
            formatSidePageInt(leagueEstimate!.loot!),
            resourceLabel,
          );

    return CKSectionPanel(
      key: const ValueKey('farm-goal-loot'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('farm-goal-average-loot'),
            controller: averageLootController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: loc.farmGoalAverageLootLabel,
              suffixText: resourceLabel,
              prefixIcon: resourceImageUrl == null
                  ? const Icon(Icons.savings_outlined)
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: MobileWebImage(
                        imageUrl: resourceImageUrl,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            onChanged: (_) => onLootChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            loc.farmGoalPerfectLootHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (leagueEstimate?.starBonus != null &&
              resourceLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              loc.farmGoalStarBonusEstimate(
                formatSidePageInt(leagueEstimate!.starBonus!),
                resourceLabel,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpgradeTrackerImportPrompt extends StatelessWidget {
  const _UpgradeTrackerImportPrompt({required this.onOpenUpgradeTracker});

  final VoidCallback onOpenUpgradeTracker;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: colorScheme.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.farmGoalTrackerMissingTitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loc.farmGoalTrackerMissingBody,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                key: const ValueKey('farm-goal-open-upgrade-tracker'),
                onPressed: onOpenUpgradeTracker,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(loc.farmGoalOpenUpgradeTracker),
                style: _calculatorSecondaryActionStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmGoalLevelSelector extends StatelessWidget {
  const _FarmGoalLevelSelector({
    required this.levels,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  final List<BuildingLevelDefinition> levels;
  final BuildingLevelDefinition selectedLevel;
  final ValueChanged<int> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            loc.farmGoalTargetLevelLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SidePageInlineSelector<int>(
          key: const ValueKey('farm-goal-level'),
          selected: selectedLevel.level,
          options: {
            for (final level in levels) level.level: loc.sideLevel(level.level),
          },
          onSelected: onLevelChanged,
          minWidth: 132,
          maxWidth: 160,
          height: 44,
        ),
      ],
    );
  }
}

class _FarmGoalTargetSummary extends StatelessWidget {
  const _FarmGoalTargetSummary({
    required this.building,
    required this.level,
    required this.upgradeCost,
    required this.resourceLabel,
  });

  final BuildingDefinition building;
  final BuildingLevelDefinition level;
  final int? upgradeCost;
  final String resourceLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final costText = upgradeCost == null || resourceLabel.isEmpty
        ? loc.farmGoalCostUnavailable
        : '${loc.farmGoalUpgradeCostLabel}: ${formatSidePageInt(upgradeCost!)} $resourceLabel';

    return Row(
      children: [
        MobileWebImage(
          imageUrl: ImageAssets.getHomeVillageBuildingImage(
            building.imageName,
            level.level,
          ),
          width: 52,
          height: 52,
          errorWidget: (_, _, _) =>
              const Icon(Icons.home_work_rounded, size: 40),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_buildingDisplayName(loc, building.name)} · ${loc.sideLevel(level.level)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                costText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FarmAttackScenario {
  const _FarmAttackScenario({
    required this.destructionPercent,
    required this.lootPerAttack,
    required this.attacks,
  });

  final int destructionPercent;
  final int lootPerAttack;
  final int attacks;
}

class _FarmGoalResultPanel extends StatelessWidget {
  const _FarmGoalResultPanel({
    required this.scenarios,
    required this.upgradeCost,
    required this.resourceLabel,
    required this.perfectLoot,
  });

  final List<_FarmAttackScenario> scenarios;
  final int upgradeCost;
  final String resourceLabel;
  final int perfectLoot;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return CKSectionPanel(
      key: const ValueKey('farm-goal-result'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MobileWebImage(
                key: const ValueKey('farm-goal-attacks-icon'),
                imageUrl: ImageAssets.sword,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => Icon(
                  Icons.track_changes_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.farmGoalResultTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.farmGoalResultSummary(
                        formatSidePageInt(upgradeCost),
                        resourceLabel,
                        formatSidePageInt(perfectLoot),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 20),
          for (var index = 0; index < scenarios.length; index++) ...[
            _FarmAttackScenarioRow(
              scenario: scenarios[index],
              resourceLabel: resourceLabel,
            ),
            if (index < scenarios.length - 1) const Divider(height: 20),
          ],
          const SizedBox(height: 12),
          Text(
            loc.farmGoalScenarioHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmAttackScenarioRow extends StatelessWidget {
  const _FarmAttackScenarioRow({
    required this.scenario,
    required this.resourceLabel,
  });

  final _FarmAttackScenario scenario;
  final String resourceLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final title = scenario.destructionPercent == 100
        ? loc.farmGoalScenarioPerfect
        : loc.farmGoalScenarioAtPercent(scenario.destructionPercent.toString());
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatSidePageInt(scenario.lootPerAttack)} $resourceLabel / ${loc.farmGoalAttackShort}',
                style: textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${scenario.attacks}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              loc.farmGoalAttacks,
              style: textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountSelectorPanel extends StatelessWidget {
  const _AccountSelectorPanel({
    required this.accountPresets,
    required this.selectedAccount,
    required this.onOpenAccountPicker,
    this.hint,
    this.showHeading = true,
  });

  final List<DamageAccountPreset> accountPresets;
  final DamageAccountPreset? selectedAccount;
  final VoidCallback onOpenAccountPicker;
  final String? hint;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return CKSectionPanel(
      padding: const EdgeInsets.all(14),
      child: accountPresets.isEmpty
          ? Row(
              children: [
                MobileWebImage(
                  imageUrl: ImageAssets.defaultProfile,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => Icon(
                    Icons.person_search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                if (showHeading) ...[
                  Row(
                    children: [
                      MobileWebImage(
                        imageUrl: ImageAssets.defaultProfile,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                ],
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: InkWell(
                    key: const ValueKey('calculator-account-selector'),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    onTap: onOpenAccountPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 44,
                            child: selectedAccount == null
                                ? MobileWebImage(
                                    imageUrl: ImageAssets.defaultProfile,
                                    fit: BoxFit.contain,
                                    errorWidget: (_, _, _) => Icon(
                                      Icons.person_search_rounded,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : MobileWebImage(
                                    imageUrl: ImageAssets.townHall(
                                      selectedAccount!.townHall,
                                    ),
                                    fit: BoxFit.contain,
                                    errorWidget: (_, _, _) => MobileWebImage(
                                      imageUrl: ImageAssets.defaultProfile,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, _, _) => Icon(
                                        Icons.person_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: selectedAccount == null
                                ? Text(
                                    loc.damageChooseAccount,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedAccount!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text(
                                        '${selectedAccount!.tag} · ${loc.gameTownHallShortLevel(selectedAccount!.townHall)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                          IconButton(
                            tooltip: loc.damageSwitchAccount,
                            onPressed: onOpenAccountPicker,
                            icon: const Icon(Icons.switch_account_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hint ?? loc.damageAccountSelectorHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

const _accountlessPresetTag = '__accountless__';

class _CalculatorAccountPickerSheet extends StatefulWidget {
  const _CalculatorAccountPickerSheet({
    required this.accountPresets,
    required this.selectedTag,
    required this.allowCustom,
  });

  final List<DamageAccountPreset> accountPresets;
  final String? selectedTag;
  final bool allowCustom;

  @override
  State<_CalculatorAccountPickerSheet> createState() =>
      _CalculatorAccountPickerSheetState();
}

class _CalculatorAccountPickerSheetState
    extends State<_CalculatorAccountPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filteredAccounts();

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchField(context),
          Expanded(
            child: accounts.isEmpty && !widget.allowCustom
                ? _buildEmptyState(context)
                : _buildAccountsList(context, accounts),
          ),
        ],
      ),
    );
  }

  List<DamageAccountPreset> _filteredAccounts() {
    final query = _query.trim().toLowerCase();
    return widget.accountPresets
        .where(
          (account) =>
              query.isEmpty ||
              account.name.toLowerCase().contains(query) ||
              account.tag.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Widget _buildHeader(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              loc.damageAccountPresetShort,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: loc.damageChooseAccount,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: loc.generalClearSearch,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.person_search_rounded,
      title: loc.damageNoAccountsAvailable,
      body: loc.generalTryAgain,
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    List<DamageAccountPreset> accounts,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: accounts.length + (widget.allowCustom ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.allowCustom && index == 0) {
          return _buildCustomTile(context);
        }
        final account = accounts[widget.allowCustom ? index - 1 : index];
        return _buildAccountTile(context, account);
      },
    );
  }

  Widget _buildCustomTile(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = widget.selectedTag == null;
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      leading: SizedBox.square(
        dimension: 44,
        child: Icon(Icons.tune_rounded, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        loc.damageQuickSetupCustom,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        loc.damageAccountSelectorHint,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, _accountlessPresetTag),
    );
  }

  Widget _buildAccountTile(BuildContext context, DamageAccountPreset account) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = account.tag == widget.selectedTag;
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      leading: SizedBox.square(
        dimension: 44,
        child: MobileWebImage(
          imageUrl: ImageAssets.townHall(account.townHall),
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => MobileWebImage(
            imageUrl: ImageAssets.defaultProfile,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Icon(Icons.person_rounded),
          ),
        ),
      ),
      title: Text(
        '${account.name} · ${loc.gameTownHallShortLevel(account.townHall)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        [
          account.tag,
          if (account.league?.trim().isNotEmpty == true) account.league!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, account.tag),
    );
  }
}

class _TargetEmptyPanel extends StatelessWidget {
  const _TargetEmptyPanel({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return CKSectionPanel(
      padding: const EdgeInsets.all(14),
      child: _BuildingEmptyContent(
        title: loc.damageNoTargetTitle,
        body: loc.damageNoTargetBody,
        actionLabel: loc.damageChooseTarget,
        buttonKey: const ValueKey('choose-building'),
        onChoose: onChoose,
      ),
    );
  }
}

class _BuildingEmptyContent extends StatelessWidget {
  const _BuildingEmptyContent({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.buttonKey,
    required this.onChoose,
  });

  final String title;
  final String body;
  final String actionLabel;
  final Key buttonKey;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileWebImage(
              imageUrl: ImageAssets.townHall(1),
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => Icon(
                Icons.gps_fixed_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
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
          child: FilledButton.icon(
            key: buttonKey,
            onPressed: onChoose,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddBuildingButton extends StatelessWidget {
  const _AddBuildingButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.tonalIcon(
        key: const ValueKey('add-building'),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.damageAddBuilding),
      ),
    );
  }
}

class _ShowAllSourcesButton extends StatelessWidget {
  const _ShowAllSourcesButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(expanded ? Icons.expand_less_rounded : Icons.add_rounded),
        label: Text(
          expanded ? loc.damageShowFewerSources : loc.damageShowAllSources,
        ),
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
    return CKSectionPanel(
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
                    MobileWebImage(
                      imageUrl: result.destroyed
                          ? ImageAssets.iconTick
                          : ImageAssets.iconCross,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => Icon(
                        result.destroyed
                            ? Icons.check_circle_outline_rounded
                            : Icons.shield_outlined,
                        size: 16,
                        color: accent,
                      ),
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

    return CKSectionPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MobileWebImage(
                imageUrl: lightningSource.imageUrl,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const Icon(Icons.bolt_rounded),
              ),
              const SizedBox(width: 10),
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
              avatar: MobileWebImage(
                imageUrl: ImageAssets.getSpellImage(_lightningSpellName),
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.bolt_rounded, size: 18),
              ),
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

class _BuildingPickerSelection {
  const _BuildingPickerSelection(this.buildingId, {this.trackerTarget});

  final String buildingId;
  final _FarmTrackerTarget? trackerTarget;
}

class _TrackerBuildingChoice {
  const _TrackerBuildingChoice({required this.building, required this.target});

  final BuildingDefinition building;
  final _FarmTrackerTarget target;
}

class _BuildingPickerSections {
  const _BuildingPickerSections({
    required this.hasQuery,
    required this.filtered,
    required this.trackerChoices,
    required this.commonBuildings,
    required this.remainingBuildings,
  });

  final bool hasQuery;
  final List<BuildingDefinition> filtered;
  final List<_TrackerBuildingChoice> trackerChoices;
  final List<BuildingDefinition> commonBuildings;
  final List<BuildingDefinition> remainingBuildings;

  List<BuildingDefinition> get visibleBuildings =>
      hasQuery ? filtered : [...commonBuildings, ...remainingBuildings];
}

class _BuildingPicker extends StatefulWidget {
  const _BuildingPicker({
    required this.buildings,
    required this.selectedIds,
    required this.townHall,
    this.trackerTargets = const [],
  });

  final List<BuildingDefinition> buildings;
  final Set<String> selectedIds;
  final int townHall;
  final List<_FarmTrackerTarget> trackerTargets;

  @override
  State<_BuildingPicker> createState() => _BuildingPickerState();
}

class _BuildingPickerState extends State<_BuildingPicker> {
  static const _commonBuildingNames = [
    _townHallBuildingName,
    'Inferno Tower',
    'Eagle Artillery',
    'Scattershot',
    'X-Bow',
    'Air Defense',
  ];

  String _query = '';

  String get _normalizedQuery => _query.trim().toLowerCase();

  bool get _hasQuery => _normalizedQuery.isNotEmpty;

  List<_TrackerBuildingChoice> _trackerChoices() {
    final buildingsByName = {
      for (final building in widget.buildings)
        building.name.trim().toLowerCase(): building,
    };
    return widget.trackerTargets
        .expand((target) {
          final building =
              buildingsByName[target.item.name.trim().toLowerCase()];
          return building == null
              ? const <_TrackerBuildingChoice>[]
              : [_TrackerBuildingChoice(building: building, target: target)];
        })
        .toList(growable: false);
  }

  List<BuildingDefinition> _commonBuildings(Set<String> trackerIds) {
    final buildingsByName = {
      for (final building in widget.buildings) building.name: building,
    };
    return _commonBuildingNames
        .map((name) => buildingsByName[name])
        .whereType<BuildingDefinition>()
        .where((building) => !trackerIds.contains(building.id))
        .toList(growable: false);
  }

  List<BuildingDefinition> _filteredBuildings() {
    final query = _normalizedQuery;
    return widget.buildings
        .where((building) => building.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<BuildingDefinition> _remainingBuildings(
    List<BuildingDefinition> commonBuildings,
    Set<String> trackerIds,
  ) {
    final excludedIds = {
      ...trackerIds,
      ...commonBuildings.map((building) => building.id),
    };
    return widget.buildings
        .where((building) => !excludedIds.contains(building.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasQuery = _hasQuery;
    final filtered = hasQuery ? _filteredBuildings() : widget.buildings;
    final trackerChoices = hasQuery
        ? const <_TrackerBuildingChoice>[]
        : _trackerChoices();
    final trackerIds = trackerChoices
        .map((choice) => choice.building.id)
        .toSet();
    final commonBuildings = hasQuery
        ? const <BuildingDefinition>[]
        : _commonBuildings(trackerIds);
    final remainingBuildings = hasQuery
        ? filtered
        : _remainingBuildings(commonBuildings, trackerIds);
    final sections = _BuildingPickerSections(
      hasQuery: hasQuery,
      filtered: filtered,
      trackerChoices: trackerChoices,
      commonBuildings: commonBuildings,
      remainingBuildings: remainingBuildings,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _buildSheet(context, loc, controller: controller, sections: sections),
    );
  }

  Widget _buildSheet(
    BuildContext context,
    AppLocalizations loc, {
    required ScrollController controller,
    required _BuildingPickerSections sections,
  }) {
    return Padding(
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
                sections.visibleBuildings.isEmpty &&
                    sections.trackerChoices.isEmpty
                ? AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: loc.damageNoBuildingsFound,
                    body: loc.damageTryAnotherSearch,
                  )
                : _buildBuildingList(
                    context,
                    loc,
                    controller: controller,
                    sections: sections,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingList(
    BuildContext context,
    AppLocalizations loc, {
    required ScrollController controller,
    required _BuildingPickerSections sections,
  }) {
    return ListView(
      controller: controller,
      children: [
        if (sections.trackerChoices.isNotEmpty) ...[
          _PickerSectionLabel(title: loc.farmGoalTrackerNextTitle),
          for (final choice in sections.trackerChoices)
            _trackerBuildingTile(context, choice),
        ],
        if (sections.commonBuildings.isNotEmpty) ...[
          _PickerSectionLabel(title: loc.damageCommonBuildings),
          for (final building in sections.commonBuildings)
            _buildingTile(context, building),
        ],
        if (sections.remainingBuildings.isNotEmpty && !sections.hasQuery) ...[
          _PickerSectionLabel(title: loc.damageAllBuildings),
          for (final building in sections.remainingBuildings)
            _buildingTile(context, building),
        ],
        if (sections.hasQuery)
          for (final building in sections.filtered)
            _buildingTile(context, building),
      ],
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
      onTap: selected
          ? null
          : () => Navigator.pop(context, _BuildingPickerSelection(building.id)),
    );
  }

  Widget _trackerBuildingTile(
    BuildContext context,
    _TrackerBuildingChoice choice,
  ) {
    final loc = AppLocalizations.of(context)!;
    final target = choice.target;
    final targetLevel =
        target.targetLevel ?? target.item.steps.first.targetLevel;
    final details = <String>[
      '${loc.sideLevel(target.item.currentLevel)} → ${loc.sideLevel(targetLevel)}',
      ...target.costs.map((cost) {
        final resource =
            _upgradeResourceLabel(loc, cost.resource) ?? cost.resource;
        return '${formatSidePageInt(cost.amount.round())} $resource';
      }),
    ];
    return ListTile(
      key: const ValueKey('farm-goal-tracker-picker-item'),
      leading: MobileWebImage(
        imageUrl: target.item.imageUrl.isNotEmpty
            ? target.item.imageUrl
            : ImageAssets.getHomeVillageBuildingImage(
                choice.building.imageName,
                targetLevel,
              ),
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorWidget: (_, _, _) => const Icon(Icons.construction_rounded),
      ),
      title: Text(_buildingDisplayName(loc, choice.building.name)),
      subtitle: Text(details.join(' · ')),
      trailing: const Icon(Icons.arrow_forward_rounded),
      onTap: () => Navigator.pop(
        context,
        _BuildingPickerSelection(choice.building.id, trackerTarget: target),
      ),
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
        league: player.league,
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

  add(DamageSourceKind.lightning, player.spells, _lightningSpellName);
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
  if (name == _townHallBuildingName) return loc.damageTownHall;
  return name;
}

String? _upgradeResourceLabel(AppLocalizations loc, String? resource) {
  final normalized = resource?.trim().toLowerCase().replaceAll('_', ' ');
  return switch (normalized) {
    'gold' => loc.resourceGold,
    'elixir' => loc.resourceElixir,
    _darkElixirResourceName => loc.resourceDarkElixir,
    final value when value != null && value.isNotEmpty => resource,
    _ => null,
  };
}

UpgradeCost? _trackerCostForSelection(
  _FarmTrackerTarget? target,
  BuildingDefinition? building,
  BuildingLevelDefinition? level,
) {
  final item = target?.item;
  if (item == null || building == null || level == null) return null;
  if (item.name.trim().toLowerCase() != building.name.trim().toLowerCase()) {
    return null;
  }
  final step = target?.plannedStep?.targetLevel == level.level
      ? target?.plannedStep
      : item.steps
            .where((candidate) => candidate.targetLevel == level.level)
            .firstOrNull;
  if (step == null || step.costs.isEmpty) return null;
  final costs = target?.plannedStep?.targetLevel == level.level
      ? target!.costs
      : step.costs;
  if (costs.isEmpty) return null;
  final selectedResource = level.upgradeResource?.trim().toLowerCase();
  return costs
          .where(
            (cost) =>
                selectedResource == null ||
                cost.resource.trim().toLowerCase() == selectedResource,
          )
          .firstOrNull ??
      costs.first;
}

class _FarmLeagueLootEstimate {
  const _FarmLeagueLootEstimate({this.loot, this.starBonus});

  final int? loot;
  final int? starBonus;
}

_FarmLeagueLootEstimate? _farmLeagueLootEstimate({
  required String? league,
  required int townHall,
  required String? resource,
}) {
  if (league == null || resource == null || resource.isEmpty) return null;
  final leagues = GameDataService.playerLeagueData['leagues'];
  final leagueData = leagues is Map ? leagues[league] : null;
  if (leagueData is! Map) return null;
  final rewards = leagueData['rewards'];
  if (rewards is! List) return null;

  Map? selectedReward;
  for (final reward in rewards) {
    if (reward is! Map) continue;
    if (!_rewardAppliesToTownHall(reward, townHall)) continue;
    selectedReward = reward;
  }
  final resourceKey = _farmResourceKey(resource);
  if (resourceKey == null) return null;
  final loot = _farmRewardAmount(selectedReward?['resources'], resourceKey);
  final starBonus = _farmRewardAmount(
    selectedReward?['star_bonus'],
    resourceKey,
  );
  if (loot == null && starBonus == null) return null;
  return _FarmLeagueLootEstimate(loot: loot, starBonus: starBonus);
}

int? _farmRewardAmount(dynamic rewards, String resourceKey) {
  if (rewards is! Map) return null;
  final value = rewards[resourceKey];
  return value is num && value > 0 ? value.round() : null;
}

bool _rewardAppliesToTownHall(Map reward, int townHall) {
  final requiredTownHall = reward['townhall_level'];
  return requiredTownHall is num && requiredTownHall <= townHall;
}

String? _farmResourceKey(String resource) =>
    switch (resource.trim().toLowerCase().replaceAll(' ', '_')) {
      'gold' => 'gold',
      'elixir' => 'elixir',
      'dark_elixir' => 'dark_elixir',
      _ => null,
    };

String? _farmResourceImage(String? resource) =>
    switch (resource?.trim().toLowerCase().replaceAll('_', ' ')) {
      'gold' => '${ImageAssets.baseUrl}/resources/gold.webp',
      'elixir' => '${ImageAssets.baseUrl}/resources/elixir.webp',
      _darkElixirResourceName =>
        '${ImageAssets.baseUrl}/resources/dark_elixir.webp',
      _ => null,
    };

int _farmDefaultPerfectLoot(String? resource) =>
    resource?.trim().toLowerCase().replaceAll('_', ' ') ==
        _darkElixirResourceName
    ? _defaultFarmDarkElixirLoot
    : _defaultFarmPerfectLoot;

int _farmDefaultVillageLoot({required String? resource}) =>
    _farmDefaultPerfectLoot(resource);

int _parseFarmAmount(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

String _quickSetupLabel(AppLocalizations loc, String id) => switch (id) {
  _zapQuakeSetupId => loc.damageQuickSetupZapQuake,
  _fireballQuakeSetupId => loc.damageQuickSetupFireballQuake,
  _giantArrowSetupId => loc.damageQuickSetupGiantArrow,
  _flameFlingerSetupId => loc.damageQuickSetupFlameFlinger,
  _ => loc.damageQuickSetupCustom,
};

IconData _quickSetupIcon(String id) => switch (id) {
  _zapQuakeSetupId => Icons.bolt_rounded,
  _fireballQuakeSetupId => Icons.local_fire_department_rounded,
  _giantArrowSetupId => Icons.north_east_rounded,
  _flameFlingerSetupId => Icons.rocket_launch_rounded,
  _ => Icons.tune_rounded,
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
