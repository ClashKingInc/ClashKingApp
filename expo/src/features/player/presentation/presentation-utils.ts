import { toIntlLocale, type I18nValue } from '../../../i18n';
import { ImageAssets } from '../../../core/assets/image-assets';
import type { Player } from '../models/player';

export function formatPlayerActivity(value: Date, t: I18nValue['t'], now = new Date()): string {
  if (value.getTime() === 0 || value > now) return t('todoLastActiveUnavailable');
  const seconds = Math.floor((now.getTime() - value.getTime()) / 1000);
  if (seconds < 60) return t('timeJustNow');
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60)
    return minutes === 1
      ? t('timeMinuteAgo', { minute: minutes })
      : t('timeMinutesAgo', { minutes });
  const hours = Math.floor(minutes / 60);
  if (hours < 24)
    return hours === 1 ? t('timeHourAgo', { hour: hours }) : t('timeHoursAgo', { hours });
  const days = Math.floor(hours / 24);
  return days === 1 ? t('timeDayAgo', { day: days }) : t('timeDaysAgo', { days });
}

export function formatLastRefresh(
  value: Date,
  t: I18nValue['t'],
  locale: I18nValue['locale'],
  now = new Date(),
): string {
  const minutes = Math.floor((now.getTime() - value.getTime()) / 60_000);
  if (minutes < 1) return t('timeJustNow');
  if (minutes < 60) return t('timeMinutesAgo', { minutes });
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return t('timeHoursAgo', { hours });
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(value);
}

export function wrapActivityCaption(value: string): string {
  const trimmed = value.trim();
  const lastSpace = trimmed.lastIndexOf(' ');
  return lastSpace <= 0
    ? trimmed
    : `${trimmed.slice(0, lastSpace)}\n${trimmed.slice(lastSpace + 1)}`;
}

export function playerClanPresentation(player: Player): { label: string; imageUrl: string } {
  const clan =
    player.clan && typeof player.clan === 'object'
      ? (player.clan as {
          name?: unknown;
          badgeUrls?: { small?: unknown; medium?: unknown };
        })
      : null;
  const linkedName = typeof clan?.name === 'string' ? clan.name : '';
  const linkedSmall = typeof clan?.badgeUrls?.small === 'string' ? clan.badgeUrls.small : '';
  const linkedMedium = typeof clan?.badgeUrls?.medium === 'string' ? clan.badgeUrls.medium : '';
  return {
    label: linkedName || player.clanOverview.name,
    imageUrl:
      linkedSmall ||
      linkedMedium ||
      player.clanOverview.badgeUrls.small ||
      player.clanOverview.badgeUrls.medium ||
      ImageAssets.clanCastle,
  };
}
