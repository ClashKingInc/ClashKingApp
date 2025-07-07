import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

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
      return _buildWarWidgetData(data, clanTag);
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
String _buildWarWidgetData(Map<String, dynamic> data, String clanTag) {
  final String updatedAt = "Updated at ${DateFormat('HH:mm').format(DateTime.now())}";
  
  DebugUtils.debugWidget("🔍 API data - isInWar: ${data["isInWar"]}, isInCwl: ${data["isInCwl"]}");
  
  // Check if in regular war
  if (data["isInWar"] == true) {
    DebugUtils.debugWidget("✅ Building regular war data");
    return _buildRegularWarData(data["war_info"], updatedAt);
  }
  
  // Check if in CWL
  if (data["isInCwl"] == true && data["league_info"] != null) {
    DebugUtils.debugWidget("✅ Building CWL war data");
    return _buildCwlWarData(data, updatedAt, clanTag);
  }
  
  // Handle different states
  final warInfo = data["war_info"] ?? {};
  final state = warInfo["state"] ?? "notInWar";
  
  DebugUtils.debugWidget("⚠️ Not in war or CWL - state: $state, war_info: ${jsonEncode(warInfo)}");
  
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
String _buildCwlWarData(Map<String, dynamic> data, String updatedAt, String clanTag) {
  DebugUtils.debugCwl("🏅 CWL Debug - clan_tag: '$clanTag'");
  DebugUtils.debugCwl("🏅 CWL Debug - clan_tag length: ${clanTag.length}");
  
  // Use WarCwl class to properly find the war for this clan
  final warCwl = WarCwl.fromJson(data, clanTag);
  DebugUtils.debugCwl("🔍 WarCwl created with ${warCwl.warLeagueInfos.length} wars");
  final activeWar = warCwl.getActiveWarByTag(clanTag);
  
  if (activeWar == null) {
    DebugUtils.debugWarning("⚠️ No wars found with our clan in CWL data");
    return jsonEncode({
      "updatedAt": updatedAt,
      "timeState": "CWL Period",
      "state": "cwl",
      "score": "-",
      "statusIcon": "🏅",
      "primaryText": "CWL Period",
      "secondaryText": "No active wars",
      "colorTheme": "neutral",
      "clan": null,
      "opponent": null
    });
  }
  
  // Use WarInfo properties directly
  final currentWar = activeWar;
  
  DebugUtils.debugCwl("🏅 CWL Processing war with state: ${currentWar.state}");
  
  final state = currentWar.state;
  DebugUtils.debugCwl("🏅 CWL Processing war with state: $state");
  
  String timeState = "CWL";
  String score = "";
  String statusIcon = "🏅";
  String primaryText = "";
  String secondaryText = "";
  String colorTheme = "cwl";
  
  final clanStars = currentWar.clan?.stars ?? 0;
  final opponentStars = currentWar.opponent?.stars ?? 0;
  
  DebugUtils.debugCwl("🏅 CWL Stars - Clan: $clanStars, Opponent: $opponentStars");
  
  if (state == "preparation") {
    statusIcon = "🏅";
    primaryText = "CWL Preparation";
    secondaryText = "";
    colorTheme = "cwl";
    if (currentWar.startTime != null) {
      final startTime = currentWar.startTime!;
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
    if (currentWar.endTime != null) {
      final endTime = currentWar.endTime!;
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

  final teamSize = currentWar.teamSize ?? 15; // CWL default
  
  // Determine which clan is "ours" and which is the "opponent"
  // Normalize clan tags for comparison
  String normalizeClanTag(String tag) {
    if (!tag.startsWith('#')) return '#$tag';
    return tag;
  }
  
  final normalizedOurTag = normalizeClanTag(clanTag);
  final warClanTag = currentWar.clan?.tag;
  
  bool isOurClanFirst = warClanTag != null && normalizeClanTag(warClanTag) == normalizedOurTag;
  
  // Set up our clan and opponent data based on which position we're in
  final ourClan = isOurClanFirst ? currentWar.clan : currentWar.opponent;
  final theirClan = isOurClanFirst ? currentWar.opponent : currentWar.clan;
  final ourStars = isOurClanFirst ? clanStars : opponentStars;
  final theirStars = isOurClanFirst ? opponentStars : clanStars;
  
  DebugUtils.debugCwl("🏅 CWL Final data - Our Clan: ${ourClan?.name ?? "Unknown"}, Their Clan: ${theirClan?.name ?? "Unknown"}");
  DebugUtils.debugCwl("🏅 CWL Position - Our clan is ${isOurClanFirst ? 'first' : 'second'} in war data");

  // Update score and color theme based on our clan's position
  if (state == "inWar") {
    secondaryText = "$ourStars - $theirStars";
    colorTheme = ourStars > theirStars ? "winning" : ourStars < theirStars ? "losing" : "tied";
    score = "$ourStars - $theirStars";
  } else if (state == "warEnded") {
    final isWin = ourStars > theirStars;
    statusIcon = isWin ? "🏆" : "🥈";
    primaryText = isWin ? "CWL Victory!" : "CWL Complete";
    secondaryText = "$ourStars - $theirStars";
    colorTheme = isWin ? "victory" : "cwl";
    score = "$ourStars - $theirStars";
  }

  // Ensure we have valid clan and opponent data (our clan always on left)
  final clanData = {
    "name": ourClan?.name ?? "CWL Clan",
    "badgeUrlMedium": ourClan?.badgeUrls.medium,
    "percent": "${(ourClan?.destructionPercentage ?? 0).toStringAsFixed(2)}%",
    "attacks": "${ourClan?.attacks ?? 0}/$teamSize",
    "stars": ourStars,
    "maxStars": teamSize * 3
  };
  
  final opponentData = {
    "name": theirClan?.name ?? "CWL Opponent",
    "badgeUrlMedium": theirClan?.badgeUrls.medium,
    "percent": "${(theirClan?.destructionPercentage ?? 0).toStringAsFixed(2)}%",
    "attacks": "${theirClan?.attacks ?? 0}/$teamSize",
    "stars": theirStars,
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
  
  DebugUtils.debugWidget("🏅 CWL Widget data created: ${jsonEncode(result)}");
  return jsonEncode(result);
}

// Build error result
String _buildErrorResult() {
  return jsonEncode({
    "updatedAt": "Error at ${DateFormat('HH:mm').format(DateTime.now())}",
    "timeState": "Refresh failed",
    "state": "error",
    "statusIcon": "⚠️",
    "primaryText": "Unable to load war data",
    "secondaryText": "Tap to open ClashKing",
    "colorTheme": "warning"
  });
}
