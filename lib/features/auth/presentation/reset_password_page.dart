import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:clashkingapp/features/auth/presentation/widgets/auth_password_requirements.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
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
    final hasSpecial = RegExp(
      r'[!@#\$%\^&\*(),.?":{}|<>\[\]\\/\\;:\-_+=~`]',
    ).hasMatch(value);

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
      await authService.resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Show success message first
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.authPasswordResetSuccess,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(elevation: 0),
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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return AuthPageShell(
      formKey: _formKey,
      title: l10n.authPasswordReset,
      description: l10n.authPasswordResetDescription,
      child: CKSectionPanel(
        padding: const EdgeInsets.all(CKSpacing.lg),
        child: Column(
          children: [
            // Email input
            TextFormField(
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.authEmail,
                hintText: AppLocalizations.of(context)!.authEmailHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CKRadius.control),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
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

            const SizedBox(height: CKSpacing.lg),

            // Reset code input
            TextFormField(
              controller: _codeController,
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.authPasswordResetCode,
                hintText: AppLocalizations.of(
                  context,
                )!.authPasswordResetCodeHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CKRadius.control),
                ),
                prefixIcon: const Icon(Icons.security),
                counterText: '', // Hide character counter
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  )!.authPasswordResetCodeRequired;
                }
                if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return AppLocalizations.of(
                    context,
                  )!.authPasswordResetCodeInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: CKSpacing.lg),

            // Password input
            TextFormField(
              controller: _passwordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.authPasswordNew,
                hintText: AppLocalizations.of(context)!.authPasswordHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CKRadius.control),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? AppLocalizations.of(context)!.tooltipShowPassword
                      : AppLocalizations.of(context)!.tooltipHidePassword,
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.authPasswordRequired;
                }
                if (!RegExp(
                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
                ).hasMatch(value)) {
                  return AppLocalizations.of(context)!.authPasswordInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            // Dynamic password requirements checklist
                            AuthPasswordRequirements(
                              hasMinLength: _pwHasMinLength,
                              hasUppercase: _pwHasUppercase,
                              hasLowercase: _pwHasLowercase,
                              hasNumber: _pwHasNumber,
                              hasSpecial: _pwHasSpecial,
                            ),

            const SizedBox(height: CKSpacing.lg),

            // Confirm Password input
            TextFormField(
              controller: _confirmPasswordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.authPasswordConfirm,
                hintText: AppLocalizations.of(context)!.authPasswordConfirmHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CKRadius.control),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? AppLocalizations.of(context)!.tooltipShowPassword
                      : AppLocalizations.of(context)!.tooltipHidePassword,
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  )!.authPasswordConfirmRequired;
                }
                if (value != _passwordController.text) {
                  return AppLocalizations.of(context)!.authPasswordMismatch;
                }
                return null;
              },
              onFieldSubmitted: (_) => _resetPassword(),
            ),

            const SizedBox(height: CKSpacing.xl),

            // Reset button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(
                    CKControlDensity.standard.minimumHeight,
                  ),
                  elevation: 0,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SkeletonActionIndicator(width: 24, height: 8)
                    : Text(
                        AppLocalizations.of(context)!.authPasswordReset,
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
    );
  }
}
