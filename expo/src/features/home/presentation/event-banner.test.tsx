import { act, fireEvent, render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { createTranslator, I18nProvider } from '../../../i18n';
import { buildHomeBannerItems, HomeEventBanner } from './event-banner';

jest.mock('../../../ui', () => ({
  ...jest.requireActual('../../../ui'),
  useCKAccessibility: () => ({
    reduceMotion: false,
    reduceTransparency: false,
    highContrast: false,
  }),
}));
const t = createTranslator('en');
afterEach(() => jest.useRealTimers());
function event(id: string, date: string) {
  return buildHomeBannerItems(new Date(date), [], t, true).find((item) => item.id === id)!;
}
test.each([
  ['raid', '2026-09-25T06:59:59Z', '2026-09-25T07:00:00.000Z', 'Starts'],
  ['raid', '2026-09-25T07:00:00Z', '2026-09-28T07:00:00.000Z', 'Ends'],
  ['raid', '2026-09-26T12:00:00Z', '2026-09-28T07:00:00.000Z', 'Ends'],
  ['raid', '2026-09-27T12:00:00Z', '2026-09-28T07:00:00.000Z', 'Ends'],
  ['raid', '2026-09-28T06:59:59Z', '2026-09-28T07:00:00.000Z', 'Ends'],
  ['raid', '2026-09-28T07:00:00Z', '2026-10-02T07:00:00.000Z', 'Starts'],
  ['season', '2026-09-25T12:00:00Z', '2026-10-01T08:00:00.000Z', 'Ends'],
  ['season', '2026-10-01T07:59:59Z', '2026-10-01T08:00:00.000Z', 'Ends'],
  ['season', '2026-10-01T08:00:00Z', '2026-11-01T08:00:00.000Z', 'Ends'],
  ['season', '2026-12-31T12:00:00Z', '2027-01-01T08:00:00.000Z', 'Ends'],
  ['season', '2028-02-29T12:00:00Z', '2028-03-01T08:00:00.000Z', 'Ends'],
  ['league-reset', '2026-09-25T12:00:00Z', '2026-10-05T05:00:00.000Z', 'Ends'],
  ['league-reset', '2026-10-05T05:00:00Z', '2026-11-02T05:00:00.000Z', 'Ends'],
  ['clan-games', '2026-09-22T07:59:59Z', '2026-09-22T08:00:00.000Z', 'Starts'],
  ['clan-games', '2026-09-22T08:00:00Z', '2026-09-28T08:00:00.000Z', 'Ends'],
  ['clan-games', '2026-09-28T08:00:00Z', '2026-10-22T08:00:00.000Z', 'Starts'],
  ['cwl', '2026-10-01T07:59:59Z', '2026-10-01T08:00:00.000Z', 'Starts'],
  ['cwl', '2026-10-01T08:00:00Z', '2026-10-03T08:00:00.000Z', 'Ends'],
  ['cwl', '2026-10-03T08:00:00Z', '2026-11-01T08:00:00.000Z', 'Starts'],
])('%s boundary at %s', (id, date, target, prefix) => {
  expect(event(id, date).sortKey?.toISOString()).toBe(target);
  expect(event(id, date).subtitle).toMatch(new RegExp(`^${prefix}`));
  expect(event(id, date).subtitle).not.toContain('-');
});

test('rotates every eight seconds, pauses on touch, and resumes after a full reading interval', async () => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date('2026-09-25T12:00:00Z'));
  const view = await render(
    <I18nProvider locale="en">
      <HomeEventBanner announcements={[]} desktop={false} onOpen={() => {}} />
    </I18nProvider>,
  );
  const color = (index: number) =>
    StyleSheet.flatten(view.getByTestId(`home-event-dot-${index}`).props.style).backgroundColor;
  const selected = color(0);
  await act(async () => jest.advanceTimersByTime(8000));
  expect(color(1)).toBe(selected);
  await fireEvent(view.getByTestId('home-event-carousel'), 'touchStart');
  await act(async () => jest.advanceTimersByTime(16000));
  expect(color(1)).toBe(selected);
  await fireEvent(view.getByTestId('home-event-carousel'), 'touchEnd');
  await act(async () => jest.advanceTimersByTime(7999));
  expect(color(1)).toBe(selected);
  await act(async () => jest.advanceTimersByTime(1));
  expect(color(2)).toBe(selected);
  await view.unmount();
  jest.useRealTimers();
});

test('refreshes countdowns at the UTC boundary without remounting the banner', async () => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date('2026-10-01T07:59:59Z'));
  const view = await render(
    <I18nProvider locale="en">
      <HomeEventBanner announcements={[]} desktop onOpen={() => {}} />
    </I18nProvider>,
  );
  expect(view.getByLabelText('Season ends, Ends in 1m')).toBeTruthy();
  await act(async () => jest.advanceTimersByTime(1000));
  expect(view.getByLabelText('Season ends, Ends in 31d 0h')).toBeTruthy();
  await view.unmount();
});
