import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/auth/presentation/email_verification_page.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/constants/layout_constants.dart';
import 'package:clashkingapp/common/widgets/responsive_layout_wrapper.dart';
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
  // Dynamic password criteria
  bool _pwHasMinLength = false;
  bool _pwHasUppercase = false;
  bool _pwHasLowercase = false;
  bool _pwHasNumber = false;
  bool _pwHasSpecial = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _passwordController.removeListener(_updatePasswordCriteria);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordCriteria);
  }

  void _updatePasswordCriteria() {
    final value = _passwordController.text;
    final hasMinLength = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(value);

    if (hasMinLength != _pwHasMinLength ||
        hasUpper != _pwHasUppercase ||
        hasLower != _pwHasLowercase ||
        hasNumber != _pwHasNumber ||
        hasSpecial != _pwHasSpecial) {
      setState(() {
        _pwHasMinLength = hasMinLength;
        _pwHasUppercase = hasUpper;
        _pwHasLowercase = hasLower;
        _pwHasNumber = hasNumber;
        _pwHasSpecial = hasSpecial;
      });
    }
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
          String errorString = e.toString().toLowerCase();
          
          // Check if email is already registered - redirect to login
          if (errorString.contains('already registered') || 
              errorString.contains('please try logging in')) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginPage(
                  prefillEmail: _emailController.text.trim(),
                ),
              ),
            );
            return;
          }
          
          // Check if verification email already sent - redirect to verification
          if (errorString.contains('verification email was already sent') ||
              errorString.contains('already sent to this address')) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailVerificationPage(
                  email: _emailController.text.trim(),
                ),
              ),
            );
            return;
          }
          
          // Show normal error message for other errors
          String errorMessage = _getLocalizedErrorMessage(e.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                maxLines: null, // Allow unlimited lines
                overflow: TextOverflow.visible, // Show all text
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 6), // Longer duration for longer text
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
    } else if (detail.contains("username is required")) {
      return AppLocalizations.of(context)!.authUsernameRequired;
    } else if (detail.contains("username must be at least")) {
      return AppLocalizations.of(context)!.authUsernameTooShort;
    } else if (detail.contains("username must be no more than")) {
      return AppLocalizations.of(context)!.authUsernameTooLong;
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
      body: ResponsiveLayoutWrapper(
        child: SingleChildScrollView(
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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: Card(
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
                          // Check for uppercase, lowercase, digit, and special character
                          if (!RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])')
                              .hasMatch(value)) {
                            return AppLocalizations.of(context)!
                              .authPasswordInvalid;
                          }
                          return null;
                        },
                      ),

                      // Dynamic password requirements checklist (placed below password field)
                      SizedBox(height: 8),
                      Builder(builder: (context) {
                        final header = AppLocalizations.of(context)!.authPasswordHeader;
                        final labelUpper = AppLocalizations.of(context)!.authPasswordUppercase;
                        final labelLower = AppLocalizations.of(context)!.authPasswordLowercase;
                        final labelNumber = AppLocalizations.of(context)!.authPasswordNumber;
                        final labelSpecial = AppLocalizations.of(context)!.authPasswordSpecial;
                        final labelLength = AppLocalizations.of(context)!.authPasswordTooShort;

                        Widget criteriaRow(bool met, String label) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  met ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: met ? Colors.green : Theme.of(context).hintColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: plain label (no checkmark)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                header,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                            criteriaRow(_pwHasMinLength, labelLength),
                            criteriaRow(_pwHasUppercase, labelUpper),
                            criteriaRow(_pwHasLowercase, labelLower),
                            criteriaRow(_pwHasNumber, labelNumber),
                            criteriaRow(_pwHasSpecial, labelSpecial),
                          ],
                        );
                      }),

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
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
