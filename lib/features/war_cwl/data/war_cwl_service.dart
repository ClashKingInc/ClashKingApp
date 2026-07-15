import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarCwlService extends ChangeNotifier {
  WarCwlService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;
  final Map<String, WarCwl> summaries = {};

  Future<void> loadAllWarData(
    List<String> clanTags, {
    bool notify = true,
    bool throwOnError = false,
  }) async {
    if (clanTags.isEmpty) return;

    if (notify) {
      notifyListeners();
    }

    try {
      DebugUtils.debugInfo("🏰 Loading war data for tags: $clanTags");
      final response = await _apiService.postResponse(
        '/war/war-summary',
        body: {"clan_tags": clanTags},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          ApiService.decodeResponseBody(response),
        )['items'];
        for (final summary in data) {
          final warSummary = WarCwl.fromJson(summary, null);
          summaries[warSummary.tag] = warSummary;
          DebugUtils.debugSuccess(
            "Loaded war data for clan: ${warSummary.tag}",
          );
        }
        if (notify) {
          notifyListeners();
        }
      } else if (throwOnError) {
        throw Exception("Failed to load war data (${response.statusCode})");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError(" Error loading war data: $e");
      if (throwOnError) {
        rethrow;
      }
    }
  }

  WarCwl? getWarCwlByTag(String tag) {
    if (tag.isEmpty) return null;
    return summaries[tag];
  }

  /// Process bulk war data from the optimized API endpoint
  void processBulkWarData(List<dynamic> warData, {bool notify = true}) {
    DebugUtils.debugInfo("🔄 Processing ${warData.length} bulk war data items");

    for (final warItem in warData) {
      try {
        if (warItem is Map<String, dynamic>) {
          final warSummary = WarCwl.fromJson(warItem, null);
          summaries[warSummary.tag] = warSummary;
          DebugUtils.debugSuccess(
            "Processed bulk war data for clan: ${warSummary.tag}",
          );
        }
      } catch (e) {
        DebugUtils.debugError(" Error processing bulk war data item: $e");
      }
    }

    DebugUtils.debugSuccess(
      "Processed all bulk war data, total summaries: ${summaries.length}",
    );
    if (notify) {
      notifyListeners();
    }
  }

  void notifyDataChanged() {
    notifyListeners();
  }

  static Future<WarInfo?> fetchWarDataFromTime(String tag, DateTime end) async {
    final apiService = ApiService.shared;
    String endTime = end.toIso8601String();
    endTime = endTime.replaceAll('-', '').replaceAll(':', '');

    final response = await apiService.getResponse(
      '',
      url: "${ApiService.apiUrlV1}/war/${tag.substring(1)}/previous/$endTime",
    );
    if (response.statusCode == 200) {
      String body = ApiService.decodeResponseBody(response);
      Map<String, dynamic> jsonBody = json.decode(body);
      return WarInfo.fromJson(jsonBody);
    } else {
      return null;
    }
  }
}
