import {
  detailLevelFromSliderPosition,
  detailSliderFractionFromPosition,
  firstSentences,
  weightValue,
} from './upgrade-tracker-breakdowns';

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

  test('tracks the finger continuously while selecting the nearest level', () => {
    expect(detailSliderFractionFromPosition(37.5, 100)).toBe(0.375);
    expect(detailLevelFromSliderPosition(37.5, 100, 1, 27)).toBe(11);
  });

  test('keeps slider positions and levels inside their bounds', () => {
    expect(detailSliderFractionFromPosition(-20, 100)).toBe(0);
    expect(detailSliderFractionFromPosition(120, 100)).toBe(1);
    expect(detailLevelFromSliderPosition(-20, 100, 1, 27)).toBe(1);
    expect(detailLevelFromSliderPosition(120, 100, 1, 27)).toBe(27);
  });
});
