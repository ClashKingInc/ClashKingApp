import 'dart:async';
import 'package:universal_html/html.dart' as html;

Future<Map<String, String>?> getDiscordAuthCodeWeb(
  Uri url,
  String expectedState,
) async {
  final dynamic openedWindow = html.window.open(
    url.toString(),
    'discordLogin',
    'popup=yes,width=520,height=760',
  );
  if (openedWindow == null) {
    throw StateError('The Discord login popup was blocked.');
  }

  final popup = openedWindow as html.WindowBase;
  final completer = Completer<Map<String, String>?>();
  late final StreamSubscription<html.MessageEvent> subscription;
  Timer? closePoll;

  subscription = html.window.onMessage.listen((event) {
    if (event.origin != Uri.base.origin || !identical(event.source, popup)) {
      return;
    }

    final data = event.data;
    if (data is! Map || data['type'] != 'discord-auth') {
      return;
    }

    final state = data['state']?.toString();
    if (state != expectedState) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Discord OAuth state did not match this login.'),
        );
      }
      return;
    }

    final error = data['error']?.toString();
    if (error == 'access_denied') {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    if (error != null && error.isNotEmpty) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError(data['error_description']?.toString() ?? error),
        );
      }
      return;
    }

    final code = data['code']?.toString();
    if (code != null && code.isNotEmpty && !completer.isCompleted) {
      completer.complete({'code': code, 'state': state!});
    }
  });

  closePoll = Timer.periodic(const Duration(milliseconds: 250), (_) {
    if (popup.closed == true && !completer.isCompleted) {
      completer.complete(null);
    }
  });

  try {
    return await completer.future.timeout(const Duration(minutes: 2));
  } finally {
    closePoll.cancel();
    await subscription.cancel();
    if (popup.closed != true) popup.close();
  }
}
