import { linkChoice } from '../../../core/deep-links/link-parameters';
import { battleStatsLinkSections, worldStatsLinkSections } from './stats-link-sections';

test('the internal items deep link opens Legend statistics', () => {
  expect(linkChoice('items', battleStatsLinkSections, battleStatsLinkSections[0])).toBe('items');
});

test('retired overview statistics deep links fall back to Players', () => {
  expect(linkChoice('overview', worldStatsLinkSections, worldStatsLinkSections[0])).toBe('players');
});
