class AppAnnouncement {
  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.subtitle,
    this.version,
    this.body,
    this.bannerImageUrl,
    this.htmlUrl,
    this.storyUrl,
    this.startsAt,
    this.endsAt,
  });

  static const animeFury = AppAnnouncement(
    id: 'anime-fury-june-2026',
    version: '2',
    title: 'Anime Fury',
    subtitle: 'Tap through the June 2026 update',
    storyUrl:
        'https://pub-b12e7ef181d94b7199105ec0e0c2ee83.r2.dev/anime-fury-story.html',
  );

  final String id;
  final String title;
  final String subtitle;
  final String? version;
  final String? body;
  final String? bannerImageUrl;
  final String? htmlUrl;
  final String? storyUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get hasReadableBody =>
      storyUrl != null ||
      (body != null && body!.trim().isNotEmpty) ||
      (htmlUrl != null && htmlUrl!.trim().isNotEmpty);

  String get presentationKey {
    final revision = version ?? startsAt?.toUtc().toIso8601String() ?? '1';
    return '$id:$revision';
  }

  factory AppAnnouncement.fromJson(Map<String, dynamic> json) {
    return AppAnnouncement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      version: _optionalString(json['version']),
      body: _optionalString(json['body']),
      bannerImageUrl: _optionalString(json['banner_image_url']),
      htmlUrl: _optionalString(json['html_url']),
      storyUrl: _optionalString(json['story_url']),
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
    );
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static DateTime? _parseDate(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
