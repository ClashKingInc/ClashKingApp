import 'package:collection/collection.dart';

enum UpgradeVillage { home, builderBase }

enum UpgradeCategory {
  defenses,
  guardians,
  craftedDefenses,
  traps,
  army,
  resources,
  troops,
  spells,
  darkTroops,
  sieges,
  heroes,
  equipment,
  pets,
  walls,
  builders,
  supercharge,
}

enum UpgradeQueue { builders, laboratory, pets, none }

enum UpgradeProgressBasis { time, resources, mixed }

enum UpgradeWallResourcePreference { gold, elixir }

enum UpgradePlanStrategy { balanced, shortest, cheapest }

enum UpgradeResourcePreference { conserve, balanced, spend }

enum UpgradePlanGoal { maxCurrentHall, rushNextHall, catchUp, unlockFirst }

enum UpgradeCollectionType {
  skins,
  sceneries,
  decorations,
  obstacles,
  capitalHouseParts,
}

class UpgradeCost {
  const UpgradeCost(this.resource, this.amount);

  final String resource;
  final num amount;
}

class UpgradeStep {
  const UpgradeStep({
    required this.targetLevel,
    required this.costs,
    required this.seconds,
  });

  final int targetLevel;
  final List<UpgradeCost> costs;
  final int seconds;
}

class UpgradeTrackerItem {
  const UpgradeTrackerItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.village,
    required this.category,
    required this.queue,
    required this.currentLevel,
    required this.targetLevel,
    required this.count,
    required this.steps,
    required this.completedUpgradeSeconds,
    required this.totalUpgradeSeconds,
    this.activeSeconds,
    this.helperSeconds,
    this.cooldownSeconds,
    this.recurrentHelper = false,
    this.isExtra = false,
    this.isSupercharge = false,
    this.progressBasis = UpgradeProgressBasis.time,
    this.completedResourceWeight = 0,
    this.totalResourceWeight = 0,
    this.parentName,
    this.meta,
  });

  final int id;
  final String name;
  final String imageUrl;
  final UpgradeVillage village;
  final UpgradeCategory category;
  final UpgradeQueue queue;
  final int currentLevel;
  final int targetLevel;
  final int count;
  final List<UpgradeStep> steps;
  final int completedUpgradeSeconds;
  final int totalUpgradeSeconds;
  final int? activeSeconds;
  final int? helperSeconds;
  final int? cooldownSeconds;
  final bool recurrentHelper;
  final bool isExtra;
  final bool isSupercharge;
  final UpgradeProgressBasis progressBasis;
  final num completedResourceWeight;
  final num totalResourceWeight;
  final String? parentName;
  final Map<String, dynamic>? meta;

  bool get isComplete => currentLevel >= targetLevel;
  bool get isUnbuilt => currentLevel <= 0;
  String get planKey => '$id:${category.name}';
  int get levelsRemaining => (targetLevel - currentLevel).clamp(0, targetLevel);
  int get totalSeconds => steps.fold(0, (sum, step) => sum + step.seconds);

  double get resourceCompletion {
    if (totalResourceWeight > 0) {
      return (completedResourceWeight / totalResourceWeight)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    if (isComplete) return 1;
    if (targetLevel <= 0) return 0;
    return (currentLevel / targetLevel).clamp(0.0, 1.0).toDouble();
  }

  double get progressCompletion => switch (progressBasis) {
    UpgradeProgressBasis.resources => resourceCompletion,
    UpgradeProgressBasis.time =>
      totalUpgradeSeconds <= 0
          ? (isComplete ? 1 : 0)
          : (completedUpgradeSeconds / totalUpgradeSeconds)
                .clamp(0.0, 1.0)
                .toDouble(),
    UpgradeProgressBasis.mixed => resourceCompletion,
  };

  Map<String, num> get totalCosts {
    final result = <String, num>{};
    for (final step in steps) {
      for (final cost in step.costs) {
        result[cost.resource] = (result[cost.resource] ?? 0) + cost.amount;
      }
    }
    return result;
  }
}

class UpgradeEventModifier {
  const UpgradeEventModifier({
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.costReductionPercent,
    required this.timeReductionPercent,
    this.resources = const {},
    this.categories = const {},
  });

  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final int costReductionPercent;
  final int timeReductionPercent;
  final Set<String> resources;
  final Set<UpgradeCategory> categories;

  bool appliesAt(DateTime time, UpgradeTrackerItem item, String resource) {
    if (time.isBefore(startsAt) || !time.isBefore(endsAt)) return false;
    if (resources.isNotEmpty && !resources.contains(resource)) return false;
    if (categories.isNotEmpty && !categories.contains(item.category)) {
      return false;
    }
    return true;
  }
}

class UpgradeBoosts {
  const UpgradeBoosts({
    this.builderBoostSeconds = 0,
    this.labBoostSeconds = 0,
    this.clockTowerBoostSeconds = 0,
    this.clockTowerCooldownSeconds = 0,
    this.builderConsumableSeconds = 0,
    this.labConsumableSeconds = 0,
    this.petConsumableSeconds = 0,
    this.helperCooldownSeconds = 0,
    this.builderCostReductionPercent = 0,
    this.builderTimeReductionPercent = 0,
    this.labCostReductionPercent = 0,
    this.labTimeReductionPercent = 0,
  });

  final int builderBoostSeconds;
  final int labBoostSeconds;
  final int clockTowerBoostSeconds;
  final int clockTowerCooldownSeconds;
  final int builderConsumableSeconds;
  final int labConsumableSeconds;
  final int petConsumableSeconds;
  final int helperCooldownSeconds;
  final int builderCostReductionPercent;
  final int builderTimeReductionPercent;
  final int labCostReductionPercent;
  final int labTimeReductionPercent;

  bool get hasTemporaryBoost =>
      builderBoostSeconds > 0 ||
      labBoostSeconds > 0 ||
      clockTowerBoostSeconds > 0 ||
      builderConsumableSeconds > 0 ||
      labConsumableSeconds > 0 ||
      petConsumableSeconds > 0;
}

class UpgradePlanPreferences {
  const UpgradePlanPreferences({
    this.homeGoal = UpgradePlanGoal.maxCurrentHall,
    this.builderBaseGoal = UpgradePlanGoal.maxCurrentHall,
    this.homeCategoryOrder = const [],
    this.builderBaseCategoryOrder = const [],
    this.homeCategoryTargets = const {},
    this.builderBaseCategoryTargets = const {},
    this.homeCategoryShares = const {},
    this.builderBaseCategoryShares = const {},
    bool? prioritizeUnbuiltBuilders,
    bool? prioritizeUnbuiltLaboratory,
    bool? prioritizeUnbuiltPets,
    this.wallResourcePreference = UpgradeWallResourcePreference.gold,
    this.wallsPerWeek = 0,
  }) : prioritizeUnbuiltBuilders = prioritizeUnbuiltBuilders ?? true,
       prioritizeUnbuiltLaboratory = prioritizeUnbuiltLaboratory ?? true,
       prioritizeUnbuiltPets = prioritizeUnbuiltPets ?? true;

  final UpgradePlanGoal homeGoal;
  final UpgradePlanGoal builderBaseGoal;
  final List<UpgradeCategory> homeCategoryOrder;
  final List<UpgradeCategory> builderBaseCategoryOrder;
  final Map<UpgradeCategory, int> homeCategoryTargets;
  final Map<UpgradeCategory, int> builderBaseCategoryTargets;
  final Map<UpgradeCategory, int> homeCategoryShares;
  final Map<UpgradeCategory, int> builderBaseCategoryShares;
  final bool prioritizeUnbuiltBuilders;
  final bool prioritizeUnbuiltLaboratory;
  final bool prioritizeUnbuiltPets;
  final UpgradeWallResourcePreference wallResourcePreference;
  final int wallsPerWeek;

  bool prioritizeUnbuiltFor(UpgradeQueue queue) => switch (queue) {
    UpgradeQueue.builders => prioritizeUnbuiltBuilders,
    UpgradeQueue.laboratory => prioritizeUnbuiltLaboratory,
    UpgradeQueue.pets => prioritizeUnbuiltPets,
    UpgradeQueue.none => false,
  };

  UpgradePlanGoal goalFor(UpgradeVillage village) =>
      village == UpgradeVillage.home ? homeGoal : builderBaseGoal;

  List<UpgradeCategory> orderFor(UpgradeVillage village) =>
      village == UpgradeVillage.home
      ? homeCategoryOrder
      : builderBaseCategoryOrder;

  int categoryRank(
    UpgradeCategory category, {
    UpgradeVillage village = UpgradeVillage.home,
  }) {
    final order = orderFor(village);
    final index = order.indexOf(category);
    final fallback = _defaultPlanningOrder.indexOf(category);
    return index >= 0 ? index : (fallback >= 0 ? fallback : 999);
  }

  int targetFor(
    UpgradeCategory category, {
    UpgradeVillage village = UpgradeVillage.home,
  }) =>
      (village == UpgradeVillage.home
          ? homeCategoryTargets[category]
          : builderBaseCategoryTargets[category]) ??
      100;

  int shareFor(
    UpgradeCategory category, {
    UpgradeVillage village = UpgradeVillage.home,
  }) =>
      (village == UpgradeVillage.home
          ? homeCategoryShares[category]
          : builderBaseCategoryShares[category]) ??
      0;

  int priorityTierFor(
    UpgradeCategory category, {
    UpgradeVillage village = UpgradeVillage.home,
  }) {
    final savedOrder = orderFor(village);
    final order = [
      ...savedOrder,
      ..._defaultPlanningOrder.where((value) => !savedOrder.contains(value)),
    ];
    var tier = 0;
    var previousWasShared = false;
    for (final value in order) {
      final shared = shareFor(value, village: village) > 0;
      if (tier == 0 || !shared || !previousWasShared) tier += 1;
      if (value == category) return tier;
      previousWasShared = shared;
    }
    return 999;
  }

  Map<String, dynamic> toJson() => {
    'home_goal': homeGoal.name,
    'builder_base_goal': builderBaseGoal.name,
    'home_category_order': homeCategoryOrder
        .map((category) => category.name)
        .toList(),
    'builder_base_category_order': builderBaseCategoryOrder
        .map((category) => category.name)
        .toList(),
    'home_category_targets': {
      for (final entry in homeCategoryTargets.entries)
        entry.key.name: entry.value,
    },
    'builder_base_category_targets': {
      for (final entry in builderBaseCategoryTargets.entries)
        entry.key.name: entry.value,
    },
    'home_category_shares': {
      for (final entry in homeCategoryShares.entries)
        entry.key.name: entry.value,
    },
    'builder_base_category_shares': {
      for (final entry in builderBaseCategoryShares.entries)
        entry.key.name: entry.value,
    },
    'prioritize_unbuilt_builders': prioritizeUnbuiltBuilders,
    'prioritize_unbuilt_laboratory': prioritizeUnbuiltLaboratory,
    'prioritize_unbuilt_pets': prioritizeUnbuiltPets,
    'wall_resource_preference': wallResourcePreference.name,
    'walls_per_week': wallsPerWeek,
  };

  factory UpgradePlanPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UpgradePlanPreferences();
    final legacyOrder = _plannerCategoryOrder(json['category_order']);
    final legacyPrioritizeUnbuilt = _plannerBool(
      json['prioritize_unbuilt'],
      fallback: true,
    );
    return UpgradePlanPreferences(
      homeGoal: _plannerGoal(json['home_goal']),
      builderBaseGoal: _plannerGoal(json['builder_base_goal']),
      homeCategoryOrder:
          _plannerCategoryOrder(json['home_category_order']).isEmpty
          ? legacyOrder
          : _plannerCategoryOrder(json['home_category_order']),
      builderBaseCategoryOrder: _plannerCategoryOrder(
        json['builder_base_category_order'],
      ),
      homeCategoryTargets: _plannerCategoryTargets(
        json['home_category_targets'] ?? json['category_targets'],
      ),
      builderBaseCategoryTargets: _plannerCategoryTargets(
        json['builder_base_category_targets'] ?? json['category_targets'],
      ),
      homeCategoryShares: _plannerCategoryTargets(json['home_category_shares']),
      builderBaseCategoryShares: _plannerCategoryTargets(
        json['builder_base_category_shares'],
      ),
      prioritizeUnbuiltBuilders: _plannerBool(
        json['prioritize_unbuilt_builders'],
        fallback: legacyPrioritizeUnbuilt,
      ),
      prioritizeUnbuiltLaboratory: _plannerBool(
        json['prioritize_unbuilt_laboratory'],
        fallback: legacyPrioritizeUnbuilt,
      ),
      prioritizeUnbuiltPets: _plannerBool(
        json['prioritize_unbuilt_pets'],
        fallback: legacyPrioritizeUnbuilt,
      ),
      wallResourcePreference: _plannerWallResourcePreference(
        json['wall_resource_preference'],
      ),
      wallsPerWeek: _plannerInt(
        json['walls_per_week'],
        fallback: 0,
      ).clamp(0, 100),
    );
  }
}

const _defaultPlanningOrder = [
  UpgradeCategory.defenses,
  UpgradeCategory.craftedDefenses,
  UpgradeCategory.traps,
  UpgradeCategory.army,
  UpgradeCategory.resources,
  UpgradeCategory.heroes,
  UpgradeCategory.guardians,
  UpgradeCategory.troops,
  UpgradeCategory.darkTroops,
  UpgradeCategory.spells,
  UpgradeCategory.sieges,
  UpgradeCategory.equipment,
  UpgradeCategory.pets,
  UpgradeCategory.supercharge,
  UpgradeCategory.walls,
];

UpgradePlanGoal _plannerGoal(Object? raw) =>
    UpgradePlanGoal.values
        .where((value) => value.name == raw?.toString())
        .firstOrNull ??
    UpgradePlanGoal.maxCurrentHall;

UpgradeWallResourcePreference _plannerWallResourcePreference(Object? raw) =>
    UpgradeWallResourcePreference.values
        .where((value) => value.name == raw?.toString())
        .firstOrNull ??
    UpgradeWallResourcePreference.gold;

Map<UpgradeCategory, int> _plannerCategoryTargets(Object? raw) {
  if (raw is! Map) return const {};
  final result = <UpgradeCategory, int>{};
  for (final entry in raw.entries) {
    final category = UpgradeCategory.values
        .where((value) => value.name == entry.key.toString())
        .firstOrNull;
    if (category != null) {
      result[category] = _plannerInt(entry.value, fallback: 100).clamp(1, 100);
    }
  }
  return result;
}

List<UpgradeCategory> _plannerCategoryOrder(Object? raw) {
  if (raw is! List) return const [];
  final result = <UpgradeCategory>[];
  for (final entry in raw) {
    final category = UpgradeCategory.values
        .where((value) => value.name == entry.toString())
        .firstOrNull;
    if (category != null && !result.contains(category)) result.add(category);
  }
  return result;
}

bool _plannerBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

int _plannerInt(Object? value, {required int fallback}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
}

class UpgradeCollectionItem {
  const UpgradeCollectionItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.owned,
    this.village,
    this.count = 0,
    this.maxCount = 1,
    this.subtitle,
    this.meta,
  });

  final int id;
  final String name;
  final String imageUrl;
  final UpgradeCollectionType type;
  final bool owned;
  final UpgradeVillage? village;
  final int count;
  final int maxCount;
  final String? subtitle;
  final Map<String, dynamic>? meta;
}

class UpgradeCategorySummary {
  const UpgradeCategorySummary({
    required this.category,
    required this.basis,
    required this.current,
    required this.target,
    required this.levelsRemaining,
    required this.seconds,
    required this.completedSeconds,
    required this.totalUpgradeSeconds,
    required this.completedProgressWeight,
    required this.totalProgressWeight,
    required this.costs,
  });

  final UpgradeCategory category;
  final UpgradeProgressBasis basis;
  final int current;
  final int target;
  final int levelsRemaining;
  final int seconds;
  final int completedSeconds;
  final int totalUpgradeSeconds;
  final double completedProgressWeight;
  final double totalProgressWeight;
  final Map<String, num> costs;

  double get completion {
    if (basis == UpgradeProgressBasis.time) {
      // A time-based category with no remaining time is complete only when
      // its items are complete; zero-duration equipment and walls use the
      // resource branch below instead.
      if (totalUpgradeSeconds <= 0) {
        return totalProgressWeight <= 0 ? 1 : 0;
      }
      return (completedSeconds / totalUpgradeSeconds)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    if (totalProgressWeight <= 0) return 1;
    return (completedProgressWeight / totalProgressWeight)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class PlannedUpgrade {
  const PlannedUpgrade({
    required this.item,
    required this.instance,
    required this.step,
    required this.startsAt,
    required this.endsAt,
    required this.costs,
    this.isOngoing = false,
  });

  final UpgradeTrackerItem item;
  final int instance;
  final UpgradeStep step;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<UpgradeCost> costs;
  final bool isOngoing;
}

class UpgradePlanLane {
  const UpgradePlanLane({
    required this.index,
    required this.upgrades,
    this.reservedUntil,
  });

  final int index;
  final List<PlannedUpgrade> upgrades;
  final DateTime? reservedUntil;

  DateTime? get finishesAt {
    final lastUpgrade = upgrades.isEmpty ? null : upgrades.last.endsAt;
    if (lastUpgrade == null) return reservedUntil;
    if (reservedUntil == null || lastUpgrade.isAfter(reservedUntil!)) {
      return lastUpgrade;
    }
    return reservedUntil;
  }
}

class UpgradeTrackerSnapshot {
  UpgradeTrackerSnapshot({
    required this.tag,
    required this.name,
    required this.townHallLevel,
    required this.builderHallLevel,
    required this.homeBuilderCount,
    required this.builderBaseBuilderCount,
    required this.items,
    required this.collections,
    required this.boosts,
    required this.events,
    required this.capturedAt,
  });

  final String tag;
  final String name;
  final int townHallLevel;
  final int builderHallLevel;
  final int homeBuilderCount;
  final int builderBaseBuilderCount;
  int get builderCount => homeBuilderCount;

  int buildersFor(UpgradeVillage village) => village == UpgradeVillage.home
      ? homeBuilderCount
      : builderBaseBuilderCount;

  int remainingActiveSeconds(UpgradeTrackerItem item, {DateTime? now}) {
    final original = item.activeSeconds;
    return remainingCapturedSeconds(original ?? 0, now: now);
  }

  int activeElapsedSeconds(UpgradeTrackerItem item, {DateTime? now}) {
    final original = item.activeSeconds;
    final firstStepSeconds = item.steps.firstOrNull?.seconds ?? 0;
    if (original == null || original <= 0 || firstStepSeconds <= 0) return 0;
    final remaining = remainingActiveSeconds(item, now: now);
    return (firstStepSeconds - remaining).clamp(0, firstStepSeconds);
  }

  int remainingCapturedSeconds(int original, {DateTime? now}) {
    if (original <= 0) return 0;
    final elapsed = (now ?? DateTime.now())
        .toUtc()
        .difference(capturedAt)
        .inSeconds;
    return (original - elapsed.clamp(0, original)).clamp(0, original);
  }

  int remainingHelperSeconds(UpgradeTrackerItem item, {DateTime? now}) {
    final original = item.helperSeconds;
    return remainingCapturedSeconds(original ?? 0, now: now);
  }

  int remainingCooldownSeconds(UpgradeTrackerItem item, {DateTime? now}) =>
      remainingCapturedSeconds(item.cooldownSeconds ?? 0, now: now);

  String? helperNameFor(UpgradeTrackerItem item) {
    if ((item.helperSeconds ?? 0) <= 0) return null;
    final helperItems = items.where(
      (candidate) => candidate.category == UpgradeCategory.builders,
    );
    final match = helperItems.where((helper) {
      final normalized = helper.name.toLowerCase();
      return item.queue == UpgradeQueue.laboratory
          ? normalized.contains('lab') || normalized.contains('research')
          : normalized.contains('builder');
    }).firstOrNull;
    return match?.name ??
        (item.queue == UpgradeQueue.laboratory
            ? 'Lab Assistant'
            : 'Builder Apprentice');
  }

  final List<UpgradeTrackerItem> items;
  final List<UpgradeCollectionItem> collections;
  final UpgradeBoosts boosts;
  final List<UpgradeEventModifier> events;
  final DateTime capturedAt;
  final Map<
    (UpgradeVillage?, UpgradeCategory?, UpgradeQueue?, bool),
    List<UpgradeTrackerItem>
  >
  _itemsForCache = {};
  final Map<(UpgradeVillage, UpgradeCategory), UpgradeCategorySummary>
  _summaryCache = {};

  List<UpgradeTrackerItem> itemsFor({
    UpgradeVillage? village,
    UpgradeCategory? category,
    UpgradeQueue? queue,
    bool remainingOnly = false,
  }) {
    final key = (village, category, queue, remainingOnly);
    return _itemsForCache.putIfAbsent(
      key,
      () => items
          .where((item) {
            if (village != null && item.village != village) return false;
            if (category != null && item.category != category) return false;
            if (queue != null && item.queue != queue) return false;
            if (remainingOnly && item.isComplete) return false;
            return true;
          })
          .toList(growable: false),
    );
  }

  UpgradeCategorySummary summaryFor(
    UpgradeCategory category, {
    UpgradeVillage village = UpgradeVillage.home,
  }) {
    return _summaryCache.putIfAbsent(
      (village, category),
      () => summaryForItems(
        itemsFor(village: village, category: category),
        category: category,
      ),
    );
  }

  UpgradeCategorySummary summaryForItems(
    Iterable<UpgradeTrackerItem> matching, {
    UpgradeCategory category = UpgradeCategory.defenses,
  }) {
    var current = 0;
    var target = 0;
    var levelsRemaining = 0;
    var seconds = 0;
    var completedSeconds = 0;
    var totalUpgradeSeconds = 0;
    var timedItems = 0;
    var resourceItems = 0;
    var normalizedCompleted = 0.0;
    var normalizedTotal = 0.0;
    var resourceCompleted = 0.0;
    var resourceTotal = 0.0;
    var weightedResourceCompleted = 0.0;
    var weightedResourceTotal = 0.0;
    var comparableResourceCategories = true;
    UpgradeCategory? resourceCategory;
    final costs = <String, num>{};
    for (final item in matching) {
      final count = item.count.toDouble();
      current += item.currentLevel * item.count;
      target += item.targetLevel * item.count;
      levelsRemaining += item.levelsRemaining * item.count;
      seconds += item.totalSeconds * item.count;
      final itemCompletedSeconds =
          item.completedUpgradeSeconds * item.count +
          activeElapsedSeconds(item);
      completedSeconds += itemCompletedSeconds;
      totalUpgradeSeconds += item.totalUpgradeSeconds * item.count;

      if (item.progressBasis == UpgradeProgressBasis.time) {
        timedItems += item.count;
        final itemTotalSeconds = item.totalUpgradeSeconds.toDouble();
        final ratio = itemTotalSeconds <= 0
            ? (item.isComplete ? 1.0 : 0.0)
            : (itemCompletedSeconds / itemTotalSeconds)
                  .clamp(0.0, 1.0)
                  .toDouble();
        normalizedCompleted += ratio * count;
        normalizedTotal += count;
      } else {
        resourceItems += item.count;
        final ratio = item.resourceCompletion;
        resourceCompleted += ratio * count;
        resourceTotal += count;
        normalizedCompleted += ratio * count;
        normalizedTotal += count;
        final comparable =
            item.category == UpgradeCategory.walls ||
            item.category == UpgradeCategory.equipment ||
            item.category == UpgradeCategory.builders;
        if (!comparable ||
            (resourceCategory != null && resourceCategory != item.category)) {
          comparableResourceCategories = false;
        } else {
          resourceCategory ??= item.category;
          weightedResourceCompleted +=
              item.completedResourceWeight.toDouble() * count;
          weightedResourceTotal += item.totalResourceWeight.toDouble() * count;
        }
      }

      for (final entry in item.totalCosts.entries) {
        costs[entry.key] = (costs[entry.key] ?? 0) + entry.value * item.count;
      }
    }
    final basis = timedItems > 0 && resourceItems > 0
        ? UpgradeProgressBasis.mixed
        : resourceItems > 0
        ? UpgradeProgressBasis.resources
        : UpgradeProgressBasis.time;
    final completedProgressWeight = switch (basis) {
      UpgradeProgressBasis.time =>
        totalUpgradeSeconds > 0
            ? completedSeconds.toDouble()
            : normalizedCompleted,
      UpgradeProgressBasis.resources =>
        comparableResourceCategories
            ? weightedResourceCompleted
            : resourceCompleted,
      UpgradeProgressBasis.mixed => normalizedCompleted,
    };
    final totalProgressWeight = switch (basis) {
      UpgradeProgressBasis.time =>
        totalUpgradeSeconds > 0
            ? totalUpgradeSeconds.toDouble()
            : normalizedTotal,
      UpgradeProgressBasis.resources =>
        comparableResourceCategories ? weightedResourceTotal : resourceTotal,
      UpgradeProgressBasis.mixed => normalizedTotal,
    };
    return UpgradeCategorySummary(
      category: category,
      basis: basis,
      current: current,
      target: target,
      levelsRemaining: levelsRemaining,
      seconds: seconds,
      completedSeconds: completedSeconds,
      totalUpgradeSeconds: totalUpgradeSeconds,
      completedProgressWeight: completedProgressWeight,
      totalProgressWeight: totalProgressWeight,
      costs: costs,
    );
  }

  UpgradeCategorySummary overallSummary({
    UpgradeVillage village = UpgradeVillage.home,
  }) {
    final matching = itemsFor(
      village: village,
    ).where((item) => item.category != UpgradeCategory.builders);
    return summaryForItems(matching, category: UpgradeCategory.army);
  }

  List<UpgradePlanLane> buildPlan({
    required UpgradeQueue queue,
    required UpgradePlanStrategy strategy,
    UpgradeVillage? village,
    DateTime? startsAt,
    Set<String>? includedItemKeys,
    int? goldPassPercent,
    UpgradePlanPreferences preferences = const UpgradePlanPreferences(),
  }) {
    final planStart = startsAt ?? DateTime.now();
    final planVillage = village ?? UpgradeVillage.home;
    final baseLaneCount = switch (queue) {
      UpgradeQueue.builders => buildersFor(planVillage).clamp(1, 7),
      UpgradeQueue.laboratory || UpgradeQueue.pets => 1,
      UpgradeQueue.none => 1,
    };
    final activeWork =
        itemsFor(village: planVillage, queue: queue)
            .map(
              (item) => (
                item: item,
                seconds: remainingActiveSeconds(item, now: planStart),
              ),
            )
            .where((work) => work.seconds > 0)
            .toList()
          ..sort((a, b) => b.seconds.compareTo(a.seconds));
    final laneCount = baseLaneCount > activeWork.length
        ? baseLaneCount
        : activeWork.length;
    final laneEnds = List<DateTime>.filled(laneCount, planStart);
    final reservedUntil = List<DateTime?>.filled(laneCount, null);
    final activeEnds = <UpgradeTrackerItem, DateTime>{};
    for (final work in activeWork) {
      var lane = 0;
      for (var index = 1; index < laneEnds.length; index++) {
        if (laneEnds[index].isBefore(laneEnds[lane])) lane = index;
      }
      final end = laneEnds[lane].add(Duration(seconds: work.seconds));
      laneEnds[lane] = end;
      reservedUntil[lane] = end;
      activeEnds[work.item] = _laterDate(
        activeEnds[work.item] ?? planStart,
        planStart.add(Duration(seconds: work.seconds)),
      );
    }

    final queues = <UpgradeCategory, List<_UpgradeChain>>{};
    for (final item
        in itemsFor(queue: queue, village: village, remainingOnly: true).where(
          (item) =>
              includedItemKeys == null ||
              includedItemKeys.contains(item.planKey),
        )) {
      if (item.steps.isEmpty || item.count <= 0) continue;
      final activeEnd = activeEnds[item];
      if (activeEnd != null) {
        final remainingSteps = item.steps.skip(1).toList(growable: false);
        if (remainingSteps.isNotEmpty) {
          queues
              .putIfAbsent(item.category, () => [])
              .add(
                _UpgradeChain(
                  item,
                  0,
                  remainingSteps,
                  dependencyReadyAt: activeEnd,
                ),
              );
        }
        // The active timer belongs to one physical instance. Reserve its lane
        // and schedule only the other copies; otherwise grouped buildings such
        // as Army Camps appear once as ongoing work and again as an extra
        // future upgrade.
        for (var instance = 1; instance < item.count; instance++) {
          queues
              .putIfAbsent(item.category, () => [])
              .add(
                _UpgradeChain(
                  item,
                  instance,
                  item.steps,
                  dependencyReadyAt: planStart,
                ),
              );
        }
      } else {
        for (var instance = 1; instance <= item.count; instance++) {
          queues
              .putIfAbsent(item.category, () => [])
              .add(
                _UpgradeChain(
                  item,
                  instance,
                  item.steps,
                  dependencyReadyAt: planStart,
                ),
              );
        }
      }
    }

    for (final pool in queues.values) {
      pool.sort(
        (a, b) => _compareChains(
          a,
          b,
          strategy,
          preferences: preferences,
          village: planVillage,
        ),
      );
    }

    final orderedChains = _orderPlanChains(
      this,
      queues.values.expand((pool) => pool).toList(),
      strategy: strategy,
      preferences: preferences,
      village: planVillage,
    );
    final readyChains = HeapPriorityQueue<_PendingUpgradeChain>(
      (a, b) => a.sequence.compareTo(b.sequence),
    );
    final futureChains = HeapPriorityQueue<_PendingUpgradeChain>((a, b) {
      final dependency = a.chain.dependencyReadyAt.compareTo(
        b.chain.dependencyReadyAt,
      );
      return dependency != 0 ? dependency : a.sequence.compareTo(b.sequence);
    });
    var pendingSequence = 0;
    DateTime earliestLaneEnd() {
      var earliest = laneEnds.first;
      for (var index = 1; index < baseLaneCount; index++) {
        if (laneEnds[index].isBefore(earliest)) earliest = laneEnds[index];
      }
      return earliest;
    }

    void enqueue(_UpgradeChain chain) {
      final pending = _PendingUpgradeChain(chain, pendingSequence++);
      if (chain.dependencyReadyAt.isAfter(earliestLaneEnd())) {
        futureChains.add(pending);
      } else {
        readyChains.add(pending);
      }
    }

    for (final chain in orderedChains) {
      enqueue(chain);
    }
    final laneItems = List.generate(laneCount, (_) => <PlannedUpgrade>[]);

    while (readyChains.isNotEmpty || futureChains.isNotEmpty) {
      final laneReadyAt = earliestLaneEnd();
      while (futureChains.isNotEmpty &&
          !futureChains.first.chain.dependencyReadyAt.isAfter(laneReadyAt)) {
        readyChains.add(futureChains.removeFirst());
      }
      final chain =
          (readyChains.isNotEmpty
                  ? readyChains.removeFirst()
                  : futureChains.removeFirst())
              .chain;
      final lane = _laneFor(
        chain.dependencyReadyAt,
        laneEnds,
        laneCount: baseLaneCount,
      );
      final cursor = laneEnds[lane].isAfter(chain.dependencyReadyAt)
          ? laneEnds[lane]
          : chain.dependencyReadyAt;
      final step = chain.nextStep;
      final adjusted = adjustStep(
        chain.item,
        step,
        cursor,
        goldPassPercent: goldPassPercent,
      );
      final end = cursor.add(Duration(seconds: adjusted.seconds));
      laneItems[lane].add(
        PlannedUpgrade(
          item: chain.item,
          instance: chain.instance,
          step: adjusted,
          startsAt: cursor,
          endsAt: end,
          costs: adjusted.costs,
        ),
      );
      laneEnds[lane] = end;
      chain.advance(end);
      if (chain.hasNextStep) enqueue(chain);
    }

    return List.generate(
      laneCount,
      (index) => UpgradePlanLane(
        index: index,
        upgrades: laneItems[index],
        reservedUntil: reservedUntil[index],
      ),
    );
  }

  UpgradeStep adjustStep(
    UpgradeTrackerItem item,
    UpgradeStep step,
    DateTime startsAt, {
    int? goldPassPercent,
  }) {
    final parsedGoldPassCost = switch (item.queue) {
      UpgradeQueue.builders => boosts.builderCostReductionPercent,
      UpgradeQueue.laboratory ||
      UpgradeQueue.pets => boosts.labCostReductionPercent,
      UpgradeQueue.none => 0,
    };
    final parsedGoldPassTime = switch (item.queue) {
      UpgradeQueue.builders => boosts.builderTimeReductionPercent,
      UpgradeQueue.laboratory ||
      UpgradeQueue.pets => boosts.labTimeReductionPercent,
      UpgradeQueue.none => 0,
    };
    final goldPassCost = goldPassPercent ?? parsedGoldPassCost;
    final goldPassTime = goldPassPercent ?? parsedGoldPassTime;

    var timeReduction = goldPassTime;
    final adjustedCosts = <UpgradeCost>[];
    for (final cost in step.costs) {
      var costReduction = goldPassCost;
      for (final event in events) {
        if (event.appliesAt(startsAt, item, cost.resource)) {
          costReduction = _combineReductions(
            costReduction,
            event.costReductionPercent,
          );
          timeReduction = _combineReductions(
            timeReduction,
            event.timeReductionPercent,
          );
        }
      }
      adjustedCosts.add(
        UpgradeCost(
          cost.resource,
          (cost.amount * (100 - costReduction) / 100).round(),
        ),
      );
    }
    return UpgradeStep(
      targetLevel: step.targetLevel,
      costs: adjustedCosts,
      seconds: (step.seconds * (100 - timeReduction) / 100).round(),
    );
  }

  static int _combineReductions(int first, int second) {
    final remaining = (100 - first) * (100 - second) / 100;
    return (100 - remaining).round().clamp(0, 95);
  }

  static int _compareChains(
    _UpgradeChain a,
    _UpgradeChain b,
    UpgradePlanStrategy strategy, {
    required UpgradePlanPreferences preferences,
    required UpgradeVillage village,
  }) {
    int totalSeconds(_UpgradeChain chain) =>
        chain.steps.fold(0, (sum, step) => sum + step.seconds);
    num totalCost(_UpgradeChain chain) => chain.steps.fold<num>(
      0,
      (sum, step) =>
          sum + step.costs.fold<num>(0, (cost, entry) => cost + entry.amount),
    );
    if (strategy != UpgradePlanStrategy.balanced) {
      return switch (strategy) {
        UpgradePlanStrategy.shortest => totalSeconds(
          a,
        ).compareTo(totalSeconds(b)),
        UpgradePlanStrategy.cheapest => totalCost(a).compareTo(totalCost(b)),
        UpgradePlanStrategy.balanced => 0,
      };
    }

    if (preferences.prioritizeUnbuiltFor(a.item.queue) &&
        a.item.isUnbuilt != b.item.isUnbuilt) {
      return a.item.isUnbuilt ? -1 : 1;
    }
    return totalSeconds(b).compareTo(totalSeconds(a));
  }
}

class _UpgradeChain {
  _UpgradeChain(
    this.item,
    this.instance,
    this.steps, {
    required this.dependencyReadyAt,
  });

  final UpgradeTrackerItem item;
  final int instance;
  final List<UpgradeStep> steps;
  DateTime dependencyReadyAt;
  int nextStepIndex = 0;

  bool get hasNextStep => nextStepIndex < steps.length;
  UpgradeStep get nextStep => steps[nextStepIndex];

  void advance(DateTime endsAt) {
    nextStepIndex += 1;
    dependencyReadyAt = endsAt;
  }
}

class _PendingUpgradeChain {
  const _PendingUpgradeChain(this.chain, this.sequence);

  final _UpgradeChain chain;
  final int sequence;
}

int _laneFor(
  DateTime dependencyReadyAt,
  List<DateTime> laneEnds, {
  required int laneCount,
}) {
  var selected = 0;
  var selectedStart = _laterDate(laneEnds.first, dependencyReadyAt);
  for (var index = 1; index < laneCount; index++) {
    final start = _laterDate(laneEnds[index], dependencyReadyAt);
    if (start.isBefore(selectedStart) ||
        (start.isAtSameMomentAs(selectedStart) &&
            laneEnds[index].isBefore(laneEnds[selected]))) {
      selected = index;
      selectedStart = start;
    }
  }
  return selected;
}

List<_UpgradeChain> _orderPlanChains(
  UpgradeTrackerSnapshot snapshot,
  List<_UpgradeChain> chains, {
  required UpgradePlanStrategy strategy,
  required UpgradePlanPreferences preferences,
  required UpgradeVillage village,
}) {
  final pools = <UpgradeCategory, List<_UpgradeChain>>{};
  for (final chain in chains) {
    pools.putIfAbsent(chain.item.category, () => []).add(chain);
  }
  for (final pool in pools.values) {
    pool.sort(
      (a, b) => UpgradeTrackerSnapshot._compareChains(
        a,
        b,
        strategy,
        preferences: preferences,
        village: village,
      ),
    );
  }

  final categories = pools.keys.toList()
    ..sort((a, b) {
      final tier = preferences
          .priorityTierFor(a, village: village)
          .compareTo(preferences.priorityTierFor(b, village: village));
      return tier != 0
          ? tier
          : preferences
                .categoryRank(a, village: village)
                .compareTo(preferences.categoryRank(b, village: village));
    });
  final ordered = <_UpgradeChain>[];
  var categoryIndex = 0;

  void appendCategories(List<UpgradeCategory> values) {
    if (values.isEmpty) return;
    if (values.length == 1 ||
        values.any(
          (value) => preferences.shareFor(value, village: village) <= 0,
        )) {
      for (final value in values) {
        ordered.addAll(pools[value]!);
      }
      return;
    }

    final remaining = {
      for (final value in values) value: [...pools[value]!],
    };
    final scores = {for (final value in values) value: 0};
    while (remaining.values.any((pool) => pool.isNotEmpty)) {
      final active = remaining.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key)
          .toList(growable: false);
      final totalWeight = active.fold<int>(
        0,
        (sum, value) => sum + preferences.shareFor(value, village: village),
      );
      for (final value in active) {
        scores[value] =
            (scores[value] ?? 0) +
            preferences.shareFor(value, village: village);
      }
      active.sort((a, b) {
        final score = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
        return score != 0
            ? score
            : preferences
                  .categoryRank(a, village: village)
                  .compareTo(preferences.categoryRank(b, village: village));
      });
      final selected = active.first;
      ordered.add(remaining[selected]!.removeAt(0));
      scores[selected] = (scores[selected] ?? 0) - totalWeight;
    }
  }

  while (categoryIndex < categories.length) {
    final tier = preferences.priorityTierFor(
      categories[categoryIndex],
      village: village,
    );
    final tierCategories = <UpgradeCategory>[];
    while (categoryIndex < categories.length &&
        preferences.priorityTierFor(
              categories[categoryIndex],
              village: village,
            ) ==
            tier) {
      tierCategories.add(categories[categoryIndex]);
      categoryIndex += 1;
    }
    final pending = tierCategories
        .where(
          (value) =>
              snapshot.summaryFor(value, village: village).completion * 100 <
              preferences.targetFor(value, village: village),
        )
        .toList(growable: false);
    final reached = tierCategories
        .where((value) => !pending.contains(value))
        .toList(growable: false);
    appendCategories(pending);
    appendCategories(reached);
  }
  return ordered;
}

DateTime _laterDate(DateTime first, DateTime second) =>
    first.isAfter(second) ? first : second;
