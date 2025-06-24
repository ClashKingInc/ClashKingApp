class LocaleInfo {
  final String languageCode;
  final String languageName;
  final String flagUrl;
  final String? scriptCode;
  final String? countryCode;

  LocaleInfo({
    required this.languageCode,
    required this.languageName,
    required this.flagUrl,
    this.scriptCode,
    this.countryCode,
  });
}

final List<LocaleInfo> supportedLocales = [
  LocaleInfo(
      languageCode: 'af',
      languageName: 'Afrikaans',
      flagUrl: 'https://flagcdn.com/w320/za.png' // South Africa flag
      ),
  LocaleInfo(
      languageCode: 'ar',
      languageName: 'العربية',
      flagUrl: 'https://flagcdn.com/w320/sa.png' // Saudi Arabia flag
      ),
  LocaleInfo(
      languageCode: 'ca',
      languageName: 'Català',
      flagUrl: 'https://flagcdn.com/w320/es.png' // Spanish flag
      ),
  LocaleInfo(
      languageCode: 'cs',
      languageName: 'Čeština',
      flagUrl: 'https://flagcdn.com/w320/cz.png' // Czech flag
      ),
  LocaleInfo(
      languageCode: 'da',
      languageName: 'Dansk',
      flagUrl: 'https://flagcdn.com/w320/dk.png' // Denmark flag
      ),
  LocaleInfo(
      languageCode: 'de',
      languageName: 'Deutsch',
      flagUrl: 'https://flagcdn.com/w320/de.png' // Germany flag
      ),
  LocaleInfo(
      languageCode: 'el',
      languageName: 'Ελληνικά',
      flagUrl: 'https://flagcdn.com/w320/gr.png' // Greece flag
      ),
  LocaleInfo(
      languageCode: 'en',
      countryCode: 'GB',
      languageName: 'English (UK)',
      flagUrl: 'https://flagcdn.com/w320/gb.png' // UK flag
      ),
  LocaleInfo(
      languageCode: 'en',
      countryCode: 'US',
      languageName: 'English (US)',
      flagUrl: 'https://flagcdn.com/w320/us.png' // US flag
      ),
  LocaleInfo(
      languageCode: 'es',
      languageName: 'Español',
      flagUrl: 'https://flagcdn.com/w320/es.png' // French flag
      ),
  LocaleInfo(
      languageCode: 'fi',
      languageName: 'Suomi',
      flagUrl: 'https://flagcdn.com/w320/fi.png' // Finland flag
      ),
  LocaleInfo(
      languageCode: 'fr',
      languageName: 'Français',
      flagUrl: 'https://flagcdn.com/w320/fr.png' // French flag
      ),
  LocaleInfo(
      languageCode: 'he',
      languageName: 'עברית',
      flagUrl: 'https://flagcdn.com/w320/il.png'),
  LocaleInfo(
      languageCode: 'hu',
      languageName: 'Magyar',
      flagUrl: 'https://flagcdn.com/w320/hu.png' // Hungary flag
      ),
  LocaleInfo(
      languageCode: 'it',
      languageName: 'Italiano',
      flagUrl: 'https://flagcdn.com/w320/it.png' // Italy flag
      ),
  LocaleInfo(
      languageCode: 'ja',
      languageName: '日本語',
      flagUrl: 'https://flagcdn.com/w320/jp.png' // Japan flag
      ),
  LocaleInfo(
      languageCode: 'ko',
      languageName: '한국어',
      flagUrl: 'https://flagcdn.com/w320/kr.png' // South Korea flag
      ),
  LocaleInfo(
      languageCode: 'nl',
      languageName: 'Nederlands',
      flagUrl: 'https://flagcdn.com/w320/nl.png' // Netherlands flag
      ),
  LocaleInfo(
      languageCode: 'no',
      languageName: 'Norsk',
      flagUrl: 'https://flagcdn.com/w320/no.png' // Norway flag
      ),
  LocaleInfo(
      languageCode: 'pl',
      languageName: 'Polski',
      flagUrl: 'https://flagcdn.com/w320/pl.png' // Poland flag
      ),
  LocaleInfo(
      languageCode: 'pt',
      languageName: 'Português',
      flagUrl: 'https://flagcdn.com/w320/pt.png' // Portugal flag
      ),
  LocaleInfo(
      languageCode: 'ro',
      languageName: 'Română',
      flagUrl: 'https://flagcdn.com/w320/ro.png' // Romania flag
      ),
  LocaleInfo(
      languageCode: 'ru',
      languageName: 'Русский',
      flagUrl: 'https://flagcdn.com/w320/ru.png' // Russia flag
      ),
  LocaleInfo(
      languageCode: 'sr',
      languageName: 'Српски',
      flagUrl: 'https://flagcdn.com/w320/rs.png' // Serbia flag
      ),
  LocaleInfo(
      languageCode: 'sv',
      languageName: 'Svenska',
      flagUrl: 'https://flagcdn.com/w320/se.png' // Sweden flag
      ),
  LocaleInfo(
      languageCode: 'tr',
      languageName: 'Türkçe',
      flagUrl: 'https://flagcdn.com/w320/tr.png' // Turkey flag
      ),
  LocaleInfo(
      languageCode: 'uk',
      languageName: 'Українська',
      flagUrl: 'https://flagcdn.com/w320/ua.png' // Ukraine flag
      ),
  LocaleInfo(
      languageCode: 'vi',
      languageName: 'Tiếng Việt',
      flagUrl: 'https://flagcdn.com/w320/vn.png' // Vietnam flag
      ),
  LocaleInfo(
      languageCode: 'zh',
      languageName: '中文',
      flagUrl: 'https://flagcdn.com/w320/cn.png' // China flag
      ),
];
