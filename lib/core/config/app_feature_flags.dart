/// Stable feature-flag keys shared by the Flutter app and the admin panel.
///
/// Existing, production-proven surfaces fail open. Preview or incomplete
/// surfaces fail closed so a config outage can never expose fabricated data.
abstract final class AppFeatureFlags {
  static const notifications = 'notifications';
  static const posts = 'posts';
  static const homeAnnouncements = 'home_announcements';
  static const leaderboards = 'leaderboards';
  static const leaderboardPreviews = 'leaderboard_previews';
  static const globalStats = 'global_stats';
  static const calculators = 'calculators';
  static const subscriptionSupport = 'subscription_support';
  static const upgradeTracker = 'upgrade_tracker';
  static const basesArmies = 'bases_armies';
  static const gameAssets = 'game_assets';
  static const clanRankingsPreview = 'clan_rankings_preview';
  static const cwlHistoryPreview = 'cwl_history_preview';
  static const accountConnections = 'account_connections';
  static const warWidgets = 'war_widgets';
  static const featureRequests = 'feature_requests';

  static const Map<String, bool> defaults = {
    notifications: true,
    posts: true,
    homeAnnouncements: true,
    leaderboards: true,
    leaderboardPreviews: false,
    globalStats: true,
    calculators: true,
    subscriptionSupport: false,
    upgradeTracker: true,
    basesArmies: false,
    gameAssets: true,
    clanRankingsPreview: false,
    cwlHistoryPreview: false,
    accountConnections: false,
    warWidgets: true,
    featureRequests: true,
  };

  static bool defaultValue(String key) => defaults[key] ?? true;
}
