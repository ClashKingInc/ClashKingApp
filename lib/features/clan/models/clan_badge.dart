import 'package:clashkingapp/core/services/api_service.dart';

class ClanBadgeUrls {
  final String small;
  final String medium;
  final String large;

  ClanBadgeUrls({
    required this.small,
    required this.medium,
    required this.large,
  });

  factory ClanBadgeUrls.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};

    return ClanBadgeUrls(
      small: ApiService.cocAssetsProxyUrl(data["small"]?.toString() ?? ""),
      medium: ApiService.cocAssetsProxyUrl(data["medium"]?.toString() ?? ""),
      large: ApiService.cocAssetsProxyUrl(data["large"]?.toString() ?? ""),
    );
  }

  factory ClanBadgeUrls.empty() =>
      ClanBadgeUrls(small: 'No small', medium: 'No medium', large: 'No large');
}
