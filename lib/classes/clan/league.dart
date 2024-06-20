import 'package:clashkingapp/classes/clan/icon_urls.dart';

class League {
  final int id;
  final String name;
  final IconUrls imageUrl;

  League({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No name',
      imageUrl: IconUrls.fromJson(json['iconUrls']),
    );
  }
}