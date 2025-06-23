import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/auth/presentation/register_page.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late TabController _tabController;
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    final accessToken = await TokenService().getAccessToken();
    if (accessToken != null && mounted) {
      final cocService = context.read<CocAccountService>();
      final playerService = context.read<PlayerService>();
      final clanService = context.read<ClanService>();
      final warCwlService = context.read<WarCwlService>();

      await cocService.loadApiData(playerService, clanService, warCwlService);

      if (mounted) {
        // Check if user has any CoC accounts linked
        if (cocService.cocAccounts.isNotEmpty) {
          // User has accounts → go to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        } else {
          // User has no accounts → go to account management/setup page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AddCocAccountPage()),
          );
        }
      }
    }
  }

  Future<void> _signInWithDiscord() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signInWithDiscord();
      await _navigateAfterAuth();
    } catch (e) {
      if (context.mounted) {
        _handleAuthError(e);
      }
    }

    if (mounted) setState(() => _isLoading = false);
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
      if (context.mounted) {
        _handleAuthError(e);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _handleAuthError(dynamic e) {
    if (e.toString().contains("503") || e.toString().contains("500")) {
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
    final logoUrl =
        (isDarkMode ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo);
    final textLogoUrl = (isDarkMode
        ? ImageAssets.darkModeTextLogo
        : ImageAssets.lightModeTextLogo);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Column(
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CachedNetworkImage(
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          imageUrl: logoUrl,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: CachedNetworkImage(
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          imageUrl: textLogoUrl,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Welcome Text
                  Text(
                    AppLocalizations.of(context)!.welcomeBack,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    AppLocalizations.of(context)!.chooseSignInMethod,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),

                  SizedBox(height: 32),

                  // Auth Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          indicatorWeight: 3,
                          tabs: [
                            Tab(
                              icon: Icon(Icons.discord),
                              text: AppLocalizations.of(context)!.discord,
                            ),
                            Tab(
                              icon: Icon(Icons.email),
                              text: AppLocalizations.of(context)!.email,
                            ),
                          ],
                        ),

                        // Tab Content
                        Container(
                          constraints:
                              BoxConstraints(minHeight: 280, maxHeight: 360),
                          padding: EdgeInsets.all(24),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Discord Tab
                              _buildDiscordTab(),

                              // email Tab
                              _buildEmailTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Help Link
                  TextButton(
                    onPressed: () async =>
                        launchUrl(Uri.parse('https://discord.gg/clashking')),
                    child: Text(
                      AppLocalizations.of(context)!.needHelpJoinDiscord,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscordTab() {
    return Column(
      children: [
        SizedBox(height: 16),
        Icon(
          Icons.discord,
          size: 48,
          color: Color(0xFF5865F2),
        ),
        SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.signInWithDiscord,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.useDiscordAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithDiscord,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5865F2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.discord, size: 24),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.signInWithDiscord,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmailTab() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email description
          Text(
            AppLocalizations.of(context)!.useEmailAccount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterEmail;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return AppLocalizations.of(context)!.pleaseEnterValidEmail;
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              prefixIcon: Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.pleaseEnterPassword;
              }
              return null;
            },
          ),
          // Register Link
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
            child: Text(AppLocalizations.of(context)!.dontHaveAccount),
          ),

          Spacer(),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      AppLocalizations.of(context)!.signIn,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }
}
