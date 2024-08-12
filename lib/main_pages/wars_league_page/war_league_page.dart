import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/access_denied_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/current_league_info_page.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/not_in_war_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/cwl_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/war_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/war_history_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/no_clan_card.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';

class CurrentWarInfoPage extends StatefulWidget {
  final Account account;
  final User discordUser;

  CurrentWarInfoPage({
    required this.discordUser,
    required this.account,
  });

  @override
  State<CurrentWarInfoPage> createState() => CurrentWarInfoPageState();
}

class CurrentWarInfoPageState extends State<CurrentWarInfoPage> {
  Future<void>? _initializeClanFuture;

  @override
  void initState() {
    super.initState();
    _initializeClanFuture = _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    while ((widget.account.clan == null) ||
        (widget.account.clan != null && !widget.account.clan!.warInitialized)) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> _refreshData() async {
    // Fetch the updated profile information
    if (widget.account.clan != null) {
      widget.account.clan!.warInitialized = false;
      final updatedClanInfo =
          await ClanService().fetchWarLeagueInfo(widget.account.clan!);
      setState(() {
        // Update the player stats with the newly fetched data
        widget.account.clan!.updateWarLeagueFrom(updatedClanInfo);
        _initializeClanFuture = _checkInitialization();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeClanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          Sentry.captureException(snapshot.error);
          return Center(
            child: Text(
              AppLocalizations.of(context)!.connectionErrorRelaunch,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        } else {
          String warState = "noClan";
          if (widget.account.clan != null) {
            warState = widget.account.clan!.warState;
          }
          return Scaffold(
            body: RefreshIndicator(
              backgroundColor: Theme.of(context).colorScheme.surface,
              onRefresh: _refreshData,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(height: 4),
                            warState == "war"
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CurrentWarInfoScreen(
                                            currentWarInfo: widget
                                                .account.clan!.currentWarInfo!,
                                            discordUser:
                                                widget.discordUser.tags,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: CurrentWarInfoCard(
                                          currentWarInfo: widget
                                              .account.clan!.currentWarInfo!,
                                          clanTag: widget.account.clan!.tag),
                                    ),
                                  )
                                : warState == "accessDenied"
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: AccessDeniedCard(
                                            clanName: widget
                                                .account.profileInfo.clan!.name,
                                            clanBadgeUrl: widget
                                                .account
                                                .profileInfo
                                                .clan!
                                                .badgeUrls
                                                .large),
                                      )
                                    : warState == "cwl"
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Card(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface
                                                  .withOpacity(0.1),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Column(
                                                  children: [
                                                    Text(AppLocalizations.of(
                                                            context)!
                                                        .clanWarLeague),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                CurrentLeagueInfoScreen(
                                                              currentLeagueInfo:
                                                                  widget
                                                                      .account
                                                                      .clan!
                                                                      .currentLeagueInfo!,
                                                              clanTag: widget
                                                                  .account
                                                                  .profileInfo
                                                                  .clan!
                                                                  .tag,
                                                              clanInfo: widget
                                                                  .account
                                                                  .clan!,
                                                              discordUser: widget
                                                                  .discordUser
                                                                  .tags,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: CwlCard(
                                                        currentLeagueInfo: widget
                                                            .account
                                                            .clan!
                                                            .currentLeagueInfo!,
                                                        clanTag: widget
                                                            .account
                                                            .profileInfo
                                                            .clan!
                                                            .tag,
                                                        clanInfo: widget
                                                            .account.clan!,
                                                        discordUser: widget
                                                            .discordUser.tags,
                                                      ),
                                                    ),
                                                    FutureBuilder<
                                                        CurrentWarInfo?>(
                                                      future: widget
                                                          .account
                                                          .clan!
                                                          .currentLeagueInfo!
                                                          .getActiveWar(widget
                                                              .account
                                                              .clan!
                                                              .tag),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return CircularProgressIndicator(); // Show a loading indicator while waiting
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Error: ${snapshot.error}'); // Handle error case
                                                        } else if (!snapshot
                                                                .hasData ||
                                                            snapshot.data ==
                                                                null) {
                                                          return Text(
                                                              'No active war found'); // Handle no data case
                                                        } else {
                                                          return GestureDetector(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            CurrentWarInfoScreen(
                                                                      currentWarInfo:
                                                                          snapshot
                                                                              .data!,
                                                                      discordUser: widget
                                                                          .discordUser
                                                                          .tags,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              child:
                                                                  CurrentWarInfoCard(
                                                                currentWarInfo:
                                                                    snapshot
                                                                        .data!,
                                                                clanTag: widget
                                                                    .account
                                                                    .clan!
                                                                    .tag,
                                                              ));
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : warState == "noClan"
                                            ? Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8.0),
                                                child: Card(
                                                  child: NoClanCard(),
                                                ),
                                              )
                                            : Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8.0),
                                                child: NotInWarCard(
                                                    clanName: widget.account
                                                        .profileInfo.clan!.name,
                                                    clanBadgeUrl: widget
                                                        .account
                                                        .profileInfo
                                                        .clan!
                                                        .badgeUrls
                                                        .large),
                                              ),
                            warState != "noClan" &&
                                    warState != "accessDenied" &&
                                    widget.account.clan!.isWarLogPublic != false
                                ? WarHistoryCard(
                                    warLogData:
                                        widget.account.clan!.warLog.items,
                                    playerStats: widget.account.profileInfo,
                                    discordUser: widget.discordUser.tags,
                                    warLogStats:
                                        widget.account.clan!.warLog.warLogStats,
                                  )
                                : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
