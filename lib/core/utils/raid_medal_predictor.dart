import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';

/// Client-side port of the ClashCliffs Discord bot's raid medal prediction
/// formulas (misc/predictions.py, MIT, codeberg.org/Kuchenmampfer/ClashCliffs
/// — credited there to MagicTheDev/MigLav). Supercell only fills in the real
/// `offensiveReward`/`defensiveReward` once a raid weekend has ended, so for
/// an ongoing raid this estimates the per-member medal reward from the
/// `attackLog`/`defenseLog` already present in the raid data instead.
///
/// Trying this client-side first, per team decision: if it proves accurate
/// against real results, the same formula gets ported into ClashKingAPI so
/// bot and app agree without duplicating the estimate.
class RaidMedalPredictor {
  RaidMedalPredictor._();

  static const int _capitalPeakDistrictId = 70000000;

  static const Map<int, int> _districtMedals = {
    1: 135,
    2: 225,
    3: 350,
    4: 405,
    5: 460,
  };

  static const Map<int, int> _capitalPeakMedals = {
    2: 180,
    3: 360,
    4: 585,
    5: 810,
    6: 1115,
    7: 1240,
    8: 1260,
    9: 1375,
    10: 1450,
  };

  /// Sum of medals from every 100%-destroyed district in [attackLog],
  /// averaged per attack made and scaled to a full 6-attack allowance,
  /// capped at the game's per-member maximum (1620).
  static int predictOffensiveReward(List<RaidAttackLog> attackLog) {
    var totalMedals = 0;
    var attacksDone = 0;

    for (final opponent in attackLog) {
      attacksDone += opponent.attackCount;
      for (final district in opponent.districts) {
        if (district.destructionPercent != 100) continue;
        final table = district.id == _capitalPeakDistrictId
            ? _capitalPeakMedals
            : _districtMedals;
        totalMedals += table[district.districtHallLevel] ?? 0;
      }
    }

    if (totalMedals == 0 || attacksDone == 0) return 0;
    final perAttack = (totalMedals / attacksDone).ceil();
    final total = perAttack * 6;
    return total < 1620 ? total : 1620;
  }

  /// Estimates the defensive medal reward from the worst single opponent's
  /// attacks in [defenseLog], based on housing space destroyed, capped at
  /// the game's per-member maximum (350).
  static int predictDefensiveReward(List<RaidAttackLog> defenseLog) {
    if (defenseLog.isEmpty) return 0;

    var housingSpace = 0;
    for (final district in defenseLog.first.districts) {
      final hallLevel = district.districtHallLevel;
      if (district.id == 70000001) {
        housingSpace += 3 * (25 + 5 * hallLevel);
      } else if (district.id == 70000002 && hallLevel > 1) {
        housingSpace += 25 + 5 * hallLevel;
      } else if (district.id == 70000005) {
        housingSpace += 25 + 5 * hallLevel;
      }
    }

    // ClashCliffs' predictions.py seeds upperWeights with a 0 default, which
    // makes min(looted, 0) collapse to 0 for every district and silently
    // breaks the weight average. Its own custom_coc_classes.py (used for
    // the bot's district embeds) reuses this same weight calculation with a
    // 100000 sentinel instead — high enough no real capital loot value
    // reaches it — which is the version we port here.
    const upperWeightSentinel = 100000;
    final lowerWeights = <int, int>{};
    final upperWeights = <int, int>{};
    for (final opponent in defenseLog) {
      for (final district in opponent.districts) {
        if (district.destructionPercent != 100) continue;
        final lower = district.totalLooted - 750;
        lowerWeights[district.id] = lower > (lowerWeights[district.id] ?? 0)
            ? lower
            : (lowerWeights[district.id] ?? 0);
        final upper = district.totalLooted;
        final currentUpper = upperWeights[district.id] ?? upperWeightSentinel;
        upperWeights[district.id] = upper < currentUpper ? upper : currentUpper;
      }
    }
    final districtWeights = <int, int>{
      for (final id in lowerWeights.keys)
        id: ((lowerWeights[id] ?? 0) + (upperWeights[id] ?? 0)) ~/ 2,
    };

    int? maxTroopsKilled;
    for (final opponent in defenseLog) {
      var troopsKilled = 0;
      for (final district in opponent.districts) {
        troopsKilled += district.attackCount * housingSpace;
        if (district.destructionPercent == 100) {
          final deduction =
              district.totalLooted - (districtWeights[district.id] ?? 0);
          troopsKilled -= _floorDiv(deduction, 3);
        }
      }
      if (maxTroopsKilled == null || troopsKilled > maxTroopsKilled) {
        maxTroopsKilled = troopsKilled;
      }
    }
    if (maxTroopsKilled == null) return 0;

    final defenseMedals = _floorDiv(maxTroopsKilled, 25);
    return defenseMedals < 350 ? defenseMedals : 350;
  }

  /// Floor division matching Python's `//` (rounds toward negative
  /// infinity), unlike Dart's `~/` which truncates toward zero — the
  /// deduction terms above can go negative.
  static int _floorDiv(int a, int b) {
    final quotient = a ~/ b;
    final hasRemainder = a % b != 0;
    final differentSigns = (a < 0) != (b < 0);
    return hasRemainder && differentSigns ? quotient - 1 : quotient;
  }
}
