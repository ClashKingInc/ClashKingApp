
class Location {
  final String localizedName;
  final int id;
  final String name;
  final bool isCountry;
  final String countryCode;

  Location(
      {required this.localizedName,
      required this.id,
      required this.name,
      required this.isCountry,
      required this.countryCode});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      localizedName: json['localizedName'] ?? 'No localizedName',
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown country',
      isCountry: json['isCountry'] ?? false,
      countryCode: json['countryCode'] ?? 'No countryCode',
    );
  }
}