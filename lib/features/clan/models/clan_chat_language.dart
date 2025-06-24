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
      id: json["id"],
      name: json["name"],
      languageCode: json["languageCode"],
    );
  }
}
