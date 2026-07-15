import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body_card.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

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
    return AppEmptyState(
      title: text,
      body: AppLocalizations.of(context)!.todoTryAnotherSearchOrFilter,
      icon: Icons.search_off_rounded,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      stickerHeight: 140,
      stickerWidth: 112,
    );
  }
}
