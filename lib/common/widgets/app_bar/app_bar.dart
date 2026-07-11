import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const MainPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint,
    this.onSearchTap,
    this.onProfileTap,
  });

  final String title;
  final String? subtitle;
  final String? searchHint;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _HeaderProfileButton(authService: authService, onTap: onProfileTap),
            const SizedBox(width: 10),
            Expanded(
              child: searchHint == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                          ),
                      ],
                    )
                  : _HeaderSearchButton(hint: searchHint!, onTap: onSearchTap),
            ),
          ],
        ),
      ),
    );
  }
}

typedef CustomAppBar = MainPageHeader;

class _HeaderProfileButton extends StatelessWidget {
  const _HeaderProfileButton({required this.authService, required this.onTap});

  final AuthService authService;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile menu',
      child: SizedBox.square(
        dimension: 46,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _TopGlassSurface(),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap:
                    onTap ??
                    (authService.currentUser == null
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
                          }),
                child: Center(
                  child: ClipOval(
                    child: SizedBox.square(
                      dimension: 36,
                      child: MobileWebImage(
                        imageUrl: authService.currentUser?.avatarUrl ?? '',
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
    );
  }
}

class _HeaderSearchButton extends StatelessWidget {
  const _HeaderSearchButton({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: hint,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LiquidGlassBar(
                height: 48,
                cornerRadius: 24,
                interactive: true,
                borderOpacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.14
                    : 0.30,
                shadowOpacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.12
                    : 0.08,
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopGlassSurface extends StatelessWidget {
  const _TopGlassSurface();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBar(
      height: 46,
      cornerRadius: 23,
      interactive: true,
      borderOpacity: Theme.of(context).brightness == Brightness.dark
          ? 0.16
          : 0.32,
      shadowOpacity: Theme.of(context).brightness == Brightness.dark
          ? 0.14
          : 0.1,
    );
  }
}
