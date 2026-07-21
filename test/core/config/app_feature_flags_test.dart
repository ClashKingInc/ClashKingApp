import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFeatureFlags defaults', () {
    test('fails closed for preview and incomplete surfaces', () {
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.subscriptionSupport),
        isFalse,
      );
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.basesArmies),
        isFalse,
      );
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.clanRankingsPreview),
        isFalse,
      );
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.cwlHistoryPreview),
        isFalse,
      );
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.accountConnections),
        isFalse,
      );
    });

    test('fails open for established production surfaces', () {
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.notifications),
        isTrue,
      );
      expect(AppFeatureFlags.defaultValue(AppFeatureFlags.posts), isTrue);
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.homeAnnouncements),
        isTrue,
      );
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.leaderboards),
        isTrue,
      );
      expect(
        AppFeatureFlags.defaultValue(AppFeatureFlags.upgradeTracker),
        isTrue,
      );
      expect(AppFeatureFlags.defaultValue(AppFeatureFlags.warWidgets), isTrue);
    });

    test('unknown keys retain the legacy fail-open behavior', () {
      expect(AppFeatureFlags.defaultValue('future_existing_feature'), isTrue);
    });

    test('removed features are absent from the app flag registry', () {
      expect(AppFeatureFlags.defaults, isNot(contains('popular_insights')));
      expect(AppFeatureFlags.defaults, isNot(contains('leaderboard_previews')));
    });
  });
}
