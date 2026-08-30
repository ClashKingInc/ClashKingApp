import { toIntlLocale, type I18nValue } from '../../../i18n';

export function formatClanLastRefresh(
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

export function clanTypeLabel(type: string, t: I18nValue['t']): string {
  if (type === 'inviteOnly') return t('clanInviteOnly');
  if (type === 'open') return t('clanOpened');
  if (type === 'closed') return t('generalClosed');
  return type;
}
