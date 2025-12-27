
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class FeatureRequests extends StatelessWidget {
  const FeatureRequests({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const url = 'https://clashkingapp.features.vote/board?api_key=ec52d587-cb17-4e63-898c-351f592f6454&is_embed=true&user_id=<Optional>&user_email=<Optional>&user_name=<Optional>&img_url=<Optional>&user_spend=<Optional>';

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.translationSuggestFeatures)),
        body: Center(
          child: ElevatedButton(
            onPressed: () => launchUrl(Uri.parse(url)),
            child: Text(AppLocalizations.of(context)!.featureRequestsOpenButton),
          ),
        ),
      );
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            Center(
              child: CircularProgressIndicator(
                value: progress / 100,
              )
            );
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.featureRequestsTitle)),
      body: WebViewWidget(controller: controller),
    );
  }
}

