import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class WarData {
  final List<String> clanTag;
  final int endTime;
  final String playerTag;
  final int attackLimit;
  final int attacksDone;
  final WarStateInfo warStateInfo;

  WarData({
    required this.clanTag,
    required this.endTime,
    required this.playerTag,
    required this.attackLimit,
    required this.attacksDone,
    required this.warStateInfo,
  });

  factory WarData.fromJson(Map<String, dynamic> json, int attackLimit,
      int attacksDone, String playerTag, WarStateInfo warStateInfo) {
    return WarData(
        clanTag: List<String>.from(json['clans'] ?? []),
        endTime: json['time'] ?? 0,
        playerTag: playerTag,
        attackLimit: attackLimit,
        attacksDone: attacksDone,
        warStateInfo: warStateInfo);
  }

  static Future<WarData> fetchWarData(Map<String, dynamic> json) async {
    List<String> clanTags = List<String>.from(json["war"]['clans'] ?? []);
    String playerTag = json['player_tag'] ?? '';
    WarStateInfo warStateInfo = await fetchAttacksByPlayer(playerTag, clanTags);

    int attacksDone = 0;
    if (warStateInfo.currentWarInfo!.fetchClanMemberByTag(playerTag)!.attacks !=
        null) {
      attacksDone = warStateInfo.currentWarInfo!
          .fetchClanMemberByTag(playerTag)!
          .attacks!
          .length;
    }
    int attackLimit = warStateInfo.currentWarInfo!.attacksPerMember;

    return WarData.fromJson(json, attackLimit, attacksDone, playerTag, warStateInfo);
  }

  static Future<WarStateInfo> fetchAttacksByPlayer(
      String playerTag, List<String> clanTag) async {
    WarStateInfo warStateInfo = await fetchToDoWarInfo(clanTag[0], clanTag[1]);
    

    return warStateInfo;
  }

  static Future<WarStateInfo> fetchToDoWarInfo(
      String clanTag, String opponentTag) async {
    try {
      WarStateInfo war =
          await ClanService().fetchCurrentWarInfo(clanTag, false);
      if (war.state == "accessDenied") {
        WarStateInfo warOpponent =
            await ClanService().fetchCurrentWarInfo(opponentTag, true);
        return warOpponent;
      } else {
        return war;
      }
    } catch (e, stackTrace) {
      final hint = Hint.withMap({"clanTag": clanTag});
      Sentry.captureException(e, stackTrace: stackTrace, hint: hint);
      return WarStateInfo(state: "notInWar");
    }
  }
}