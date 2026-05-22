class ClanChatLanguage {
  final int id;
  final String name;
  final String languageCode;

  ClanChatLanguage({
    required this.id,
    required this.name,
    required this.languageCode,
  });

  factory ClanChatLanguage.fromJson(Map<String, dynamic> json) {
    return ClanChatLanguage(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      languageCode: json["languageCode"]?.toString() ?? "",
    );
  }
}
