import 'dart:async';

import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/widgets/war_widget.dart';

/// Owns the account-related work that must run after a session is restored or
/// a user signs in. Keeping this sequence here prevents the startup and login
/// flows from drifting apart.
class AccountBootstrapService {
  const AccountBootstrapService();

  Future<void> initialize({
    required String? userId,
    required CocAccountService cocAccounts,
    required BookmarkService bookmarks,
    required PlayerService players,
    required ClanService clans,
    required WarCwlService wars,
  }) async {
    cocAccounts.setCurrentUserId(userId);
    bookmarks.setCurrentUserId(userId);

    await Future.wait([
      cocAccounts.loadSelectedTag(),
      if (!bookmarks.loaded) bookmarks.load(),
    ]);

    final bookmarkedPlayerTags = bookmarks.players
        .map((player) => player.tag)
        .toList(growable: false);
    final bookmarkedClanTags = bookmarks.clans
        .map((clan) => clan.tag)
        .toList(growable: false);

    await Future.wait([
      cocAccounts.loadApiData(
        players,
        clans,
        wars,
        bookmarkedClanTags: bookmarkedClanTags,
      ),
      if (bookmarkedPlayerTags.isNotEmpty)
        players.hydrateBookmarkedPlayers(bookmarkedPlayerTags),
    ]);

    unawaited(
      WarWidgetService.seedClanOptionsFromProfiles(
        players.profiles,
        bookmarkedClans: bookmarks.clans,
        selectedPlayerTag: cocAccounts.selectedTag,
        refreshWarData: true,
      ).catchError((Object error) {
        DebugUtils.debugWarning('Could not seed war widget clans: $error');
      }),
    );
  }
}
