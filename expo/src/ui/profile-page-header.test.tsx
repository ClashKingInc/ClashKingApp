import { fireEvent, render } from '@testing-library/react-native';
import { Pressable, StyleSheet } from 'react-native';

import { I18nProvider } from '../i18n';
import { CKThemeProvider } from './theme';
import { CKText } from './text';
import { ProfilePageHeader } from './profile-page-header';
import { ProfileStatChip } from './profile-stat-chip';

test('profile header shares Player Info art treatment while sizing to its content', async () => {
  const onBack = jest.fn();
  const onHistory = jest.fn();
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <ProfilePageHeader
          title="A long localized statistics section name that may wrap"
          imageUrl="https://assets.clashk.ing/leagues/league-tier/legend.png"
          backgroundUrl="https://assets.clashk.ing/landscape/example.png"
          onBack={onBack}
          backLabel="Back"
          safeTop={24}
          actions={
            <Pressable accessibilityRole="button" accessibilityLabel="History" onPress={onHistory}>
              <CKText>History</CKText>
            </Pressable>
          }
        >
          <ProfileStatChip label="Date range" value="1 Jul – 30 Jul 2026" />
        </ProfilePageHeader>
      </CKThemeProvider>
    </I18nProvider>,
  );

  const header = view.getByTestId('profile-page-header');
  const headerStyle = StyleSheet.flatten(header.props.style);
  expect(headerStyle.paddingTop).toBe(24);
  expect(headerStyle.height).toBeUndefined();
  expect(
    StyleSheet.flatten(view.getByTestId('profile-page-header-image').props.style),
  ).toMatchObject({ width: 64, height: 64 });
  expect(view.getByTestId('profile-page-header-backdrop').props.pointerEvents).toBe('none');
  expect(
    view.getByText('A long localized statistics section name that may wrap').props.numberOfLines,
  ).toBeUndefined();
  expect(view.getByLabelText('Date range: 1 Jul – 30 Jul 2026')).toBeTruthy();
  await fireEvent.press(view.getByRole('button', { name: 'Back' }));
  await fireEvent.press(view.getByRole('button', { name: 'History' }));
  expect(onBack).toHaveBeenCalledTimes(1);
  expect(onHistory).toHaveBeenCalledTimes(1);
  await view.unmount();
});

test('shared Player Info stat chip keeps locale formatting and wraps long values', async () => {
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <ProfileStatChip label="War stars" value={12345} />
        <ProfileStatChip
          label="Date range"
          value="A long date range that should be allowed to wrap"
        />
      </CKThemeProvider>
    </I18nProvider>,
  );
  expect(view.getByLabelText('War stars: 12345')).toBeTruthy();
  expect(view.getByText('12,345')).toBeTruthy();
  expect(
    view.getByLabelText('Date range: A long date range that should be allowed to wrap'),
  ).toBeTruthy();
  await view.unmount();
});
