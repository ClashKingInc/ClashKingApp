import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/auth/presentation/startup_widget.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/common/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  EmailVerificationPageState createState() => EmailVerificationPageState();
}

class EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _verificationCode {
    return _codeControllers.map((controller) => controller.text).join();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (_verificationCode.length == 6) {
      _verifyEmailWithCode();
    }
  }

  Future<void> _verifyEmailWithCode() async {
    if (_verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.authEmailVerificationCodeRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.verifyEmailWithCode(widget.email, _verificationCode);

      final accessToken = await TokenService().getAccessToken();
      if (accessToken != null && mounted) {
        if (mounted) {
          // Navigate to StartupWidget to show loading screen and handle proper navigation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => StartupWidget()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains("503") || e.toString().contains("500")) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MaintenanceScreen()),
          );
        } else {
          String errorString = e.toString().toLowerCase();
          String displayMessage = e.toString().replaceAll('Exception: ', '');
          
          // Check if email is already verified - redirect to login
          if (errorString.contains('already verified') || 
              errorString.contains('try logging in instead')) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginPage(
                  prefillEmail: widget.email,
                ),
              ),
            );
            return;
          }
          
          // Check for verification errors (401 - invalid or expired code)
          if (errorString.contains('unauthorized') || errorString.contains('autorisations') ||
              errorString.contains('expired') || errorString.contains('expiré') ||
              errorString.contains('invalid')) {
            // Invalid or expired code - unified message
            displayMessage = AppLocalizations.of(context)!.authEmailVerificationCodeInvalid;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage),
              backgroundColor: Colors.red,
            ),
          );
          // Clear the code on error
          for (var controller in _codeControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resendVerificationEmail() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.resendVerificationEmail(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .authEmailVerificationResendSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('ApiException: ', '')
            .replaceAll('NotFoundException: ', '');

        // Handle specific error cases
        if (errorMessage.contains("already verified")) {
          // Redirect to login page if email is already verified
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginPage(
                prefillEmail: widget.email,
              ),
            ),
          );
          return;
        } else if (errorMessage.contains("expired")) {
          errorMessage =
              AppLocalizations.of(context)!.authEmailVerificationExpired;
        } else if (errorMessage.contains("No pending verification")) {
          errorMessage =
              AppLocalizations.of(context)!.authEmailVerificationExpiredResend;
        }
        else if (errorMessage.contains("This email is already verified")) {
          errorMessage =
              AppLocalizations.of(context)!.authEmailVerificationAlreadyVerified;
        }


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text(AppLocalizations.of(context)!.authEmailVerificationTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveLayoutWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
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

            SizedBox(height: 24),

            Text(
              AppLocalizations.of(context)!.authEmailVerificationCheckEmail,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.authEmailVerificationSentTo,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8),

            Text(
              widget.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            // Verification card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .authEmailVerificationCodeInstructions,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 32),

                    // 6-digit code input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 56,
                          child: TextFormField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              counterText: '',
                            ),
                            onChanged: (value) => _onCodeChanged(value, index),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 32),

                    // Show loading when verifying
                    if (_isLoading) ...[
                      Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!
                                .authEmailVerificationVerifying,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ] else ...[
                      // Verify button (manual verification)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _verificationCode.length == 6
                              ? _verifyEmailWithCode
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .authEmailVerificationVerify,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Resend email button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _resendVerificationEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .authEmailVerificationResend,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Back to login
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // Navigate back to login page specifically
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => LoginPage()),
                              (route) => false,
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!
                                .authBackToLogin,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
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
