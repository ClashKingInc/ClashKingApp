import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class WarData {
  final List<String> clanTag;
  final int endTime;
  final String playerTag;
  final int attackLimit;
  final int attacksDone;

  WarData({
    required this.clanTag,
    required this.endTime,
    required this.playerTag,
    required this.attackLimit,
    required this.attacksDone,
  });

  factory WarData.fromJson(Map<String, dynamic> json, int attackLimit,
      int attacksDone, String playerTag) {
    return WarData(
        clanTag: List<String>.from(json['clans'] ?? []),
        endTime: json['time'] ?? 0,
        playerTag: playerTag,
        attackLimit: attackLimit,
        attacksDone: attacksDone);
  }

  static Future<WarData> fetchWarData(Map<String, dynamic> json) async {
    List<String> clanTags = List<String>.from(json["war"]['clans'] ?? []);
    String playerTag = json['player_tag'] ?? '';
    Map<String, int> value = await fetchAttacksByPlayer(playerTag, clanTags);
    int attackLimit = value['attack_limit'] ?? 0;
    int attacksDone = value['attacks_done'] ?? 0;

    return WarData.fromJson(json, attackLimit, attacksDone, playerTag);
  }

  static Future<Map<String, int>> fetchAttacksByPlayer(
      String playerTag, List<String> clanTag) async {
    WarStateInfo warStateInfo = await fetchToDoWarInfo(clanTag[0], clanTag[1]);
    int attacksDone = 0;
    if (warStateInfo.currentWarInfo!.fetchClanMemberByTag(playerTag)!.attacks !=
        null) {
      attacksDone = warStateInfo.currentWarInfo!
          .fetchClanMemberByTag(playerTag)!
          .attacks!
          .length;
    }
    int attackLimit = warStateInfo.currentWarInfo!.attacksPerMember;

    return {"attacks_done": attacksDone, "attack_limit": attackLimit};
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
