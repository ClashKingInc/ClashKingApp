import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_parser.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = UpgradeTrackerParser();

  test('parses raw IDs and uses the correct cost direction', () {
    final snapshot = parser.parse(
      {
        'tag': '#TEST',
        'name': 'Chief',
        'timestamp': 1783752646,
        'buildings': [
          {'data': 1, 'lvl': 18},
          {'data': 2, 'lvl': 1, 'cnt': 5},
          {'data': 3, 'lvl': 16, 'cnt': 2, 'supercharge': 1},
          {
            'data': 4,
            'types': [
              {
                'data': 40,
                'modules': [
                  {'data': 41, 'lvl': 1},
                ],
              },
            ],
          },
        ],
        'units': [
          {'data': 5, 'lvl': 11},
        ],
        'equipment': [
          {'data': 6, 'lvl': 1},
        ],
        'skins': [7],
        'sceneries': [8],
        'decos': [
          {'data': 9, 'cnt': 3},
        ],
        'obstacles': [
          {'data': 10, 'cnt': 2},
        ],
        'house_parts': [11],
        'boosts': {'builder_cost_reduction': 20, 'builder_time_reduction': 20},
      },
      staticData: _bundle,
      now: DateTime.utc(2026, 7, 11),
    );

    expect(snapshot.townHallLevel, 18);
    expect(snapshot.builderCount, 5);

    final mine = snapshot.items.firstWhere((item) => item.name == 'Gold Mine');
    expect(mine.currentLevel, 16);
    expect(mine.targetLevel, 17);
    expect(mine.steps.single.costs.single.amount, 8000000);
    expect(mine.steps.single.seconds, 172800);
    expect(mine.count, 2);

    final troop = snapshot.items.firstWhere((item) => item.name == 'Barbarian');
    expect(troop.steps.single.costs.single.amount, 8000000);
    expect(troop.steps.single.seconds, 345600);

    final crafted = snapshot.items.firstWhere(
      (item) => item.category == UpgradeCategory.craftedDefenses,
    );
    expect(crafted.name, 'Roaster HP Module');
    expect(crafted.steps.single.targetLevel, 2);

    final supercharge = snapshot.items.firstWhere((item) => item.isSupercharge);
    expect(supercharge.currentLevel, 1);
    expect(supercharge.targetLevel, 2);

    expect(
      snapshot.collections
          .firstWhere((item) => item.type == UpgradeCollectionType.decorations)
          .count,
      3,
    );
    expect(
      snapshot.collections
          .firstWhere((item) => item.type == UpgradeCollectionType.decorations)
          .maxCount,
      4,
    );
    expect(snapshot.collections.where((item) => item.owned), hasLength(5));
  });

  test('applies durable reductions without prototype events', () {
    final snapshot = parser.parse(
      {
        'tag': '#TEST',
        'buildings': [
          {'data': 1, 'lvl': 18},
          {'data': 2, 'lvl': 1, 'cnt': 1},
          {'data': 3, 'lvl': 16},
        ],
        'boosts': {'builder_cost_reduction': 20, 'builder_time_reduction': 20},
      },
      staticData: _bundle,
      now: DateTime.utc(2026, 7, 11),
    );
    final mine = snapshot.items.firstWhere((item) => item.name == 'Gold Mine');
    final adjusted = snapshot.adjustStep(
      mine,
      mine.steps.single,
      DateTime.utc(2026, 7, 11),
    );

    expect(adjusted.costs.single.amount, 6400000);
    expect(adjusted.seconds, 138240);

    final afterEvent = snapshot.adjustStep(
      mine,
      mine.steps.single,
      DateTime.utc(2026, 7, 16),
    );
    expect(afterEvent.costs.single.amount, 6400000);
    expect(afterEvent.seconds, 138240);
  });

  test('infers separate builder capacities and advances active timers', () {
    final capturedAt = DateTime.utc(2026, 7, 11, 10);
    final snapshot = parser.parse(
      {
        'tag': '#TEST',
        'timestamp': capturedAt.millisecondsSinceEpoch ~/ 1000,
        'buildings': [
          {'data': 1, 'lvl': 18},
          {'data': 2, 'lvl': 1, 'cnt': 5},
          {'data': 12, 'lvl': 1},
          {'data': 3, 'lvl': 16, 'timer': 3600},
        ],
        'buildings2': [
          {'data': 13, 'lvl': 6},
        ],
      },
      staticData: _bundle,
      now: capturedAt,
    );

    expect(snapshot.homeBuilderCount, 6);
    expect(snapshot.builderBaseBuilderCount, 2);
    final mine = snapshot.items.firstWhere((item) => item.name == 'Gold Mine');
    expect(
      snapshot.remainingActiveSeconds(
        mine,
        now: capturedAt.add(const Duration(minutes: 15)),
      ),
      2700,
    );
  });

  test('weights helper completion by gems spent', () {
    final snapshot = parser.parse(
      {
        'tag': '#TEST',
        'buildings': [
          {'data': 1, 'lvl': 18},
        ],
        'helpers': [
          {'data': 20, 'lvl': 2},
          {'data': 21, 'lvl': 1},
        ],
      },
      staticData: _bundle,
      now: DateTime.utc(2026, 7, 11),
    );

    final helpers = snapshot.itemsFor(
      village: UpgradeVillage.home,
      category: UpgradeCategory.builders,
      queue: UpgradeQueue.none,
    );
    final summary = snapshot.summaryForItems(helpers);

    expect(helpers, hasLength(2));
    expect(summary.completion, closeTo(0.05, 0.0001));
  });

  test('active grouped building consumes one planned instance', () {
    final capturedAt = DateTime.utc(2026, 7, 11, 10);
    final snapshot = parser.parse(
      {
        'tag': '#TEST',
        'timestamp': capturedAt.millisecondsSinceEpoch ~/ 1000,
        'buildings': [
          {'data': 1, 'lvl': 18},
          {'data': 2, 'lvl': 1, 'cnt': 5},
          {'data': 3, 'lvl': 16, 'cnt': 2, 'timer': 3600},
        ],
      },
      staticData: _bundle,
      now: capturedAt,
    );

    final plan = snapshot.buildPlan(
      queue: UpgradeQueue.builders,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: capturedAt,
    );
    final futureMineUpgrades = plan
        .expand((lane) => lane.upgrades)
        .where((upgrade) => upgrade.item.name == 'Gold Mine')
        .toList();

    expect(futureMineUpgrades, hasLength(1));
  });

  test('planner preserves pending-chain order as dependencies advance', () {
    final startsAt = DateTime.utc(2026, 7, 11);
    UpgradeTrackerItem item(int id, String name, List<int> durations) =>
        UpgradeTrackerItem(
          id: id,
          name: name,
          imageUrl: 'https://example.com/$id.png',
          village: UpgradeVillage.home,
          category: UpgradeCategory.defenses,
          queue: UpgradeQueue.builders,
          currentLevel: 0,
          targetLevel: durations.length,
          count: 1,
          steps: [
            for (var index = 0; index < durations.length; index++)
              UpgradeStep(
                targetLevel: index + 1,
                costs: const [UpgradeCost('gold', 1)],
                seconds: durations[index],
              ),
          ],
          completedUpgradeSeconds: 0,
          totalUpgradeSeconds: durations.fold(
            0,
            (total, value) => total + value,
          ),
        );

    final snapshot = UpgradeTrackerSnapshot(
      tag: '#TEST',
      name: 'Chief',
      townHallLevel: 18,
      builderHallLevel: 0,
      homeBuilderCount: 1,
      builderBaseBuilderCount: 1,
      items: [
        item(1, 'Long', const [10, 10]),
        item(2, 'Short', const [5, 5]),
      ],
      collections: const [],
      boosts: const UpgradeBoosts(),
      events: const [],
      capturedAt: startsAt,
    );

    final plan = snapshot.buildPlan(
      queue: UpgradeQueue.builders,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: startsAt,
    );

    expect(
      plan.single.upgrades
          .map((upgrade) => '${upgrade.item.name}:${upgrade.step.targetLevel}')
          .toList(),
      ['Long:1', 'Short:1', 'Long:2', 'Short:2'],
    );
  });
}

final _bundle = <String, dynamic>{
  'buildings': [
    {
      '_id': 1,
      'name': 'Town Hall',
      'village': 'home',
      'type': 'Town Hall',
      'upgrade_resource': 'Gold',
      'levels': [
        {
          'level': 18,
          'build_cost': 1,
          'build_time': 1,
          'required_townhall': 18,
        },
      ],
    },
    {
      '_id': 2,
      'name': "Builder's Hut",
      'village': 'home',
      'type': 'Worker',
      'upgrade_resource': 'Gold',
      'levels': [
        {'level': 1, 'build_cost': 1, 'build_time': 1, 'required_townhall': 1},
      ],
    },
    {
      '_id': 3,
      'name': 'Gold Mine',
      'village': 'home',
      'type': 'Resource',
      'upgrade_resource': 'Elixir',
      'superchargeable': true,
      'levels': [
        {
          'level': 16,
          'build_cost': 2000000,
          'build_time': 86400,
          'required_townhall': 15,
        },
        {
          'level': 17,
          'build_cost': 8000000,
          'build_time': 172800,
          'required_townhall': 16,
          'supercharge': {
            'upgrade_resource': 'Elixir',
            'levels': [
              {'level': 1, 'build_cost': 1700000, 'build_time': 172800},
              {'level': 2, 'build_cost': 1500000, 'build_time': 259200},
            ],
          },
        },
      ],
    },
    {
      '_id': 4,
      'name': 'Crafting Station',
      'village': 'home',
      'type': 'Defense',
      'upgrade_resource': 'Gold',
      'levels': <Map<String, dynamic>>[],
      'seasonal_defenses': [
        {
          '_id': 40,
          'name': 'Roaster',
          'modules': [
            {
              '_id': 41,
              'name': 'Roaster HP Module',
              'upgrade_resource': 'Elixir',
              'levels': [
                {'level': 1, 'build_cost': 0, 'build_time': 0},
                {'level': 2, 'build_cost': 3500000, 'build_time': 21600},
              ],
            },
          ],
        },
      ],
    },
    {
      '_id': 12,
      'name': "B.O.B's Hut",
      'village': 'home',
      'type': 'Worker',
      'upgrade_resource': 'Gold',
      'levels': [
        {'level': 1, 'build_cost': 1, 'build_time': 1},
      ],
    },
    {
      '_id': 13,
      'name': 'Builder Hall',
      'village': 'builderBase',
      'type': 'Town Hall',
      'upgrade_resource': 'Builder Gold',
      'levels': [
        {'level': 6, 'build_cost': 1, 'build_time': 1},
      ],
    },
  ],
  'traps': <Map<String, dynamic>>[],
  'guardians': <Map<String, dynamic>>[],
  'troops': [
    {
      '_id': 5,
      'name': 'Barbarian',
      'village': 'home',
      'production_building': 'Laboratory',
      'upgrade_resource': 'Elixir',
      'levels': [
        {
          'level': 11,
          'upgrade_cost': 8000000,
          'upgrade_time': 345600,
          'required_townhall': 15,
        },
        {
          'level': 12,
          'upgrade_cost': 0,
          'upgrade_time': 0,
          'required_townhall': 16,
        },
      ],
    },
  ],
  'spells': <Map<String, dynamic>>[],
  'heroes': <Map<String, dynamic>>[],
  'pets': <Map<String, dynamic>>[],
  'equipment': [
    {
      '_id': 6,
      'name': 'Barbarian Puppet',
      'village': 'home',
      'levels': [
        {
          'level': 1,
          'upgrade_cost': {'shiny_ore': 120},
          'required_townhall': 8,
        },
        {
          'level': 2,
          'upgrade_cost': {'shiny_ore': 0},
          'required_townhall': 8,
        },
      ],
    },
  ],
  'skins': [
    {
      '_id': 7,
      'name': 'Gladiator King',
      'tier': 'Gold',
      'character': 'Barbarian King',
    },
  ],
  'sceneries': [
    {
      '_id': 8,
      'name': 'Epic Scenery',
      'thumbnail': 'sceneries/epic/thumbnail.webp',
    },
  ],
  'decorations': [
    {'_id': 9, 'name': 'Torch', 'village': 'home', 'max_count': 4},
  ],
  'obstacles': [
    {'_id': 10, 'name': 'Tree', 'village': 'home'},
  ],
  'capital_house_parts': [
    {'_id': 11, 'name': 'Fence', 'slot_type': 'decoration'},
  ],
  'helpers': [
    {
      '_id': 20,
      'name': 'Builder Apprentice',
      'village': 'home',
      'upgrade_resource': 'Gems',
      'levels': [
        {'level': 1, 'upgrade_cost': 100},
        {'level': 2, 'upgrade_cost': 900},
        {'level': 3, 'upgrade_cost': 0},
      ],
    },
    {
      '_id': 21,
      'name': 'Lab Assistant',
      'village': 'home',
      'upgrade_resource': 'Gems',
      'levels': [
        {'level': 1, 'upgrade_cost': 1000},
        {'level': 2, 'upgrade_cost': 0},
      ],
    },
  ],
};
