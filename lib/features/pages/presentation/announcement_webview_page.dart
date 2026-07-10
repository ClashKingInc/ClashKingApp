import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    if (channelName != null && messageHandler != null) {
      _controller.addJavaScriptChannel(
        channelName,
        onMessageReceived: (message) => messageHandler(message.message),
      );
    }

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
