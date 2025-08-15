
class LegendRanking {
  final String localRank;
  final String countryName;
  final String globalRank;
  final bool isRankedLocally;
  final String countryCode;
  final bool isRankedGlobally;

  LegendRanking(
      {required this.localRank,
      required this.countryName,
      required this.globalRank,
      required this.isRankedLocally,
      required this.isRankedGlobally,
      required this.countryCode});

  factory LegendRanking.fromJson(Map<String, dynamic> json) {
    return LegendRanking(
        localRank: json['local_rank']?.toString() ?? '200+',
        isRankedLocally: json['local_rank'] != null,
        countryName: json['country_name'] ?? '',
        globalRank:
            json['global_rank'] == null ? '' : json['global_rank'].toString(),
        isRankedGlobally: json['global_rank'] != null,
        countryCode: json['country_code'] ?? '');
  }
}