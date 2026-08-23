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
    _handleDiscordAuthMessage(event, popup, expectedState, completer);
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

void _handleDiscordAuthMessage(
  html.MessageEvent event,
  html.WindowBase popup,
  String expectedState,
  Completer<Map<String, String>?> completer,
) {
  if (event.origin != Uri.base.origin || !identical(event.source, popup)) {
    return;
  }
  if (completer.isCompleted) return;

  try {
    final result = _parseDiscordAuthMessage(event.data, expectedState);
    if (result.handled) completer.complete(result.value);
  } catch (error, stackTrace) {
    completer.completeError(error, stackTrace);
  }
}

({bool handled, Map<String, String>? value}) _parseDiscordAuthMessage(
  dynamic rawData,
  String expectedState,
) {
  if (rawData is! Map || rawData['type'] != 'discord-auth') {
    return (handled: false, value: null);
  }

  final state = rawData['state']?.toString();
  if (state != expectedState) {
    throw StateError('Discord OAuth state did not match this login.');
  }

  final error = rawData['error']?.toString();
  if (error == 'access_denied') return (handled: true, value: null);
  if (error != null && error.isNotEmpty) {
    throw StateError(rawData['error_description']?.toString() ?? error);
  }

  final code = rawData['code']?.toString();
  if (code == null || code.isEmpty) return (handled: false, value: null);
  return (handled: true, value: {'code': code, 'state': state!});
}
