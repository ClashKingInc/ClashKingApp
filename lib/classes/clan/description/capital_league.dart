class CapitalLeague {
  final int id;
  final String name;

  CapitalLeague({required this.id, required this.name});

  factory CapitalLeague.fromJson(Map<String, dynamic> json) {
    return CapitalLeague(
      id: json['id'],
      name: json['name'],
    );
  }
}