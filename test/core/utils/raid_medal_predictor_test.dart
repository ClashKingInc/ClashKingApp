import 'package:clashkingapp/core/utils/raid_medal_predictor.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:flutter_test/flutter_test.dart';

District _district({
  required int id,
  required int districtHallLevel,
  required int destructionPercent,
  int totalLooted = 0,
  int attackCount = 0,
}) {
  return District(
    id: id,
    name: '',
    districtHallLevel: districtHallLevel,
    destructionPercent: destructionPercent,
    stars: 0,
    attackCount: attackCount,
    totalLooted: totalLooted,
    attacks: const [],
  );
}

RaidAttackLog _entry({
  required int attackCount,
  required List<District> districts,
}) {
  return RaidAttackLog(
    defender: RaidDefender(tag: '', name: '', level: 0, badgeUrls: const {}),
    attackCount: attackCount,
    districtCount: districts.length,
    districtsDestroyed: districts
        .where((d) => d.destructionPercent == 100)
        .length,
    districts: districts,
  );
}

void main() {
  group('predictOffensiveReward', () {
    test('returns 0 for an empty attack log', () {
      expect(RaidMedalPredictor.predictOffensiveReward(const []), 0);
    });

    test('averages medals per attack and scales to 6 attacks', () {
      final attackLog = [
        _entry(
          attackCount: 4,
          districts: [
            _district(
              id: 70000000,
              districtHallLevel: 4,
              destructionPercent: 100,
            ),
            _district(
              id: 70000001,
              districtHallLevel: 2,
              destructionPercent: 100,
            ),
          ],
        ),
        _entry(
          attackCount: 3,
          districts: [
            _district(
              id: 70000002,
              districtHallLevel: 1,
              destructionPercent: 100,
            ),
          ],
        ),
      ];

      // (585 [capital peak lvl4] + 225 [district lvl2] + 135 [district lvl1]) / 7 attacks = 135/attack -> *6
      expect(RaidMedalPredictor.predictOffensiveReward(attackLog), 810);
    });

    test('ignores districts that are not fully destroyed', () {
      final attackLog = [
        _entry(
          attackCount: 2,
          districts: [
            _district(
              id: 70000001,
              districtHallLevel: 3,
              destructionPercent: 80,
            ),
          ],
        ),
      ];

      expect(RaidMedalPredictor.predictOffensiveReward(attackLog), 0);
    });

    test('caps the total at the game maximum of 1620', () {
      final attackLog = [
        _entry(
          attackCount: 1,
          districts: [
            _district(
              id: 70000000,
              districtHallLevel: 10,
              destructionPercent: 100,
            ),
          ],
        ),
      ];

      expect(RaidMedalPredictor.predictOffensiveReward(attackLog), 1620);
    });
  });

  group('predictDefensiveReward', () {
    test('returns 0 for an empty defense log', () {
      expect(RaidMedalPredictor.predictDefensiveReward(const []), 0);
    });

    test(
      'matches the reference floor-division behaviour on a single opponent',
      () {
        final defenseLog = [
          _entry(
            attackCount: 2,
            districts: [
              _district(
                id: 70000002,
                districtHallLevel: 3,
                destructionPercent: 100,
                totalLooted: 1000,
                attackCount: 2,
              ),
            ],
          ),
        ];

        // housingSpace = 25 + 5*3 = 40
        // weight = (max(1000-750,0) + min(1000, 100000)) ~/ 2 = (250+1000) ~/ 2 = 625
        // troopsKilled = 2*40 - floorDiv(1000-625, 3) = 80 - 125 = -45
        // floorDiv(-45, 25) = -2 (Python-style floor division, not truncation)
        expect(RaidMedalPredictor.predictDefensiveReward(defenseLog), -2);
      },
    );
  });
}
