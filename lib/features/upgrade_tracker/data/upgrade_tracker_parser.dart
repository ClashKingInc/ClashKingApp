import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';

class UpgradeTrackerParser {
  const UpgradeTrackerParser();

  static Map<String, dynamic>? _cachedBundle;
  static _StaticLookup? _cachedLookup;

  UpgradeTrackerSnapshot parse(
    Map<String, dynamic> account, {
    Map<String, dynamic>? staticData,
    DateTime? now,
  }) {
    final bundle = staticData ?? GameDataService.bundleData;
    final lookup = _lookupFor(bundle);
    final items = <UpgradeTrackerItem>[];
    final buildingRows = [
      ..._mapList(account['buildings']),
      ..._mapList(account['buildings2']),
    ];
    final townHallLevel = _hallLevel(buildingRows, lookup, name: 'Town Hall');
    final builderHallLevel = _hallLevel(
      buildingRows,
      lookup,
      name: 'Builder Hall',
    );

    var builderHuts = 0;
    var bobUnlocked = false;
    for (final raw in buildingRows) {
      final data = lookup.byId[_int(raw['data'])];
      if (data == null) continue;
      final name = data['name']?.toString() ?? '';
      if (name == "Builder's Hut") builderHuts += _int(raw['cnt'], fallback: 1);
      if (name == "B.O.B's Hut" && _int(raw['lvl']) > 0) bobUnlocked = true;
      _addBuildingItems(
        items,
        raw,
        data,
        townHallLevel: townHallLevel,
        builderHallLevel: builderHallLevel,
        lookup: lookup,
      );
    }

    _addLeveledSection(
      items,
      rows: [..._mapList(account['traps']), ..._mapList(account['traps2'])],
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.traps,
      queue: (_) => UpgradeQueue.builders,
      image: (data, level) => _village(data) == UpgradeVillage.home
          ? ImageAssets.getHomeVillageTrapImage(_name(data), level)
          : ImageAssets.getBuilderBaseTrapImage(_name(data), level),
      usesBuildFields: true,
    );
    _addLeveledSection(
      items,
      rows: _mapList(account['guardians']),
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.guardians,
      queue: (_) => UpgradeQueue.builders,
      image: (data, _) =>
          '${ImageAssets.baseUrl}/guardians/${_slug(_name(data))}/icon.webp',
    );
    _addLeveledSection(
      items,
      rows: [
        ..._mapList(account['units']),
        ..._mapList(account['units2']),
        ..._mapList(account['siege_machines']),
      ],
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (data) {
        if (data['production_building'] == 'Workshop') {
          return UpgradeCategory.sieges;
        }
        if (_normalizeResource(data['upgrade_resource']).contains('dark')) {
          return UpgradeCategory.darkTroops;
        }
        return UpgradeCategory.troops;
      },
      queue: (_) => UpgradeQueue.laboratory,
      image: (data, _) => _village(data) == UpgradeVillage.home
          ? (data['production_building'] == 'Workshop'
                ? ImageAssets.getSiegeMachineImage(_name(data))
                : ImageAssets.getTroopImage(_name(data)))
          : ImageAssets.getBuilderBaseTroopImage(_name(data)),
    );
    _addLeveledSection(
      items,
      rows: _mapList(account['spells']),
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.spells,
      queue: (_) => UpgradeQueue.laboratory,
      image: (data, _) => ImageAssets.getSpellImage(_name(data)),
    );
    _addLeveledSection(
      items,
      rows: [..._mapList(account['heroes']), ..._mapList(account['heroes2'])],
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.heroes,
      queue: (_) => UpgradeQueue.builders,
      image: (data, _) => _village(data) == UpgradeVillage.home
          ? ImageAssets.getHeroImage(_name(data))
          : ImageAssets.getBuilderBaseHeroImage(_name(data)),
    );
    _addLeveledSection(
      items,
      rows: _mapList(account['pets']),
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.pets,
      queue: (_) => UpgradeQueue.pets,
      image: (data, _) => ImageAssets.getPetImage(_name(data)),
    );
    _addLeveledSection(
      items,
      rows: _mapList(account['equipment']),
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.equipment,
      queue: (_) => UpgradeQueue.none,
      image: (data, _) => ImageAssets.getGearImage(_name(data)),
    );
    _addLeveledSection(
      items,
      rows: _mapList(account['helpers']),
      lookup: lookup,
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      category: (_) => UpgradeCategory.builders,
      queue: (_) => UpgradeQueue.none,
      image: (data, _) =>
          '${ImageAssets.baseUrl}/helpers/${_slug(_name(data))}.webp',
    );

    items.sort((a, b) {
      final village = a.village.index.compareTo(b.village.index);
      if (village != 0) return village;
      final category = a.category.index.compareTo(b.category.index);
      if (category != 0) return category;
      final complete = a.isComplete == b.isComplete
          ? 0
          : (a.isComplete ? 1 : -1);
      if (complete != 0) return complete;
      return a.name.compareTo(b.name);
    });

    final timestamp = _optionalInt(account['timestamp']);
    final capturedAt = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
        : (now ?? DateTime.now()).toUtc();
    // Builder Base unlocks its second simultaneous builder with the second
    // stage at Builder Hall 6. The raw snapshot does not expose a builder count.
    final builderBaseBuilders = builderHallLevel >= 6 ? 2 : 1;
    return UpgradeTrackerSnapshot(
      tag: account['tag']?.toString() ?? '',
      name: account['name']?.toString() ?? 'Player',
      townHallLevel: townHallLevel,
      builderHallLevel: builderHallLevel,
      homeBuilderCount: (builderHuts + (bobUnlocked ? 1 : 0)).clamp(1, 7),
      builderBaseBuilderCount: builderBaseBuilders,
      items: items,
      collections: _parseCollections(account, lookup),
      boosts: _parseBoosts(
        account['boosts'],
        helpers: _mapList(account['helpers']),
      ),
      events: const [],
      capturedAt: capturedAt,
    );
  }

  static _StaticLookup _lookupFor(Map<String, dynamic> bundle) {
    if (identical(bundle, _cachedBundle) && _cachedLookup != null) {
      return _cachedLookup!;
    }
    _cachedBundle = bundle;
    return _cachedLookup = _StaticLookup(bundle);
  }

  static void _addBuildingItems(
    List<UpgradeTrackerItem> output,
    Map<String, dynamic> raw,
    Map<String, dynamic> data, {
    required int townHallLevel,
    required int builderHallLevel,
    required _StaticLookup lookup,
  }) {
    final village = _village(data);
    final current = _int(raw['lvl']);
    final hall = village == UpgradeVillage.home
        ? townHallLevel
        : builderHallLevel;
    final target = _maxLevelForHall(data, hall);
    final type = data['type']?.toString() ?? '';
    final name = _name(data);
    final category = _buildingCategory(type, name, target);
    final image = village == UpgradeVillage.home
        ? ImageAssets.getHomeVillageBuildingImage(name, current)
        : (name == 'Battle Machine' || name == 'Battle Copter')
        ? ImageAssets.getBuilderBaseHeroImage(name)
        : ImageAssets.getBuilderBaseBuildingImage(name, current);
    final steps = _buildSteps(
      data,
      current: current,
      target: target,
      usesBuildFields: true,
    );
    final timeTotals = _upgradeTimeTotals(
      data,
      current: current,
      target: target,
      usesBuildFields: true,
      steps: steps,
    );
    final resourceTotals = category == UpgradeCategory.walls
        ? _resourceProgressTotals(
            data,
            current: current,
            usesBuildFields: true,
            category: UpgradeCategory.walls,
            steps: steps,
          )
        : null;
    output.add(
      UpgradeTrackerItem(
        id: _int(data['_id']),
        name: name,
        imageUrl: image,
        village: village,
        category: category,
        queue: type == 'Wall' ? UpgradeQueue.none : UpgradeQueue.builders,
        currentLevel: current,
        targetLevel: target,
        count: _int(raw['cnt'], fallback: 1),
        steps: steps,
        completedUpgradeSeconds: timeTotals.completedSeconds,
        totalUpgradeSeconds: timeTotals.totalSeconds,
        meta: data,
        progressBasis: resourceTotals == null
            ? UpgradeProgressBasis.time
            : UpgradeProgressBasis.resources,
        completedResourceWeight: resourceTotals?.completedWeight ?? 0,
        totalResourceWeight: resourceTotals?.totalWeight ?? 0,
        activeSeconds: _seconds(raw, const ['timer', 'upgrade_timer']),
        helperSeconds: _seconds(raw, const ['helper_timer', 'helperTimer']),
        recurrentHelper: _bool(
          raw['recurrent_helper'] ??
              raw['helper_recurrent'] ??
              raw['recurrentHelper'],
        ),
        isExtra: _bool(raw['extra']),
      ),
    );

    _addSupercharge(output, raw, data, image, village);
    _addCraftedDefenses(output, raw, data, lookup, village);
  }

  static void _addSupercharge(
    List<UpgradeTrackerItem> output,
    Map<String, dynamic> raw,
    Map<String, dynamic> data,
    String image,
    UpgradeVillage village,
  ) {
    final levels = data['levels'];
    if (levels is! List || levels.isEmpty) return;
    final last = levels.last;
    if (last is! Map || last['supercharge'] is! Map) return;
    final supercharge = Map<String, dynamic>.from(last['supercharge'] as Map);
    final superLevels = supercharge['levels'];
    if (superLevels is! List || superLevels.isEmpty) return;
    final current = _int(raw['supercharge']);
    final target = _maxLevel(superLevels);
    final superchargeData = {
      'levels': superLevels,
      'upgrade_resource': supercharge['upgrade_resource'],
    };
    final steps = _buildSteps(
      superchargeData,
      current: current,
      target: target,
      usesBuildFields: true,
    );
    final timeTotals = _upgradeTimeTotals(
      superchargeData,
      current: current,
      target: target,
      usesBuildFields: true,
      steps: steps,
    );
    output.add(
      UpgradeTrackerItem(
        id: _int(data['_id']),
        name: '${_name(data)} Supercharge',
        imageUrl: image,
        village: village,
        category: UpgradeCategory.supercharge,
        queue: UpgradeQueue.builders,
        currentLevel: current,
        targetLevel: target,
        count: _int(raw['cnt'], fallback: 1),
        steps: steps,
        completedUpgradeSeconds: timeTotals.completedSeconds,
        totalUpgradeSeconds: timeTotals.totalSeconds,
        isSupercharge: true,
        parentName: _name(data),
        meta: data,
      ),
    );
  }

  static void _addCraftedDefenses(
    List<UpgradeTrackerItem> output,
    Map<String, dynamic> raw,
    Map<String, dynamic> data,
    _StaticLookup lookup,
    UpgradeVillage village,
  ) {
    final types = _mapList(raw['types']);
    for (final type in types) {
      final seasonal = lookup.byId[_int(type['data'])];
      if (seasonal == null) continue;
      for (final moduleRaw in _mapList(type['modules'])) {
        final module = lookup.byId[_int(moduleRaw['data'])];
        if (module == null) continue;
        final current = _int(moduleRaw['lvl']);
        final target = _maxLevel(module['levels']);
        final steps = _buildSteps(
          module,
          current: current,
          target: target,
          usesBuildFields: true,
        );
        final timeTotals = _upgradeTimeTotals(
          module,
          current: current,
          target: target,
          usesBuildFields: true,
          steps: steps,
        );
        output.add(
          UpgradeTrackerItem(
            id: _int(module['_id']),
            name: _name(module),
            imageUrl: ImageAssets.getSeasonalDefenseImage(
              _name(seasonal),
              current,
            ),
            village: village,
            category: UpgradeCategory.craftedDefenses,
            queue: UpgradeQueue.builders,
            currentLevel: current,
            targetLevel: target,
            count: 1,
            steps: steps,
            completedUpgradeSeconds: timeTotals.completedSeconds,
            totalUpgradeSeconds: timeTotals.totalSeconds,
            meta: module,
            activeSeconds: _seconds(moduleRaw, const [
              'timer',
              'upgrade_timer',
            ]),
            helperSeconds: _seconds(moduleRaw, const [
              'helper_timer',
              'helperTimer',
            ]),
            recurrentHelper: _bool(
              moduleRaw['recurrent_helper'] ??
                  moduleRaw['helper_recurrent'] ??
                  moduleRaw['recurrentHelper'],
            ),
            isExtra: _bool(moduleRaw['extra']),
            parentName: _name(seasonal),
          ),
        );
      }
    }
  }

  static void _addLeveledSection(
    List<UpgradeTrackerItem> output, {
    required List<Map<String, dynamic>> rows,
    required _StaticLookup lookup,
    required int townHallLevel,
    required int builderHallLevel,
    required UpgradeCategory Function(Map<String, dynamic>) category,
    required UpgradeQueue Function(Map<String, dynamic>) queue,
    required String Function(Map<String, dynamic>, int) image,
    bool usesBuildFields = false,
  }) {
    for (final raw in rows) {
      final data = lookup.byId[_int(raw['data'])];
      if (data == null || data['is_seasonal'] == true) continue;
      final village = _village(data);
      final hall = village == UpgradeVillage.home
          ? townHallLevel
          : builderHallLevel;
      final current = _int(raw['lvl']);
      final target = _maxLevelForHall(data, hall);
      final itemCategory = category(data);
      final steps = _buildSteps(
        data,
        current: current,
        target: target,
        usesBuildFields: usesBuildFields,
      );
      final timeTotals = _upgradeTimeTotals(
        data,
        current: current,
        target: target,
        usesBuildFields: usesBuildFields,
        steps: steps,
      );
      final itemQueue = queue(data);
      final resourceTotals =
          itemCategory == UpgradeCategory.equipment ||
              (itemCategory == UpgradeCategory.builders &&
                  itemQueue == UpgradeQueue.none)
          ? _resourceProgressTotals(
              data,
              current: current,
              usesBuildFields: usesBuildFields,
              category: itemCategory,
              steps: steps,
            )
          : null;
      output.add(
        UpgradeTrackerItem(
          id: _int(data['_id']),
          name: _name(data),
          imageUrl: image(data, current),
          village: village,
          category: itemCategory,
          queue: itemQueue,
          currentLevel: current,
          targetLevel: target,
          count: _int(raw['cnt'], fallback: 1),
          steps: steps,
          completedUpgradeSeconds: timeTotals.completedSeconds,
          totalUpgradeSeconds: timeTotals.totalSeconds,
          meta: data,
          wardenWeight: _optionalNum(data['warden_weight']),
          healerWeight: _optionalNum(data['healer_weight']),
          progressBasis: resourceTotals == null
              ? UpgradeProgressBasis.time
              : UpgradeProgressBasis.resources,
          completedResourceWeight: resourceTotals?.completedWeight ?? 0,
          totalResourceWeight: resourceTotals?.totalWeight ?? 0,
          activeSeconds: _seconds(raw, const ['timer', 'upgrade_timer']),
          helperSeconds: _seconds(raw, const ['helper_timer', 'helperTimer']),
          cooldownSeconds: _seconds(raw, const [
            'helper_cooldown',
            'helperCooldown',
            'cooldown',
          ]),
          recurrentHelper: _bool(
            raw['recurrent_helper'] ??
                raw['helper_recurrent'] ??
                raw['recurrentHelper'],
          ),
          isExtra: _bool(raw['extra']),
        ),
      );
    }
  }

  static UpgradeCategory _buildingCategory(
    String type,
    String name,
    int target,
  ) {
    final normalizedName = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final weaponizedBuilderHut =
        type == 'Worker' &&
        target > 1 &&
        (normalizedName == 'builderhut' || normalizedName == 'buildershut');
    if (weaponizedBuilderHut) return UpgradeCategory.defenses;
    return switch (type) {
      'Defense' => UpgradeCategory.defenses,
      'Resource' => UpgradeCategory.resources,
      'Wall' => UpgradeCategory.walls,
      'Worker' || 'Worker2' || 'Helper' => UpgradeCategory.builders,
      _ => UpgradeCategory.army,
    };
  }

  static ({num completedWeight, num totalWeight}) _resourceProgressTotals(
    Map<String, dynamic> data, {
    required int current,
    required bool usesBuildFields,
    required UpgradeCategory category,
    required List<UpgradeStep> steps,
  }) {
    final byLevel = {
      for (final level in _mapList(data['levels'])) _int(level['level']): level,
    };
    final costKey = usesBuildFields ? 'build_cost' : 'upgrade_cost';
    final completedThrough = usesBuildFields ? current : current - 1;

    num weightFor(Map<String, dynamic>? level) {
      if (level == null) return 0;
      final costs = _costs(
        level[costKey],
        fallbackResource: data['upgrade_resource']?.toString(),
      );
      return _resourceCostsWeight(category, costs);
    }

    num completedWeight = 0;
    for (var level = 1; level <= completedThrough; level++) {
      completedWeight += weightFor(byLevel[level]);
    }
    final remainingWeight = steps.fold<num>(
      0,
      (sum, step) => sum + _resourceCostsWeight(category, step.costs),
    );
    return (
      completedWeight: completedWeight,
      totalWeight: completedWeight + remainingWeight,
    );
  }

  static num _resourceCostsWeight(
    UpgradeCategory category,
    List<UpgradeCost> costs,
  ) {
    if (category == UpgradeCategory.walls) {
      final gold = costs.where(
        (cost) => cost.resource == 'gold' || cost.resource == 'builder_gold',
      );
      final selectedGold = gold.firstOrNull;
      if (selectedGold != null) return selectedGold.amount;

      final elixir = costs.where(
        (cost) =>
            cost.resource == 'elixir' || cost.resource == 'builder_elixir',
      );
      return elixir.firstOrNull?.amount ?? 0;
    }
    return costs.fold<num>(
      0,
      (sum, cost) => sum + _resourceCostWeight(category, cost),
    );
  }

  static num _resourceCostWeight(UpgradeCategory category, UpgradeCost cost) {
    if (category != UpgradeCategory.equipment) return cost.amount;
    return switch (cost.resource) {
      'shiny_ore' => cost.amount,
      'glowy_ore' => cost.amount * 5,
      'starry_ore' => cost.amount * 35,
      _ => 0,
    };
  }

  static List<UpgradeStep> _buildSteps(
    Map<String, dynamic> data, {
    required int current,
    required int target,
    required bool usesBuildFields,
  }) {
    final levels = _mapList(data['levels']);
    final byLevel = {for (final level in levels) _int(level['level']): level};
    final steps = <UpgradeStep>[];
    for (var next = current + 1; next <= target; next++) {
      final source = usesBuildFields ? next : next - 1;
      final stats = byLevel[source];
      if (stats == null) continue;
      final costValue = stats[usesBuildFields ? 'build_cost' : 'upgrade_cost'];
      final timeValue = stats[usesBuildFields ? 'build_time' : 'upgrade_time'];
      steps.add(
        UpgradeStep(
          targetLevel: next,
          costs: _costs(
            costValue,
            fallbackResource: data['upgrade_resource']?.toString(),
          ),
          seconds: _int(timeValue),
        ),
      );
    }
    return steps;
  }

  static ({int completedSeconds, int totalSeconds}) _upgradeTimeTotals(
    Map<String, dynamic> data, {
    required int current,
    required int target,
    required bool usesBuildFields,
    required List<UpgradeStep> steps,
  }) {
    final byLevel = {
      for (final level in _mapList(data['levels'])) _int(level['level']): level,
    };
    final timeKey = usesBuildFields ? 'build_time' : 'upgrade_time';
    final completedThrough = usesBuildFields ? current : current - 1;
    var completedSeconds = 0;
    for (var level = 1; level <= completedThrough; level++) {
      completedSeconds += _int(byLevel[level]?[timeKey]);
    }
    final remainingSeconds = steps.fold(0, (sum, step) => sum + step.seconds);
    return (
      completedSeconds: completedSeconds,
      totalSeconds: completedSeconds + remainingSeconds,
    );
  }

  static List<UpgradeCost> _costs(dynamic value, {String? fallbackResource}) {
    if (value is Map) {
      return value.entries
          .where((entry) => entry.value is num && (entry.value as num) > 0)
          .map(
            (entry) =>
                UpgradeCost(_normalizeResource(entry.key), entry.value as num),
          )
          .toList(growable: false);
    }
    if (value is num && value > 0) {
      return [UpgradeCost(_normalizeResource(fallbackResource), value)];
    }
    return const [];
  }

  static List<UpgradeCollectionItem> _parseCollections(
    Map<String, dynamic> account,
    _StaticLookup lookup,
  ) {
    final ownedCounts = <int, int>{};
    for (final key in ['decos', 'decos2', 'obstacles', 'obstacles2']) {
      for (final row in _mapList(account[key])) {
        final id = _int(row['data']);
        ownedCounts[id] =
            (ownedCounts[id] ?? 0) + _int(row['cnt'], fallback: 1);
      }
    }
    final ownedIds = <int>{...ownedCounts.keys};
    for (final key in [
      'skins',
      'skins2',
      'sceneries',
      'sceneries2',
      'house_parts',
    ]) {
      final values = account[key];
      if (values is List) ownedIds.addAll(values.map(_int));
    }

    final collections = <UpgradeCollectionItem>[];
    final collectionKeys = <(UpgradeCollectionType, int)>{};
    void addSection(
      String staticKey,
      UpgradeCollectionType type,
      String Function(Map<String, dynamic>) image, {
      bool Function(Map<String, dynamic>)? defaultOwned,
      String? Function(Map<String, dynamic>)? subtitle,
      UpgradeVillage? villageOverride,
    }) {
      for (final data in _mapList(lookup.bundle[staticKey])) {
        final id = _int(data['_id']);
        if (!collectionKeys.add((type, id))) continue;
        final owned =
            ownedIds.contains(id) || (defaultOwned?.call(data) ?? false);
        collections.add(
          UpgradeCollectionItem(
            id: id,
            name: _name(data),
            imageUrl: image(data),
            type: type,
            owned: owned,
            village: switch (type) {
              UpgradeCollectionType.skins =>
                villageOverride ?? _skinVillage(data),
              UpgradeCollectionType.sceneries =>
                data['type'] == 'builderBase'
                    ? UpgradeVillage.builderBase
                    : UpgradeVillage.home,
              UpgradeCollectionType.decorations ||
              UpgradeCollectionType.obstacles => _village(data),
              _ => null,
            },
            count: ownedCounts[id] ?? (owned ? 1 : 0),
            maxCount: _int(data['max_count'], fallback: 1),
            subtitle: subtitle?.call(data),
            meta: data,
          ),
        );
      }
    }

    addSection(
      'skins',
      UpgradeCollectionType.skins,
      (data) => '${ImageAssets.baseUrl}/skins/${_slug(_name(data))}/icon.webp',
      defaultOwned: (data) => data['tier'] == 'Default',
      subtitle: (data) => data['character']?.toString(),
    );
    addSection(
      'skins2',
      UpgradeCollectionType.skins,
      (data) => '${ImageAssets.baseUrl}/skins/${_slug(_name(data))}/icon.webp',
      defaultOwned: (data) => data['tier'] == 'Default',
      subtitle: (data) => data['character']?.toString(),
      villageOverride: UpgradeVillage.builderBase,
    );
    addSection(
      'sceneries',
      UpgradeCollectionType.sceneries,
      (data) => '${ImageAssets.baseUrl}/${data['thumbnail']}',
      defaultOwned: (data) => _name(data) == 'Classic Scenery',
      subtitle: (data) => data['type']?.toString(),
    );
    addSection(
      'decorations',
      UpgradeCollectionType.decorations,
      (data) =>
          '${ImageAssets.baseUrl}/decorations/${_villageFolder(data)}/${_slug(_name(data))}.webp',
    );
    addSection(
      'obstacles',
      UpgradeCollectionType.obstacles,
      (data) =>
          '${ImageAssets.baseUrl}/obstacles/${_villageFolder(data)}/${_slug(_name(data))}.webp',
    );
    addSection(
      'capital_house_parts',
      UpgradeCollectionType.capitalHouseParts,
      (data) =>
          '${ImageAssets.baseUrl}/capital_house_parts/${data['_id']}.webp',
      subtitle: (data) => data['slot_type']?.toString(),
    );
    collections.sort((a, b) {
      final type = a.type.index.compareTo(b.type.index);
      if (type != 0) return type;
      if (a.owned != b.owned) return a.owned ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return collections;
  }

  static UpgradeBoosts _parseBoosts(
    dynamic raw, {
    List<Map<String, dynamic>> helpers = const [],
  }) {
    final boosts = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    int percent(List<String> keys) {
      for (final key in keys) {
        final value = _optionalInt(boosts[key]);
        if (value != null) return value.clamp(0, 50);
      }
      return 0;
    }

    int seconds(List<String> keys) {
      for (final key in keys) {
        final value = _optionalInt(boosts[key]);
        if (value != null) return value.clamp(0, 31536000);
      }
      return 0;
    }

    var helperCooldown = seconds(const ['helper_cooldown', 'helperCooldown']);
    for (final helper in helpers) {
      final rowCooldown = _seconds(helper, const [
        'helper_cooldown',
        'helperCooldown',
        'cooldown',
      ]);
      helperCooldown = helperCooldown > (rowCooldown ?? 0)
          ? helperCooldown
          : (rowCooldown ?? 0);
    }
    return UpgradeBoosts(
      builderBoostSeconds: seconds(const [
        'town_hall_builder_boost',
        'townHallBuilderBoost',
      ]),
      labBoostSeconds: seconds(const [
        'town_hall_lab_boost',
        'townHallLabBoost',
      ]),
      clockTowerBoostSeconds: seconds(const [
        'clocktower_boost',
        'clockTowerBoost',
      ]),
      clockTowerCooldownSeconds: seconds(const [
        'clocktower_cooldown',
        'clockTowerCooldown',
      ]),
      builderConsumableSeconds: seconds(const [
        'builder_boost',
        'builderBoost',
        'builder_consumable',
        'builder_potion',
        'builderPotion',
      ]),
      labConsumableSeconds: seconds(const [
        'lab_boost',
        'labBoost',
        'lab_consumable',
        'research_potion',
        'researchPotion',
      ]),
      petConsumableSeconds: seconds(const [
        'pet_consumable',
        'pet_potion',
        'petPotion',
        'pet_boost',
        'petBoost',
      ]),
      helperCooldownSeconds: helperCooldown,
      builderCostReductionPercent: percent(const [
        'builder_cost_reduction',
        'building_cost_reduction',
      ]),
      builderTimeReductionPercent: percent(const [
        'builder_time_reduction',
        'building_time_reduction',
      ]),
      labCostReductionPercent: percent(const [
        'lab_cost_reduction',
        'research_cost_reduction',
      ]),
      labTimeReductionPercent: percent(const [
        'lab_time_reduction',
        'research_time_reduction',
      ]),
    );
  }

  static int _hallLevel(
    List<Map<String, dynamic>> rows,
    _StaticLookup lookup, {
    required String name,
  }) {
    for (final raw in rows) {
      final data = lookup.byId[_int(raw['data'])];
      if (data?['name'] == name) return _int(raw['lvl']);
    }
    return 0;
  }

  static int _maxLevelForHall(Map<String, dynamic> data, int hall) {
    final levels = _mapList(data['levels']);
    if (levels.isEmpty) return 0;
    var max = 0;
    for (final level in levels) {
      final requiredHall = _optionalInt(level['required_townhall']);
      if (requiredHall == null || hall <= 0 || requiredHall <= hall) {
        final value = _int(level['level']);
        if (value > max) max = value;
      }
    }
    return max > 0 ? max : _maxLevel(levels);
  }

  static int _maxLevel(dynamic rawLevels) {
    var max = 0;
    for (final level in _mapList(rawLevels)) {
      final value = _int(level['level']);
      if (value > max) max = value;
    }
    return max;
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  static int _int(dynamic value, {int fallback = 0}) =>
      _optionalInt(value) ?? fallback;
  static int? _optionalInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static num? _optionalNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  static int? _seconds(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _optionalInt(row[key]);
      if (value != null) return value.clamp(0, 31536000);
    }
    return null;
  }

  static bool _bool(dynamic value) => switch (value) {
    true || 1 => true,
    String text => text.toLowerCase() == 'true' || text == '1',
    _ => false,
  };
  static String _name(Map<String, dynamic> data) =>
      data['name']?.toString() ?? 'Unknown';
  static UpgradeVillage _village(Map<String, dynamic> data) =>
      data['village'] == 'builderBase'
      ? UpgradeVillage.builderBase
      : UpgradeVillage.home;
  static UpgradeVillage _skinVillage(Map<String, dynamic> data) {
    final character = data['character']?.toString().toLowerCase() ?? '';
    return character.startsWith('bb ')
        ? UpgradeVillage.builderBase
        : _village(data);
  }

  static String _villageFolder(Map<String, dynamic> data) =>
      _village(data) == UpgradeVillage.home ? 'home-village' : 'builder-base';
  static String _normalizeResource(dynamic value) =>
      value
          ?.toString()
          .trim()
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_') ??
      'resource';
  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('.', '')
      .replaceAll('?', '')
      .replaceAll(r'\q', '')
      .replaceAll('’', '');
}

class _StaticLookup {
  _StaticLookup(this.bundle) {
    for (final key in const [
      'buildings',
      'traps',
      'troops',
      'guardians',
      'spells',
      'heroes',
      'pets',
      'equipment',
      'decorations',
      'obstacles',
      'sceneries',
      'skins',
      'skins2',
      'capital_house_parts',
      'helpers',
    ]) {
      for (final raw in UpgradeTrackerParser._mapList(bundle[key])) {
        byId[UpgradeTrackerParser._int(raw['_id'])] = raw;
        if (key == 'buildings') _addSeasonal(raw);
      }
    }
  }

  final Map<String, dynamic> bundle;
  final Map<int, Map<String, dynamic>> byId = {};

  void _addSeasonal(Map<String, dynamic> building) {
    for (final seasonal in UpgradeTrackerParser._mapList(
      building['seasonal_defenses'],
    )) {
      byId[UpgradeTrackerParser._int(seasonal['_id'])] = seasonal;
      for (final module in UpgradeTrackerParser._mapList(seasonal['modules'])) {
        byId[UpgradeTrackerParser._int(module['_id'])] = module;
      }
    }
  }
}
