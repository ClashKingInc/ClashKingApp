import 'package:clashkingapp/classes/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/foundation.dart';

class Accounts {
  final List<Account> accounts;
  late ValueListenable<String?> selectedTag;

  Accounts({required this.accounts});

  // Method to find the account with the selected tag
  Account? findAccountBySelectedTag() {
    try {
      return accounts
          .firstWhere((acc) => acc.profileInfo.tag == selectedTag.value);
    } catch (e) {
      return null;
    }
  }

  Account? findAccountByTag(String tag) {
    try {
      return accounts.firstWhere((acc) => acc.profileInfo.tag == tag);
    } catch (e) {
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
    try {
      final tags = user.tags;

      // Step 1: Initialize an empty list for Account objects
      List<Account> accountsList = [];

      // Step 2: Create a list of futures for each tag
      List<Future<Account>> fetchTasks = tags.map((tag) async {
        ProfileInfo profileInfo =
            await ProfileInfoService().fetchProfileInfo(tag);
        Clan? clanInfo;

        if (profileInfo.clan != null) {
          var results = await Future.wait([
            ClanService().fetchClanInfo(profileInfo.clan!.tag),
          ]);
          clanInfo = results[0] as Clan?;
        }

        // Step 4: Create an Account object
        return Account(
          profileInfo: profileInfo,
          clan: clanInfo,
        );
      }).toList();

      // Step 3: Use Future.wait to run all fetch tasks concurrently
      accountsList = await Future.wait(fetchTasks);

      // Sort the accountsList
      accountsList.sort((a, b) {
        int townHallComparison =
            b.profileInfo.townHallLevel.compareTo(a.profileInfo.townHallLevel);
        if (townHallComparison != 0) {
          return townHallComparison;
        } else {
          return b.profileInfo.expLevel.compareTo(a.profileInfo.expLevel);
        }
      });

      print(accountsList.first.clan);

      // Step 5: Create an Accounts object
      Accounts accounts = Accounts(accounts: accountsList);

      accounts.selectedTag = ValueNotifier<String?>(tags.first);
      print(accounts.selectedTag.value);

      // Step 6: Return the Accounts object
      return accounts;
    } catch (e, stackTrace) {
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Failed to load accounts: $e');
    }
  }
}
