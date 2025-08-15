class IconUrls {
  final String small;
  final String tiny;
  final String medium;

  IconUrls({
    required this.small,
    required this.tiny,
    required this.medium,
  });

  factory IconUrls.fromJson(Map<String, dynamic> json) {
    return IconUrls(
      small: json['small'] ?? 'No small image URL',
      tiny: json['tiny'] ?? 'No tiny image URL',
      medium: json['medium'] ?? 'No medium image URL',
    );
  }

  static IconUrls defaultIconUrls() {
    return IconUrls(
      small: '',
      tiny: '',
      medium: '',
    );
  }
}