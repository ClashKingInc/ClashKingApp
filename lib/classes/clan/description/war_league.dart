
class WarLeague {
  final int id;
  final String name;
  late String imageUrl;

  WarLeague({required this.id, required this.name});

  factory WarLeague.fromJson(Map<String, dynamic> json) {
    WarLeague warLeague = WarLeague(
      id: json['id'],
      name: json['name'],
    );
    return warLeague;
  }
}