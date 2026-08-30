import { render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { CwlRankingHistoryEntry } from '../models';
import { CwlCard } from './clan-statistics-tabs';

describe('clan CWL history card parity', () => {
  it('keeps the compact Flutter hierarchy and season metrics', async () => {
    const entry = new CwlRankingHistoryEntry(
      '2026-08-15',
      12,
      'Master League II',
      3,
      257,
      94.37,
      5,
      1,
      2,
      true,
    );
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <CwlCard entry={entry} movement="up" locale="en" />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(
      StyleSheet.flatten(screen.getByTestId('clan-cwl-card-2026-08-15').props.style).height,
    ).toBe(74);
    expect(screen.getByTestId('clan-cwl-main')).toBeTruthy();
    expect(screen.getByTestId('clan-cwl-side')).toBeTruthy();
    expect(screen.getByText('Master League II')).toBeTruthy();
    expect(screen.getByText('#3')).toBeTruthy();
    expect(screen.getByText('5W')).toBeTruthy();
    expect(screen.getByText('1T')).toBeTruthy();
    expect(screen.getByText('2L')).toBeTruthy();
    expect(screen.getByText('August 2026')).toBeTruthy();
    expect(screen.getByText('257')).toBeTruthy();
    expect(screen.getByText('94.37')).toBeTruthy();
    expect(screen.getByLabelText('Promoted')).toBeTruthy();
    const shellStyle = StyleSheet.flatten(
      screen.getByTestId('clan-cwl-card-2026-08-15').props.style,
    );
    expect(shellStyle).toMatchObject({
      height: 74,
      padding: 0.8,
      borderRadius: 16,
      backgroundColor: 'transparent',
      overflow: 'hidden',
      shadowColor: '#000000',
      shadowOpacity: 0.16,
      shadowRadius: 10,
      shadowOffset: { width: 0, height: 4 },
    });
    expect(
      StyleSheet.flatten(screen.getByTestId('clan-cwl-card-inner-2026-08-15').props.style),
    ).toMatchObject({
      flex: 1,
      borderRadius: 15.2,
      overflow: 'hidden',
    });
    const shell = screen.getByTestId('clan-cwl-card-shell-2026-08-15');
    expect(shell.props.width).toBeUndefined();
    expect(shell.props.height).toBeUndefined();
    expect(StyleSheet.flatten(shell.props.style)).toMatchObject({
      position: 'absolute',
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    });
    const gradient = screen.getByTestId('clan-cwl-card-gradient-2026-08-15');
    expect(gradient.props.width).toBeUndefined();
    expect(gradient.props.height).toBeUndefined();
    expect(StyleSheet.flatten(gradient.props.style)).toMatchObject({
      position: 'absolute',
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    });
    const highlight = screen.getByTestId('clan-cwl-card-highlight-2026-08-15');
    expect(StyleSheet.flatten(highlight.props.style)).toMatchObject({
      position: 'absolute',
      top: 0,
      left: 12,
      right: 54,
      height: 1.1,
    });
  });
});
