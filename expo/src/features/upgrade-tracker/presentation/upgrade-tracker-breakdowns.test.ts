import { firstSentences, weightValue } from './upgrade-tracker-breakdowns';

describe('upgrade tracker breakdown formatting', () => {
  test('keeps sentence punctuation while limiting descriptions', () => {
    expect(firstSentences(' First sentence. Second question? Third answer! ', 2)).toBe(
      'First sentence. Second question?',
    );
    expect(firstSentences('One sentence without punctuation', 2)).toBe(
      'One sentence without punctuation',
    );
  });

  test('formats integer and fractional weights without changing their values', () => {
    expect(weightValue(15)).toBe('15');
    expect(weightValue(2.5)).toBe('2.5');
  });
});
