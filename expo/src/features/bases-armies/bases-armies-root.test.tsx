import { render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import { BasesArmiesRoot } from './bases-armies-root';

test('matches the Flutter Discord-sync preview sections', async () => {
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <BasesArmiesRoot onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getByText('Bases & Armies')).toBeTruthy();
  expect(view.getByText('Bot sync target')).toBeTruthy();
  expect(view.getByText('War base slots')).toBeTruthy();
  expect(view.getByText('Legend base slots')).toBeTruthy();
  expect(view.getByText('Army links')).toBeTruthy();
  expect(view.getAllByText('sync')).toHaveLength(3);
});
