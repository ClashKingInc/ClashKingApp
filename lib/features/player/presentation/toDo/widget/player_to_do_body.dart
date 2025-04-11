import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/toDo/widget/player_to_do_body_card.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerToDoBody extends StatefulWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;
  final Map<String, String> filterOptions;
  final bool active;

  PlayerToDoBody({
    super.key,
    required this.filterOptions,
    required this.active,
    required this.players,
    required this.memberPresenceMap,
  });

  @override
  PlayerToDoBodyState createState() => PlayerToDoBodyState();
}

class PlayerToDoBodyState extends State<PlayerToDoBody> {
  List<Widget> _buildCards() {
    final today = DateTime.now();
    final threshold = today.subtract(const Duration(days: 14));
    final List<Widget> cards = [];

    for (var player in widget.players) {
      final isActive = player.lastOnline.isAfter(threshold);
      final member =
          widget.memberPresenceMap[player.tag] ?? WarMemberPresence.empty();

      if ((widget.active && isActive) || (!widget.active && !isActive)) {
        cards.add(
          PlayerToDoBodyCard(
            player: player,
            member: member,
          ),
        );
      }
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final cards = _buildCards();

    return Column(
      children: [
        const SizedBox(height: 8),
        if (cards.isEmpty && !widget.active)
          _emptyCard(
            context,
            AppLocalizations.of(context)!.noActiveAccounts,
            'https://assets.clashk.ing/stickers/Villager_BB_Master_Builder_7.png',
          )
        else if (cards.isEmpty && widget.active)
          _emptyCard(
            context,
            AppLocalizations.of(context)!.noInactiveAccounts,
            'https://assets.clashk.ing/stickers/Villager_BB_Master_Builder_4.png',
          )
        else
          ...cards,
      ],
    );
  }

  Widget _emptyCard(BuildContext context, String text, String imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(text),
              const SizedBox(height: 10),
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: 200,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
