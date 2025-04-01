class PlayerItem {
  final String name;
  final int level;
  final int maxLevel;
  final String type;
  final String imageUrl;
  final bool isMaxLevel;
  final bool? isActive; // Pour les Super Troupes

  PlayerItem({
    required this.name,
    required this.level,
    required this.maxLevel,
    required this.type,
    required this.imageUrl,
    this.isActive,
  }) : isMaxLevel = level == maxLevel;
}
