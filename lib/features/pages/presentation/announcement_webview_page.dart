import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

NavigationDecision announcementNavigationDecision({
  required String requestedUrl,
  String? initialUrl,
  bool loadsLocalFile = false,
}) {
  final requestedUri = Uri.tryParse(requestedUrl);
  if (requestedUri == null) {
    return NavigationDecision.prevent;
  }

  if (requestedUri.scheme == 'about' || requestedUri.scheme == 'data') {
    return NavigationDecision.navigate;
  }

  if (loadsLocalFile && requestedUri.scheme == 'file') {
    return NavigationDecision.navigate;
  }

  final initialUri = initialUrl == null ? null : Uri.tryParse(initialUrl);
  if (requestedUri.scheme == 'https' &&
      initialUri?.scheme == 'https' &&
      requestedUri.origin == initialUri?.origin) {
    return NavigationDecision.navigate;
  }

  return NavigationDecision.prevent;
}

class AnnouncementWebViewPage extends StatefulWidget {
  const AnnouncementWebViewPage({
    super.key,
    required this.title,
    this.html,
    this.url,
  });

  final String title;
  final String? html;
  final String? url;

  @override
  State<AnnouncementWebViewPage> createState() =>
      _AnnouncementWebViewPageState();
}

class _AnnouncementWebViewPageState extends State<AnnouncementWebViewPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text(widget.title)),
      body: AnnouncementWebView(html: widget.html, url: widget.url),
    );
  }
}

class AnnouncementWebView extends StatefulWidget {
  const AnnouncementWebView({
    super.key,
    this.html,
    this.url,
    this.filePath,
    this.javaScriptMode = JavaScriptMode.disabled,
    this.javaScriptChannelName,
    this.onJavaScriptMessage,
    this.onPageFinished,
    this.pageFinishedJavaScript,
    this.showLoadingProgress = true,
  });

  final String? html;
  final String? url;
  final String? filePath;
  final JavaScriptMode javaScriptMode;
  final String? javaScriptChannelName;
  final ValueChanged<String>? onJavaScriptMessage;
  final ValueChanged<String>? onPageFinished;
  final String? pageFinishedJavaScript;
  final bool showLoadingProgress;

  @override
  State<AnnouncementWebView> createState() => _AnnouncementWebViewState();
}

class _AnnouncementWebViewState extends State<AnnouncementWebView> {
  late final WebViewController _controller;
  var _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(widget.javaScriptMode)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onNavigationRequest: (request) => announcementNavigationDecision(
            requestedUrl: request.url,
            initialUrl: widget.url,
            loadsLocalFile: widget.filePath?.isNotEmpty ?? false,
          ),
          onPageFinished: (url) async {
            final javaScript = widget.pageFinishedJavaScript;
            if (javaScript != null && javaScript.isNotEmpty) {
              await _controller.runJavaScript(javaScript);
            }
            widget.onPageFinished?.call(url);
          },
        ),
      );

    final channelName = widget.javaScriptChannelName;
    final messageHandler = widget.onJavaScriptMessage;
    final filePath = widget.filePath;
    final isTrustedLocalStory =
        filePath != null &&
        filePath.isNotEmpty &&
        channelName == 'AnnouncementStory';
    if (isTrustedLocalStory && messageHandler != null) {
      // The bridge is limited to a cached local story and only receives the
      // validated ready/close/complete events handled by the dialog.
      _controller.addJavaScriptChannel( // NOSONAR
        channelName!,
        onMessageReceived: (message) => messageHandler(message.message),
      );
    }

    final url = widget.url;
    if (filePath != null && filePath.isNotEmpty) {
      _controller.loadFile(filePath);
    } else if (url != null && url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(url));
    } else {
      _controller.loadHtmlString(widget.html ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (widget.showLoadingProgress && _loadingProgress < 100)
          LinearProgressIndicator(value: _loadingProgress / 100),
      ],
    );
  }
}
