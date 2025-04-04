class CwlLeagueRound {
  final int roundNumber;
  final List<String> warTags;

  CwlLeagueRound({required this.roundNumber, required this.warTags});

  factory CwlLeagueRound.fromJson(Map<String, dynamic> json, int index) {
    return CwlLeagueRound(
      roundNumber: index + 1,
      warTags: List<String>.from(json['warTags'] ?? []),
    );
  }

  bool containsWar(String? warTag) => warTag != null && warTags.contains(warTag);
}