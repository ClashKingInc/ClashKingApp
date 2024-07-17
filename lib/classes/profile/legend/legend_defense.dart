

class Defense {
  final int change;
  final int time;
  final int trophies;

  Defense({
    required this.change,
    required this.time,
    required this.trophies,
  });

  factory Defense.fromJson(Map<String, dynamic> json) {
    return Defense(
      change: json['change'],
      time: json['time'],
      trophies: json['trophies'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'change': change,
      'time': time,
      'trophies': trophies,
    };
  }
}
