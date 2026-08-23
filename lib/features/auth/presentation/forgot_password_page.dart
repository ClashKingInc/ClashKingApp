import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/auth/presentation/reset_password_page.dart';
import 'package:clashkingapp/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.forgotPassword(_emailController.text.trim());

      setState(() {
        _emailSent = true;
      });
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
    return AuthPageShell(
      formKey: _formKey,
      maxWidth: 520,
      centerContent: true,
      child: AnimatedSwitcher(
        duration: CKMotion.durationOf(context, CKMotion.standard),
        switchInCurve: CKMotion.standardCurve,
        switchOutCurve: CKMotion.standardCurve,
        child: _emailSent
            ? _buildSuccessState(context)
            : _buildRequestState(context),
      ),
    );
  }

  Widget _buildRequestState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      key: const ValueKey('request-password-reset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.authPasswordForgot,
          style: CKTypography.of(
            context,
            CKTextRole.screenTitle,
          ).copyWith(color: colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CKSpacing.sm),
        Text(
          l10n.authPasswordForgotDescription,
          style: CKTypography.of(
            context,
            CKTextRole.body,
          ).copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CKSpacing.xl),
        CKSectionPanel(
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: l10n.authEmail,
                  hintText: l10n.authEmailHint,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.authEmailRequired;
                  }
                  if (!RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  ).hasMatch(value)) {
                    return l10n.authEmailInvalid;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _requestPasswordReset(),
              ),
              const SizedBox(height: CKSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPasswordReset,
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
                      : Text(l10n.authPasswordResetSend),
                ),
              ),
              const SizedBox(height: CKSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.authBackToLogin),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      liveRegion: true,
      child: CKSectionPanel(
        key: const ValueKey('password-reset-sent'),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: CKSpacing.lg),
            Text(
              l10n.authPasswordResetSent,
              style: CKTypography.of(
                context,
                CKTextRole.sectionTitle,
              ).copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CKSpacing.sm),
            Text(
              l10n.authPasswordResetSentDescription,
              style: CKTypography.of(
                context,
                CKTextRole.body,
              ).copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CKSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ResetPasswordPage(
                        email: _emailController.text.trim(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(
                    CKControlDensity.standard.minimumHeight,
                  ),
                  elevation: 0,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(l10n.authPasswordResetContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
