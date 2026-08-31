import type { SupportedLocale } from './catalogs.generated';

// Flutter 3.27 GlobalMaterialLocalizations.continueButtonLabel values for the
// languages exposed by lib/l10n/locale.dart.
const continueLabels: Readonly<Record<string, string>> = {
  af: 'Gaan voort',
  ar: 'المتابعة',
  ca: 'Continua',
  cs: 'Pokračovat',
  da: 'Fortsæt',
  de: 'Weiter',
  el: 'Συνέχεια',
  en: 'Continue',
  es: 'Continuar',
  fi: 'Jatka',
  fr: 'Continuer',
  he: 'המשך',
  hi: 'जारी रखें',
  hu: 'Folytatás',
  it: 'Continua',
  ja: '続行',
  ko: '계속',
  nl: 'Doorgaan',
  no: 'Fortsett',
  pl: 'Dalej',
  pt: 'Continuar',
  ro: 'Continuați',
  ru: 'Продолжить',
  sr: 'Настави',
  sv: 'Fortsätt',
  tr: 'Devam',
  uk: 'Продовжити',
  ur: 'جاری رکھیں',
  vi: 'Tiếp tục',
  zh: '继续',
};

const backLabels: Readonly<Record<string, string>> = {
  af: 'Terug',
  ar: 'رجوع',
  ca: 'Enrere',
  cs: 'Zpět',
  da: 'Tilbage',
  de: 'Zurück',
  el: 'Πίσω',
  en: 'Back',
  es: 'Atrás',
  fi: 'Takaisin',
  fr: 'Retour',
  he: 'הקודם',
  hi: 'वापस जाएं',
  hu: 'Vissza',
  it: 'Indietro',
  ja: '戻る',
  ko: '뒤로',
  nl: 'Terug',
  no: 'Tilbake',
  pl: 'Wstecz',
  pt: 'Voltar',
  ro: 'Înapoi',
  ru: 'Назад',
  sr: 'Назад',
  sv: 'Tillbaka',
  tr: 'Geri',
  uk: 'Назад',
  ur: 'پیچھے',
  vi: 'Quay lại',
  zh: '返回',
};

const monthTooltips: Readonly<Record<string, readonly [string, string]>> = {
  af: ['Vorige maand', 'Volgende maand'],
  ar: ['الشهر السابق', 'الشهر التالي'],
  ca: ['Mes anterior', 'Mes següent'],
  cs: ['Předchozí měsíc', 'Další měsíc'],
  da: ['Forrige måned', 'Næste måned'],
  de: ['Vorheriger Monat', 'Nächster Monat'],
  el: ['Προηγούμενος μήνας', 'Επόμενος μήνας'],
  en: ['Previous month', 'Next month'],
  es: ['Mes anterior', 'Mes siguiente'],
  fi: ['Edellinen kuukausi', 'Seuraava kuukausi'],
  fr: ['Mois précédent', 'Mois suivant'],
  he: ['החודש הקודם', 'החודש הבא'],
  hi: ['पिछला महीना', 'अगला महीना'],
  hu: ['Előző hónap', 'Következő hónap'],
  it: ['Mese precedente', 'Mese successivo'],
  ja: ['前月', '来月'],
  ko: ['지난달', '다음 달'],
  nl: ['Vorige maand', 'Volgende maand'],
  no: ['Forrige måned', 'Neste måned'],
  pl: ['Poprzedni miesiąc', 'Następny miesiąc'],
  pt: ['Mês anterior', 'Próximo mês'],
  ro: ['Luna trecută', 'Luna viitoare'],
  ru: ['Предыдущий месяц', 'Следующий месяц'],
  sr: ['Претходни месец', 'Следећи месец'],
  sv: ['Föregående månad', 'Nästa månad'],
  tr: ['Önceki ay', 'Gelecek ay'],
  uk: ['Попередній місяць', 'Наступний місяць'],
  ur: ['پچھلا مہینہ', 'اگلا مہینہ'],
  vi: ['Tháng trước', 'Tháng sau'],
  zh: ['上个月', '下个月'],
};
// Flutter 3.27.3 GlobalMaterialLocalizations previousPageTooltip/nextPageTooltip.
const pageTooltips: Readonly<Record<string, readonly [string, string]>> = {
  af: ['Vorige bladsy', 'Volgende bladsy'],
  ar: ['الصفحة السابقة', 'الصفحة التالية'],
  ca: ['Pàgina anterior', 'Pàgina següent'],
  cs: ['Předchozí stránka', 'Další stránka'],
  da: ['Forrige side', 'Næste side'],
  de: ['Vorherige Seite', 'Nächste Seite'],
  el: ['Προηγούμενη σελίδα', 'Επόμενη σελίδα'],
  en: ['Previous page', 'Next page'],
  es: ['Página anterior', 'Página siguiente'],
  fi: ['Edellinen sivu', 'Seuraava sivu'],
  fr: ['Page précédente', 'Page suivante'],
  he: ['הדף הקודם', 'הדף הבא'],
  hi: ['पिछला पेज', 'अगला पेज'],
  hu: ['Előző oldal', 'Következő oldal'],
  it: ['Pagina precedente', 'Pagina successiva'],
  ja: ['前のページ', '次のページ'],
  ko: ['이전 페이지', '다음 페이지'],
  nl: ['Vorige pagina', 'Volgende pagina'],
  no: ['Forrige side', 'Neste side'],
  pl: ['Poprzednia strona', 'Następna strona'],
  pt: ['Página anterior', 'Próxima página'],
  ro: ['Pagina anterioară', 'Pagina următoare'],
  ru: ['Предыдущая страница', 'Следующая страница'],
  sr: ['Претходна страница', 'Следећа страница'],
  sv: ['Föregående sida', 'Nästa sida'],
  tr: ['Önceki sayfa', 'Sonraki sayfa'],
  uk: ['Попередня сторінка', 'Наступна сторінка'],
  ur: ['گزشتہ صفحہ', 'اگلا صفحہ'],
  vi: ['Trang trước', 'Trang tiếp theo'],
  zh: ['上一页', '下一页'],
};
const closeLabels: Readonly<Record<string, string>> = {
  af: 'Maak toe',
  ar: 'الإغلاق',
  ca: 'Tanca',
  cs: 'Zavřít',
  da: 'Luk',
  de: 'Schließen',
  el: 'Κλείσιμο',
  en: 'Close',
  es: 'Cerrar',
  fi: 'Sulje',
  fr: 'Fermer',
  he: 'סגירה',
  hi: 'बंद करें',
  hu: 'Bezárás',
  it: 'Chiudi',
  ja: '閉じる',
  ko: '닫기',
  nl: 'Sluiten',
  no: 'Lukk',
  pl: 'Zamknij',
  pt: 'Fechar',
  ro: 'Închideți',
  ru: 'Закрыть',
  sr: 'Затвори',
  sv: 'Stäng',
  tr: 'Kapat',
  uk: 'Закрити',
  ur: 'بند کریں',
  vi: 'Đóng',
  zh: '关闭',
};

export function materialContinueLabel(locale: SupportedLocale): string {
  return continueLabels[locale.split('_', 1)[0]!] ?? continueLabels.en!;
}

export function materialBackLabel(locale: SupportedLocale): string {
  return backLabels[locale.split('_', 1)[0]!] ?? backLabels.en!;
}

export function materialPreviousMonthTooltip(locale: SupportedLocale): string {
  return (monthTooltips[locale.split('_', 1)[0]!] ?? monthTooltips.en!)[0];
}

export function materialNextMonthTooltip(locale: SupportedLocale): string {
  return (monthTooltips[locale.split('_', 1)[0]!] ?? monthTooltips.en!)[1];
}
export function materialPreviousPageTooltip(locale: SupportedLocale): string {
  return (pageTooltips[locale.split('_', 1)[0]!] ?? pageTooltips.en!)[0];
}

export function materialNextPageTooltip(locale: SupportedLocale): string {
  return (pageTooltips[locale.split('_', 1)[0]!] ?? pageTooltips.en!)[1];
}
export function materialCloseLabel(locale: SupportedLocale): string {
  return closeLabels[locale.split('_', 1)[0]!] ?? closeLabels.en!;
}
