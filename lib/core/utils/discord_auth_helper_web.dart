import 'dart:async';
import 'package:universal_html/html.dart' as html;

Future<String?> getDiscordAuthCodeWeb(Uri url) async {
  final completer = Completer<String?>();

  void listener(html.Event event) {
    final data = (event as html.MessageEvent).data;
    if (data is Map && data['type'] == 'discord-auth') {
      completer.complete(data['code']);
      html.window.removeEventListener('message', listener);
    }
  }

  html.window.addEventListener('message', listener);
  html.window.open(url.toString(), 'discordLogin');

  return completer.future;
}
