import 'package:flutter/material.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class DeepLinkHandler {
  static void handleDeepLink(BuildContext context, Uri uri) {
    DebugUtils.debugInfo("🔗 Deep link received: $uri");
    DebugUtils.debugInfo("🔗 Path: ${uri.path}, Query: ${uri.queryParameters}");
    
    // Handle different deep link paths
    switch (uri.path) {
      case '/oauth': // Existing Discord OAuth
      case 'oauth':
        // Discord OAuth is already handled by discord_auth_helper
        DebugUtils.debugInfo("🔗 OAuth deep link handled by flutter_web_auth_2");
        break;
      
      case '/player':
      case 'player':
        _handlePlayerPage(context, uri);
        break;
      
      case '/clan':
      case 'clan':
        _handleClanPage(context, uri);
        break;
      
      case '/war':
      case 'war':
        _handleWarPage(context, uri);
        break;
      
      default:
        DebugUtils.debugInfo("🔗 Unknown deep link path: ${uri.path}");
        _showUnknownLinkMessage(context, uri);
        break;
    }
  }

  static void _handlePlayerPage(BuildContext context, Uri uri) {
    final playerTag = uri.queryParameters['tag'];
    
    if (playerTag == null || playerTag.trim().isEmpty) {
      DebugUtils.debugError("❌ Player tag missing from deep link");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid player link - no tag found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    DebugUtils.debugInfo("🔗 Navigating to player page: $playerTag");
    
    // TODO: Navigate to player page
    // Example: Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayerPage(tag: playerTag)));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Player page navigation: $playerTag (Coming soon!)"),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  static void _handleClanPage(BuildContext context, Uri uri) {
    final clanTag = uri.queryParameters['tag'];
    
    if (clanTag == null || clanTag.trim().isEmpty) {
      DebugUtils.debugError("❌ Clan tag missing from deep link");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid clan link - no tag found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    DebugUtils.debugInfo("🔗 Navigating to clan page: $clanTag");
    
    // TODO: Navigate to clan page
    // Example: Navigator.of(context).push(MaterialPageRoute(builder: (context) => ClanPage(tag: clanTag)));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Clan page navigation: $clanTag (Coming soon!)"),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  static void _handleWarPage(BuildContext context, Uri uri) {
    final warId = uri.queryParameters['id'];
    
    if (warId == null || warId.trim().isEmpty) {
      DebugUtils.debugError("❌ War ID missing from deep link");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid war link - no ID found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    DebugUtils.debugInfo("🔗 Navigating to war page: $warId");
    
    // TODO: Navigate to war page
    // Example: Navigator.of(context).push(MaterialPageRoute(builder: (context) => WarPage(id: warId)));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("War page navigation: $warId (Coming soon!)"),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  static void _showUnknownLinkMessage(BuildContext context, Uri uri) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unknown deep link: ${uri.path}"),
        backgroundColor: Colors.orange,
      ),
    );
  }
}