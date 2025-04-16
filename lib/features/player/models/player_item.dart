class PlayerItem {
  final String name;
  final int level;
  final int maxLevel;
  final String type;
  final String imageUrl;
  final bool isMaxLevel;
  final bool? isActive;
  final bool isUnlocked;

  PlayerItem({
    required this.name,
    required this.level,
    required this.maxLevel,
    required this.type,
    required this.imageUrl,
    required this.isUnlocked,
    this.isActive,
  }) : isMaxLevel = level == maxLevel;
}
