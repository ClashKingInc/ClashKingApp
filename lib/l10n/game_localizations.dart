import 'dart:ui';

import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

extension GameLocalizations on AppLocalizations {
  Locale get _gameLocale => Locale(localeName.split(RegExp(r'[-_]')).first);

  String gameName(String tid, String fallback) =>
      GameDataService.localizedNameForTidOrFallback(
        tid,
        locale: _gameLocale,
        fallback: fallback,
      );

  String gameItemName(Map<String, dynamic>? item, String fallback) =>
      GameDataService.localizedNameForItemOrFallback(
        item,
        locale: _gameLocale,
        fallback: fallback,
      );
}
