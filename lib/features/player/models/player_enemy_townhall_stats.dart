class EnemyTownhallStats {
  final double averageStars;
  double averageDestruction;
  int count;
  final Map<String, int> starsCount;

  EnemyTownhallStats({
    required this.averageStars,
    required this.averageDestruction,
    required this.count,
    required this.starsCount,
  });

  factory EnemyTownhallStats.fromJson(Map<String, dynamic> json) {
    return EnemyTownhallStats(
      averageStars: (json['averageStars'] as num).toDouble(),
      averageDestruction: (json['averageDestruction'] as num).toDouble(),
      count: json['count'],
      starsCount: Map<String, int>.from(json['starsCount']),
    );
  }

  get starsCountDef => null;

  void merge(EnemyTownhallStats other) {
    final newCount = count + other.count;
    averageDestruction = newCount > 0
        ? ((averageDestruction * count) +
                (other.averageDestruction * other.count)) /
            newCount
        : 0.0;
    count = newCount;

    for (var k in starsCount.keys) {
      starsCount[k] = (starsCount[k] ?? 0) + (other.starsCount[k] ?? 0);
    }
  }

  EnemyTownhallStats copy() {
    return EnemyTownhallStats(
      averageStars: averageStars,
      averageDestruction: averageDestruction,
      count: count,
      starsCount: Map<String, int>.from(starsCount),
    );
  }
}
