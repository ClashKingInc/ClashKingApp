import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/auth/presentation/email_verification_page.dart';
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

      // Registration successful - verification email sent
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains("503") || e.toString().contains("500")) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MaintenanceScreen()),
          );
        } else {
          String errorMessage = _getLocalizedErrorMessage(e.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.generalOk,
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _getLocalizedErrorMessage(String errorString) {
    // Extract the detail message from BadRequestException format
    String detail = "";
    if (errorString.contains('"detail"')) {
      final regex = RegExp(r'"detail"\s*:\s*"([^"]*)"');
      final match = regex.firstMatch(errorString);
      detail = match?.group(1)?.toLowerCase() ?? errorString.toLowerCase();
    } else {
      detail = errorString.toLowerCase();
    }

    // Map API error messages to localized messages
    if (detail.contains("already registered")) {
      return AppLocalizations.of(context)!.authErrorEmailAlreadyRegistered;
    } else if (detail.contains("verification email was already sent")) {
      return AppLocalizations.of(context)!.authErrorEmailAlreadyPending;
    } else if (detail.contains("invalid email format")) {
      return AppLocalizations.of(context)!.authErrorEmailInvalidFormat;
    } else if (detail.contains("failed to send verification email")) {
      return AppLocalizations.of(context)!.authErrorEmailSendFailed;
    } else if (detail.contains("password must contain") ||
        detail.contains("weak patterns")) {
      return AppLocalizations.of(context)!.authErrorPasswordWeak;
    } else if (detail.contains("password must be at least")) {
      return AppLocalizations.of(context)!.authPasswordTooShort;
    } else if (detail.contains("username must be at least")) {
      return AppLocalizations.of(context)!.authUsernameTooShort;
    } else if (detail.contains("username can only contain")) {
      return AppLocalizations.of(context)!.authErrorUsernameInvalid;
    } else if (detail.contains("rate limit") || detail.contains("too many")) {
      return AppLocalizations.of(context)!.authErrorRateLimited;
    } else if (detail.contains("network") || detail.contains("connection")) {
      return AppLocalizations.of(context)!.authErrorConnection;
    } else if (detail.contains("server") ||
        detail.contains("500") ||
        detail.contains("503")) {
      return AppLocalizations.of(context)!.authErrorServerUnavailable;
    } else {
      return AppLocalizations.of(context)!.authErrorRegistrationFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoUrl =
        (isDarkMode ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Registration form card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.authUsernameLabel,
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!
                                .authUsernameRequired;
                          }
                          if (value.trim().length < 3) {
                            return AppLocalizations.of(context)!
                                .authUsernameTooShort;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.authEmail,
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!
                                .authEmailRequired;
                          }
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(value)) {
                            return AppLocalizations.of(context)!
                                .authEmailInvalid;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.authPasswordLabel,
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .authPasswordRequired;
                          }
                          if (value.length < 8) {
                            return AppLocalizations.of(context)!
                                .authPasswordTooShort;
                          }
                          // Check for uppercase, lowercase, digit, and special character
                          if (!RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])')
                              .hasMatch(value)) {
                            return AppLocalizations.of(context)!
                                .authPasswordRequirements;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.authPasswordConfirm,
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .authPasswordConfirmRequired;
                          }
                          if (value != _passwordController.text) {
                            return AppLocalizations.of(context)!
                                .authPasswordMismatch;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _register(),
                      ),

                      SizedBox(height: 32),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!
                                      .authCreateAccount,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Back to Login
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.of(context)!
                            .authAlreadyHaveAccount),
                      ),
                    ],
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
