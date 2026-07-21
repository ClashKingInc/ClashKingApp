import 'dart:collection';

const supportedGameAssetExtensions = <String>{
  'gif',
  'jpeg',
  'jpg',
  'png',
  'svg',
  'webp',
};

class GameAssetManifest {
  GameAssetManifest({
    required this.version,
    required Iterable<GameAsset> assets,
  }) : assets = UnmodifiableListView(
         assets.toList()..sort((a, b) => a.path.compareTo(b.path)),
       );

  factory GameAssetManifest.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 1) {
      throw FormatException(
        'Unsupported game asset manifest version: $version',
      );
    }

    final rawAssets = json['assets'];
    if (rawAssets is! List) {
      throw const FormatException('Game asset manifest assets must be a list');
    }

    return GameAssetManifest(
      version: version as int,
      assets: rawAssets.indexed.map((entry) {
        final (index, value) = entry;
        if (value is! Map) {
          throw FormatException('Game asset at index $index must be an object');
        }
        return GameAsset.fromJson(Map<String, dynamic>.from(value));
      }),
    );
  }

  final int version;
  final List<GameAsset> assets;

  late final List<GameAssetCategory> categories = _buildCategories(assets);

  static List<GameAssetCategory> _buildCategories(List<GameAsset> assets) {
    final grouped = <String, List<GameAsset>>{};
    for (final asset in assets) {
      grouped.putIfAbsent(asset.category, () => <GameAsset>[]).add(asset);
    }

    final categoryIds = grouped.keys.toList()..sort();
    return UnmodifiableListView([
      for (final id in categoryIds)
        GameAssetCategory(id: id, assets: grouped[id]!),
    ]);
  }
}

class GameAsset {
  GameAsset({
    required this.path,
    required this.category,
    required this.displayName,
    required this.extension,
    required this.url,
  }) : _searchText = '$path $displayName'.toLowerCase();

  factory GameAsset.fromJson(Map<String, dynamic> json) {
    final path = _requiredString(json, 'path');
    final category = _requiredString(json, 'category');
    final displayName = _requiredString(json, 'display_name');
    final extension = _requiredString(json, 'extension').toLowerCase();
    final urlValue = _requiredString(json, 'url');

    if (!supportedGameAssetExtensions.contains(extension)) {
      throw FormatException('Unsupported game asset extension: $extension');
    }
    if (path.startsWith('bot/')) {
      throw const FormatException('The bot asset folder is not supported');
    }
    final pathSegments = path.split('/');
    if (pathSegments.length < 2 || pathSegments.first != category) {
      throw FormatException(
        'Game asset category does not match its path: $category / $path',
      );
    }
    if (!path.toLowerCase().endsWith('.$extension')) {
      throw FormatException(
        'Game asset extension does not match its path: $path',
      );
    }

    final url = Uri.tryParse(urlValue);
    if (url == null ||
        !url.hasScheme ||
        !url.hasAuthority ||
        (url.scheme != 'https' && url.scheme != 'http')) {
      throw FormatException('Invalid game asset URL: $urlValue');
    }

    return GameAsset(
      path: path,
      category: category,
      displayName: displayName,
      extension: extension,
      url: url,
    );
  }

  final String path;
  final String category;
  final String displayName;
  final String extension;
  final Uri url;
  final String _searchText;

  String get fileName => Uri.decodeComponent(url.pathSegments.last);

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty || _searchText.contains(normalized);
  }
}

class GameAssetCategory {
  GameAssetCategory({required this.id, required Iterable<GameAsset> assets})
    : assets = UnmodifiableListView(assets);

  final String id;
  final List<GameAsset> assets;

  int get count => assets.length;

  List<String> get extensions {
    final values = assets.map((asset) => asset.extension).toSet().toList()
      ..sort();
    return UnmodifiableListView(values);
  }
}

List<GameAsset> filterGameAssets(
  Iterable<GameAsset> assets, {
  String query = '',
  String extension = '',
}) {
  return assets
      .where(
        (asset) =>
            (extension.isEmpty || asset.extension == extension) &&
            asset.matches(query),
      )
      .toList(growable: false);
}

String formatGameAssetCategory(String category) {
  return category
      .split(RegExp(r'[-_]+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Game asset $key must be a non-empty string');
  }
  return value;
}
