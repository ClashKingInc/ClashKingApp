part of '../side_tabs_pages.dart';

class GameAssetsPage extends StatefulWidget {
  const GameAssetsPage({super.key});

  @override
  State<GameAssetsPage> createState() => _GameAssetsPageState();
}

class _GameAssetsPageState extends State<GameAssetsPage> {
  String _folder = 'troops';

  @override
  Widget build(BuildContext context) {
    final entries = _assetEntriesFor(_folder);
    return _SidePageScaffold(
      title: 'Game Assets',
      subtitle: 'Hosted ClashKing assets, grouped by folder.',
      child: ListView(
        padding: _pagePadding,
        children: [
          _HorizontalSelector<String>(
            values: _assetFolders,
            selected: _folder,
            labelBuilder: _assetFolderLabel,
            onSelected: (value) => setState(() => _folder = value),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 760
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

class _OreCalculator extends StatefulWidget {
  const _OreCalculator();

  @override
  State<_OreCalculator> createState() => _OreCalculatorState();
}

class _OreCalculatorState extends State<_OreCalculator> {
  String? _selectedTag;
  int _shinyOwned = 0;
  int _glowyOwned = 0;
  int _starryOwned = 0;
  int _shinyTarget = 5600;
  int _glowyTarget = 600;
  int _starryTarget = 60;
  int _extraDailyShiny = 0;
  int _extraDailyGlowy = 0;
  int _extraDailyStarry = 0;

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerService>().profiles;
    final selected = _selectedPlayer(players);
    final bonus = _OreBonus.forLeague(selected?.league ?? 'Crystal League');
    final dailyShiny = bonus.shiny + _extraDailyShiny;
    final dailyGlowy = bonus.glowy + _extraDailyGlowy;
    final dailyStarry = bonus.starry + _extraDailyStarry;
    final days = [
      _daysLeft(_shinyTarget - _shinyOwned, dailyShiny),
      _daysLeft(_glowyTarget - _glowyOwned, dailyGlowy),
      _daysLeft(_starryTarget - _starryOwned, dailyStarry),
    ].reduce(math.max);

    return ListView(
      padding: _pagePadding,
      children: [
        if (players.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: selected?.tag,
            decoration: const InputDecoration(labelText: 'Linked account'),
            items: players
                .map(
                  (player) => DropdownMenuItem(
                    value: player.tag,
                    child: Text('${player.name} · ${player.league}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedTag = value),
          )
        else
          const _EmptyState(
            icon: Icons.person_outline_rounded,
            title: 'No linked players loaded',
            body: 'Add or refresh linked accounts to prefill league data.',
          ),
        const SizedBox(height: 16),
        _CalculatorResult(
          title: days == 0 ? 'Ready now' : '$days days',
          subtitle:
              '${_formatInt(math.max(0, _shinyTarget - _shinyOwned))} shiny, '
              '${_formatInt(math.max(0, _glowyTarget - _glowyOwned))} glowy, '
              '${_formatInt(math.max(0, _starryTarget - _starryOwned))} starry left',
        ),
        const SizedBox(height: 18),
        _NumberRow(
          label: 'Shiny ore',
          owned: _shinyOwned,
          target: _shinyTarget,
          daily: dailyShiny,
          onOwnedChanged: (value) => setState(() => _shinyOwned = value),
          onTargetChanged: (value) => setState(() => _shinyTarget = value),
        ),
        _NumberRow(
          label: 'Glowy ore',
          owned: _glowyOwned,
          target: _glowyTarget,
          daily: dailyGlowy,
          onOwnedChanged: (value) => setState(() => _glowyOwned = value),
          onTargetChanged: (value) => setState(() => _glowyTarget = value),
        ),
        _NumberRow(
          label: 'Starry ore',
          owned: _starryOwned,
          target: _starryTarget,
          daily: dailyStarry,
          onOwnedChanged: (value) => setState(() => _starryOwned = value),
          onTargetChanged: (value) => setState(() => _starryTarget = value),
        ),
        const SizedBox(height: 12),
        _SectionHeader(title: 'Daily bonus adjustment'),
        _CompactStepper(
          label: 'Extra shiny',
          value: _extraDailyShiny,
          step: 50,
          onChanged: (value) => setState(() => _extraDailyShiny = value),
        ),
        _CompactStepper(
          label: 'Extra glowy',
          value: _extraDailyGlowy,
          step: 5,
          onChanged: (value) => setState(() => _extraDailyGlowy = value),
        ),
        _CompactStepper(
          label: 'Extra starry',
          value: _extraDailyStarry,
          step: 1,
          onChanged: (value) => setState(() => _extraDailyStarry = value),
        ),
      ],
    );
  }

  Player? _selectedPlayer(List<Player> players) {
    if (players.isEmpty) return null;
    if (_selectedTag == null) return players.first;
    return players.firstWhere(
      (player) => player.tag == _selectedTag,
      orElse: () => players.first,
    );
  }

  int _daysLeft(int remaining, int daily) {
    if (remaining <= 0) return 0;
    if (daily <= 0) return 999;
    return (remaining / daily).ceil();
  }
}

class _ZapQuakeCalculator extends StatefulWidget {
  const _ZapQuakeCalculator();

  @override
  State<_ZapQuakeCalculator> createState() => _ZapQuakeCalculatorState();
}

class _ZapQuakeCalculatorState extends State<_ZapQuakeCalculator> {
  int _buildingHp = 4200;
  int _lightningLevel = 11;
  int _quakeLevel = 5;

  @override
  Widget build(BuildContext context) {
    final lightning = _lightningDamage[_lightningLevel] ?? 600;
    final quake = (_buildingHp * ((_quakePercent[_quakeLevel] ?? 29) / 100))
        .floor();
    final afterQuake = math.max(0, _buildingHp - quake);
    final zaps = (afterQuake / lightning).ceil();
    final noQuakeZaps = (_buildingHp / lightning).ceil();

    return ListView(
      padding: _pagePadding,
      children: [
        _CalculatorResult(
          title: '$zaps lightning + 1 quake',
          subtitle:
              '${_formatInt(quake)} quake damage, '
              '${_formatInt(lightning)} per lightning',
        ),
        const SizedBox(height: 16),
        _CompactStepper(
          label: 'Building HP',
          value: _buildingHp,
          step: 100,
          min: 100,
          onChanged: (value) => setState(() => _buildingHp = value),
        ),
        _LevelSelector(
          label: 'Lightning level',
          value: _lightningLevel,
          min: 1,
          max: 12,
          onChanged: (value) => setState(() => _lightningLevel = value),
        ),
        _LevelSelector(
          label: 'Earthquake level',
          value: _quakeLevel,
          min: 1,
          max: 5,
          onChanged: (value) => setState(() => _quakeLevel = value),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          label: 'Without earthquake',
          value: '$noQuakeZaps lightning',
        ),
      ],
    );
  }
}

class _FireballQuakeCalculator extends StatefulWidget {
  const _FireballQuakeCalculator();

  @override
  State<_FireballQuakeCalculator> createState() =>
      _FireballQuakeCalculatorState();
}

class _FireballQuakeCalculatorState extends State<_FireballQuakeCalculator> {
  int _buildingHp = 5200;
  int _fireballLevel = 18;
  int _quakeLevel = 5;

  @override
  Widget build(BuildContext context) {
    final fireball = _fireballDamage(_fireballLevel);
    final afterFireball = math.max(0, _buildingHp - fireball);
    final quakeDamage =
        (_buildingHp * ((_quakePercent[_quakeLevel] ?? 29) / 100)).floor();
    final remaining = math.max(0, afterFireball - quakeDamage);
    final quakesNeeded = remaining == 0
        ? 1
        : math.min(4, (remaining / math.max(1, quakeDamage)).ceil() + 1);

    return ListView(
      padding: _pagePadding,
      children: [
        _CalculatorResult(
          title: remaining == 0 ? 'Fireball + 1 quake' : 'Add support damage',
          subtitle:
              '${_formatInt(fireball)} fireball damage, '
              '${_formatInt(math.max(0, remaining))} HP left after quake',
        ),
        const SizedBox(height: 16),
        _CompactStepper(
          label: 'Building HP',
          value: _buildingHp,
          step: 100,
          min: 100,
          onChanged: (value) => setState(() => _buildingHp = value),
        ),
        _LevelSelector(
          label: 'Fireball level',
          value: _fireballLevel,
          min: 1,
          max: 27,
          onChanged: (value) => setState(() => _fireballLevel = value),
        ),
        _LevelSelector(
          label: 'Earthquake level',
          value: _quakeLevel,
          min: 1,
          max: 5,
          onChanged: (value) => setState(() => _quakeLevel = value),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          label: 'Quake pressure',
          value: '$quakesNeeded quake spell${quakesNeeded == 1 ? '' : 's'}',
        ),
      ],
    );
  }
}
