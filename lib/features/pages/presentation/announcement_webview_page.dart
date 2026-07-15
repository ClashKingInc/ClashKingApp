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

String? announcementStoryMessageFromNavigation({
  required String requestedUrl,
  required bool isTrustedLocalStory,
}) {
  if (!isTrustedLocalStory) {
    return null;
  }
  final uri = Uri.tryParse(requestedUrl);
  if (uri?.scheme != 'clashking-story' || uri?.host != 'message') {
    return null;
  }
  return uri?.queryParameters['payload'];
}

const _announcementStoryBridgeJavaScript = '''
window.AnnouncementStory = Object.freeze({
  postMessage: function(message) {
    window.location.href = 'clashking-story://message?payload=' +
      encodeURIComponent(String(message));
  }
});
''';

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

  bool get _isTrustedLocalStory {
    final filePath = widget.filePath;
    return filePath != null &&
        filePath.isNotEmpty &&
        widget.javaScriptChannelName == 'AnnouncementStory' &&
        widget.onJavaScriptMessage != null;
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final storyMessage = announcementStoryMessageFromNavigation(
      requestedUrl: request.url,
      isTrustedLocalStory: _isTrustedLocalStory,
    );
    if (storyMessage != null) {
      widget.onJavaScriptMessage?.call(storyMessage);
      return NavigationDecision.prevent;
    }
    return announcementNavigationDecision(
      requestedUrl: request.url,
      initialUrl: widget.url,
      loadsLocalFile: widget.filePath?.isNotEmpty ?? false,
    );
  }

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
          onNavigationRequest: _handleNavigationRequest,
          onPageFinished: (url) async {
            if (_isTrustedLocalStory) {
              await _controller.runJavaScript(
                _announcementStoryBridgeJavaScript,
              );
            }
            final javaScript = widget.pageFinishedJavaScript;
            if (javaScript != null && javaScript.isNotEmpty) {
              await _controller.runJavaScript(javaScript);
            }
            widget.onPageFinished?.call(url);
          },
        ),
      );

    final filePath = widget.filePath;
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
