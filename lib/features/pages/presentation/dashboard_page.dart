import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/pages/widgets/home_todo_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final prefs = context.watch<PlayerCardPreferencesService>();
    final cocService = context.watch<CocAccountService>();
    final players = playerService.profiles;
    final linkedTags = cocService
        .getAccountTags()
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final pinnedTags = prefs.todoOnHomeTags;
    final pinnedPlayers = players
        .where((player) => pinnedTags.contains(_normalizeTag(player.tag)))
        .toList(growable: false);
    final linkedPlayers = players
        .where((player) => linkedTags.contains(_normalizeTag(player.tag)))
        .toList(growable: false);
    final pinnedBookmarkedPlayers = players
        .where((player) {
          final tag = _normalizeTag(player.tag);
          return !linkedTags.contains(tag) && pinnedTags.contains(tag);
        })
        .toList(growable: false);
    final todoPlayers = [...linkedPlayers, ...pinnedBookmarkedPlayers];
    final horizontalPadding = ((MediaQuery.sizeOf(context).width - 840) / 2)
        .clamp(16.0, double.infinity)
        .toDouble();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            const HomeEventBanner(),
            const SizedBox(height: 16),
            if (players.isEmpty)
              _EmptyDashboard(
                title: AppLocalizations.of(
                  context,
                )!.dashboardNoLinkedAccountsTitle,
                message: AppLocalizations.of(
                  context,
                )!.dashboardNoLinkedAccountsBody,
                icon: Icons.account_circle_outlined,
                actionLabel: AppLocalizations.of(context)!.drawerManageAccounts,
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const AddCocAccountPage(refreshOnExit: false),
                  ),
                ),
              )
            else if (pinnedPlayers.isEmpty)
              _EmptyDashboard(
                title: AppLocalizations.of(
                  context,
                )!.dashboardNothingPinnedTitle,
                message: AppLocalizations.of(
                  context,
                )!.dashboardNothingPinnedBody,
                icon: Icons.push_pin_outlined,
              )
            else
              HomeTodoCard(players: pinnedPlayers, allPlayers: todoPlayers),
          ],
        ),
      ),
    );
  }

  static String _normalizeTag(String tag) =>
      tag.replaceAll('#', '').trim().toUpperCase();
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      body: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
    );
  }
}
