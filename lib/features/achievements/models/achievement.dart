enum AchievementId { downhill18, warWarrior, mrLegend, defenseDoesntMatter }

class Achievement {
  const Achievement({
    required this.id,
    required this.modelUrl,
    required this.isUnlocked,
    required this.earnedCount,
    required this.isRepeatable,
  });

  final AchievementId id;
  final String modelUrl;
  final bool isUnlocked;
  final int earnedCount;
  final bool isRepeatable;
}

const mockAchievements = <Achievement>[
  Achievement(
    id: AchievementId.downhill18,
    modelUrl:
        'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
    isUnlocked: true,
    earnedCount: 1,
    isRepeatable: false,
  ),
  Achievement(
    id: AchievementId.warWarrior,
    modelUrl:
        'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
    isUnlocked: false,
    earnedCount: 0,
    isRepeatable: false,
  ),
  Achievement(
    id: AchievementId.mrLegend,
    modelUrl:
        'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
    isUnlocked: true,
    earnedCount: 4,
    isRepeatable: true,
  ),
  Achievement(
    id: AchievementId.defenseDoesntMatter,
    modelUrl:
        'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
    isUnlocked: true,
    earnedCount: 2,
    isRepeatable: true,
  ),
];
