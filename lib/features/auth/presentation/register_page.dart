import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );

      final accessToken = await TokenService().getAccessToken();
      if (accessToken != null && mounted) {
        final cocService = context.read<CocAccountService>();
        final playerService = context.read<PlayerService>();
        final clanService = context.read<ClanService>();
        final warCwlService = context.read<WarCwlService>();
        
        await cocService.loadApiData(playerService, clanService, warCwlService);
        
        if (mounted) {
          // Check if user has CoC accounts and navigate accordingly
          if (cocService.cocAccounts.isNotEmpty) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MyHomePage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AddCocAccountPage()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
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
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoUrl = (isDarkMode ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.authCreateClashKingAccount),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              
              // Logo
              Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CachedNetworkImage(
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl: logoUrl,
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              Text(
                AppLocalizations.of(context)!.authJoinClashKing,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8),
              
              Text(
                AppLocalizations.of(context)!.authCreateAccountToGetStarted,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32),
              
              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authUsernameLabel,
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.authUsernameRequired;
                  }
                  if (value.trim().length < 3) {
                    return AppLocalizations.of(context)!.authUsernameTooShort;
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authEmailTitle,
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.authEmailRequired;
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return AppLocalizations.of(context)!.authEmailInvalid;
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
                  labelText: AppLocalizations.of(context)!.authPasswordLabel,
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.authPasswordRequired;
                  }
                  if (value.length < 8) {
                    return AppLocalizations.of(context)!.authPasswordTooShort;
                  }
                  // Check for uppercase, lowercase, digit, and special character
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
                    return AppLocalizations.of(context)!.authPasswordRequirements;
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authPasswordConfirm,
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.authPasswordConfirmRequired;
                  }
                  if (value != _passwordController.text) {
                    return AppLocalizations.of(context)!.authPasswordMismatch;
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 24),
              
              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context)!.authCreateAccount,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              
              SizedBox(height: 16),
              
              // Back to Login
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.authAlreadyHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}