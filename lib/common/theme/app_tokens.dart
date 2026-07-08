import 'package:flutter/material.dart';

/// Centralized corner radii for the flat, card-in-card-free layout used
/// across clan/CWL/capital/war detail screens. Button/input radius (12)
/// and the legacy Card radius (28) stay defined directly in ThemeData
/// (see my_app.dart) since they predate this token set; new screens
/// should reach for these three instead of a magic number.
class AppRadius {
  AppRadius._();

  /// Small "glass chip" family (chip.dart, stat_tile.dart) and flat list
  /// rows (member rows, district rows, opponent rows...).
  static const double chip = 16;

  /// Section-level panels — the raid/war summary card, empty states, any
  /// top-level flat container directly under a header or tab bar.
  static const double card = 20;

  /// Fully-rounded pills — filter chips, summary chips, status badges.
  static const double pill = 999;
}

/// Recurring `withValues(alpha: ...)` levels for the flat container border
/// language (`Border.all(color: colorScheme.outlineVariant.withValues(...))`)
/// so new screens match existing ones instead of picking a nearby-but-off
/// value. Not universally retrofitted yet — treat as the target for new
/// code, not a guarantee every existing widget already uses it.
class AppOpacity {
  AppOpacity._();

  /// Default border on a flat card/row against the page background.
  static const double border = 0.28;

  /// Slightly stronger border for a card that sits directly under a tab
  /// bar or header (needs a touch more definition).
  static const double borderStrong = 0.32;

  /// Muted icon-circle / pill background fill
  /// (`colorScheme.surfaceContainerHighest.withValues(...)`).
  static const double fillMuted = 0.45;
}

/// Shared stat colors so recurring accents (war-star gold, win/loss/tie)
/// aren't redefined slightly differently across feature files.
class StatColors {
  StatColors._();

  /// Matches the war-star gold already used in player/clan headers.
  static const Color warStarGold = Color(0xFFE8A524);

  /// Matches the donation green already used in the player header.
  static const Color win = Color(0xFF14A37F);

  /// Matches the "received"/negative red already used in the player header.
  static const Color loss = Color(0xFFE35D4F);

  static const Color tie = Color(0xFF026CC2);

  /// Clan Capital accents.
  static const Color capitalLoot = Color(0xFFE8A524);
  static const Color capitalDistrict = Color(0xFF14A37F);
  static const Color capitalAttack = Color(0xFF2A9FD6);
  static const Color capitalProjected = Color(0xFFE56B2F);
  static const Color capitalTrophy = Color(0xFFD8891F);
}
