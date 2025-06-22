import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Get the current war data for a clan using the new /war/war-summary endpoint
Future<String> fetchWarSummary(String? clanTag) async {
  if (clanTag == null || clanTag.isEmpty) {
    return jsonEncode({
      "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
      "timeState": "",
      "state": "notInClan"
    });
  }

  try {
    final token = await TokenService().getAccessToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    // Clean the clan tag for the URL
    final cleanTag = clanTag.replaceAll('#', '!');
    
    final response = await http.get(
      Uri.parse("${ApiService.apiUrlV2}/war/$cleanTag/war-summary"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      print("🔍 War API Response: ${jsonEncode(data)}");
      return _buildWarWidgetData(data);
    } else {
      Sentry.captureMessage("War summary API returned status ${response.statusCode} for clan $clanTag");
      return _buildErrorResult();
    }
  } catch (e, stackTrace) {
    Sentry.captureException(e, stackTrace: stackTrace);
    Sentry.captureMessage("Error fetching war summary for clan: $clanTag");
    return _buildErrorResult();
  }
}

// Build the war widget data from the API response
String _buildWarWidgetData(Map<String, dynamic> data) {
  final String updatedAt = "Updated at ${DateFormat('HH:mm').format(DateTime.now())}";
  
  print("🔍 API data - isInWar: ${data["isInWar"]}, isInCwl: ${data["isInCwl"]}");
  
  // Check if in regular war
  if (data["isInWar"] == true) {
    print("✅ Building regular war data");
    return _buildRegularWarData(data["war_info"], updatedAt);
  }
  
  // Check if in CWL
  if (data["isInCwl"] == true && data["league_info"] != null) {
    print("✅ Building CWL war data");
    return _buildCwlWarData(data, updatedAt);
  }
  
  // Handle different states
  final warInfo = data["war_info"] ?? {};
  final state = warInfo["state"] ?? "notInWar";
  
  print("⚠️ Not in war or CWL - state: $state, war_info: ${jsonEncode(warInfo)}");
  
  switch (state) {
    case "accessDenied":
      return jsonEncode({
        "updatedAt": updatedAt,
        "timeState": "",
        "state": "accessDenied"
      });
    case "notInWar":
    default:
      return jsonEncode({
        "updatedAt": updatedAt,
        "timeState": "",
        "state": "notInWar"
      });
  }
}

// Build data for regular war
String _buildRegularWarData(Map<String, dynamic> warInfo, String updatedAt) {
  final currentWar = warInfo["currentWarInfo"] ?? {};
  final state = currentWar["state"] ?? "unknown";
  
  String timeState = "";
  String score = "";
  
  // Handle different war states
  if (state == "preparation") {
    if (currentWar["startTime"] != null) {
      final startTime = DateTime.parse(currentWar["startTime"]);
      timeState = "Starts at ${DateFormat('HH:mm').format(startTime.toLocal())}";
    }
    score = "-";
  } else if (state == "inWar") {
    if (currentWar["endTime"] != null) {
      final endTime = DateTime.parse(currentWar["endTime"]);
      timeState = "Ends at ${DateFormat('HH:mm').format(endTime.toLocal())}";
    }
    final clanStars = currentWar["clan"]?["stars"] ?? 0;
    final opponentStars = currentWar["opponent"]?["stars"] ?? 0;
    score = "$clanStars - $opponentStars";
  } else if (state == "warEnded") {
    timeState = "War Ended";
    final clanStars = currentWar["clan"]?["stars"] ?? 0;
    final opponentStars = currentWar["opponent"]?["stars"] ?? 0;
    score = "$clanStars - $opponentStars";
  }

  final teamSize = currentWar["teamSize"] ?? 0;
  final clan = currentWar["clan"] ?? {};
  final opponent = currentWar["opponent"] ?? {};

  return jsonEncode({
    "state": state,
    "updatedAt": updatedAt,
    "timeState": timeState,
    "score": score,
    "clan": {
      "name": clan["name"] ?? "Unknown",
      "badgeUrlMedium": clan["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png",
      "percent": "${(clan["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
      "attacks": "${clan["attacks"] ?? 0}/${teamSize * 2}"
    },
    "opponent": {
      "name": opponent["name"] ?? "Unknown", 
      "badgeUrlMedium": opponent["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png",
      "percent": "${(opponent["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
      "attacks": "${opponent["attacks"] ?? 0}/${teamSize * 2}"
    }
  });
}

// Build data for CWL war
String _buildCwlWarData(Map<String, dynamic> data, String updatedAt) {
  final leagueInfo = data["league_info"] ?? {};
  final warLeagueInfos = data["war_league_infos"] ?? [];
  
  // Find current war from war league infos
  Map<String, dynamic>? currentWar;
  for (final war in warLeagueInfos) {
    final state = war["state"];
    if (state == "inWar" || state == "preparation") {
      currentWar = war;
      break;
    }
  }
  
  // If no current war, find the latest one
  if (currentWar == null && warLeagueInfos.isNotEmpty) {
    currentWar = warLeagueInfos.last;
  }
  
  if (currentWar == null) {
    return jsonEncode({
      "updatedAt": updatedAt,
      "timeState": "CWL Period",
      "state": "cwl",
      "score": "-",
      "clan": {
        "name": "CWL Active",
        "badgeUrlMedium": "https://assets.clashk.ing/clashkinglogo.png",
        "percent": "0%",
        "attacks": "0/0"
      },
      "opponent": {
        "name": "CWL",
        "badgeUrlMedium": "https://assets.clashk.ing/clashkinglogo.png", 
        "percent": "0%",
        "attacks": "0/0"
      }
    });
  }

  final state = currentWar["state"] ?? "unknown";
  String timeState = "CWL";
  String score = "";
  
  if (state == "preparation") {
    if (currentWar["startTime"] != null) {
      final startTime = DateTime.parse(currentWar["startTime"]);
      timeState = "CWL Starts at ${DateFormat('HH:mm').format(startTime.toLocal())}";
    }
    score = "-";
  } else if (state == "inWar") {
    if (currentWar["endTime"] != null) {
      final endTime = DateTime.parse(currentWar["endTime"]);
      timeState = "CWL Ends at ${DateFormat('HH:mm').format(endTime.toLocal())}";
    }
    final clanStars = currentWar["clan"]?["stars"] ?? 0;
    final opponentStars = currentWar["opponent"]?["stars"] ?? 0;
    score = "$clanStars - $opponentStars";
  } else if (state == "warEnded") {
    timeState = "CWL War Ended";
    final clanStars = currentWar["clan"]?["stars"] ?? 0;
    final opponentStars = currentWar["opponent"]?["stars"] ?? 0;
    score = "$clanStars - $opponentStars";
  }

  final teamSize = currentWar["teamSize"] ?? 15; // CWL default
  final clan = currentWar["clan"] ?? {};
  final opponent = currentWar["opponent"] ?? {};

  return jsonEncode({
    "state": "cwl", 
    "updatedAt": updatedAt,
    "timeState": timeState,
    "score": score,
    "clan": {
      "name": clan["name"] ?? "Unknown",
      "badgeUrlMedium": clan["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png",
      "percent": "${(clan["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
      "attacks": "${clan["attacks"] ?? 0}/$teamSize"
    },
    "opponent": {
      "name": opponent["name"] ?? "Unknown",
      "badgeUrlMedium": opponent["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png", 
      "percent": "${(opponent["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
      "attacks": "${opponent["attacks"] ?? 0}/$teamSize"
    }
  });
}

// Build error result
String _buildErrorResult() {
  return jsonEncode({
    "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
    "timeState": "",
    "state": "error"
  });
}
