import { linkChoice } from '../../../core/deep-links/link-parameters';
import { battleStatsLinkSections } from './stats-link-sections';

test('retired item statistics deep links fall back to Ranked', () => {
  expect(linkChoice('items', battleStatsLinkSections, battleStatsLinkSections[0])).toBe('ranked');
});
