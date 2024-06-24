import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_join_leave_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_info_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_search_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/no_clan_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_join_leave/clan_join_leave.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClanInfoPage extends StatefulWidget {
  final Clan? clanInfo;
  final User user;

  ClanInfoPage({required this.clanInfo, required this.user});

  @override
  ClanInfoPageState createState() => ClanInfoPageState();
}

class ClanInfoPageState extends State<ClanInfoPage>
    with SingleTickerProviderStateMixin {
  Future<void>? _initializeClanFuture;

  @override
  void initState() {
    super.initState();
    _initializeClanFuture = _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    while (widget.clanInfo == null && !widget.clanInfo!.clanInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> _refreshData() async {
    // Fetch the updated profile information
    if (widget.clanInfo != null) {
      widget.clanInfo!.clanInitialized = false;
      final updatedClanInfo =
          await ClanService().fetchClanInfo(widget.clanInfo!);
      setState(() {
        // Update the clan info with the newly fetched data
        widget.clanInfo!.updateClanInfoFrom(updatedClanInfo);
        widget.clanInfo!.clanInitialized = true;
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
              textAlign: TextAlign.center,
            ),
          );
        } else {
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
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: ClanSearch(discordUser: widget.user.tags),
                            ),
                            if (widget.clanInfo != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClanInfoScreen(
                                          clanInfo: widget.clanInfo!,
                                          discordUser: widget.user.tags),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child:
                                      ClanInfoCard(clanInfo: widget.clanInfo!),
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Card(
                                  child: NoClanCard(),
                                ),
                              ),
                            if (widget.clanInfo != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClanJoinLeaveScreen(
                                          user: widget.user.tags,
                                          clanInfo: widget.clanInfo!),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ClanJoinLeaveCard(
                                    discordUser: widget.user.tags,
                                    clanInfo: widget.clanInfo!,
                                  ),
                                ),
                              ),
                            Spacer(),
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
