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
    this.targetRoute,
    this.presentationType = 'article',
    this.status = 'live',
    this.publishedAt,
    this.showOnHome = false,
    this.pinnedOnHome = false,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? version;
  final String? body;
  final String? bannerImageUrl;
  final String? htmlUrl;
  final String? storyUrl;
  final String? targetRoute;
  final String presentationType;
  final String status;
  final DateTime? publishedAt;
  final bool showOnHome;
  final bool pinnedOnHome;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get hasReadableBody =>
      storyUrl != null ||
      (body != null && body!.trim().isNotEmpty) ||
      (htmlUrl != null && htmlUrl!.trim().isNotEmpty);

  bool get isStory => presentationType == 'story' || storyUrl != null;

  bool get isCurrent {
    final now = DateTime.now().toUtc();
    return status == 'live' && (endsAt == null || endsAt!.toUtc().isAfter(now));
  }

  String get presentationKey {
    final revision = version ?? startsAt?.toUtc().toIso8601String() ?? '1';
    return '$id:$revision';
  }

  factory AppAnnouncement.fromJson(Map<String, dynamic> json) {
    final explicitBody = _optionalString(json['body']);
    final bannerImageUrl = _optionalString(json['banner_image_url']);
    return AppAnnouncement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      version: _optionalString(json['version']),
      body:
          explicitBody ??
          _blocksToHtml(
            json['body_blocks'],
            bannerImageUrl: bannerImageUrl,
            fallbackText: json['subtitle'],
          ),
      bannerImageUrl: bannerImageUrl,
      htmlUrl: _optionalString(json['html_url']),
      storyUrl: _optionalString(json['story_url']),
      targetRoute: _optionalString(json['target_route']),
      presentationType: _optionalString(json['presentation_type']) ?? 'article',
      status: _optionalString(json['status']) ?? 'live',
      publishedAt: _parseDate(json['published_at']),
      showOnHome: json['show_on_home'] == true,
      pinnedOnHome: json['pinned_on_home'] == true,
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
    );
  }

  static String? _blocksToHtml(
    Object? value, {
    String? bannerImageUrl,
    Object? fallbackText,
  }) {
    final content = StringBuffer();
    final bannerUri = Uri.tryParse(bannerImageUrl ?? '');
    if (bannerUri != null && bannerUri.scheme == 'https') {
      content.write(
        '<img class="hero" src="${_escapeHtml(bannerImageUrl)}" alt="">',
      );
    }
    final blocks = value is List ? value : const <Object>[];
    for (final rawBlock in blocks) {
      if (rawBlock is! Map) continue;
      final block = Map<String, dynamic>.from(rawBlock);
      final type = block['type']?.toString();
      switch (type) {
        case 'heading':
          content.write('<h2>${_escapeHtml(block['text'])}</h2>');
        case 'paragraph':
          content.write('<p>${_escapeHtml(block['text'])}</p>');
        case 'bullet_list':
          final items = block['items'];
          if (items is List) {
            content.write('<ul>');
            for (final item in items.where(
              (item) => item.toString().trim().isNotEmpty,
            )) {
              content.write('<li>${_escapeHtml(item)}</li>');
            }
            content.write('</ul>');
          }
        case 'image':
          final source = block['url']?.toString().trim() ?? '';
          final uri = Uri.tryParse(source);
          if (uri != null && uri.scheme == 'https') {
            final caption = _escapeHtml(block['caption']);
            content.write(
              '<figure><img src="${_escapeHtml(source)}" alt="$caption">',
            );
            if (caption.isNotEmpty) {
              content.write('<figcaption>$caption</figcaption>');
            }
            content.write('</figure>');
          }
      }
    }
    if (content.isEmpty && fallbackText?.toString().trim().isNotEmpty == true) {
      content.write('<p>${_escapeHtml(fallbackText)}</p>');
    }
    if (content.isEmpty) {
      return null;
    }
    return '''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;padding:20px;line-height:1.55;color:#172033;background:#fff}h2{margin-top:1.4em}img{max-width:100%;height:auto;border-radius:16px}.hero{display:block;width:100%;margin-bottom:20px}figure{margin:20px 0}figcaption{opacity:.7;margin-top:8px}@media(prefers-color-scheme:dark){body{color:#f4f6fb;background:#10131a}}</style></head><body>$content</body></html>''';
  }

  static String _escapeHtml(Object? value) => (value?.toString() ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

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
