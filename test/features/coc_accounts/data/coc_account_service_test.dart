import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CocAccountService — initial state', () {
    test('starts with empty accounts', () {
      final service = CocAccountService();
      expect(service.cocAccounts, isEmpty);
      expect(service.accounts, isEmpty);
    });

    test('starts not loading', () {
      final service = CocAccountService();
      expect(service.isLoading, isFalse);
    });

    test('starts with null selectedTag', () {
      final service = CocAccountService();
      expect(service.selectedTag, isNull);
      expect(service.selectedTagNotifier.value, isNull);
    });
  });

  group('CocAccountService — addLocalAccount', () {
    test('adds account to cocAccounts', () {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#ABC123', 'name': 'Test'});
      expect(service.cocAccounts, hasLength(1));
      expect(service.cocAccounts.first['player_tag'], '#ABC123');
    });

    test('notifies listeners on add', () {
      final service = CocAccountService();
      var notified = false;
      service.addListener(() => notified = true);
      service.addLocalAccount({'player_tag': '#ABC123'});
      expect(notified, isTrue);
    });

    test('accounts getter returns player_tag values', () {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#AAA'});
      service.addLocalAccount({'player_tag': '#BBB'});
      expect(service.accounts, containsAll(['#AAA', '#BBB']));
      expect(service.accounts, hasLength(2));
    });
  });

  group('CocAccountService — getAccountTags', () {
    test('returns empty list when no accounts', () {
      final service = CocAccountService();
      expect(service.getAccountTags(), isEmpty);
    });

    test('returns all player tags', () {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#P1'});
      service.addLocalAccount({'player_tag': '#P2'});
      expect(service.getAccountTags(), containsAll(['#P1', '#P2']));
    });
  });

  group('CocAccountService — clearAccountData', () {
    test('resets all fields to defaults', () {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#ABC'});
      service.clearAccountData();
      expect(service.cocAccounts, isEmpty);
      expect(service.selectedTag, isNull);
      expect(service.isLoading, isFalse);
    });

    test('notifies listeners on clear', () {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#ABC'});
      var notified = false;
      service.addListener(() => notified = true);
      service.clearAccountData();
      expect(notified, isTrue);
    });

    test('clears selectedTagNotifier', () {
      final service = CocAccountService();
      service.clearAccountData();
      expect(service.selectedTagNotifier.value, isNull);
    });
  });

  group('CocAccountService — initializeSelectedTag', () {
    test('does nothing when no accounts', () async {
      final service = CocAccountService();
      service.initializeSelectedTag();
      await Future.delayed(Duration.zero);
      expect(service.selectedTag, isNull);
    });

    test('sets first account tag when none selected', () async {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#FIRST'});
      service.addLocalAccount({'player_tag': '#SECOND'});
      service.initializeSelectedTag();
      // _selectedTag is set synchronously at start of setSelectedTag
      expect(service.selectedTag, '#FIRST');
      expect(service.selectedTagNotifier.value, '#FIRST');
    });

    test('does not override existing selection', () async {
      final service = CocAccountService();
      service.addLocalAccount({'player_tag': '#FIRST'});
      service.initializeSelectedTag(); // sets to #FIRST
      service.addLocalAccount({'player_tag': '#SECOND'});
      service.initializeSelectedTag(); // should be no-op
      expect(service.selectedTag, '#FIRST');
    });
  });

  group('CocAccountService — setSelectedTag', () {
    test('updates selectedTag synchronously', () {
      final service = CocAccountService();
      service.setSelectedTag('#TAG1');
      expect(service.selectedTag, '#TAG1');
    });

    test('updates selectedTagNotifier synchronously', () {
      final service = CocAccountService();
      service.setSelectedTag('#TAG1');
      expect(service.selectedTagNotifier.value, '#TAG1');
    });

    test('accepts null to clear selection', () {
      final service = CocAccountService();
      service.setSelectedTag('#TAG1');
      service.setSelectedTag(null);
      expect(service.selectedTag, isNull);
      expect(service.selectedTagNotifier.value, isNull);
    });
  });
}
