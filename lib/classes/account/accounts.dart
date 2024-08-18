import 'package:clashkingapp/classes/account/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/classes/profile/todo/to_do_list.dart';
import 'package:clashkingapp/classes/profile/todo/to_do_service.dart';

class Accounts {
  final List<Account> accounts;
  final List<String> tags;
  late ValueListenable<String?> selectedTag;
  late ToDoList toDoList;
  late bool isTodoInitialized = false;

  Accounts({required this.accounts, required this.tags});

  List<Account> get list => accounts;

  // Method to find the account with the selected tag
  Account? findAccountBySelectedTag() {
    try {
      return accounts
          .firstWhere((acc) => acc.profileInfo.tag == selectedTag.value);
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'No account found with the selected tag',
        'selected_tag': selectedTag.value,
        'accounts_tag': accounts.map((acc) => acc.profileInfo.tag).toList(),
      });

      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);

      return null;
    }
  }

  Account? findAccountByTag(String tag) {
    try {
      return accounts.firstWhere((acc) => acc.profileInfo.tag == tag);
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'No account found with the tag',
        'selected_tag': selectedTag.value,
        'accounts_tag': accounts.map((acc) => acc.profileInfo.tag).toList(),
      });
      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);
      return null;
    }
  }
}

class Account {
  final ProfileInfo profileInfo;
  Clan? clan;

  Account({required this.profileInfo, this.clan});

  String get tag => profileInfo.tag;
}

class AccountsService {
  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<Accounts> fetchAccounts(User user) async {
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
      List<Future<void>> fetchTasks = tags.map((tag) async {
        final profileSpan = transaction.startChild('fetchProfileInfo');
        ProfileInfo? profileInfo =
            await ProfileInfoService().fetchProfileInfo(tag);
        profileSpan.finish(status: SpanStatus.ok());

        if (profileInfo != null) {
          // Step 4: Create an Account object
          Account account = Account(
            profileInfo: profileInfo,
            clan: null,
          );

          // Add the account to the list immediately
          accountsList.add(account);

          // Load clanInfo in the background
          if (profileInfo.clan != null) {
            fetchClanWarInfoInBackground(
                profileInfo.clan!.tag, account, transaction);
            //fetchClanCapitalInfoInBackground(profileInfo.clan!.tag, account, transaction);
          }
        }
      }).toList();

      // Step 3: Use Future.wait to run all fetch tasks concurrently
      final fetchSpan = transaction.startChild('Future.wait');
      await Future.wait(fetchTasks);
      fetchSpan.finish(status: SpanStatus.ok());

      // Fetch selectedTag from SharedPreferences
      String? selectedTag = await getPrefs('selectedTag');

      // Step 4: Sort the accountsList with the selectedTag at the top
      final sortSpan = transaction.startChild('sortAccounts');
      accountsList.sort((a, b) {
        if (a.profileInfo.tag == selectedTag) {
          return -1; // Move the account with selectedTag to the top
        } else if (b.profileInfo.tag == selectedTag) {
          return 1; // Move the account with selectedTag to the top
        } else {
          int townHallComparison = b.profileInfo.townHallLevel
              .compareTo(a.profileInfo.townHallLevel);
          if (townHallComparison != 0) {
            return townHallComparison;
          } else {
            return b.profileInfo.expLevel.compareTo(a.profileInfo.expLevel);
          }
        }
      });
      sortSpan.finish(status: SpanStatus.ok());

      // Step 5: Create an Accounts object
      final accounts = Accounts(accounts: accountsList, tags: tags);

      final todoSpan = transaction.startChild('fetchToDo');
      ToDoService.fetchBulkPlayerToDoData(tags, accounts);
      todoSpan.finish(status: SpanStatus.ok());

      accounts.selectedTag =
          ValueNotifier<String?>(accounts.accounts.first.profileInfo.tag);

      // Step 6: Finish the transaction and return the Accounts object
      transaction.finish(status: SpanStatus.ok());
      return accounts;
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'Failed to load accounts',
        'user_tags': user.tags,
        'user_id': user.id,
        'user_username': user.globalName
      });
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);
      throw Exception('Failed to load accounts: $exception');
    }
  }

  void fetchClanWarInfoInBackground(
      String clanTag, Account account, ISentrySpan transaction) async {
    final clanSpan = transaction.startChild('fetchClanInfo');
    try {
      Clan clanInfo = await ClanService().fetchClanAndWarInfo(clanTag);
      account.clan = clanInfo;
      clanSpan.finish(status: SpanStatus.ok());
      clanInfo.clanInitialized = true;
      clanInfo.warInitialized = true;
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'Failed to load clan info',
        'clan_tag': clanTag,
        'account_tag': account.profileInfo.tag,
      });
      clanSpan.finish(status: SpanStatus.internalError());
      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);
    }
  }
}
