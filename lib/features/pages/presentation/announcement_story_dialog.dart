import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:clashkingapp/features/pages/data/announcement_story_cache_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_webview_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum AnnouncementStoryResult { closed, completed }

bool supportsEmbeddedAnnouncementStories({required bool isWeb}) => !isWeb;

Uri? announcementStoryWebUri(AppAnnouncement announcement) {
  for (final candidate in [announcement.storyUrl, announcement.htmlUrl]) {
    final uri = Uri.tryParse(candidate ?? '');
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      return uri;
    }
  }
  return null;
}

Future<bool> openAnnouncementStory(
  BuildContext context, {
  required AppAnnouncement announcement,
  bool Function()? canDisplay,
}) async {
  if (kIsWeb) {
    final uri = announcementStoryWebUri(announcement);
    return uri != null && await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  final preparedFilePath = await AnnouncementStoryCacheService().prepare(
    announcement,
  );
  if (!context.mounted ||
      preparedFilePath == null ||
      (canDisplay != null && !canDisplay())) {
    return false;
  }
  await showAnnouncementStoryDialog(
    context,
    announcement: announcement,
    preparedFilePath: preparedFilePath,
  );
  return true;
}

Future<AnnouncementStoryResult?> showAnnouncementStoryDialog(
  BuildContext context, {
  required AppAnnouncement announcement,
  required String preparedFilePath,
}) {
  if (!supportsEmbeddedAnnouncementStories(isWeb: kIsWeb)) {
    return Future.value(null);
  }
  return showGeneralDialog<AnnouncementStoryResult>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Close ${announcement.title}',
    barrierColor: Colors.black.withValues(alpha: 0.86),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AnnouncementStoryDialog(
        announcement: announcement,
        preparedFilePath: preparedFilePath,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AnnouncementStoryDialog extends StatefulWidget {
  const _AnnouncementStoryDialog({
    required this.announcement,
    required this.preparedFilePath,
  });

  final AppAnnouncement announcement;
  final String preparedFilePath;

  @override
  State<_AnnouncementStoryDialog> createState() =>
      _AnnouncementStoryDialogState();
}

class _AnnouncementStoryDialogState extends State<_AnnouncementStoryDialog> {
  Timer? _revealTimer;
  var _ready = false;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  void _scheduleReveal(Duration delay) {
    if (_ready) {
      return;
    }
    _revealTimer?.cancel();
    _revealTimer = Timer(delay, () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  void _handleMessage(String rawMessage) {
    try {
      final message = jsonDecode(rawMessage);
      if (message is! Map<String, dynamic>) {
        return;
      }

      switch (message['type']) {
        case 'ready':
          _scheduleReveal(const Duration(milliseconds: 120));
        case 'close':
          Navigator.of(
            context,
            rootNavigator: true,
          ).pop(AnnouncementStoryResult.closed);
        case 'complete':
          Navigator.of(
            context,
            rootNavigator: true,
          ).pop(AnnouncementStoryResult.completed);
      }
    } on FormatException {
      // Ignore malformed messages from the story document.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimension = math.min(
            560.0,
            math.min(constraints.maxWidth, constraints.maxHeight),
          );
          return Center(
            child: SizedBox.square(
              dimension: dimension,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    ignoring: !_ready,
                    child: AnimatedOpacity(
                      opacity: _ready ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111529),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 40,
                              offset: Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AnnouncementWebView(
                            filePath: widget.preparedFilePath,
                            javaScriptMode: JavaScriptMode.unrestricted,
                            javaScriptChannelName: 'AnnouncementStory',
                            onJavaScriptMessage: _handleMessage,
                            onPageFinished: (_) => _scheduleReveal(
                              const Duration(milliseconds: 350),
                            ),
                            pageFinishedJavaScript:
                                "document.querySelector('.close-button')?.remove();",
                            showLoadingProgress: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _ready ? 0 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: const SizedBox.square(
                        dimension: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
