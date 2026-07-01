import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_header.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerToDoScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;

  PlayerToDoScreen({
    super.key,
    required this.players,
    required this.memberPresenceMap,
  });

  @override
  PlayerToDoScreenState createState() => PlayerToDoScreenState();
}

class PlayerToDoScreenState extends State<PlayerToDoScreen> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final activePlayers = widget.players
        .where(
          (player) => player.lastOnline.isAfter(
            DateTime.now().subtract(const Duration(days: 14)),
          ),
        )
        .toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          PlayerToDoHeader(
            players: activePlayers,
            memberPresenceMap: widget.memberPresenceMap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                NativeLiquidGlassSegmentedControl<bool>(
                  values: const [true, false],
                  labels: [loc.todoAccountsActive, loc.todoAccountsInactive],
                  selected: _showActive,
                  onChanged: (value) => setState(() => _showActive = value),
                ),
                PlayerToDoBody(
                  players: widget.players,
                  memberPresenceMap: widget.memberPresenceMap,
                  filterOptions: const {},
                  active: _showActive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
