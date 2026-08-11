enum AchievementId { townhall18, warWarrior, mrLegend, defenseDoesntMatter }

extension AchievementIdApi on AchievementId {
  String get apiId => switch (this) {
    AchievementId.townhall18 => 'townhall_18',
    AchievementId.warWarrior => 'war_warrior',
    AchievementId.mrLegend => 'mr_legend',
    AchievementId.defenseDoesntMatter => 'defense_doesnt_matter',
  };

  static AchievementId? tryParse(String value) {
    for (final id in AchievementId.values) {
      if (id.apiId == value) return id;
    }
    return null;
  }
}

class Achievement {
  const Achievement({
    required this.id,
    required this.modelUrl,
    required this.earnedCount,
    required this.isRepeatable,
  });

  final AchievementId id;
  final String modelUrl;
  final int earnedCount;
  final bool isRepeatable;

  bool get isUnlocked => earnedCount > 0;
}

const achievementCatalogFallback = <Achievement>[
  Achievement(
    id: AchievementId.townhall18,
    modelUrl:
        'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  ),
  Achievement(
    id: AchievementId.warWarrior,
    modelUrl:
        'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  ),
  Achievement(
    id: AchievementId.mrLegend,
    modelUrl:
        'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  ),
  Achievement(
    id: AchievementId.defenseDoesntMatter,
    modelUrl:
        'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  ),
];
