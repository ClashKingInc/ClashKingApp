import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/features/player/models/player_troop.dart';
import 'package:clashkingapp/features/player/presentation/player/player_item_section.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the shared game item tile with a level badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlayerItemSection(
            title: 'Troops',
            townHallLevel: 17,
            initiallyExpanded: true,
            items: [
              PlayerTroop(
                name: 'Balloon',
                level: 10,
                maxLevel: 12,
                superTroopIsActive: false,
                village: 'home',
                isUnlocked: true,
              ),
            ],
          ),
        ),
      ),
    );

    final tile = tester.widget<CKGameItemTile>(find.byType(CKGameItemTile));
    expect(tile.badge, '10');
    expect(tile.semanticLabel, contains('Level: 10/12'));
    expect(tile.onTap, isNotNull);
  });
}
