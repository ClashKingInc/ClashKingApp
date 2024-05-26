class LocaleInfo {
  final String languageCode;
  final String languageName;
  final String flagUrl;

  LocaleInfo({required this.languageCode, required this.languageName, required this.flagUrl});
}


final List<LocaleInfo> supportedLocales = [
  LocaleInfo(
    languageCode: 'en',
    languageName: 'English',
    flagUrl: 'https://flagcdn.com/w320/gb.png' // UK flag
  ),
  LocaleInfo(
    languageCode: 'fr',
    languageName: 'Français',
    flagUrl: 'https://flagcdn.com/w320/fr.png' // French flag
  ),
];
