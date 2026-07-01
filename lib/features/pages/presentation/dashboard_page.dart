import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/pages/widgets/home_todo_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final prefs = context.watch<PlayerCardPreferencesService>();
    final players = playerService.profiles;
    final pinnedTags = prefs.todoOnHomeTags;
    final pinnedPlayers = players
        .where((player) => pinnedTags.contains(_normalizeTag(player.tag)))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            const HomeEventBanner(),
            const SizedBox(height: 16),
            if (players.isEmpty)
              const _EmptyDashboard(
                title: 'No linked accounts',
                message:
                    'Link a Clash account to see attacks, events, and activity here.',
              )
            else if (pinnedPlayers.isEmpty)
              const _EmptyDashboard(
                title: 'Nothing pinned yet',
                message:
                    'Open the Players tab, expand a card\'s options, and turn on '
                    '"Show to-do on home" to pin an account here.',
              )
            else
              HomeTodoCard(players: pinnedPlayers, allPlayers: players),
          ],
        ),
      ),
    );
  }

  static String _normalizeTag(String tag) =>
      tag.replaceAll('#', '').trim().toUpperCase();
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
