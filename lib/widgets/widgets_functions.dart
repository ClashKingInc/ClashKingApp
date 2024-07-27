import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';

// Get the current war data for a clan
Future<String> checkCurrentWar(String? clanTag) async {
  CurrentWarInfo? currentWarInfo;
  String time = "";
  int multiplicator = 2;

  if (clanTag == null || clanTag.isEmpty) {
    var result = {
      "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
      "timeState": time,
      "state": "notInClan"
    };
    return jsonEncode(result);
  }

  final responseWar = await http.get(
    Uri.parse(
        'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar'),
  );

  final responseCwl = await http.get(
    Uri.parse(
        'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar/leaguegroup'),
  );

  if (responseWar.statusCode == 200) {
    var decodedResponse = jsonDecode(utf8.decode(responseWar.bodyBytes));
    if (decodedResponse["state"] != "notInWar" &&
        decodedResponse["reason"] != "accessDenied") {
      currentWarInfo = CurrentWarInfo.fromJson(
          jsonDecode(utf8.decode(responseWar.bodyBytes)), "war", clanTag, false);
    } else if (decodedResponse["state"] == "notInWar") {
      DateTime now = DateTime.now();
      if (now.day >= 1 && now.day <= 10) {
        if (responseCwl.statusCode == 200) {
          var decodedResponseCwl =
              jsonDecode(utf8.decode(responseCwl.bodyBytes));
          if (decodedResponseCwl.containsKey("state")) {
            CurrentLeagueInfo currentLeagueInfo =
                CurrentLeagueInfo.fromJson(decodedResponseCwl, clanTag);
            CurrentWarInfo? inWar;
            CurrentWarInfo? inPreparation;
            CurrentWarInfo? lastMatchedWarInfo;
            multiplicator = 1;

            for (var round in currentLeagueInfo.rounds) {
              List<CurrentWarInfo> warLeagueInfos = await round.warLeagueInfos;

              for (var warInfo in warLeagueInfos) {
                if (warInfo.clan.tag == clanTag ||
                    warInfo.opponent.tag == clanTag) {
                  lastMatchedWarInfo =
                      warInfo; // Store the last matched warInfo

                  if (warInfo.state == 'inWar') {
                    inWar = warInfo;
                  } else if (warInfo.state == 'preparation') {
                    inPreparation = warInfo;
                  }
                }
              }
            }

            currentWarInfo = inWar ?? inPreparation ?? lastMatchedWarInfo;
          } else {
            var result = {
              "updatedAt":
                  "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
              "timeState": time,
              "state": "error"
            };
            return jsonEncode(result);
          }
        } else {
          var result = {
            "updatedAt":
                "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
            "timeState": time,
            "state": "notInWar"
          };
          return jsonEncode(result);
        }
      } else {
        var result = {
          "updatedAt":
              "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
          "timeState": time,
          "state": "notInWar"
        };
        return jsonEncode(result);
      }
    } else {
      var result = {
        "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
        "timeState": time,
        "state": "notInWar"
      };
      return jsonEncode(result);
    }

    // Accessing time details
    if (currentWarInfo?.state == "preparation") {
      String formattedTime =
          DateFormat('HH:mm').format(currentWarInfo!.startTime.toLocal());
      time = "Starts at $formattedTime";
    } else if (currentWarInfo?.state == "inWar") {
      String formattedTime =
          DateFormat('HH:mm').format(currentWarInfo!.endTime.toLocal());
      time = "Ends at $formattedTime";
    } else if (currentWarInfo?.state == "warEnded") {
      time = "War Ended";
    }

    var result = {
      "state": currentWarInfo?.state ?? "error",
      "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
      "timeState": time,
      "score": currentWarInfo?.state == "preparation"
          ? "-"
          : "${currentWarInfo?.clan.stars} - ${currentWarInfo?.opponent.stars}",
      "clan": {
        "name": currentWarInfo?.clan.name,
        "badgeUrlMedium": currentWarInfo?.clan.badgeUrls.medium,
        "percent":
            "${currentWarInfo?.clan.destructionPercentage.toStringAsFixed(2)}%",
        "attacks":
            "${currentWarInfo?.clan.attacks}/${(currentWarInfo?.teamSize ?? 0) * multiplicator}"
      },
      "opponent": {
        "name": currentWarInfo?.opponent.name,
        "badgeUrlMedium": currentWarInfo?.opponent.badgeUrls.medium,
        "percent":
            "${currentWarInfo?.opponent.destructionPercentage.toStringAsFixed(2)}%",
        "attacks":
            "${currentWarInfo?.opponent.attacks}/${(currentWarInfo?.teamSize ?? 0) * multiplicator}"
      }
    };
    // Convert the Map object to a JSON string
    var jsonString = jsonEncode(result);

    // Return the JSON string
    return jsonString;
  } else {
    var result = {
      "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
      "timeState": time,
      "state": "error"
    };
    return jsonEncode(result);
  }
}
