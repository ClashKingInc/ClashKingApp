import 'package:clashkingapp/classes/account/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Accounts {
  final List<Account> accounts;
  late ValueListenable<String?> selectedTag;

  Accounts({required this.accounts});

  // Method to find the account with the selected tag
  Account? findAccountBySelectedTag() {
    try {
      return accounts
          .firstWhere((acc) => acc.profileInfo.tag == selectedTag.value);
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      return null;
    }
  }

  Account? findAccountByTag(String tag) {
    try {
      return accounts.firstWhere((acc) => acc.profileInfo.tag == tag);
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      return null;
    }
  }
}

class Account {
  final ProfileInfo profileInfo;
  final Clan? clan;

  Account({required this.profileInfo, this.clan});
}


class AccountsService {
  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<Accounts> fetchAccounts(User user) async {

    print("fetchAccounts");
    final transaction = Sentry.startTransaction(
      'fetchAccounts',
      'task',
      bindToScope: true,
    );

    try {
      final tags = user.tags;

      // Step 1: Initialize an empty list for Account objects
      List<Account> accountsList = [];

      // Step 2: Create a list of futures for each tag
      List<Future<Account>> fetchTasks = tags.map((tag) async {
        final profileSpan = transaction.startChild('fetchProfileInfo');
        ProfileInfo profileInfo =
            await ProfileInfoService().fetchProfileInfo(tag);
        profileSpan.finish(status: SpanStatus.ok());

        Clan? clanInfo;

        if (profileInfo.clan != null) {
          final clanSpan = transaction.startChild('fetchClanInfo');
          var results = await Future.wait([
            ClanService().fetchClanInfo(profileInfo.clan!.tag),
          ]);
          clanInfo = results[0] as Clan?;
          clanSpan.finish(status: SpanStatus.ok());
        }

        // Step 4: Create an Account object
        return Account(
          profileInfo: profileInfo,
          clan: clanInfo,
        );
      }).toList();

      // Step 3: Use Future.wait to run all fetch tasks concurrently
      final fetchSpan = transaction.startChild('Future.wait');
      accountsList = await Future.wait(fetchTasks);
      fetchSpan.finish(status: SpanStatus.ok());

      // Sort the accountsList
      final sortSpan = transaction.startChild('sortAccounts');
      accountsList.sort((a, b) {
        int townHallComparison =
            b.profileInfo.townHallLevel.compareTo(a.profileInfo.townHallLevel);
        if (townHallComparison != 0) {
          return townHallComparison;
        } else {
          return b.profileInfo.expLevel.compareTo(a.profileInfo.expLevel);
        }
      });
      sortSpan.finish(status: SpanStatus.ok());

      // Step 5: Create an Accounts object
      final accounts = Accounts(accounts: accountsList);
      accounts.selectedTag = ValueNotifier<String?>(tags.first);

      // Step 6: Finish the transaction and return the Accounts object
      transaction.finish(status: SpanStatus.ok());
      return accounts;
    } catch (exception, stackTrace) {
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(exception, stackTrace: stackTrace);
      throw Exception('Failed to load accounts: $exception');
    }
  }
}