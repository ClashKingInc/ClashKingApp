import 'package:clashkingapp/core/services/api_service.dart';

class ClanBadgeUrls {
  final String small;
  final String medium;
  final String large;

  ClanBadgeUrls(
      {required this.small, required this.medium, required this.large});

  factory ClanBadgeUrls.fromJson(Map<String, dynamic> json) {
    return ClanBadgeUrls(
      small: ApiService.cocAssetsProxyUrl(json["small"]),
      medium: ApiService.cocAssetsProxyUrl(json["medium"]),
      large: ApiService.cocAssetsProxyUrl(json["large"]),
    );
  }

  factory ClanBadgeUrls.empty() => ClanBadgeUrls(
        small: 'No small',
        medium: 'No medium',
        large: 'No large',
      );
}
