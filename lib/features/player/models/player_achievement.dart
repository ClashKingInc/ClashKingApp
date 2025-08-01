
class PlayerAchievement {
  final String name;
  final int stars;
  final int value;
  final int target;
  final String info;
  final String completionInfo;
  final String village;

  PlayerAchievement(
      {required this.name,
      required this.stars,
      required this.value,
      required this.target,
      this.info = '',
      this.completionInfo = '',
      this.village = ''});

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) {
    return PlayerAchievement(
      name: json['name'] ?? 'No name',
      stars: json['stars'] ?? 0,
      value: json['value'] ?? 0,
      target: json['target'] ?? 0,
      info: json['info'] ?? '',
      completionInfo: json['completionInfo'] ?? '',
      village: json['village'] ?? 'home',
    );
  }
}
