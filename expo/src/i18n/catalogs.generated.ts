import catalogaf from './catalogs/af.json';
import catalogar from './catalogs/ar.json';
import catalogca from './catalogs/ca.json';
import catalogcs from './catalogs/cs.json';
import catalogda from './catalogs/da.json';
import catalogde from './catalogs/de.json';
import catalogel from './catalogs/el.json';
import catalogen_GB from './catalogs/en_GB.json';
import catalogen_US from './catalogs/en_US.json';
import catalogen from './catalogs/en.json';
import cataloges_ES from './catalogs/es_ES.json';
import cataloges from './catalogs/es.json';
import catalogfi from './catalogs/fi.json';
import catalogfr from './catalogs/fr.json';
import cataloghe from './catalogs/he.json';
import cataloghi from './catalogs/hi.json';
import cataloghu from './catalogs/hu.json';
import catalogit from './catalogs/it.json';
import catalogja from './catalogs/ja.json';
import catalogko from './catalogs/ko.json';
import catalognl from './catalogs/nl.json';
import catalogno from './catalogs/no.json';
import catalogpl from './catalogs/pl.json';
import catalogpt from './catalogs/pt.json';
import catalogro from './catalogs/ro.json';
import catalogru from './catalogs/ru.json';
import catalogsr from './catalogs/sr.json';
import catalogsv from './catalogs/sv.json';
import catalogtr from './catalogs/tr.json';
import cataloguk from './catalogs/uk.json';
import catalogur from './catalogs/ur.json';
import catalogvi from './catalogs/vi.json';
import catalogzh from './catalogs/zh.json';

export const catalogs = {
  "af": catalogaf,
  "ar": catalogar,
  "ca": catalogca,
  "cs": catalogcs,
  "da": catalogda,
  "de": catalogde,
  "el": catalogel,
  "en_GB": catalogen_GB,
  "en_US": catalogen_US,
  "en": catalogen,
  "es_ES": cataloges_ES,
  "es": cataloges,
  "fi": catalogfi,
  "fr": catalogfr,
  "he": cataloghe,
  "hi": cataloghi,
  "hu": cataloghu,
  "it": catalogit,
  "ja": catalogja,
  "ko": catalogko,
  "nl": catalognl,
  "no": catalogno,
  "pl": catalogpl,
  "pt": catalogpt,
  "ro": catalogro,
  "ru": catalogru,
  "sr": catalogsr,
  "sv": catalogsv,
  "tr": catalogtr,
  "uk": cataloguk,
  "ur": catalogur,
  "vi": catalogvi,
  "zh": catalogzh,
} as const;

export type SupportedLocale = keyof typeof catalogs;
export type MessageKey = keyof typeof catalogs.en;
