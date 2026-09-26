import { render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { WarResultStars } from './war-detail-screen';

test('renders three real star images and mutes only the unearned stars', async () => {
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <WarResultStars stars={1} testID="result-stars" />
      </CKThemeProvider>
    </I18nProvider>,
  );

  expect(view.getByLabelText('Stars: 1 / 3')).toBeTruthy();
  expect(view.getAllByTestId(/result-stars-/)).toHaveLength(3);
  expect(StyleSheet.flatten(view.getByTestId('result-stars-0').props.style).opacity).toBeUndefined();
  expect(StyleSheet.flatten(view.getByTestId('result-stars-1').props.style)).toMatchObject({
    opacity: 0.22,
  });
  expect(StyleSheet.flatten(view.getByTestId('result-stars-2').props.style)).toMatchObject({
    opacity: 0.22,
  });
});
