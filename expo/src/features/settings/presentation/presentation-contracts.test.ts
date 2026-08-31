import { createTranslator } from '../../../i18n';
import { FAQ_ENTRIES, filterFaqEntries } from './faq-screen';
import { timingLabel } from './notification-settings-screen';
import { privacyColumnCount } from './privacy-controls-screen';
import { isDesktopSettings } from './settings-screen';

describe('settings presentation contracts', () => {
  it('keeps Flutter web-only responsive breakpoints', () => {
    expect(isDesktopSettings('web', 899)).toBe(false);
    expect(isDesktopSettings('web', 900)).toBe(true);
    expect(isDesktopSettings('ios', 1200)).toBe(false);
    expect(privacyColumnCount('web', 900)).toBe(2);
    expect(privacyColumnCount('ios', 1200)).toBe(1);
  });

  it('formats reminder timings and preserves the complete FAQ inventory', () => {
    const t = createTranslator('en');
    expect(timingLabel(t, 15)).toBe('15 minutes before');
    expect(timingLabel(t, 60)).toBe('1 hour before');
    expect(timingLabel(t, 2820)).toBe('47 hours before');
    const tFr = createTranslator('fr');
    expect(timingLabel(tFr, 15)).toBe('15 minutes avant');
    expect(timingLabel(tFr, 60)).toBe('1 heure avant');
    expect(FAQ_ENTRIES).toHaveLength(15);
    const translated = (key: string) => (key === 'faqNotificationsAnswer' ? 'Push alerts' : key);
    expect(
      filterFaqEntries(FAQ_ENTRIES, 'push alerts', translated as never).map(({ id }) => id),
    ).toEqual(['notifications']);
  });
});
