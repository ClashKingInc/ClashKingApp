import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';

class CocAccountsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CocAccountsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : IconButton(
              icon: const Icon(Icons.logout),
              tooltip: AppLocalizations.of(context)?.authLogout ?? 'Log out',
              onPressed: () async {
                final playerService = context.read<PlayerService>();
                await context.read<AuthService>().logout();
                if (!context.mounted) return;
                context.read<CocAccountService>().clearAccountData();
                clearAccountScopedHomeCaches(playerService);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (_) => false,
                );
              },
            ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            user != null
                ? Text(
                    user.username,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(AppLocalizations.of(context)!.generalLoading),
            Padding(padding: EdgeInsets.all(5)),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: user != null
                    ? MobileWebImage(
                        imageUrl: user.avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      ],
    );
  }
}
