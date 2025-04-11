import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

class WarCwlService extends ChangeNotifier {
  final Map<String, WarCwl> summaries = {};

  Future<void> loadAllWarData(List<String> clanTags) async {
    if (clanTags.isEmpty) return;

    notifyListeners();

    try {
      print("🏰 Loading war data for tags: $clanTags");
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.post(
        Uri.parse("${ApiService.apiUrl}/war/war-summary"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"clan_tags": clanTags}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes))['items'];
        for (final summary in data) {
          final warSummary = WarCwl.fromJson(summary);
          summaries[warSummary.tag] = warSummary;
          print("✅ Loaded war data for clan: ${warSummary.tag}");
        }
        notifyListeners();
      }
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading war data: $e");
    }
  }

  WarCwl? getWarCwlByTag(String tag) {
    if (tag.isEmpty) return null;
    return summaries[tag];
  }

}
