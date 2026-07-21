import 'package:clashkingapp/features/coc_accounts/models/coc_account_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CocAccountLink.fromJson', () {
    test('decodes the required hidden field', () {
      final link = CocAccountLink.fromJson({
        'player_tag': '#ABC',
        'is_verified': true,
        'hidden': true,
        'name': 'Player',
      });

      expect(link.playerTag, '#ABC');
      expect(link.isVerified, isTrue);
      expect(link.hidden, isTrue);
      expect(link.toJson()['name'], 'Player');
    });

    test('rejects a missing hidden field', () {
      expect(
        () => CocAccountLink.fromJson({
          'player_tag': '#ABC',
          'is_verified': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-boolean hidden field', () {
      expect(
        () => CocAccountLink.fromJson({
          'player_tag': '#ABC',
          'is_verified': true,
          'hidden': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
