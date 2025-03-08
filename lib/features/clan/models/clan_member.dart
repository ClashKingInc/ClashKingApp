class ClanMember {
  final String tag;
  final String name;
  final String role;
  final int townHallLevel;
  final int expLevel;
  final int trophies;
  final int donations;
  final int donationsReceived;

  ClanMember({
    required this.tag,
    required this.name,
    required this.role,
    required this.townHallLevel,
    required this.expLevel,
    required this.trophies,
    required this.donations,
    required this.donationsReceived,
  });

  factory ClanMember.fromJson(Map<String, dynamic> json) {
    return ClanMember(
      tag: json["tag"],
      name: json["name"],
      role: json["role"],
      townHallLevel: json["townHallLevel"],
      expLevel: json["expLevel"],
      trophies: json["trophies"],
      donations: json["donations"],
      donationsReceived: json["donationsReceived"],
    );
  }
}
