import 'package:flutter/material.dart';

/// Centralized radius for the small "glass chip" family (chip.dart,
/// stat_tile.dart) — siblings of MetricChip in header_widgets.dart.
/// Card/panel radius (28) and button/input radius (12) stay defined
/// directly in ThemeData (see my_app.dart); this only names the smaller
/// chip/tile radius that was previously a repeated magic number.
class AppRadius {
  AppRadius._();

  static const double chip = 16;
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
}
