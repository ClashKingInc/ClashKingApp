import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/pages/widgets/home_todo_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final players = playerService.profiles;
    final linkedTags = cocService.verifiedAccounts
        .map(
          (account) => _normalizeTag(account['player_tag']?.toString() ?? ''),
        )
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final linkedPlayers = players
        .where((player) => linkedTags.contains(_normalizeTag(player.tag)))
        .toList(growable: false);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final bottomPadding = isDesktopWeb
        ? 32.0
        : MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = isDesktopWeb ? 1320.0 : 840.0;
            final horizontalPadding =
                ((constraints.maxWidth - maxContentWidth) / 2)
                    .clamp(16.0, double.infinity)
                    .toDouble();

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                bottomPadding,
              ),
              children: [
                const HomeEventBanner(),
                SizedBox(height: isDesktopWeb ? 24 : 16),
                if (linkedPlayers.isEmpty)
                  _EmptyDashboard(
                    title: AppLocalizations.of(
                      context,
                    )!.dashboardNoLinkedAccountsTitle,
                    message: AppLocalizations.of(
                      context,
                    )!.dashboardNoLinkedAccountsBody,
                    icon: Icons.account_circle_outlined,
                    actionLabel: AppLocalizations.of(
                      context,
                    )!.drawerManageAccounts,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const AddCocAccountPage(refreshOnExit: false),
                      ),
                    ),
                  )
                else
                  HomeTodoCard(
                    players: linkedPlayers,
                    allPlayers: linkedPlayers,
                  ),
              ],
            );
          },
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
