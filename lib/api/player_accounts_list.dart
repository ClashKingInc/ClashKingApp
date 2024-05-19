import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/api/player_account_info.dart';

class PlayerAccounts {
  final List<PlayerAccountInfo> playerAccountInfo;
  final List<ClanInfo>? clanInfo;
  final List<CurrentWarInfo> warInfo;

  PlayerAccounts(
      {required this.playerAccountInfo,
      required this.clanInfo,
      required this.warInfo});

  factory PlayerAccounts.fromJson(List<dynamic> json) {
    List<PlayerAccountInfo> playerAccounts = [];
    List<ClanInfo>? clanInfo = [];
    List<CurrentWarInfo> warInfo = [];

    for (var item in json) {
      playerAccounts.add(PlayerAccountInfo.fromJson(item));
      if (!item['clan'] == null) {
        ClanInfo clan = ClanInfo.fromJson(item['clan']);
        clanInfo!.add(clan);
        CurrentWarInfo war =
            CurrentWarInfo.fromJson(item['clan']['currentWar'], "war");
        warInfo.add(war);
      } else {
        clanInfo = null;
      }
    }

    return PlayerAccounts(
        playerAccountInfo: playerAccounts,
        clanInfo: clanInfo,
        warInfo: warInfo);
  }
}
