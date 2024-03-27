class CurrentWarInfo {
  final String state;
  final int teamSize;
  final int attacksPerMember;
  final DateTime preparationStartTime;
  final DateTime startTime;
  final DateTime endTime;
  final ClanWarDetails clan;
  final ClanWarDetails opponent;

  CurrentWarInfo({
    required this.state,
    required this.teamSize,
    required this.attacksPerMember,
    required this.preparationStartTime,
    required this.startTime,
    required this.endTime,
    required this.clan,
    required this.opponent,
  });

  factory CurrentWarInfo.fromJson(Map<String, dynamic> json) {
    return CurrentWarInfo(
      state: json['state'],
      teamSize: json['teamSize'],
      attacksPerMember: json['attacksPerMember'],
      preparationStartTime: DateTime.parse(json['preparationStartTime']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      clan: ClanWarDetails.fromJson(json['clan']),
      opponent: ClanWarDetails.fromJson(json['opponent']),
    );
  }
}

class ClanWarDetails {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
  final int clanLevel;
  final List<WarMember> members;

  ClanWarDetails({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.members,
  });

  factory ClanWarDetails.fromJson(Map<String, dynamic> json) {
    return ClanWarDetails(
      tag: json['tag'],
      name: json['name'],
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
      clanLevel: json['clanLevel'],
      members: List<WarMember>.from(json['members'].map((x) => WarMember.fromJson(x))),
    );
  }
}

class BadgeUrls {
  final String small;
  final String large;
  final String medium;

  BadgeUrls({
    required this.small,
    required this.large,
    required this.medium,
  });

  factory BadgeUrls.fromJson(Map<String, dynamic> json) {
    return BadgeUrls(
      small: json['small'],
      large: json['large'],
      medium: json['medium'],
    );
  }
}

class WarMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;

  WarMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
  });

  factory WarMember.fromJson(Map<String, dynamic> json) {
    return WarMember(
      tag: json['tag'],
      name: json['name'],
      townhallLevel: json['townhallLevel'],
      mapPosition: json['mapPosition'],
    );
  }
}
