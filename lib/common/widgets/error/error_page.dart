import 'package:clashkingapp/common/widgets/app_bar/coc_accounts_app_bar.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ErrorPage extends StatefulWidget {
  final Future<void> Function() onRetry;
  final bool isNetworkError;

  ErrorPage({super.key, required this.onRetry, this.isNetworkError = false});

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CocAccountsAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.8),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Thematic Image with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle for network error
                        if (widget.isNetworkError)
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        MobileWebImage(
                          imageUrl: ImageAssets.sleepingApprenticeBuilder,
                          fit: BoxFit.contain,
                        ),
                        // Network icon overlay for network errors
                        if (widget.isNetworkError)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.wifi_off,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error Title with better typography
                  Text(
                    widget.isNetworkError 
                        ? AppLocalizations.of(context)!.errorNetworkTitle
                        : AppLocalizations.of(context)!.errorTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Simple network error message
                  if (widget.isNetworkError)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        AppLocalizations.of(context)!.errorNetworkMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Enhanced Retry Button with loading state
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: ElevatedButton.icon(
                      onPressed: _isRetrying ? null : () async {
                        setState(() {
                          _isRetrying = true;
                        });
                        
                        // Add a small delay for visual feedback
                        await Future.delayed(const Duration(milliseconds: 300));
                        
                        try {
                          await widget.onRetry();
                        } catch (retryError) {
                          // Handle retry failures - show feedback but stay on error page
                          DebugUtils.debugError("Retry failed: $retryError");
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isRetrying = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRetrying 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isRetrying ? 1 : 3,
                      ),
                      icon: _isRetrying 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh, size: 20),
                      label: Text(
                        _isRetrying 
                            ? AppLocalizations.of(context)!.generalRetrying
                            : AppLocalizations.of(context)!.generalRetry,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isRetrying ? Colors.white.withValues(alpha: 0.8) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error subtitle with Discord link
                  Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.errorSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async => launchUrl(
                            Uri.parse('https://discord.gg/clashking')),
                        icon: Icon(
                          Icons.discord,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.helpJoinDiscord,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
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
