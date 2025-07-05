import 'package:clashkingapp/common/widgets/app_bar/coc_accounts_app_bar.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ErrorPage extends StatelessWidget {
  final VoidCallback onRetry;

  ErrorPage({super.key, required this.onRetry,});

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
                  // Thematic Image
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: MobileWebImage(
                      imageUrl: ImageAssets.goblin,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error Title with better typography
                  Text(
                    AppLocalizations.of(context)!.errorTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Enhanced Retry Button
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.generalRetry,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Discord Support Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.discord,
                          color: const Color(0xFF5865F2),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.helpTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse(ApiService.discordUrl)),
                          child: Text(
                            AppLocalizations.of(context)!.errorSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
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
