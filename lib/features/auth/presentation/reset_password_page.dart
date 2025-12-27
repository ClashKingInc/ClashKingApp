import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/common/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? email;

  const ResetPasswordPage({super.key, this.email});

  @override
  ResetPasswordPageState createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    _passwordController.addListener(_updatePasswordCriteria);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.removeListener(_updatePasswordCriteria);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordCriteria() {
    final value = _passwordController.text;
    final hasMinLength = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\[\]\\/\\;:\-_+=~`]').hasMatch(value);

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

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(_emailController.text.trim(),
          _codeController.text.trim(), _passwordController.text);

      if (mounted) {
        // Show success message first
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.authPasswordResetSuccess,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.authBackToLogin),
              ),
            ],
          ),
        );

        // Then navigate to login page
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ApiService.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ClashKing logo
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

                const SizedBox(height: 32),

                // Title
                Text(
                  AppLocalizations.of(context)!.authPasswordReset,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  AppLocalizations.of(context)!.authPasswordResetDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Combined form card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Email input
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.authEmail,
                            hintText:
                                AppLocalizations.of(context)!.authEmailHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
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

                        const SizedBox(height: 20),

                        // Reset code input
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .authPasswordResetCode,
                            hintText: AppLocalizations.of(context)!
                                .authPasswordResetCodeHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.security),
                            counterText: '', // Hide character counter
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .authPasswordResetCodeRequired;
                            }
                            if (value.length != 6 ||
                                !RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return AppLocalizations.of(context)!
                                  .authPasswordResetCodeInvalid;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Password input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.authPasswordNew,
                            hintText:
                                AppLocalizations.of(context)!.authPasswordHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .authPasswordRequired;
                            }
                            if (!RegExp(
                                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
                                .hasMatch(value)) {
                              return AppLocalizations.of(context)!
                                  .authPasswordInvalid;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Dynamic password requirements checklist (same as registration)
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
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  header,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
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

                        const SizedBox(height: 20),

                        // Confirm Password input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .authPasswordConfirm,
                            hintText: AppLocalizations.of(context)!
                                .authPasswordConfirmHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
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
                          onFieldSubmitted: (_) => _resetPassword(),
                        ),

                        const SizedBox(height: 32),

                        // Reset button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                                        .authPasswordReset,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Back to login link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              AppLocalizations.of(context)!.authBackToLogin,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
