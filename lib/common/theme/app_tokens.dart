import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';

/// Centralized corner radii for the flat, card-in-card-free layout used
/// across clan/CWL/capital/war detail screens.
///
/// Values are sourced from the shared ClashKing design system package so the
/// app, admin panel, and future clients can stay aligned while existing app
/// imports keep working through this compatibility layer.
class AppRadius {
  AppRadius._();

  /// Small "glass chip" family (chip.dart, stat_tile.dart) and flat list
  /// rows (member rows, district rows, opponent rows...).
  static const double chip = CKRadius.chip;

  /// Section-level panels — the raid/war summary card, empty states, any
  /// top-level flat container directly under a header or tab bar.
  static const double card = CKRadius.card;

  /// Fully-rounded pills — filter chips, summary chips, status badges.
  static const double pill = CKRadius.pill;
}

/// Recurring `withValues(alpha: ...)` levels for the flat container border
/// language (`Border.all(color: colorScheme.outlineVariant.withValues(...))`)
/// so new screens match existing ones instead of picking a nearby-but-off
/// value.
class AppOpacity {
  AppOpacity._();

  /// Default border on a flat card/row against the page background.
  static const double border = CKOpacity.border;

  /// Slightly stronger border for a card that sits directly under a tab
  /// bar or header (needs a touch more definition).
  static const double borderStrong = CKOpacity.borderStrong;

  /// Muted icon-circle / pill background fill
  /// (`colorScheme.surfaceContainerHighest.withValues(...)`).
  static const double fillMuted = CKOpacity.fillMuted;
}

/// Shared stat colors so recurring accents (war-star gold, win/loss/tie)
/// aren't redefined slightly differently across feature files.
class StatColors {
  StatColors._();

  /// Matches the war-star gold already used in player/clan headers.
  static const Color warStarGold = CKColors.warGold;

  /// Matches the donation green already used in the player header.
  static const Color win = CKColors.donationGreen;

  /// Matches the "received"/negative red already used in the player header.
  static const Color loss = CKColors.lossRed;

  static const Color tie = CKColors.secondaryBlue;

  /// Clan Capital accents.
  static const Color capitalLoot = CKColors.warGold;
  static const Color capitalDistrict = CKColors.donationGreen;
  static const Color capitalAttack = CKColors.builderBlue;
  static const Color capitalProjected = CKColors.capitalOrange;
  static const Color capitalTrophy = CKColors.capitalTrophy;
}
