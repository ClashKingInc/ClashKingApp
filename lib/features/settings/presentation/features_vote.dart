import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeatureRequests extends StatelessWidget {
  const FeatureRequests({super.key});

  static final Uri _featureBoardUri = Uri.parse(
    'https://clashkingapp.features.vote/board?api_key=ec52d587-cb17-4e63-898c-351f592f6454&is_embed=true&user_id=<Optional>&user_email=<Optional>&user_name=<Optional>&img_url=<Optional>&user_spend=<Optional>',
  );

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _FeatureRequestsWebFallback(url: _featureBoardUri);
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            Center(child: CircularProgressIndicator(value: progress / 100));
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(_featureBoardUri);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsFeatureRequestsTitle),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

class _FeatureRequestsWebFallback extends StatelessWidget {
  const _FeatureRequestsWebFallback({required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.settingsFeatureRequestsTitle),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = (constraints.maxWidth - 48)
              .clamp(0.0, 640.0)
              .toDouble();
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: colorScheme.primary,
                        size: 34,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.settingsFeatureRequestsTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The feature board opens in a browser tab on web.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(l10n.settingsFeatureRequestsTitle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
