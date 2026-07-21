import 'package:clashkingapp/features/game_assets/data/game_asset_actions.dart';
import 'package:clashkingapp/features/game_assets/data/game_asset_manifest_service.dart';
import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:clashkingapp/features/pages/presentation/game_assets_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLocalized(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('landing page has categories but no global search', (
    tester,
  ) async {
    final repository = _FakeRepository([_manifest]);

    await pumpLocalized(
      tester,
      GameAssetsPage(
        repository: repository,
        imageBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('game-assets-categories')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('game-assets-search')), findsNothing);
    expect(find.text('Buildings'), findsOneWidget);
    expect(find.text('Troops'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('game-asset-category-buildings')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('game-assets-search')), findsOneWidget);
    expect(find.text('2 images'), findsOneWidget);
  });

  testWidgets('error retry and empty manifest states are visible', (
    tester,
  ) async {
    final repository = _FakeRepository([
      const GameAssetManifestLoadException('offline'),
      GameAssetManifest(version: 1, assets: const []),
    ]);

    await pumpLocalized(tester, GameAssetsPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Could not load game assets'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No game assets available'), findsOneWidget);
    expect(repository.loads, 2);
  });

  testWidgets('category grid is lazy, searchable, and long press copies URL', (
    tester,
  ) async {
    var builtImages = 0;
    final actions = _FakeActions();
    final assets = List.generate(
      1000,
      (index) => _asset(
        'troops/troop_$index.webp',
        'Troop $index',
        category: 'troops',
      ),
    );

    await pumpLocalized(
      tester,
      GameAssetCategoryPage(
        category: GameAssetCategory(id: 'troops', assets: assets),
        actions: actions,
        imageBuilder: (_, _, _) {
          builtImages++;
          return const SizedBox.expand();
        },
      ),
    );
    await tester.pump();

    expect(builtImages, lessThan(1000));
    expect(find.text('1,000 images'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('game-assets-search')),
      'Troop 999',
    );
    await tester.pump();

    expect(find.text('1 result'), findsOneWidget);
    final tile = find.byKey(const ValueKey('game-asset-troops/troop_999.webp'));
    expect(tile, findsOneWidget);

    await tester.longPress(tile);
    await tester.pump();

    expect(actions.copied, ['https://assets.clashk.ing/troops/troop_999.webp']);
    expect(find.text('Asset URL copied'), findsOneWidget);
  });

  testWidgets('preview exposes copy, share, and save actions', (tester) async {
    final actions = _FakeActions();
    final asset = _asset('troops/archer.webp', 'Archer', category: 'troops');

    await pumpLocalized(
      tester,
      GameAssetPreviewPage(
        asset: asset,
        actions: actions,
        imageBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );

    await tester.tap(find.text('Copy URL'));
    await tester.pump();
    await tester.tap(find.text('Copy path'));
    await tester.pump();
    await tester.tap(find.text('Share'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(actions.copied, [
      'https://assets.clashk.ing/troops/archer.webp',
      'troops/archer.webp',
    ]);
    expect(actions.shared, [asset]);
    expect(actions.saved, [asset]);
  });

  testWidgets('localized count formatting handles singular and grouping', (
    tester,
  ) async {
    await pumpLocalized(tester, const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final loc = AppLocalizations.of(context)!;

    expect(
      formatGameAssetImageCount(loc, 1, const Locale('en', 'US')),
      '1 image',
    );
    expect(
      formatGameAssetResultCount(loc, 1234, const Locale('en', 'US')),
      '1,234 results',
    );
  });
}

final _manifest = GameAssetManifest(
  version: 1,
  assets: [
    _asset('troops/wizard.webp', 'Wizard', category: 'troops'),
    _asset('buildings/cannon.webp', 'Cannon', category: 'buildings'),
    _asset('buildings/archer_tower.png', 'Archer Tower', category: 'buildings'),
  ],
);

GameAsset _asset(String path, String name, {required String category}) {
  return GameAsset(
    path: path,
    category: category,
    displayName: name,
    extension: path.split('.').last,
    url: Uri.parse('https://assets.clashk.ing/$path'),
  );
}

class _FakeRepository implements GameAssetManifestRepository {
  _FakeRepository(this.responses);

  final List<Object> responses;
  var loads = 0;

  @override
  Future<GameAssetManifest> load({bool forceRefresh = false}) {
    final response = responses[loads++];
    if (response is GameAssetManifest) return Future.value(response);
    return Future.error(response);
  }
}

class _FakeActions implements GameAssetActions {
  final copied = <String>[];
  final shared = <GameAsset>[];
  final saved = <GameAsset>[];

  @override
  Future<void> copy(String value) async {
    copied.add(value);
  }

  @override
  Future<String> save(GameAsset asset) async {
    saved.add(asset);
    return '/downloads/${asset.fileName}';
  }

  @override
  Future<void> share(GameAsset asset, {Rect? origin}) async {
    shared.add(asset);
  }
}
