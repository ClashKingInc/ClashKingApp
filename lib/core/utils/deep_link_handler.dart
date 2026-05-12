import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeepLinkHandler {
  static Uri? _pendingUri;
  static bool _isHandling = false;

  static void queueDeepLink(Uri uri) {
    _pendingUri = uri;
    DebugUtils.debugInfo("🔗 Queued deep link: $uri");
  }

  static Future<void> tryHandlePendingDeepLink(
      [BuildContext? explicitContext]) async {
    if (_pendingUri == null || _isHandling) {
      return;
    }

    final context = explicitContext ?? globalNavigatorKey.currentContext;
    final uri = _pendingUri;
    if (context == null || uri == null || !context.mounted) {
      return;
    }

    _isHandling = true;
    try {
      final handled = await _dispatchDeepLink(context, uri);
      if (handled && _pendingUri == uri) {
        _pendingUri = null;
      }
    } finally {
      _isHandling = false;
    }
  }

  static Future<bool> _dispatchDeepLink(BuildContext context, Uri uri) async {
    DebugUtils.debugInfo(
        "🔗 Deep link received: $uri (host=${uri.host}, path=${uri.path})");

    final route = _extractRoute(uri);
    if (route == 'oauth') {
      DebugUtils.debugInfo("🔗 OAuth deep link handled by flutter_web_auth_2");
      return true;
    }

    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      DebugUtils.debugInfo(
          "🔗 Deferring deep link until authentication completes: $uri");
      return false;
    }

    switch (route) {
      case 'player':
        await _openPlayer(context, uri);
        return true;
      case 'clan':
        await _openClan(context, uri);
        return true;
      case 'war':
        _showSnackBar(
          context,
          AppLocalizations.of(context)?.generalComingSoon ?? 'Coming soon!',
        );
        return true;
      default:
        _showSnackBar(
          context,
          AppLocalizations.of(context)?.deepLinkUnknown ?? 'Unknown deep link.',
        );
        return true;
    }
  }

  static String _extractRoute(Uri uri) {
    final pathSegments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (pathSegments.isNotEmpty) {
      return pathSegments.first.toLowerCase();
    }

    return uri.host.toLowerCase();
  }

  static String? _extractNormalizedTag(Uri uri) {
    final rawTag = uri.queryParameters['tag'] ??
        uri.queryParameters['player_tag'] ??
        uri.queryParameters['clan_tag'];
    if (rawTag == null) {
      return null;
    }

    final trimmed = rawTag.trim().replaceAll(' ', '').replaceFirst('!', '#');
    if (trimmed.isEmpty) {
      return null;
    }

    final tag = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    return tag.toUpperCase();
  }

  static Future<void> _openPlayer(BuildContext context, Uri uri) async {
    final playerTag = _extractNormalizedTag(uri);
    final l10n = AppLocalizations.of(context);

    if (playerTag == null) {
      DebugUtils.debugError(" Player tag missing from deep link");
      _showSnackBar(
        context,
        l10n?.deepLinkInvalidPlayer ?? 'Invalid player link.',
      );
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final player =
          await context.read<PlayerService>().getPlayerAndClanData(playerTag);
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(selectedPlayer: player),
        ),
      );
    } catch (error) {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      DebugUtils.debugError(" Error opening player deep link: $error");
      if (context.mounted) {
        _showSnackBar(
          context,
          l10n?.deepLinkFailedToOpenPlayer ?? 'Failed to open player.',
        );
      }
    }
  }

  static Future<void> _openClan(BuildContext context, Uri uri) async {
    final clanTag = _extractNormalizedTag(uri);
    final l10n = AppLocalizations.of(context);

    if (clanTag == null) {
      DebugUtils.debugError(" Clan tag missing from deep link");
      _showSnackBar(
        context,
        l10n?.deepLinkInvalidClan ?? 'Invalid clan link.',
      );
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clan = await context.read<ClanService>().getClanAndWarData(clanTag);
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClanInfoScreen(clanInfo: clan),
        ),
      );
    } catch (error) {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      DebugUtils.debugError(" Error opening clan deep link: $error");
      if (context.mounted) {
        _showSnackBar(
          context,
          l10n?.deepLinkFailedToOpenClan ?? 'Failed to open clan.',
        );
      }
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
