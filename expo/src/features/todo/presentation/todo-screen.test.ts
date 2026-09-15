import { createTranslator } from '../../../i18n';
import { formatProgressRingLabel, formatTimerRemaining } from './todo-screen';

const t = createTranslator('en');

describe('Todo timer parity', () => {
  test.each([
    [26 * 60 * 60 * 1000, '1d 2h'],
    [(3 * 60 + 7) * 60 * 1000, '3h 7m'],
    [42 * 60 * 1000, '42m'],
    [-1, '0m'],
  ])('formats %i milliseconds using Flutter duration branches', (milliseconds, expected) => {
    expect(formatTimerRemaining(milliseconds, t)).toBe(expected);
  });
});

describe('Todo progress ring', () => {
  test.each([
    [0, '0%'],
    [0.004, '0%'],
    [0.42, '42%'],
    [1, '100%'],
    [Number.NaN, '0%'],
    [Number.POSITIVE_INFINITY, '0%'],
  ])('formats %p as %s', (progress, expected) => {
    expect(formatProgressRingLabel(progress)).toBe(expected);
  });
});
