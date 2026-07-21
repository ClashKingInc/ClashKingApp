class CocAccountLink {
  CocAccountLink._({
    required this.playerTag,
    required this.isVerified,
    required this.hidden,
    required Map<String, dynamic> json,
  }) : _json = json;

  final String playerTag;
  final bool isVerified;
  final bool hidden;
  final Map<String, dynamic> _json;

  factory CocAccountLink.fromJson(Map<String, dynamic> json) {
    final playerTag = json['player_tag'];
    if (playerTag is! String || playerTag.trim().isEmpty) {
      throw const FormatException('Link account is missing player_tag');
    }

    final hidden = json['hidden'];
    if (hidden is! bool) {
      throw const FormatException('Link account hidden must be a bool');
    }

    final isVerified = json['is_verified'];
    if (isVerified != null && isVerified is! bool) {
      throw const FormatException('Link account is_verified must be a bool');
    }

    return CocAccountLink._(
      playerTag: playerTag,
      isVerified: isVerified as bool? ?? false,
      hidden: hidden,
      json: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ..._json,
      'player_tag': playerTag,
      'is_verified': isVerified,
      'hidden': hidden,
    };
  }
}
