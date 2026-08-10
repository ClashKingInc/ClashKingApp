import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/auth/presentation/email_verification_page.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

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
    _passwordController.removeListener(_updatePasswordCriteria);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
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
            builder: (context) =>
                EmailVerificationPage(email: _emailController.text.trim()),
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
                builder: (context) =>
                    LoginPage(prefillEmail: _emailController.text.trim()),
              ),
            );
            return;
          }

          // Check if verification email already sent - redirect to verification
          if (errorString.contains('verification email was already sent') ||
              errorString.contains('already sent to this address')) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    EmailVerificationPage(email: _emailController.text.trim()),
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
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 6), // Longer duration for longer text
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.generalOk,
                textColor: Theme.of(context).colorScheme.onError,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = theme.brightness == Brightness.dark;
    final logoUrl = (isDarkMode
        ? ImageAssets.darkModeLogo
        : ImageAssets.lightModeLogo);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              CKSpacing.lg,
              CKSpacing.sm,
              CKSpacing.lg,
              CKSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  minHeight: viewport.maxHeight > CKSpacing.xxl
                      ? viewport.maxHeight - CKSpacing.xxl
                      : 0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        image: true,
                        label: l10n.appTitle,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 80,
                            child: MobileWebImage(
                              errorWidget: (context, url, error) => Icon(
                                Icons.shield_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              imageUrl: logoUrl,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: CKSpacing.xl),
                      Text(
                        l10n.authJoinClashKing,
                        style: CKTypography.of(
                          context,
                          CKTextRole.screenTitle,
                        ).copyWith(color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CKSpacing.sm),
                      Text(
                        l10n.authCreateAccountToGetStarted,
                        style: CKTypography.of(
                          context,
                          CKTextRole.body,
                        ).copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CKSpacing.xl),
                      CKSectionPanel(
                        padding: const EdgeInsets.all(CKSpacing.lg),
                        child: Column(
                          children: [
                            const SizedBox(height: CKSpacing.xs),
                            // Username Field
                            TextFormField(
                              controller: _usernameController,
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.authUsernameLabel,
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CKRadius.control,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authUsernameRequired;
                                }
                                if (value.trim().length < 3) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authUsernameTooShort;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: CKSpacing.lg),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              autofillHints: const [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.authEmail,
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CKRadius.control,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authEmailRequired;
                                }
                                if (!RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                ).hasMatch(value)) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authEmailInvalid;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: CKSpacing.lg),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              autofillHints: const [AutofillHints.newPassword],
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.authPasswordLabel,
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? AppLocalizations.of(
                                          context,
                                        )!.tooltipShowPassword
                                      : AppLocalizations.of(
                                          context,
                                        )!.tooltipHidePassword,
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CKRadius.control,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authPasswordRequired;
                                }
                                // Check for uppercase, lowercase, digit, and special character
                                if (!RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])',
                                ).hasMatch(value)) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authPasswordInvalid;
                                }
                                return null;
                              },
                            ),

                            // Dynamic password requirements checklist (placed below password field)
                            const SizedBox(height: CKSpacing.sm),
                            Builder(
                              builder: (context) {
                                final header = AppLocalizations.of(
                                  context,
                                )!.authPasswordHeader;
                                final labelUpper = AppLocalizations.of(
                                  context,
                                )!.authPasswordUppercase;
                                final labelLower = AppLocalizations.of(
                                  context,
                                )!.authPasswordLowercase;
                                final labelNumber = AppLocalizations.of(
                                  context,
                                )!.authPasswordNumber;
                                final labelSpecial = AppLocalizations.of(
                                  context,
                                )!.authPasswordSpecial;
                                final labelLength = AppLocalizations.of(
                                  context,
                                )!.authPasswordTooShort;

                                Widget criteriaRow(bool met, String label) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          met
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: met
                                              ? colorScheme.secondary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
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
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    criteriaRow(_pwHasMinLength, labelLength),
                                    criteriaRow(_pwHasUppercase, labelUpper),
                                    criteriaRow(_pwHasLowercase, labelLower),
                                    criteriaRow(_pwHasNumber, labelNumber),
                                    criteriaRow(_pwHasSpecial, labelSpecial),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: CKSpacing.lg),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              autofillHints: const [AutofillHints.newPassword],
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.authPasswordConfirm,
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? AppLocalizations.of(
                                          context,
                                        )!.tooltipShowPassword
                                      : AppLocalizations.of(
                                          context,
                                        )!.tooltipHidePassword,
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CKRadius.control,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authPasswordConfirmRequired;
                                }
                                if (value != _passwordController.text) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.authPasswordMismatch;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _register(),
                            ),

                            const SizedBox(height: CKSpacing.xl),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.fromHeight(
                                    CKControlDensity.standard.minimumHeight,
                                  ),
                                  elevation: 0,
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                child: _isLoading
                                    ? const SkeletonActionIndicator(
                                        width: 24,
                                        height: 8,
                                      )
                                    : Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.authCreateAccount,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: CKSpacing.sm),

                            // Back to Login
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.authAlreadyHaveAccount,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CKSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
