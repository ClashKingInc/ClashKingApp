
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeatureRequests extends StatelessWidget {
  const FeatureRequests({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
      ..loadRequest(Uri.parse(
          'https://clashkingapp.features.vote/board?api_key=ec52d587-cb17-4e63-898c-351f592f6454&is_embed=true&user_id=<Optional>&user_email=<Optional>&user_name=<Optional>&img_url=<Optional>&user_spend=<Optional>'));

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Requests')),
      body: WebViewWidget(controller: controller),
    );
  }
}

