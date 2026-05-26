import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/settings/presentation/settings_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final authService = context.watch<AuthService>();
    final colorScheme = Theme.of(context).colorScheme;

    if (cocService.selectedTag != null &&
        !playerService.profiles.any((p) => p.tag == cocService.selectedTag) &&
        playerService.profiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cocService.setSelectedTag(playerService.profiles.first.tag);
      });
    }

    final selectedProfile = _selectedProfile(playerService, cocService);
    final accountMenuItemCount = playerService.profiles.length + 1;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final accountWidth = math.min(constraints.maxWidth - 74, 284.0);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: accountWidth,
                  height: 46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TopGlassSurface(cornerRadius: 23),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(23),
                          splashFactory: NoSplash.splashFactory,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () => _showAccountMenu(
                            context,
                            cocService,
                            playerService,
                            accountMenuItemCount,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SelectedAccountLabel(
                                    selectedProfile: selectedProfile,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox.square(
                  dimension: 46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TopGlassSurface(cornerRadius: 23),
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          splashFactory: NoSplash.splashFactory,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: authService.currentUser == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SettingsInfoScreen(
                                        user: authService.currentUser!,
                                      ),
                                    ),
                                  );
                                },
                          child: Center(
                            child: ClipOval(
                              child: SizedBox.square(
                                dimension: 36,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      authService.currentUser?.avatarUrl ?? "",
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.person),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Player? _selectedProfile(
    PlayerService playerService,
    CocAccountService cocService,
  ) {
    for (final profile in playerService.profiles) {
      if (profile.tag == cocService.selectedTag) {
        return profile;
      }
    }
    return null;
  }

  Future<void> _showAccountMenu(
    BuildContext context,
    CocAccountService cocService,
    PlayerService playerService,
    int itemCount,
  ) {
    final screen = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight + 2;
    final width = math.min(screen.width - 24, 306.0);
    final height = math.min(70.0 + itemCount * 54.0, screen.height * 0.58);

    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Accounts',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              top: top,
              left: 12,
              width: width,
              height: height,
              child: _AccountGlassMenu(
                cocService: cocService,
                playerService: playerService,
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
    );
  }
}

class _TopGlassSurface extends StatelessWidget {
  const _TopGlassSurface({required this.cornerRadius});

  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return NativeLiquidGlassBar(
      height: 46,
      cornerRadius: cornerRadius,
      interactive: true,
      borderOpacity: Theme.of(context).brightness == Brightness.dark
          ? 0.26
          : 0.32,
      shadowOpacity: Theme.of(context).brightness == Brightness.dark
          ? 0.3
          : 0.1,
    );
  }
}

class _AccountGlassMenu extends StatelessWidget {
  const _AccountGlassMenu({
    required this.cocService,
    required this.playerService,
  });

  final CocAccountService cocService;
  final PlayerService playerService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        NativeLiquidGlassBar(
          height: 1,
          cornerRadius: 34,
          interactive: true,
          selected: true,
          borderOpacity: Theme.of(context).brightness == Brightness.dark
              ? 0.34
              : 0.42,
          shadowOpacity: Theme.of(context).brightness == Brightness.dark
              ? 0.46
              : 0.18,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Material(
            color: Colors.transparent,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Accounts',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            AppLocalizations.of(context)?.generalManage ??
                            'Manage',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddCocAccountPage(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.tune,
                          color: colorScheme.onSurface,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                ...playerService.profiles.map((profile) {
                  final selected = profile.tag == cocService.selectedTag;
                  return _AccountMenuRow(
                    selected: selected,
                    imageUrl: profile.townHallPic,
                    title: profile.name,
                    subtitle: profile.tag,
                    onTap: () {
                      cocService.setSelectedTag(profile.tag);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.white.withValues(alpha: 0.04),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: selected
                  ? Icon(Icons.check, color: colorScheme.onSurface, size: 24)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 6),
            SizedBox.square(
              dimension: 34,
              child: imageUrl == null
                  ? const Icon(Icons.shield_outlined)
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.shield_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedAccountLabel extends StatelessWidget {
  const _SelectedAccountLabel({required this.selectedProfile});

  final Player? selectedProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          height: 32,
          width: 32,
          child: selectedProfile == null
              ? const Icon(Icons.shield_outlined)
              : CachedNetworkImage(
                  imageUrl: selectedProfile!.townHallPic,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            selectedProfile?.name ??
                AppLocalizations.of(context)?.generalManage ??
                'Manage',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
