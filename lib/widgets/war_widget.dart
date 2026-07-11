import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';

const String _widgetAppGroup = 'group.com.clashking.apps';

class WarWidgetClanOption {
  const WarWidgetClanOption({
    required this.tag,
    required this.name,
    this.badgeUrl,
  });

  final String tag;
  final String name;
  final String? badgeUrl;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'name': name,
    if (badgeUrl != null && badgeUrl!.isNotEmpty) 'badgeUrl': badgeUrl,
  };

  factory WarWidgetClanOption.fromJson(Map<String, dynamic> json) {
    return WarWidgetClanOption(
      tag: json['tag']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      badgeUrl: json['badgeUrl']?.toString(),
    );
  }
}

class WarWidgetService {
  static final WarWidgetService _instance = WarWidgetService._internal();
  factory WarWidgetService() => _instance;
  WarWidgetService._internal();

  static final Map<String, Future<String>> _warSummaryLoads = {};

  static String _normalizedClanTag(String clanTag) {
    return clanTag.replaceAll('#', '').toUpperCase();
  }

  static String warInfoKeyForClan(String clanTag) {
    return 'warInfo_${_normalizedClanTag(clanTag)}';
  }

  static String? _appGroupForPlatform() {
    if (kIsWeb) return null;
    return defaultTargetPlatform == TargetPlatform.iOS ? _widgetAppGroup : null;
  }

  static List<WarWidgetClanOption> clanOptionsFromProfiles(
    Iterable<Player> profiles, {
    Iterable<BookmarkedClan> bookmarkedClans = const [],
  }) {
    final clansByTag = <String, WarWidgetClanOption>{};
    for (final player in profiles) {
      final clan = player.clanOverview;
      if (clan.tag.isEmpty || clan.name.isEmpty) continue;
      clansByTag[_normalizedClanTag(clan.tag)] = WarWidgetClanOption(
        tag: clan.tag,
        name: clan.name,
        badgeUrl: clan.badgeUrls.medium,
      );
    }
    for (final clan in bookmarkedClans) {
      if (clan.tag.isEmpty || clan.name.isEmpty) continue;
      clansByTag.putIfAbsent(
        _normalizedClanTag(clan.tag),
        () => WarWidgetClanOption(
          tag: clan.tag,
          name: clan.name,
          badgeUrl: clan.badgeUrl,
        ),
      );
    }

    return clansByTag.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static String? selectedClanTagFromProfiles(
    Iterable<Player> profiles,
    String? selectedPlayerTag,
  ) {
    if (selectedPlayerTag == null || selectedPlayerTag.isEmpty) return null;

    final normalizedSelected = selectedPlayerTag.replaceAll('#', '');
    for (final player in profiles) {
      if (player.tag.replaceAll('#', '') == normalizedSelected &&
          player.clanOverview.tag.isNotEmpty) {
        return player.clanOverview.tag;
      }
    }
    return null;
  }

  static Future<void> seedClanOptionsFromProfiles(
    Iterable<Player> profiles, {
    Iterable<BookmarkedClan> bookmarkedClans = const [],
    String? selectedPlayerTag,
    bool refreshWarData = false,
  }) async {
    final clans = clanOptionsFromProfiles(
      profiles,
      bookmarkedClans: bookmarkedClans,
    );
    if (clans.isEmpty) return;

    final selectedClanTag =
        selectedClanTagFromProfiles(profiles, selectedPlayerTag) ??
        clans.first.tag;

    if (refreshWarData) {
      await prepareClanWidgets(clans, selectedClanTag: selectedClanTag);
    } else {
      await cacheClanOptions(clans, selectedClanTag: selectedClanTag);
      await _updateWidget();
    }
  }

  // Handle widget refresh requests from the Android widget
  static Future<void> handleWidgetRefresh() async {
    try {
      DebugUtils.debugWidget("🔄 War widget refresh requested");

      final cachedClans = await getCachedClanOptions();
      if (cachedClans.isNotEmpty) {
        await Future.wait(
          cachedClans.map((clan) => refreshWarInfoForClan(clan.tag)),
        );
        await _updateWidget();
        DebugUtils.debugSuccess("War widget refresh completed");
        return;
      }

      final clanTag = await WarWidgetService.getCurrentPlayerClanTag();
      if (clanTag == null || clanTag.isEmpty) {
        DebugUtils.debugWarning("⚠️ No clan tag found for widget refresh");
        return;
      }

      DebugUtils.debugWidget("🔍 Using clan tag for widget refresh: $clanTag");

      await refreshWarInfoForClan(clanTag, makeDefault: true);
      await _updateWidget();

      DebugUtils.debugSuccess("War widget refresh completed");
    } catch (e, stackTrace) {
      ErrorReporter.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'widget.refresh',
      );
      DebugUtils.debugError(" Error refreshing war widget: $e");
    }
  }

  // Initialize widget background callbacks
  static void initialize() {
    // Set up the callback for when the widget refresh button is tapped
    HomeWidget.setAppGroupId(_widgetAppGroup);

    // Register callback for widget interactions
    HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  // Background callback handler
  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri == null) {
      DebugUtils.debugWarning(
        "⚠️ Widget background callback received null URI",
      );
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
        DebugUtils.debugWarning(
          "⚠️ No selected player tag found in any preference key",
        );

        // If still no selected tag, try to get the first available CoC account
        final firstAccountTag = await _getFirstAvailableAccount();
        if (firstAccountTag != null) {
          DebugUtils.debugInfo(
            "🔄 Using first available account: $firstAccountTag",
          );
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
        DebugUtils.debugSuccess(
          "Got clan tag for selected player $selectedPlayerTag: $playerClanTag",
        );
        return playerClanTag;
      } else {
        DebugUtils.debugWarning(
          "⚠️ Player $selectedPlayerTag is not in a clan",
        );
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
      final token = await TokenService.shared.getAccessToken();
      if (token == null) {
        DebugUtils.debugWarning("⚠️ User not authenticated");
        return null;
      }

      final userResponse = await http
          .get(
            Uri.parse("${ApiService.apiUrlV2}/auth/me"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (userResponse.statusCode != 200) {
        DebugUtils.debugWarning(
          "⚠️ Failed to get current user: ${userResponse.statusCode}",
        );
        return null;
      }

      final userData = jsonDecode(userResponse.body);
      final userId = userData['user_id']?.toString();
      if (userId == null || userId.isEmpty) {
        DebugUtils.debugWarning("⚠️ Current user id missing");
        return null;
      }

      final response = await http
          .get(
            Uri.parse(
              "${ApiService.apiUrlV2}/links/${Uri.encodeComponent(userId)}",
            ),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accounts = data['items'] as List?;

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
        DebugUtils.debugWarning(
          "⚠️ Failed to get CoC accounts: ${response.statusCode}",
        );
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
        DebugUtils.debugInfo(
          "💾 Using cached clan tag for $playerTag: $cachedClanTag",
        );
        return cachedClanTag;
      }

      // If not cached, we need to make an API call as fallback
      DebugUtils.debugInfo(
        "🔍 No cached clan tag found, making API call for $playerTag",
      );

      final token = await TokenService.shared.getAccessToken();
      if (token == null) {
        DebugUtils.debugWarning(
          "⚠️ User not authenticated - no token available",
        );
        return null;
      }

      final response = await http
          .post(
            Uri.parse("${ApiService.apiUrlV2}/players"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "player_tags": [playerTag],
            }),
          )
          .timeout(const Duration(seconds: 10));

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
          DebugUtils.debugWarning(
            "⚠️ No player data found for tag: $playerTag",
          );
          return null;
        }
      } else {
        DebugUtils.debugWarning(
          "⚠️ Failed to get player data: ${response.statusCode}",
        );
        return null;
      }
    } catch (e) {
      DebugUtils.debugError(" Error fetching player clan tag: $e");
      return null;
    }
  }

  static Future<List<WarWidgetClanOption>> getCachedClanOptions() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        'warWidgetClans',
        appGroupId: _appGroupForPlatform(),
      );
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                WarWidgetClanOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((option) => option.tag.isNotEmpty)
          .toList();
    } catch (e) {
      DebugUtils.debugError(" Error reading widget clan options: $e");
      return const [];
    }
  }

  static Future<void> cacheClanOptions(
    List<WarWidgetClanOption> clans, {
    String? selectedClanTag,
    bool syncConfig = true,
  }) async {
    if (syncConfig) await syncWidgetProxyConfig();

    final deduped = <String, WarWidgetClanOption>{};
    for (final clan in clans) {
      if (clan.tag.isEmpty) continue;
      deduped[_normalizedClanTag(clan.tag)] = clan;
    }

    final options = deduped.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await HomeWidget.saveWidgetData<String>(
      'warWidgetClans',
      jsonEncode(options.map((option) => option.toJson()).toList()),
      appGroupId: _appGroupForPlatform(),
    );

    final selected =
        selectedClanTag ??
        (options.isNotEmpty
            ? options.first.tag
            : await getCurrentPlayerClanTag());
    if (selected != null && selected.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(
        'warWidgetSelectedClan',
        selected,
        appGroupId: _appGroupForPlatform(),
      );
    }
  }

  static Future<void> refreshWarInfoForClan(
    String clanTag, {
    bool makeDefault = false,
  }) async {
    final warInfo = await _loadWarSummary(clanTag);
    await HomeWidget.saveWidgetData<String>(
      warInfoKeyForClan(clanTag),
      warInfo,
      appGroupId: _appGroupForPlatform(),
    );

    if (makeDefault) {
      await HomeWidget.saveWidgetData<String>(
        'warInfo',
        warInfo,
        appGroupId: _appGroupForPlatform(),
      );
      await HomeWidget.saveWidgetData<String>(
        'warWidgetSelectedClan',
        clanTag,
        appGroupId: _appGroupForPlatform(),
      );
    }
  }

  static Future<String> _loadWarSummary(String clanTag) async {
    final key = _normalizedClanTag(clanTag);
    final existing = _warSummaryLoads[key];
    if (existing != null) return existing;

    final load = fetchWarSummary(clanTag);
    _warSummaryLoads[key] = load;
    try {
      return await load;
    } finally {
      if (identical(_warSummaryLoads[key], load)) {
        _warSummaryLoads.remove(key);
      }
    }
  }

  static Future<void> prepareClanWidgets(
    List<WarWidgetClanOption> clans, {
    String? selectedClanTag,
  }) async {
    await syncWidgetProxyConfig();
    await cacheClanOptions(
      clans,
      selectedClanTag: selectedClanTag,
      syncConfig: false,
    );

    final selectedKey = selectedClanTag == null
        ? null
        : _normalizedClanTag(selectedClanTag);
    final clansByTag = <String, WarWidgetClanOption>{
      for (final clan in clans)
        if (clan.tag.isNotEmpty) _normalizedClanTag(clan.tag): clan,
    };
    await Future.wait(
      clansByTag.entries.map(
        (entry) => refreshWarInfoForClan(
          entry.value.tag,
          makeDefault: entry.key == selectedKey,
        ),
      ),
    );

    if (selectedKey != null &&
        selectedKey.isNotEmpty &&
        !clansByTag.containsKey(selectedKey)) {
      await refreshWarInfoForClan(selectedClanTag!, makeDefault: true);
    }

    await _updateWidget();
  }

  static Future<void> requestPinnedWarWidget() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final supported = await HomeWidget.isRequestPinWidgetSupported();
    if (supported == true) {
      await HomeWidget.requestPinWidget(androidName: 'WarAppWidgetProvider');
    }
  }

  static Future<void> syncWidgetProxyConfig() async {
    await HomeWidget.saveWidgetData<String>(
      'warWidgetProxyUrl',
      ApiService.proxyUrl,
      appGroupId: _appGroupForPlatform(),
    );

    final token = await TokenService.shared.getAccessToken();
    if (token != null && token.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(
        'warWidgetAuthToken',
        token,
        appGroupId: _appGroupForPlatform(),
      );
    }
  }

  static Future<void> _updateWidget() {
    return HomeWidget.updateWidget(
      name: 'WarWidget',
      androidName: 'WarAppWidgetProvider',
      iOSName: 'WarWidget',
    );
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
          child: Center(child: CircularProgressIndicator()),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Text(
                'Last updated: ${DateTime.now().toString().substring(11, 16)}',
              )
            else
              const Text('No war data available'),
          ],
        ),
      ),
    );
  }
}
