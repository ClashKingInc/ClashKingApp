import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/observability_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_repository.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';
import 'package:clashkingapp/features/coc_accounts/models/coc_account_link.dart';

class CocAccountService extends ChangeNotifier {
  static const String _msgNotAuthenticated = 'User not authenticated';

  CocAccountService({ApiService? apiService, String? currentUserId})
    : _apiService = apiService ?? ApiService.shared,
      _currentUserId = currentUserId?.trim().isEmpty == true
          ? null
          : currentUserId?.trim();

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  final ApiService _apiService;
  List<Map<String, dynamic>> _cocAccounts = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _selectedTag;
  DateTime? _lastRefresh;
  ValueNotifier<String?> selectedTagNotifier = ValueNotifier(null);
  List<Map<String, dynamic>> get cocAccounts => _cocAccounts;
  List<Map<String, dynamic>> get verifiedAccounts => _cocAccounts
      .where((account) => account['is_verified'] == true)
      .toList(growable: false);
  bool get hasVerifiedAccounts => verifiedAccounts.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get selectedTag => _selectedTag;
  DateTime? get lastRefresh => _lastRefresh;
  List<String> get accounts =>
      _cocAccounts.map((account) => account["player_tag"].toString()).toList();

  void setCurrentUserId(String? userId) {
    final normalizedUserId = userId?.trim();
    _currentUserId = normalizedUserId == null || normalizedUserId.isEmpty
        ? null
        : normalizedUserId;
  }

  String _linksEndpoint([String? path]) {
    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw UnauthorizedException(_msgNotAuthenticated);
    }

    final endpoint = '/links/${Uri.encodeComponent(currentUserId)}';
    return path == null ? endpoint : '$endpoint/$path';
  }

  /// Clears all cached account data (for logout)
  void clearAccountData() {
    _cocAccounts = [];
    _selectedTag = null;
    selectedTagNotifier.value = null;
    unawaited(ObservabilityService.setSelectedPlayerTag(null));
    _isLoading = false;
    _lastRefresh = null;
    _safeNotify();
  }

  /// Fetches the user's linked Clash of Clans accounts from the backend.
  Future<void> fetchCocAccounts() async {
    _isLoading = true;
    _safeNotify();

    try {
      final response = await _apiService.getResponse(
        _linksEndpoint(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = json.decode(ApiService.decodeResponseBody(response));
        final cocAccounts = data["items"];
        if (cocAccounts is! List) {
          throw const FormatException("Invalid CoC accounts payload");
        }
        _cocAccounts = cocAccounts
            .map((rawAccount) {
              if (rawAccount is! Map) {
                throw const FormatException('Invalid CoC account item');
              }
              return CocAccountLink.fromJson(
                Map<String, dynamic>.from(rawAccount),
              ).toJson();
            })
            .toList(growable: true);
        DebugUtils.debugInfo("🔍 Fetched accounts data: $_cocAccounts");
        // Verification status is now included in the API response
      } else {
        throw HttpException(
          "Failed to fetch CoC accounts (${response.statusCode})",
          uri: response.request?.url,
        );
      }
    } catch (exception, stackTrace) {
      ErrorReporter.captureException(
        exception,
        stackTrace: stackTrace,
        operation: 'accounts.fetch',
      );
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Adds a Clash of Clans account (without verification).
  Future<Map<String, dynamic>> addCocAccount(String playerTag) async {
    DebugUtils.debugInfo("🔄 Adding CoC account with tag: $playerTag");

    try {
      final response = await _apiService.postResponse(
        _linksEndpoint(),
        body: {"player_tag": playerTag},
        requiresAuth: true,
      );

      final responseBody = ApiService.decodeResponseBody(response);
      final data = _decodeResponseMap(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _reportAddAccountFailure(
          playerTag: playerTag,
          statusCode: response.statusCode,
          responseBody: responseBody,
          responseData: data,
        );
      }

      final account = response.statusCode == 200
          ? _normalizeAccount(data["account"])
          : (data["detail"] is Map && data["detail"]["account"] != null
                ? _normalizeAccount(data["detail"]["account"])
                : null);
      if (response.statusCode == 200 && account != null) {
        _upsertAccount(account);
      }

      return {
        "code": response.statusCode,
        "message": _extractErrorMessage(data),
        "account": account,
      };
    } on UnauthorizedException {
      return {"code": 401, "message": _msgNotAuthenticated};
    } catch (error, stackTrace) {
      _reportAddAccountException(playerTag, error, stackTrace);
      return {"code": 500, "message": "Internal server error"};
    }
  }

  /// Adds a Clash of Clans account with an API token through the links API.
  Future<Map<String, dynamic>> addCocAccountWithVerification(
    String playerTag,
    String apiToken,
  ) async {
    try {
      final response = await _apiService.postResponse(
        _linksEndpoint(),
        body: {"player_tag": playerTag, "api_token": apiToken},
        requiresAuth: true,
      );

      final responseBody = ApiService.decodeResponseBody(response);
      final data = _decodeResponseMap(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _reportAddAccountFailure(
          playerTag: playerTag,
          statusCode: response.statusCode,
          responseBody: responseBody,
          responseData: data,
        );
      }

      final account = response.statusCode == 200
          ? _normalizeAccount(data["account"])
          : null;
      if (response.statusCode == 200 && account != null) {
        _upsertAccount(account);
      }

      return {
        "code": response.statusCode,
        "message": _extractErrorMessage(data),
        "account": account,
      };
    } on UnauthorizedException {
      return {"code": 401, "message": _msgNotAuthenticated};
    } catch (error, stackTrace) {
      _reportAddAccountException(playerTag, error, stackTrace);
      return {"code": 500, "message": "Internal server error"};
    }
  }

  Map<String, dynamic>? _normalizeAccount(dynamic rawAccount) {
    if (rawAccount is! Map) return null;
    final account = Map<String, dynamic>.from(rawAccount);
    final playerTag =
        account["player_tag"]?.toString() ?? account["tag"]?.toString() ?? "";
    if (playerTag.isEmpty) return null;
    account["player_tag"] = playerTag;
    account["tag"] ??= playerTag;
    account["name"] ??= "Unknown Player";
    account["townHallLevel"] ??= 1;
    account["is_verified"] ??= false;
    return CocAccountLink.fromJson(account).toJson();
  }

  void _upsertAccount(Map<String, dynamic> account) {
    final playerTag = account["player_tag"]?.toString();
    if (playerTag == null || playerTag.isEmpty) return;
    _cocAccounts.removeWhere(
      (existing) => existing["player_tag"]?.toString() == playerTag,
    );
    _cocAccounts.add(account);
    _safeNotify();
  }

  /// Removes a Clash of Clans account from the user's linked accounts.
  Future<void> removeCocAccount(String playerTag) async {
    try {
      final encodedPlayerTag = Uri.encodeComponent(playerTag);

      final response = await _apiService.deleteResponse(
        _linksEndpoint(encodedPlayerTag),
        requiresAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _cocAccounts.removeWhere(
          (account) => account["player_tag"] == playerTag,
        );
        _safeNotify();
      } else {
        Sentry.captureMessage(
          "Error removing CoC account, status code: ${response.statusCode}, body: ${response.body}",
          level: SentryLevel.error,
        );
      }
    } catch (e) {
      ErrorReporter.captureException(e, operation: 'accounts.remove');
    }
  }

  Future<void> updateAccountHidden(String playerTag, bool hidden) async {
    final encodedPlayerTag = Uri.encodeComponent(playerTag);

    try {
      final response = await _apiService.patchResponse(
        _linksEndpoint(encodedPlayerTag),
        body: {'hidden': hidden},
        requiresAuth: true,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Failed to update account visibility (${response.statusCode})',
          uri: response.request?.url,
        );
      }

      final accountIndex = _cocAccounts.indexWhere(
        (account) => account['player_tag'] == playerTag,
      );
      if (accountIndex != -1) {
        _cocAccounts[accountIndex]['hidden'] = hidden;
        _safeNotify();
      }
    } catch (exception, stackTrace) {
      ErrorReporter.captureException(
        exception,
        stackTrace: stackTrace,
        operation: 'accounts.visibility',
      );
      rethrow;
    }
  }

  /// Reorder accounts and send the updated order to the API
  Future<void> updateAccountOrder(List<String> playerTags) async {
    final response = await _apiService.putResponse(
      _linksEndpoint('order'),
      body: {"ordered_tags": playerTags},
      requiresAuth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      Sentry.captureMessage(
        "Failed to update account order, status code: ${response.statusCode}, body: ${response.body}",
        level: SentryLevel.error,
      );
      return;
    }

    final orderedTags = playerTags.map((tag) => tag.toUpperCase()).toList();
    final accountsByTag = {
      for (final account in _cocAccounts)
        account["player_tag"].toString().toUpperCase(): account,
    };
    final reorderedAccounts = <Map<String, dynamic>>[
      for (final tag in orderedTags)
        if (accountsByTag[tag] != null) accountsByTag[tag]!,
      for (final account in _cocAccounts)
        if (!orderedTags.contains(
          account["player_tag"].toString().toUpperCase(),
        ))
          account,
    ];

    _cocAccounts = reorderedAccounts;
    _safeNotify();
  }

  Future<void> reorderLocalAccounts(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _cocAccounts.length) return;
    if (newIndex < 0 || newIndex > _cocAccounts.length) return;

    final account = _cocAccounts.removeAt(oldIndex);
    _cocAccounts.insert(newIndex, account);

    _safeNotify();
    await updateAccountOrder(getAccountTags());
  }

  Future<void> setSelectedTag(String? tag) async {
    final previousTag = _selectedTag;
    _selectedTag = tag;
    selectedTagNotifier.value = tag;
    unawaited(ObservabilityService.setSelectedPlayerTag(tag));

    // Persist to SharedPreferences for widget access
    if (tag != null) {
      try {
        await storePrefs('selectedTag', tag);

        // Check if we need to refresh the war widget due to clan change
        await _checkAndRefreshWarWidget(previousTag, tag);
      } catch (e) {
        DebugUtils.debugWarning("⚠️ Could not store selected tag: $e");
        // Continue without storing - not critical for app functionality
      }
    } else {
      await deletePrefs('selectedTag');
    }

    _safeNotify();
  }

  Future<void> initializeSelectedTag() async {
    if (_cocAccounts.isNotEmpty && selectedTagNotifier.value == null) {
      await setSelectedTag(_cocAccounts.first["player_tag"]);
    }
  }

  // Load selected tag from SharedPreferences on app start
  Future<void> loadSelectedTag() async {
    try {
      final storedTag = await getPrefs('selectedTag');
      if (storedTag != null && storedTag.isNotEmpty) {
        _selectedTag = storedTag;
        selectedTagNotifier.value = storedTag;
        unawaited(ObservabilityService.setSelectedPlayerTag(storedTag));
        DebugUtils.debugInfo(
          "🔄 Loaded selected tag from preferences: $storedTag",
        );
      }
    } catch (e) {
      DebugUtils.debugWarning(
        "⚠️ Could not load selected tag from preferences: $e",
      );
      // Continue without stored tag - will use first account as default
    }
  }

  /// Updates the last refresh timestamp and notifies listeners
  void updateRefreshTime() {
    _lastRefresh = DateTime.now();
    _safeNotify();
  }

  /// Refresh data for a specific page with direct parallel requests.
  Future<void> refreshPageData(
    List<String> playerTags,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService, {
    List<String> bookmarkedClanTags = const [],
  }) async {
    if (playerTags.isEmpty) return;

    DebugUtils.debugInfo(
      "🔄 Refreshing page data for ${playerTags.length} players",
    );

    try {
      await _loadDataWithParallelRequests(
        playerTags,
        playerService,
        clanService,
        warCwlService,
        bookmarkedClanTags: bookmarkedClanTags,
        forceAuxiliaryRefresh: true,
      );
      _lastRefresh = DateTime.now();
      _safeNotify();
      DebugUtils.debugSuccess("Page refresh completed successfully");
    } catch (e) {
      DebugUtils.debugError(" Page refresh failed: $e");
      rethrow;
    }
  }

  List<String> getAccountTags() {
    return _cocAccounts
        .map((account) => account["player_tag"].toString())
        .toList();
  }

  Future<void> loadApiData(
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService, {
    List<String> bookmarkedClanTags = const [],
  }) async {
    final transaction = Sentry.startTransaction(
      "CocAccountService.loadApiData",
      "task",
      bindToScope: true,
    );

    try {
      final spanFetchAccounts = transaction.startChild("fetchCocAccounts");
      DebugUtils.debugApi("Startup phase: fetch CoC accounts");
      await fetchCocAccounts();
      spanFetchAccounts.finish();

      if (cocAccounts.isEmpty) {
        transaction.finish(status: SpanStatus.ok());
        return;
      }

      final List<String> playerTags = cocAccounts
          .map((account) => account["player_tag"].toString())
          .toList();

      transaction.setTag("playerTags", playerTags.toString());
      transaction.setTag("playerTagsCount", playerTags.length.toString());

      final spanDataLoad = transaction.startChild("parallelAccountHydration");
      DebugUtils.debugApi("Startup phase: hydrate linked account data");
      await _loadDataWithParallelRequests(
        playerTags,
        playerService,
        clanService,
        warCwlService,
        bookmarkedClanTags: bookmarkedClanTags,
      );
      spanDataLoad.finish();

      transaction.finish(status: SpanStatus.ok());
      _lastRefresh = DateTime.now();
      await initializeSelectedTag();
    } on HttpException catch (e) {
      transaction.throwable = e;
      transaction.status = SpanStatus.internalError();
      transaction.finish();
      if (e.message.contains("503")) {
        throw Exception("503");
      } else if (e.message.contains("500")) {
        throw Exception("500");
      } else {
        rethrow;
      }
    } catch (e, stack) {
      transaction.throwable = e;
      transaction.status = SpanStatus.internalError();
      transaction.finish();
      ErrorReporter.captureException(
        e,
        stackTrace: stack,
        operation: 'accounts.startup',
      );
      rethrow;
    }
  }

  Future<void> _loadDataWithParallelRequests(
    List<String> playerTags,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService, {
    List<String> bookmarkedClanTags = const [],
    bool forceAuxiliaryRefresh = false,
  }) async {
    DebugUtils.debugInfo(
      "🚀 Hydrating ${playerTags.length} players with parallel requests",
    );

    // At startup this stays outside the awaited critical path so slow
    // per-account endpoints never delay the loading screen. Manual refresh
    // forces and awaits it so lastRefresh covers the Home dashboard cards too.
    UpgradeTrackerRepository.shared.configureRemote(
      accountId: _currentUserId,
      verifiedPlayerTags: verifiedAccounts.map(
        (account) => account['player_tag']?.toString() ?? '',
      ),
    );
    final homeDashboardWarmup = _warmHomeDashboardData(
      playerTags,
      playerService,
      forceRefresh: forceAuxiliaryRefresh,
    );
    if (!forceAuxiliaryRefresh) {
      unawaited(homeDashboardWarmup);
    }

    final timer = Stopwatch()..start();
    final cachedClanTagsByPlayer = await _cachedClanTagsByPlayer(playerTags);
    final optimisticClanTags = {
      ...cachedClanTagsByPlayer.values,
      ...bookmarkedClanTags,
    }.where((tag) => tag.isNotEmpty).toSet();

    final optimisticClanLoad = optimisticClanTags.isEmpty
        ? Future<void>.value()
        : _loadInitialClanData(
            optimisticClanTags,
            playerService,
            clanService,
            warCwlService,
          );

    DebugUtils.debugApi("Parallel phase: load official player data");
    final clanTagsByPlayer = await playerService.loadOfficialPlayerData(
      playerTags,
      notify: false,
      throwOnError: true,
    );

    final discoveredClanTags = playerService.profiles
        .map((profile) => profile.clanTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    discoveredClanTags.addAll(
      clanTagsByPlayer.values.where((tag) => tag.isNotEmpty),
    );

    final missingClanTags = discoveredClanTags
        .difference(optimisticClanTags)
        .where((tag) => tag.isNotEmpty)
        .toSet();

    DebugUtils.debugApi("Parallel phase: load initial clan and war data");
    await Future.wait([
      optimisticClanLoad,
      if (missingClanTags.isNotEmpty)
        _loadInitialClanData(
          missingClanTags,
          playerService,
          clanService,
          warCwlService,
        ),
    ]);

    if (forceAuxiliaryRefresh) {
      await homeDashboardWarmup;
    }

    final allClanTags = {
      ...optimisticClanTags,
      ...discoveredClanTags,
    }.where((tag) => tag.isNotEmpty).toSet();

    _linkHydratedData(allClanTags, playerService, clanService, warCwlService);

    playerService.notifyDataChanged();
    clanService.notifyDataChanged();
    warCwlService.notifyDataChanged();
    DebugUtils.debugSuccess(
      "All data linked successfully in ${timer.elapsedMilliseconds} ms",
    );
  }

  Future<void> _warmHomeDashboardData(
    Iterable<String> playerTags,
    PlayerService playerService, {
    required bool forceRefresh,
  }) async {
    await Future.wait([
      playerService.prefetchRankedLeagueData(
        playerTags,
        forceRefresh: forceRefresh,
      ),
      ...playerTags.map((tag) async {
        try {
          await UpgradeTrackerRepository.shared.load(
            tag,
            forceRefresh: forceRefresh,
          );
        } catch (_) {
          // Best-effort warm-up only; card-level loads surface their own errors.
        }
      }),
    ]);
  }

  Future<Map<String, String>> _cachedClanTagsByPlayer(
    List<String> playerTags,
  ) async {
    final entries = await Future.wait(
      playerTags.map((rawTag) async {
        final tag = rawTag.trim().toUpperCase();
        if (tag.isEmpty) return null;
        final normalizedTag = tag.startsWith('#') ? tag : '#$tag';
        final cachedClanTag = await getPrefs(
          'player_${normalizedTag}_clan_tag',
        );
        if (cachedClanTag == null || cachedClanTag.isEmpty) return null;
        return MapEntry(normalizedTag, cachedClanTag);
      }),
    );
    final cached = <String, String>{
      for (final entry in entries.whereType<MapEntry<String, String>>())
        entry.key: entry.value,
    };
    return cached;
  }

  Future<void> _loadInitialClanData(
    Set<String> clanTags,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService,
  ) async {
    if (clanTags.isEmpty) return;
    final tags = clanTags.toList(growable: false);

    await Future.wait([
      clanService.loadAllClanData(tags, notify: false, throwOnError: false),
      warCwlService.loadAllWarData(tags, notify: false, throwOnError: false),
    ]);
  }

  void _linkHydratedData(
    Set<String> clanTags,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService,
  ) {
    if (clanTags.isNotEmpty) {
      playerService.linkClansToPlayer(
        playerService.profiles,
        clanService.clans.values.toList(),
      );

      clanService.linkWarsToClans(
        clanService.clans.values.toList(),
        warCwlService.summaries.values.toList(),
      );
    }
  }

  // Check if clan changed and refresh war widget if needed (non-blocking)
  Future<void> _checkAndRefreshWarWidget(
    String? previousTag,
    String newTag,
  ) async {
    try {
      // Only refresh widget on mobile platforms
      if (kIsWeb) return;

      // Skip if no previous tag (first time selection)
      if (previousTag == null) return;

      // Get clan tags for both players from cache
      final previousClanTag = await getPrefs('player_${previousTag}_clan_tag');
      final newClanTag = await getPrefs('player_${newTag}_clan_tag');

      DebugUtils.debugInfo(
        "🔄 Account switch - Previous: $previousTag (clan: $previousClanTag) → New: $newTag (clan: $newClanTag)",
      );

      // If clan tags are different, refresh the war widget in background
      if (previousClanTag != newClanTag) {
        DebugUtils.debugInfo(
          "🔄 Clan changed! Refreshing war widget in background...",
        );
        // Don't await - let it run in background
        unawaited(
          WarWidgetService.handleWidgetRefresh().catchError((error) {
            DebugUtils.debugError(" Background widget refresh error: $error");
          }),
        );
      } else {
        DebugUtils.debugInfo("✅ Same clan, no widget refresh needed");
      }
    } catch (e) {
      DebugUtils.debugWarning("⚠️ Error checking clan change: $e");
      // If there's an error, refresh anyway to be safe (in background)
      unawaited(
        WarWidgetService.handleWidgetRefresh().catchError((error) {
          DebugUtils.debugError(" Background widget refresh error: $error");
        }),
      );
    }
  }

  /// Adds an account with token verification (used when account is already linked to another user)
  Future<bool> addAccountWithToken(
    String playerTag,
    String apiToken,
    Function(String) updateErrorMessage,
  ) async {
    try {
      final response = await _apiService.postResponse(
        _linksEndpoint(),
        body: {"player_tag": playerTag, "api_token": apiToken},
        requiresAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(ApiService.decodeResponseBody(response));
        DebugUtils.debugSuccess(
          "✅ Account added with token successfully: $playerTag",
        );

        // Extract player data from the token response
        final Map<String, dynamic>? accountData = data["account"];
        final String? playerName = accountData?["name"];
        final int? townHallLevel = accountData?["townHallLevel"];

        DebugUtils.debugInfo(
          "🔍 Extracted player data - Name: $playerName, TH: $townHallLevel",
        );

        // Refresh account list after successful addition
        await fetchCocAccounts();

        // Update the specific account with player data from token response
        if (accountData != null &&
            playerName != null &&
            townHallLevel != null) {
          final accountIndex = _cocAccounts.indexWhere(
            (account) => account["player_tag"] == playerTag,
          );
          if (accountIndex != -1) {
            _cocAccounts[accountIndex]["name"] = playerName;
            _cocAccounts[accountIndex]["townHallLevel"] = townHallLevel;
            DebugUtils.debugSuccess(
              "✅ Updated account display data for $playerTag: $playerName (TH$townHallLevel)",
            );
            _safeNotify();
          }
        }

        return true;
      } else if (response.statusCode == 403) {
        updateErrorMessage("Invalid API token for this account");
      } else if (response.statusCode == 404) {
        updateErrorMessage("Account not found");
      } else {
        updateErrorMessage("Failed to add account. Please try again.");
      }

      return false;
    } on UnauthorizedException {
      updateErrorMessage(_msgNotAuthenticated);
      return false;
    } catch (e) {
      updateErrorMessage("Failed to add account: $e");
      return false;
    }
  }

  /// Applies an API token to an existing account through the links API.
  Future<bool> verifyAccount(
    String playerTag,
    String apiToken,
    Function(String) updateErrorMessage,
  ) async {
    try {
      final response = await _apiService.postResponse(
        _linksEndpoint(),
        body: {"player_tag": playerTag, "api_token": apiToken},
        requiresAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        updateAccountVerificationStatus(playerTag, true);
        return true;
      } else if (response.statusCode == 403) {
        updateErrorMessage("Invalid API token for this account");
      } else if (response.statusCode == 404) {
        updateErrorMessage("Account not found");
      } else {
        updateErrorMessage("Verification failed. Please try again.");
      }

      return false;
    } on UnauthorizedException {
      updateErrorMessage(_msgNotAuthenticated);
      return false;
    } catch (e) {
      updateErrorMessage("Verification failed: $e");
      return false;
    }
  }

  /// Updates the verification status of an account locally
  void updateAccountVerificationStatus(String playerTag, bool isVerified) {
    final accountIndex = _cocAccounts.indexWhere(
      (account) => account["player_tag"] == playerTag,
    );
    if (accountIndex != -1) {
      _cocAccounts[accountIndex]["is_verified"] = isVerified;
      _safeNotify();
    }
  }

  /// Gets the verification status for an account
  bool getAccountVerificationStatus(String playerTag) {
    final account = _cocAccounts.firstWhere(
      (account) => account["player_tag"] == playerTag,
      orElse: () => <String, dynamic>{},
    );
    return account["is_verified"] ?? false;
  }

  CocAccountLink? getAccountLink(String playerTag) {
    final normalizedTag = playerTag.trim().toUpperCase();
    for (final account in _cocAccounts) {
      final accountTag = account['player_tag']?.toString().trim().toUpperCase();
      if (accountTag == normalizedTag) {
        return CocAccountLink.fromJson(account);
      }
    }
    return null;
  }

  Map<String, dynamic> _decodeResponseMap(String responseBody) {
    final trimmedBody = responseBody.trim();
    if (trimmedBody.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{
        "message": "Unexpected response payload: ${decoded.runtimeType}",
      };
    } on FormatException {
      return <String, dynamic>{"message": trimmedBody};
    }
  }

  void _reportAddAccountFailure({
    required String playerTag,
    required int statusCode,
    required String responseBody,
    required Map<String, dynamic> responseData,
  }) {
    final message = _extractErrorMessage(responseData);
    Sentry.captureException(
      HttpException("Failed to add CoC account: $statusCode $message"),
      stackTrace: StackTrace.current,
      withScope: (scope) {
        scope.setTag("operation", "coc_account.add");
        scope.setTag("status_code", statusCode.toString());
        scope.setContexts("CoC account add response", {
          "player_tag": playerTag,
          "status_code": statusCode,
          "message": message,
          "response_body": _truncateForDiagnostics(responseBody),
        });
      },
    );
  }

  void _reportAddAccountException(
    String playerTag,
    Object error,
    StackTrace stackTrace,
  ) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag("operation", "coc_account.add");
        scope.setContexts("CoC account add exception", {
          "player_tag": playerTag,
        });
      },
    );
  }

  String _truncateForDiagnostics(String value) {
    const maxLength = 2000;
    if (value.length <= maxLength) {
      return value;
    }
    return "${value.substring(0, maxLength)}...";
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final detail = data["detail"];
    if (data["message"] is String && (data["message"] as String).isNotEmpty) {
      return data["message"] as String;
    }
    if (detail is Map<String, dynamic>) {
      final nestedMessage = detail["message"];
      if (nestedMessage is String && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }
    }
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    return "Unknown error";
  }

  @override
  void dispose() {
    _disposed = true;
    selectedTagNotifier.dispose();
    super.dispose();
  }
}
