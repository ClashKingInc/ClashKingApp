import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:clashkingapp/common/widgets/buttons/info_button.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';

class PlayerToDoHeader extends StatefulWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;

  PlayerToDoHeader({super.key, required this.players, required this.memberPresenceMap});

  @override
  PlayerToDoHeaderState createState() => PlayerToDoHeaderState();
}

class PlayerToDoHeaderState extends State<PlayerToDoHeader> {
  @override
  Widget build(BuildContext context) {
    print("PlayerToDoHeader build called");
    final loc = AppLocalizations.of(context)!;
    int total = widget.players.length;
    int active = widget.players.where((p) => DateTime.now().difference(p.lastOnline).inDays < 14).length;
    int inactive = total - active;

    int totalClanGames = 0;
    int requiredClanGames = widget.players.length * 4000;
    int totalSeasonPass = 0;
    int requiredSeasonPass = widget.players.length * 2600; // min threshold
    int totalLegend = 0;
    int requiredLegend = 0;
    int totalCwl = 0;
    int requiredCwl = 0;

    for (final player in widget.players) {
      totalClanGames += player.currentClanGamesPoints;
      totalSeasonPass += player.currentSeasonPoints;

      if (player.league == "Legend League" && player.currentLegendSeason?.currentDay != null) {
        requiredLegend += 8;
        totalLegend += player.currentLegendSeason!.currentDay!.totalAttacks;
      }

      final warPresence = widget.memberPresenceMap[player.tag];
      if (warPresence != null && warPresence.attacksAvailable > 0) {
        requiredCwl += warPresence.attacksAvailable;
        totalCwl += warPresence.attacksDone;
      }
    }

    final double progressRatio = widget.players.isEmpty
        ? 0
        : widget.players
                .map((p) => p.getTodoProgressRatio(
                    memberCwl: widget.memberPresenceMap[p.tag] ?? WarMemberPresence.empty()))
                .reduce((a, b) => a + b) /
            widget.players.length;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7),
                BlendMode.darken,
              ),
              child: CachedNetworkImage(
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl: "https://assets.clashk.ing/landscape/todo-landscape.png",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Column(
          children: [
            Text(loc.numberAccounts(total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            Text(loc.numberActiveAccounts(active),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            Text(loc.numberInactiveAccounts(inactive),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 7.0,
              runSpacing: -7.0,
              children: <Widget>[
                if (requiredLegend > 0)
                  _buildChip(context, ImageAssets.legendBlazonNoPadding, totalLegend, requiredLegend),
                if (requiredCwl > 0)
                  _buildChip(context, ImageAssets.cwlSwordsNoBorder, totalCwl, requiredCwl),
                if (totalClanGames > 0)
                  _buildChip(context, ImageAssets.clanGamesMedals, totalClanGames, requiredClanGames),
                _buildChip(context, ImageAssets.iconGoldPass, totalSeasonPass, requiredSeasonPass),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 10,
          left: 20,
          right: 20,
          child: Row(
            children: [
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text('${(progressRatio * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        InfoButton(
          title: loc.todoExplanation_title,
          textSpan: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface),
            children: [
              TextSpan(text: "${loc.todoExplanation_intro}\n\n"),
              TextSpan(text: "${loc.todoExplanation_legends_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "${loc.todoExplanation_legends}\n\n"),
              TextSpan(text: "${loc.todoExplanation_raids_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "${loc.todoExplanation_raids}\n\n"),
              TextSpan(text: "${loc.todoExplanation_clanWars_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "${loc.todoExplanation_clanWars}\n\n"),
              TextSpan(text: "${loc.todoExplanation_cwl_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "${loc.todoExplanation_cwl}\n\n"),
              TextSpan(text: "${loc.todoExplanation_passAndGames_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "${loc.todoExplanation_passAndGames}\n\n"),
              TextSpan(text: loc.todoExplanation_conclusion),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String imageUrl, int value, int max) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: CachedNetworkImage(
          errorWidget: (context, url, error) => Icon(Icons.error),
          imageUrl: imageUrl,
        ),
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: 4.0),
      label: Text('$value/$max', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: value >= max ? Colors.green : Colors.red, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
