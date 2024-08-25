
class BuilderBaseLeague {
  final int id;
  final String name;

  BuilderBaseLeague({
    required this.id,
    required this.name,
  });

  factory BuilderBaseLeague.fromJson(Map<String, dynamic> json) {
    return BuilderBaseLeague(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No name',
    );
  }

  static BuilderBaseLeague defaultBuilderBaseLeague() {
    return BuilderBaseLeague(
      id: 0,
      name: '',
    );
  }
}