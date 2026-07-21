import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'side_page_components.dart';

class GameAssetsPage extends StatefulWidget {
  const GameAssetsPage({super.key});

  @override
  State<GameAssetsPage> createState() => _GameAssetsPageState();
}

class _GameAssetsPageState extends State<GameAssetsPage> {
  String _folder = 'troops';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final entries = _assetEntriesFor(_folder);
    return SidePageScaffold(
      title: loc.sideGameAssetsTitle,
      subtitle: loc.sideGameAssetsSubtitle,
      child: ListView(
        padding: sidePagePadding,
        children: [
          SidePageHorizontalSelector<String>(
            values: _assetFolders,
            selected: _folder,
            labelBuilder: (folder) => _assetFolderLabel(folder, loc),
            onSelected: (value) => setState(() => _folder = value),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1080
                  ? 6
                  : width > 880
                  ? 5
                  : width > 680
                  ? 4
                  : width > 480
                  ? 3
                  : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _AssetTile(entry: entries[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<_AssetEntry> _assetEntriesFor(String folder) {
    switch (folder) {
      case 'troops':
        return _entriesFromBundle(
          GameDataService.troopsData['troops'],
          'troops',
          (name) => ImageAssets.getTroopImage(name),
        );
      case 'spells':
        return _entriesFromBundle(
          GameDataService.spellsData['spells'],
          'spells',
          (name) => ImageAssets.getSpellImage(name),
        );
      case 'heroes':
        return _entriesFromBundle(
          GameDataService.heroesData['heroes'],
          'heroes',
          (name) => ImageAssets.getHeroImage(name),
        );
      case 'equipment':
        return _entriesFromBundle(
          GameDataService.gearsData['gears'],
          'equipment',
          _equipmentUrl,
        );
      case 'leagues':
        return _leagueEntries();
      case 'resources':
        return const [
          _AssetEntry(
            name: 'Shiny Ore',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/shiny_ore.webp',
          ),
          _AssetEntry(
            name: 'Glowy Ore',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/glowy_ore.webp',
          ),
          _AssetEntry(
            name: 'Starry Ore',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/starry_ore.webp',
          ),
          _AssetEntry(
            name: 'Capital Gold',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/capital_gold.webp',
          ),
          _AssetEntry(
            name: 'Raid Medals',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/raid_medals.webp',
          ),
        ];
      default:
        return _staticAssetCatalog
            .where((entry) => entry.folder == folder)
            .toList();
    }
  }

  List<_AssetEntry> _entriesFromBundle(
    dynamic raw,
    String folder,
    String Function(String name) urlBuilder,
  ) {
    if (raw is! Map || raw.isEmpty) {
      return _staticAssetCatalog
          .where((entry) => entry.folder == folder)
          .toList();
    }
    return raw.keys
        .map((key) => key.toString())
        .where((name) => name.trim().isNotEmpty)
        .map(
          (name) =>
              _AssetEntry(name: name, folder: folder, url: urlBuilder(name)),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<_AssetEntry> _leagueEntries() {
    final entries = <_AssetEntry>[];
    final playerLeagues = GameDataService.playerLeagueData['leagues'];
    if (playerLeagues is Map) {
      entries.addAll(
        playerLeagues.keys.map(
          (key) => _AssetEntry(
            name: key.toString(),
            folder: 'leagues',
            url: ImageAssets.getLeagueImage(key.toString()),
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return _staticAssetCatalog
          .where((entry) => entry.folder == 'leagues')
          .toList();
    }
    return entries..sort((a, b) => a.name.compareTo(b.name));
  }

  String _equipmentUrl(String name) {
    final gears = GameDataService.gearsData['gears'];
    if (gears is Map) {
      final gear = gears[name];
      if (gear is Map && gear['url'] is String) {
        return gear['url'] as String;
      }
    }
    return ImageAssets.defaultImage;
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.entry});

  final _AssetEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: MobileWebImage(imageUrl: entry.url, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              entry.folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetEntry {
  const _AssetEntry({
    required this.name,
    required this.folder,
    required this.url,
  });

  final String name;
  final String folder;
  final String url;
}

const _assetFolders = [
  'troops',
  'spells',
  'heroes',
  'equipment',
  'leagues',
  'resources',
  'stickers',
];

const _staticAssetCatalog = [
  _AssetEntry(name: 'Villager', folder: 'stickers', url: ImageAssets.villager),
  _AssetEntry(
    name: 'Builder',
    folder: 'stickers',
    url: ImageAssets.builderWave,
  ),
  _AssetEntry(name: 'Goblin', folder: 'stickers', url: ImageAssets.goblin),
  _AssetEntry(
    name: 'Thinking Barbarian King',
    folder: 'stickers',
    url: ImageAssets.thinkingBarbarianKing,
  ),
  _AssetEntry(
    name: 'Legend League',
    folder: 'leagues',
    url: ImageAssets.legendBlazon,
  ),
  _AssetEntry(name: 'Clan War', folder: 'resources', url: ImageAssets.warClan),
  _AssetEntry(name: 'Trophy', folder: 'resources', url: ImageAssets.trophies),
  _AssetEntry(
    name: 'Capital Trophy',
    folder: 'resources',
    url: ImageAssets.capitalTrophy,
  ),
];

String _assetFolderLabel(String folder, AppLocalizations loc) {
  return switch (folder) {
    'troops' => loc.assetFolderTroops,
    'spells' => loc.assetFolderSpells,
    'heroes' => loc.assetFolderHeroes,
    'equipment' => loc.assetFolderEquipment,
    'leagues' => loc.assetFolderLeagues,
    'resources' => loc.assetFolderResources,
    'stickers' => loc.assetFolderStickers,
    _ => folder,
  };
}
