import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarWidgetService {
  static final WarWidgetService _instance = WarWidgetService._internal();
  factory WarWidgetService() => _instance;
  WarWidgetService._internal();

  // Handle widget refresh requests from the Android widget
  static Future<void> handleWidgetRefresh() async {
    try {
      DebugUtils.debugWidget("🔄 War widget refresh requested");
      
      // Get clan tag from current context
      final clanTag = await WarWidgetService.getCurrentPlayerClanTag();
      if (clanTag == null || clanTag.isEmpty) {
        DebugUtils.debugWarning("⚠️ No clan tag found for widget refresh");
        return;
      }

      DebugUtils.debugWidget("🔍 Using clan tag for widget refresh: $clanTag");
      
      // Fetch fresh war data
      final warInfo = await fetchWarSummary(clanTag);
      
      // Save to widget data
      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: 'WarWidget',
        androidName: 'WarAppWidgetProvider',
        iOSName: 'WarWidget',
      );
      
      DebugUtils.debugSuccess("War widget refresh completed");
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      DebugUtils.debugError(" Error refreshing war widget: $e");
    }
  }

  // Initialize widget background callbacks
  static void initialize() {
    // Set up the callback for when the widget refresh button is tapped
    HomeWidget.setAppGroupId('group.com.clashking.clashkingapp');
    
    // Register callback for widget interactions
    HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  // Background callback handler
  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri == null) {
      DebugUtils.debugWarning("⚠️ Widget background callback received null URI");
      return;
    }
    
    DebugUtils.debugWidget("📱 Widget background callback: ${uri.toString()}");
    
    if (uri.host == 'refreshClicked') {
      await handleWidgetRefresh();
    }
  }

  // Get the clan tag from the currently selected player
  static Future<String?> getCurrentPlayerClanTag() async {
    try {
      // Get the currently selected player tag (don't use cached clan tag)
      String? selectedPlayerTag = await getPrefs('selectedTag');
      if (selectedPlayerTag == null || selectedPlayerTag.isEmpty) {
        // Try alternative key names
        selectedPlayerTag = await getPrefs('selected_player_tag');
        if (selectedPlayerTag == null || selectedPlayerTag.isEmpty) {
          selectedPlayerTag = await getPrefs('selectedPlayerTag');
        }
      }
      
      if (selectedPlayerTag == null || selectedPlayerTag.isEmpty) {
        DebugUtils.debugWarning("⚠️ No selected player tag found in any preference key");
        
        // If still no selected tag, try to get the first available CoC account
        final firstAccountTag = await _getFirstAvailableAccount();
        if (firstAccountTag != null) {
          DebugUtils.debugInfo("🔄 Using first available account: $firstAccountTag");
          selectedPlayerTag = firstAccountTag;
          // Store it for future use
          await storePrefs('selectedTag', firstAccountTag);
        } else {
          return null;
        }
      }

      DebugUtils.debugInfo("🔍 Using selected player tag: $selectedPlayerTag");

      // Get player data to extract clan tag
      final playerClanTag = await _getPlayerClanTag(selectedPlayerTag);
      
      if (playerClanTag != null && playerClanTag.isNotEmpty) {
        DebugUtils.debugSuccess("Got clan tag for selected player $selectedPlayerTag: $playerClanTag");
        return playerClanTag;
      } else {
        DebugUtils.debugWarning("⚠️ Player $selectedPlayerTag is not in a clan");
        return null;
      }
      
    } catch (e) {
      DebugUtils.debugError(" Error getting current player clan tag: $e");
      return null;
    }
  }

  // Get the first available CoC account from the API
  static Future<String?> _getFirstAvailableAccount() async {
    try {
      final token = await TokenService().getAccessToken();
      if (token == null) {
        DebugUtils.debugWarning("⚠️ User not authenticated");
        return null;
      }

      final response = await http.get(
        Uri.parse("${ApiService.apiUrlV2}/users/coc-accounts"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accounts = data['coc_accounts'] as List?;
        
        if (accounts != null && accounts.isNotEmpty) {
          final firstAccount = accounts.first;
          final playerTag = firstAccount['player_tag'];
          DebugUtils.debugSuccess("🎯 Found first account: $playerTag");
          return playerTag;
        } else {
          DebugUtils.debugWarning("⚠️ No CoC accounts found");
          return null;
        }
      } else {
        DebugUtils.debugWarning("⚠️ Failed to get CoC accounts: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      DebugUtils.debugError(" Error getting first available account: $e");
      return null;
    }
  }

  // Get clan tag from cached player data (much more efficient!)
  static Future<String?> _getPlayerClanTag(String playerTag) async {
    try {
      // First try to get from cached player data in SharedPreferences
      final cachedClanTag = await getPrefs('player_${playerTag}_clan_tag');
      if (cachedClanTag != null && cachedClanTag.isNotEmpty) {
        DebugUtils.debugInfo("💾 Using cached clan tag for $playerTag: $cachedClanTag");
        return cachedClanTag;
      }

      // If not cached, we need to make an API call as fallback
      DebugUtils.debugInfo("🔍 No cached clan tag found, making API call for $playerTag");
      
      final token = await TokenService().getAccessToken();
      if (token == null) {
        DebugUtils.debugWarning("⚠️ User not authenticated - no token available");
        return null;
      }
      
      final response = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/players"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"player_tags": [playerTag]}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          final playerData = data['items'][0];
          final clanTag = playerData['clan']?['tag'] ?? '';
          if (clanTag.isNotEmpty) {
            // Cache the clan tag for future use
            await storePrefs('player_${playerTag}_clan_tag', clanTag);
            DebugUtils.debugSuccess("Got and cached clan tag: $clanTag");
            return clanTag;
          } else {
            DebugUtils.debugWarning("⚠️ Player $playerTag is not in a clan");
            return null;
          }
        } else {
          DebugUtils.debugWarning("⚠️ No player data found for tag: $playerTag");
          return null;
        }
      } else {
        DebugUtils.debugWarning("⚠️ Failed to get player data: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      DebugUtils.debugError(" Error fetching player clan tag: $e");
      return null;
    }
  }
}

// Widget for in-app war display (if needed)
class WarDisplayWidget extends StatefulWidget {
  const WarDisplayWidget({super.key});

  @override
  WarDisplayWidgetState createState() => WarDisplayWidgetState();
}

class WarDisplayWidgetState extends State<WarDisplayWidget> {
  String? warData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWarData();
  }

  Future<void> _loadWarData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final clanTag = await WarWidgetService.getCurrentPlayerClanTag();
      final data = await fetchWarSummary(clanTag);
      
      if (mounted) {
        setState(() {
          warData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      DebugUtils.debugError(" Error loading war data: $e");
    }
  }

  Future<void> _refreshWarData() async {
    await _loadWarData();
    // Also update the home widget
    await WarWidgetService.handleWidgetRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'War Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _refreshWarData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh War Data',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (warData != null) 
              Text('Last updated: ${DateTime.now().toString().substring(11, 16)}')
            else
              const Text('No war data available'),
          ],
        ),
      ),
    );
  }
}
