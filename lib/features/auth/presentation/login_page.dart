import 'package:clashkingapp/common/widgets/loading/app_loading_screen.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/auth/presentation/register_page.dart';
import 'package:clashkingapp/features/auth/presentation/forgot_password_page.dart';
import 'package:clashkingapp/features/auth/presentation/email_verification_page.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/account_bootstrap_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/utils/network_error_utils.dart';

class LoginPage extends StatefulWidget {
  final String? prefillEmail;

  const LoginPage({super.key, this.prefillEmail});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedAuthTab = 0;
  bool _isLoading = false;

  // Email form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && _selectedAuthTab != _tabController.index) {
        setState(() => _selectedAuthTab = _tabController.index);
      }
    });

    // Pre-fill email if provided
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
      // Show a brief message to let user know why they're here
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.authErrorEmailAlreadyRegistered,
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    if (mounted) {
      // Navigate to loading screen and let it handle the data loading and navigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => _PostAuthLoadingScreen()),
      );
    }
  }

  Future<void> _signInWithDiscord() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signInWithDiscord();
      await _navigateAfterAuth();
    } catch (e) {
      if (mounted) {
        _handleAuthError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await _navigateAfterAuth();
    } catch (e) {
      if (mounted) {
        if (e is EmailVerificationRequiredException) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  EmailVerificationPage(email: _emailController.text.trim()),
            ),
          );
        } else {
          _handleAuthError(e);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAuthError(dynamic e) {
    if (!mounted) {
      return;
    }

    if (isMaintenanceError(e)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MaintenanceScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoUrl = (isDarkMode
        ? ImageAssets.darkModeLogo
        : ImageAssets.lightModeLogo);
    final textLogoUrl = (isDarkMode
        ? ImageAssets.darkModeTextLogo
        : ImageAssets.lightModeTextLogo);
    final size = MediaQuery.sizeOf(context);
    final isDesktopWeb = kIsWeb && size.width >= 900;

    if (isDesktopWeb) {
      return _buildDesktopLayout(context, logoUrl, textLogoUrl);
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  _LoginBrandLockup(
                    logoUrl: logoUrl,
                    textLogoUrl: textLogoUrl,
                    centered: true,
                  ),

                  SizedBox(height: 16),

                  // ClashKing Description
                  Text(
                    AppLocalizations.of(context)!.appDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24),

                  // Auth Tabs
                  _buildAuthPanel(context, maxWidth: 700, contentHeight: 328),

                  SizedBox(height: 12),

                  // Help Section
                  _LoginHelpLinks(centered: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    String logoUrl,
    String textLogoUrl,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.fromLTRB(56, 48, 48, 48),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.28,
                  ),
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.26),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LoginBrandLockup(
                      logoUrl: logoUrl,
                      textLogoUrl: textLogoUrl,
                      centered: false,
                    ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.appDescription,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1.16,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _LoginSignalChip(
                          icon: Icons.home_outlined,
                          label: AppLocalizations.of(context)!.navigationHome,
                        ),
                        _LoginSignalChip(
                          icon: Icons.person_outline_rounded,
                          label: AppLocalizations.of(context)!.searchTabPlayers,
                        ),
                        _LoginSignalChip(
                          icon: Icons.groups_outlined,
                          label: AppLocalizations.of(context)!.clanTitle,
                        ),
                        _LoginSignalChip(
                          icon: Icons.shield_outlined,
                          label: AppLocalizations.of(context)!.warTitle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.authDiscordSignIn,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.authDiscordDescription,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 22),
                        _buildAuthPanel(
                          context,
                          maxWidth: 520,
                          contentHeight: 316,
                        ),
                        const SizedBox(height: 18),
                        _LoginHelpLinks(centered: false),
                      ],
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

  Widget _buildAuthPanel(
    BuildContext context, {
    required double maxWidth,
    required double contentHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: LiquidGlassSegmentedControl<int>(
                values: const [0, 1],
                labels: [
                  AppLocalizations.of(context)!.authDiscordTitle,
                  AppLocalizations.of(context)!.authEmail,
                ],
                selected: _selectedAuthTab,
                height: 44,
                onChanged: (index) {
                  setState(() => _selectedAuthTab = index);
                  _tabController.animateTo(index);
                },
              ),
            ),
            SizedBox(
              height: contentHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildDiscordTab(), _buildEmailTab()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscordTab() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 12),
              Icon(Icons.discord, size: 48, color: Color(0xFF5865F2)),
              SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.authDiscordSignIn,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.authDiscordDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithDiscord,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5865F2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.discord, size: 20),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.authDiscordContinue,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmailTab() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 8),

                  // Email description
                  Text(
                    AppLocalizations.of(context)!.authEmailDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.authEmail,
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.authEmailRequired;
                      }
                      if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(value)) {
                        return AppLocalizations.of(context)!.authEmailInvalid;
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 10),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.authPasswordLabel,
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? AppLocalizations.of(context)!.tooltipShowPassword
                            : AppLocalizations.of(context)!.tooltipHidePassword,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.authPasswordRequired;
                      }
                      return null;
                    },
                  ),

                  // Authentication Links
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.authSignUp,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.authPasswordForgot,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sign In Button (aligned with Discord button)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.authLogin,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoginBrandLockup extends StatelessWidget {
  const _LoginBrandLockup({
    required this.logoUrl,
    required this.textLogoUrl,
    required this.centered,
  });

  final String logoUrl;
  final String textLogoUrl;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox(
      height: centered ? 80 : 64,
      width: centered ? 80 : 64,
      child: MobileWebImage(
        imageUrl: logoUrl,
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
    final textLogo = SizedBox(
      width: centered ? 160 : 184,
      child: MobileWebImage(
        imageUrl: textLogoUrl,
        errorWidget: (context, url, error) => Text(
          'ClashKing',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );

    if (centered) {
      return Column(children: [logo, const SizedBox(height: 12), textLogo]);
    }

    return Row(children: [logo, const SizedBox(width: 14), textLogo]);
  }
}

class _LoginSignalChip extends StatelessWidget {
  const _LoginSignalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHelpLinks extends StatelessWidget {
  const _LoginHelpLinks({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = [
      TextButton.icon(
        onPressed: () async =>
            launchUrl(Uri.parse('https://discord.gg/clashking')),
        icon: Icon(Icons.discord, size: 16, color: colorScheme.primary),
        label: Text(
          AppLocalizations.of(context)!.helpJoinDiscord,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      TextButton.icon(
        onPressed: () async => launchUrl(
          Uri.parse('mailto:devs@clashk.ing?subject=ClashKing App Support'),
        ),
        icon: Icon(Icons.email_outlined, size: 16, color: colorScheme.primary),
        label: Text(
          AppLocalizations.of(context)!.helpEmailUs,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.helpTitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          spacing: 8,
          runSpacing: 4,
          children: children,
        ),
      ],
    );
  }
}

class _PostAuthLoadingScreen extends StatefulWidget {
  @override
  _PostAuthLoadingScreenState createState() => _PostAuthLoadingScreenState();
}

class _PostAuthLoadingScreenState extends State<_PostAuthLoadingScreen> {
  static const _accountBootstrap = AccountBootstrapService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPostAuth());
  }

  Future<void> _initPostAuth() async {
    if (mounted) {
      final cocService = context.read<CocAccountService>();
      final playerService = context.read<PlayerService>();
      final clanService = context.read<ClanService>();
      final warCwlService = context.read<WarCwlService>();
      final authService = context.read<AuthService>();
      final bookmarkService = context.read<BookmarkService>();

      try {
        await _accountBootstrap.initialize(
          userId: authService.currentUser?.userId,
          cocAccounts: cocService,
          bookmarks: bookmarkService,
          players: playerService,
          clans: clanService,
          wars: warCwlService,
        );
      } catch (e) {
        if (mounted) {
          _showPostAuthFailure(e);
        }
        return;
      }
    }

    setState(() {
      _isInitializing = false;
    });

    _navigateToNextScreen();
  }

  void _showPostAuthFailure(dynamic error) {
    if (!mounted) return;

    if (isMaintenanceError(error)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ErrorPage(
          isNetworkError: isNetworkError(error),
          onRetry: () async {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => _PostAuthLoadingScreen()),
            );
          },
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    Future.microtask(() {
      Widget nextPage;
      if (mounted) {
        if (context.read<CocAccountService>().cocAccounts.isNotEmpty) {
          // ✅ User has CoC account → Go to home page
          nextPage = MyHomePage();
        } else {
          // ❌ No account → Go to add account page
          nextPage = AddCocAccountPage();
        }
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => nextPage));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isInitializing ? const AppLoadingScreen() : const SizedBox.shrink();
  }
}
