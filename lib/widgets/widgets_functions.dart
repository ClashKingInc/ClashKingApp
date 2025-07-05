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
        "state": "accessDenied",
        "statusIcon": "🔒",
        "primaryText": "War Log Private",
        "secondaryText": "",
        "colorTheme": "warning"
      });
    case "notInWar":
    default:
      return jsonEncode({
        "updatedAt": updatedAt,
        "timeState": "",
        "state": "notInWar",
        "statusIcon": "😴",
        "primaryText": "Not in War", 
        "secondaryText": "",
        "colorTheme": "neutral"
      });
  }
}

// Build data for regular war
String _buildRegularWarData(Map<String, dynamic> warInfo, String updatedAt) {
  final currentWar = warInfo["currentWarInfo"] ?? {};
  final state = currentWar["state"] ?? "unknown";
  
  String timeState = "";
  String score = "";
  String statusIcon = "⚔️";
  String primaryText = "";
  String secondaryText = "";
  String colorTheme = "active";
  
  final clanStars = currentWar["clan"]?["stars"] ?? 0;
  final opponentStars = currentWar["opponent"]?["stars"] ?? 0;
  final teamSize = currentWar["teamSize"] ?? 0;
  
  // Handle different war states with status as primary, score as secondary
  if (state == "preparation") {
    statusIcon = "🛡️";
    primaryText = "War Preparation";
    secondaryText = "";
    colorTheme = "preparation";
    if (currentWar["startTime"] != null) {
      final startTime = DateTime.parse(currentWar["startTime"]);
      final timeUntilStart = startTime.difference(DateTime.now());
      if (timeUntilStart.inHours > 0) {
        timeState = "Starts in ${timeUntilStart.inHours}h ${timeUntilStart.inMinutes % 60}m";
        primaryText = timeState;
      } else {
        timeState = "Starts at ${DateFormat('HH:mm').format(startTime.toLocal())}";
        primaryText = timeState;
      }
    }
    score = "";
  } else if (state == "inWar") {
    statusIcon = "⚔️";
    secondaryText = "$clanStars - $opponentStars";
    colorTheme = clanStars > opponentStars ? "winning" : clanStars < opponentStars ? "losing" : "tied";
    if (currentWar["endTime"] != null) {
      final endTime = DateTime.parse(currentWar["endTime"]);
      final timeUntilEnd = endTime.difference(DateTime.now());
      if (timeUntilEnd.inHours > 0) {
        timeState = "${timeUntilEnd.inHours}h ${timeUntilEnd.inMinutes % 60}m left";
      } else {
        timeState = "Ends at ${DateFormat('HH:mm').format(endTime.toLocal())}";
      }
      primaryText = timeState;
    }
    score = "$clanStars - $opponentStars";
  } else if (state == "warEnded") {
    final isWin = clanStars > opponentStars;
    statusIcon = isWin ? "🏆" : "💔";
    primaryText = isWin ? "Victory!" : "Defeat";
    secondaryText = "$clanStars - $opponentStars";
    colorTheme = isWin ? "victory" : "defeat";
    timeState = "War Ended";
    score = "$clanStars - $opponentStars";
  }

  final clan = currentWar["clan"] ?? {};
  final opponent = currentWar["opponent"] ?? {};

  return jsonEncode({
    "state": state,
    "updatedAt": updatedAt,
    "timeState": timeState,
    "score": score,
    "statusIcon": statusIcon,
    "primaryText": primaryText,
    "secondaryText": secondaryText,
    "colorTheme": colorTheme,
    "clan": {
      "name": clan["name"] ?? "Unknown",
      "badgeUrlMedium": clan["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png",
      "percent": "${(clan["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
      "attacks": "${clan["attacks"] ?? 0}/${teamSize * 2}",
      "stars": clanStars,
      "maxStars": teamSize * 3
    },
    "opponent": {
      "name": opponent["name"] ?? "Unknown", 
      "badgeUrlMedium": opponent["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png",
      "percent": "${(opponent["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
      "attacks": "${opponent["attacks"] ?? 0}/${teamSize * 2}",
      "stars": opponentStars,
      "maxStars": teamSize * 3
    }
  });
}

// Build data for CWL war
String _buildCwlWarData(Map<String, dynamic> data, String updatedAt) {
  final warLeagueInfos = data["war_league_infos"] ?? [];
  
  print("🏅 CWL Debug - war_league_infos count: ${warLeagueInfos.length}");
  
  // Find current war from war league infos
  Map<String, dynamic>? currentWar;
  
  // First priority: active wars (inWar)
  for (final war in warLeagueInfos) {
    final state = war["state"];
    print("🔍 CWL War state: $state");
    if (state == "inWar") {
      currentWar = war;
      print("✅ Found active CWL war");
      break;
    }
  }
  
  // Second priority: preparation wars
  if (currentWar == null) {
    for (final war in warLeagueInfos) {
      final state = war["state"];
      if (state == "preparation") {
        currentWar = war;
        print("✅ Found CWL preparation war");
        break;
      }
    }
  }
  
  // Third priority: most recent war (could be ended)
  if (currentWar == null && warLeagueInfos.isNotEmpty) {
    // Sort by endTime or startTime to get the most recent
    final sortedWars = List<Map<String, dynamic>>.from(warLeagueInfos);
    sortedWars.sort((a, b) {
      final aTime = a["endTime"] ?? a["startTime"] ?? "";
      final bTime = b["endTime"] ?? b["startTime"] ?? "";
      return bTime.compareTo(aTime);
    });
    currentWar = sortedWars.first;
    print("✅ Using most recent CWL war: ${currentWar?["state"]}");
  }
  
  // Handle case where no wars found at all
  if (currentWar == null) {
    print("❌ No CWL wars found");
    return jsonEncode({
      "updatedAt": updatedAt,
      "timeState": "CWL Period",
      "state": "cwl",
      "score": "-",
      "statusIcon": "🏅",
      "primaryText": "CWL Active",
      "secondaryText": "",
      "colorTheme": "cwl",
      "clan": {
        "name": "CWL",
        "badgeUrlMedium": "https://assets.clashk.ing/clashkinglogo.png",
        "percent": "0%",
        "attacks": "0/0"
      },
      "opponent": {
        "name": "TBD",
        "badgeUrlMedium": "https://assets.clashk.ing/clashkinglogo.png", 
        "percent": "0%",
        "attacks": "0/0"
      }
    });
  }

  final state = currentWar["state"] ?? "unknown";
  print("🏅 CWL Processing war with state: $state");
  
  String timeState = "CWL";
  String score = "";
  String statusIcon = "🏅";
  String primaryText = "";
  String secondaryText = "";
  String colorTheme = "cwl";
  
  final clanStars = currentWar["clan"]?["stars"] ?? 0;
  final opponentStars = currentWar["opponent"]?["stars"] ?? 0;
  
  print("🏅 CWL Stars - Clan: $clanStars, Opponent: $opponentStars");
  
  if (state == "preparation") {
    statusIcon = "🏅";
    primaryText = "CWL Preparation";
    secondaryText = "";
    colorTheme = "cwl";
    if (currentWar["startTime"] != null) {
      final startTime = DateTime.parse(currentWar["startTime"]);
      final timeUntilStart = startTime.difference(DateTime.now());
      if (timeUntilStart.inHours > 0) {
        timeState = "Starts in ${timeUntilStart.inHours}h ${timeUntilStart.inMinutes % 60}m";
        primaryText = timeState;
      } else {
        timeState = "Starts at ${DateFormat('HH:mm').format(startTime.toLocal())}";
        primaryText = timeState;
      }
    }
    score = "";
  } else if (state == "inWar") {
    statusIcon = "🏅";
    secondaryText = "$clanStars - $opponentStars";
    colorTheme = clanStars > opponentStars ? "winning" : clanStars < opponentStars ? "losing" : "tied";
    if (currentWar["endTime"] != null) {
      final endTime = DateTime.parse(currentWar["endTime"]);
      final timeUntilEnd = endTime.difference(DateTime.now());
      if (timeUntilEnd.inHours > 0) {
        timeState = "${timeUntilEnd.inHours}h ${timeUntilEnd.inMinutes % 60}m left";
      } else {
        timeState = "Ends at ${DateFormat('HH:mm').format(endTime.toLocal())}";
      }
      primaryText = timeState;
    }
    score = "$clanStars - $opponentStars";
  } else if (state == "warEnded") {
    final isWin = clanStars > opponentStars;
    statusIcon = isWin ? "🏆" : "🥈";
    primaryText = isWin ? "CWL Victory!" : "CWL Complete";
    secondaryText = "$clanStars - $opponentStars";
    colorTheme = isWin ? "victory" : "cwl";
    timeState = "CWL War Ended";
    score = "$clanStars - $opponentStars";
  }

  final teamSize = currentWar["teamSize"] ?? 15; // CWL default
  final clan = currentWar["clan"] ?? {};
  final opponent = currentWar["opponent"] ?? {};
  
  print("🏅 CWL Final data - Clan: ${clan["name"] ?? "Unknown"}, Opponent: ${opponent["name"] ?? "Unknown"}");

  // Ensure we have valid clan and opponent data
  final clanData = {
    "name": clan["name"] ?? "CWL Clan",
    "badgeUrlMedium": clan["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png",
    "percent": "${(clan["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
    "attacks": "${clan["attacks"] ?? 0}/$teamSize",
    "stars": clanStars,
    "maxStars": teamSize * 3
  };
  
  final opponentData = {
    "name": opponent["name"] ?? "CWL Opponent",
    "badgeUrlMedium": opponent["badgeUrls"]?["medium"] ?? "https://assets.clashk.ing/clashkinglogo.png", 
    "percent": "${(opponent["destructionPercentage"] ?? 0).toStringAsFixed(2)}%",
    "attacks": "${opponent["attacks"] ?? 0}/$teamSize",
    "stars": opponentStars,
    "maxStars": teamSize * 3
  };

  final result = {
    "state": "cwl", 
    "updatedAt": updatedAt,
    "timeState": timeState,
    "score": score,
    "statusIcon": statusIcon,
    "primaryText": primaryText,
    "secondaryText": secondaryText,
    "colorTheme": colorTheme,
    "clan": clanData,
    "opponent": opponentData
  };
  
  print("🏅 CWL Widget data created: ${jsonEncode(result)}");
  return jsonEncode(result);
}

// Build error result
String _buildErrorResult() {
  return jsonEncode({
    "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
    "timeState": "",
    "state": ""
  });
}
