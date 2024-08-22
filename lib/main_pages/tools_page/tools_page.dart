//import 'package:clashkingapp/main_pages/tools_page/tools_cards/community_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ToolsPage extends StatefulWidget {
  @override
  ToolsPageState createState() => ToolsPageState();
}

class ToolsPageState extends State<ToolsPage> {
  @override
  Widget build(BuildContext context) {
    //return Center(
    //    child: Text(AppLocalizations.of(context)!.comingSoon),
    //  );


    Future<void> refreshData() async {
    setState(() {
      // Update the player stats with the newly fetched data
    });
  }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: RefreshIndicator(
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: refreshData,
          child: ListView(
            children: <Widget>[
              //Padding(
              //  padding: EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
              //  child: CommunityCard(),
              //),
                SizedBox(height: 300),
                Center(
                  child: Text(AppLocalizations.of(context)!.comingSoon
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}