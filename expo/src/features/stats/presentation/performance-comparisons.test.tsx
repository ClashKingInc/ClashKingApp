import { render } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { StatsBreakdown, StatsMetrics, StatsSection } from '../models';
import { PerformanceComparisons } from './performance-comparisons';

function comparison(key: string, sampleSize: number, threeStarRate: number) {
  return new StatsBreakdown(
    key,
    new StatsMetrics(sampleSize > 0, sampleSize, 0, 0, 0, 0, 0, threeStarRate, []),
  );
}

test('war comparison keeps all Town Halls visible and distinguishes missing data from zero', async () => {
  const comparisons = Array.from({ length: 18 }, (_, index) =>
    comparison(`TH${index + 1}`, index === 0 ? 0 : 1000, index / 100),
  );
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <PerformanceComparisons section={StatsSection.war} comparisons={comparisons} />
      </CKThemeProvider>
    </I18nProvider>,
  );
  expect(view.getByTestId('performance-comparison-TH1')).toBeTruthy();
  expect(view.getByTestId('performance-comparison-TH18')).toBeTruthy();
  expect(view.getByLabelText('TH1, —, 0 Attacks')).toBeTruthy();
  expect(view.getByLabelText('TH18, 17%, 1,000 Attacks')).toBeTruthy();
});
