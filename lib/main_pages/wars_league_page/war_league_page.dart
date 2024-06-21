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
  @override
  Widget build(BuildContext context) {
    String warState = "noClan";
    if (widget.account.clan != null) {
      warState = widget.account.clan!.warState;
    }

    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          setState(() {});
        },
        child: Column(
          children: [
            warState == "war"
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CurrentWarInfoScreen(
                            currentWarInfo: widget.account.clan!.currentWarInfo,
                            discordUser: widget.discordUser.tags,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 4.0, right: 4.0),
                      child: CurrentWarInfoCard(
                          currentWarInfo: widget.account.clan!.currentWarInfo,
                          clanTag: widget.account.clan!.tag),
                    ),
                  )
                : warState == "accessDenied"
                    ? Padding(
                        padding: EdgeInsets.only(left: 4.0, right: 4.0),
                        child: AccessDeniedCard(
                            clanName: widget.account.profileInfo.clan!.name,
                            clanBadgeUrl: widget
                                .account.profileInfo.clan!.badgeUrls.large),
                      )
                    : warState == "cwl"
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CurrentLeagueInfoScreen(
                                    currentLeagueInfo:
                                        widget.account.clan!.currentLeagueInfo,
                                    clanTag:
                                        widget.account.profileInfo.clan!.tag,
                                    clanInfo: widget.account.clan!,
                                    discordUser: widget.discordUser.tags,
                                  ),
                                ),
                              );
                            },
                            child: CwlCard(
                              currentLeagueInfo:
                                  widget.account.clan!.currentLeagueInfo,
                              clanTag: widget.account.profileInfo.clan!.tag,
                              clanInfo: widget.account.clan!,
                            ),
                          )
                        : warState == "noClan"
                            ? Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Card(
                                  child: NoClanCard(),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                child: NotInWarCard(
                                    clanName:
                                        widget.account.profileInfo.clan!.name,
                                    clanBadgeUrl: widget.account.profileInfo
                                        .clan!.badgeUrls.large),
                              ),
            warState != "noClan" && warState != "accessDenied"
                ? WarHistoryCard(
                    warLogData: widget.account.clan!.warLog.items,
                    playerStats: widget.account.profileInfo,
                    discordUser: widget.discordUser.tags,
                    warLogStats: widget.account.clan!.warLog.warLogStats,
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
