import { linkChoice } from '../../../core/deep-links/link-parameters';
import { battleStatsLinkSections, worldStatsLinkSections } from './stats-link-sections';

test('retired item statistics deep links fall back to Ranked', () => {
  expect(linkChoice('items', battleStatsLinkSections, battleStatsLinkSections[0])).toBe('ranked');
});

test('retired overview statistics deep links fall back to Players', () => {
  expect(linkChoice('overview', worldStatsLinkSections, worldStatsLinkSections[0])).toBe('players');
});
