import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';

class WarInfo {
  final String? tag;
  final String state;
  final int? teamSize;
  final int? attacksPerMember;
  final WarClan? clan;
  final WarClan? opponent;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? preparationStartTime;
  final String? warType;

  WarInfo({
    this.tag,
    required this.state,
    this.teamSize,
    this.attacksPerMember,
    this.clan,
    this.opponent,
    this.startTime,
    this.endTime,
    this.preparationStartTime,
    this.warType,
  });

  factory WarInfo.fromJson(Map<String, dynamic> json) {
    return WarInfo(
      tag: json['war_tag'],
      state: json['state'] ?? 'unknown',
      teamSize: json['teamSize'],
      attacksPerMember: json['attacksPerMember'],
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      preparationStartTime: json['preparationStartTime'] != null
          ? DateTime.parse(json['preparationStartTime'])
          : null,
      warType: json['warType'],
      clan: json['clan'] != null ? WarClan.fromJson(json['clan']) : null,
      opponent:
          json['opponent'] != null ? WarClan.fromJson(json['opponent']) : null,
    );
  }

  /// Return a WarMember from either clan or opponent by tag
  WarMember? getMemberByTag(String tag) {
    try {
      return (clan?.members ?? []).firstWhere((m) => m.tag == tag,
          orElse: () =>
              (opponent?.members ?? []).firstWhere((m) => m.tag == tag));
    } catch (e) {
      return null;
    }
  }

  /// Get the TH level from a tag
  int? getTownhallLevelByTag(String tag) {
    return getMemberByTag(tag)?.townhallLevel;
  }

  /// Get the map position from a tag
  int? getMapPositionByTag(String tag) {
    return getMemberByTag(tag)?.mapPosition;
  }

  /// Get the name from a tag
  String? getNameByTag(String tag) {
    return getMemberByTag(tag)?.name;
  }
}
