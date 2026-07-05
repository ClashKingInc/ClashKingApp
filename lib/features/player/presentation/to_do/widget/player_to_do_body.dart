import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body_card.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';

class PlayerToDoBody extends StatelessWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;
  final String emptyText;

  const PlayerToDoBody({
    super.key,
    required this.players,
    required this.memberPresenceMap,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePlayers = players.toList(growable: false)
      ..sort((a, b) => b.lastOnline.compareTo(a.lastOnline));

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          if (visiblePlayers.isEmpty)
            _EmptyTodoCard(text: emptyText)
          else
            ...visiblePlayers.map(
              (player) => PlayerToDoBodyCard(
                player: player,
                member:
                    memberPresenceMap[player.tag] ?? WarMemberPresence.empty(),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTodoCard extends StatelessWidget {
  final String text;

  const _EmptyTodoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.74),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another search or filter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
