import { describe, expect, it, jest } from '@jest/globals';
import { act, fireEvent, render } from '@testing-library/react-native';
import { createElement, type ReactElement } from 'react';
import { StyleSheet, Text } from 'react-native';
import { Search } from 'lucide-react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { EmptyState, ErrorState, Snackbar } from '../feedback';
import { tintIcon } from '../icon-slot';
import { ProfileTabs } from '../profile-tabs';
import { SearchSortBar } from '../search-sort';
import { SelectionPicker, SelectionPickerModal } from '../selection-picker';
import { CKText } from '../text';
import { CKThemeProvider } from '../theme';

jest.mock('expo-glass-effect', () => {
  const { View } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    GlassView: View,
    isGlassEffectAPIAvailable: () => false,
    isLiquidGlassAvailable: () => false,
  };
});

function renderWithTheme(node: ReactElement) {
  return render(<CKThemeProvider preference="dark">{node}</CKThemeProvider>);
}

function renderPickerWithTheme(node: ReactElement) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <CKThemeProvider preference="dark">{node}</CKThemeProvider>
    </SafeAreaProvider>,
  );
}

describe('shared UI semantics', () => {
  it('allows the uncapped platform text scaling used by Flutter', async () => {
    const screen = await renderWithTheme(<CKText>Scalable</CKText>);
    const text = screen.getByText('Scalable');

    expect(text.props.allowFontScaling).toBe(true);
    expect(text.props.maxFontSizeMultiplier).toBeUndefined();
  });

  it('exposes empty and retry states to assistive technology', async () => {
    const retry = jest.fn();
    const empty = await renderWithTheme(<EmptyState title="No wars" body="Check back later" />);
    expect(empty.getByText('No wars')).toBeTruthy();
    expect(empty.getByText('Check back later')).toBeTruthy();
    expect(empty.getByTestId('empty-state-sticker')).toBeTruthy();
    await empty.unmount();

    const error = await renderWithTheme(
      <ErrorState title="Could not load" actionLabel="Retry" onAction={retry} />,
    );
    await fireEvent.press(error.getByRole('button', { name: 'Retry' }));
    expect(retry).toHaveBeenCalledTimes(1);
  });

  it('uses peer tabs for three destinations and a selector above three', async () => {
    const onSelect = jest.fn();
    const tabs = [
      { key: 'one', label: 'One' },
      { key: 'two', label: 'Two' },
      { key: 'three', label: 'Three' },
    ];
    const peers = await renderWithTheme(
      <ProfileTabs tabs={tabs} selectedKey="one" onSelect={onSelect} />,
    );
    await fireEvent.press(peers.getByRole('tab', { name: 'Two' }));
    expect(onSelect).toHaveBeenCalledWith('two');
    await peers.unmount();

    const open = jest.fn();
    const overflow = await renderWithTheme(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <ProfileTabs
          tabs={[...tabs, { key: 'four', label: 'Four' }]}
          selectedKey="three"
          onSelect={onSelect}
          onOverflowPress={open}
        />
      </SafeAreaProvider>,
    );
    await fireEvent.press(overflow.getByRole('button', { name: 'Three' }));
    expect(open).toHaveBeenCalledTimes(1);
    expect(overflow.queryByRole('menuitem', { name: 'Four' })).toBeNull();
    await overflow.unmount();

    const internal = await renderWithTheme(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <ProfileTabs
          tabs={[...tabs, { key: 'four', label: 'Four' }]}
          selectedKey="three"
          onSelect={onSelect}
        />
      </SafeAreaProvider>,
    );
    await fireEvent.press(internal.getByRole('button', { name: 'Three' }));
    expect(internal.getByTestId('destination-picker-position')).toBeTruthy();
    expect(internal.getByText('3/4')).toBeTruthy();
    expect(
      StyleSheet.flatten(internal.getByTestId('destination-picker-control').props.style).minHeight,
    ).toBe(44);
    expect(internal.getByRole('radio', { name: 'Four' })).toBeTruthy();
    await fireEvent.press(internal.getByRole('radio', { name: 'Four' }));
    expect(onSelect).toHaveBeenCalledWith('four');
  });

  it('filters modal picker options and commits one selection', async () => {
    const onSelect = jest.fn();
    const screen = await renderPickerWithTheme(
      <SelectionPicker
        title="Choose country"
        searchPlaceholder="Search countries"
        options={[
          { key: 'us', label: 'United States', searchText: 'US' },
          { key: 'se', label: 'Sweden', searchText: 'SE' },
        ]}
        selectedKey="us"
        onSelect={onSelect}
      />,
    );
    await fireEvent.press(screen.getByRole('button', { name: 'United States' }));
    await fireEvent.changeText(screen.getByLabelText('Search countries'), 'SE');
    expect(screen.queryByRole('radio', { name: 'United States' })).toBeNull();
    await fireEvent.press(screen.getByRole('radio', { name: 'Sweden' }));
    expect(onSelect).toHaveBeenCalledWith('se');
  });

  it('sizes a short modal picker to expose every option without scrolling', async () => {
    const screen = await renderPickerWithTheme(
      <SelectionPicker
        title="Choose mode"
        options={[
          { key: 'one', label: 'One' },
          { key: 'two', label: 'Two' },
        ]}
        selectedKey="one"
        onSelect={jest.fn()}
      />,
    );
    await fireEvent.press(screen.getByRole('button', { name: 'One' }));
    expect(
      StyleSheet.flatten(screen.getByTestId('selection-picker-list-viewport').props.style).height,
    ).toBe(100);
    expect(screen.getByTestId('selection-picker-list').props.scrollEnabled).toBe(false);
    expect(screen.getByRole('radio', { name: 'One' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'Two' })).toBeTruthy();
  });

  it('shows up to ten options fully and adds a scroll cue above that limit', async () => {
    const tenOptions = Array.from({ length: 10 }, (_, index) => ({
      key: `option-${index}`,
      label: `Option ${index + 1}`,
    }));
    const ten = await renderPickerWithTheme(
      <SelectionPicker
        title="Choose option"
        options={tenOptions}
        selectedKey="option-0"
        onSelect={jest.fn()}
      />,
    );
    await fireEvent.press(ten.getByRole('button', { name: 'Option 1' }));
    expect(
      StyleSheet.flatten(ten.getByTestId('selection-picker-list-viewport').props.style).height,
    ).toBe(500);
    expect(ten.getByTestId('selection-picker-list').props.scrollEnabled).toBe(false);
    expect(ten.queryByTestId('selection-picker-scroll-cue')).toBeNull();
    await ten.unmount();

    const eleven = await renderPickerWithTheme(
      <SelectionPicker
        title="Choose option"
        options={[...tenOptions, { key: 'option-10', label: 'Option 11' }]}
        selectedKey="option-0"
        onSelect={jest.fn()}
      />,
    );
    await fireEvent.press(eleven.getByRole('button', { name: 'Option 1' }));
    expect(eleven.getByTestId('selection-picker-list').props.scrollEnabled).toBe(true);
    expect(eleven.getByTestId('selection-picker-scroll-cue')).toBeTruthy();
    await fireEvent.scroll(eleven.getByTestId('selection-picker-list'), {
      nativeEvent: {
        contentOffset: { y: 50 },
        contentSize: { height: 550 },
        layoutMeasurement: { height: 500 },
      },
    });
    expect(eleven.queryByTestId('selection-picker-scroll-cue')).toBeNull();
  });

  it('keeps a scrollable picker interactive without routing list touches through the backdrop', async () => {
    const onSelect = jest.fn();
    const options = Array.from({ length: 12 }, (_, index) => ({
      key: `option-${index}`,
      label: `Option ${index + 1}`,
    }));
    const screen = await renderPickerWithTheme(
      <SelectionPicker
        title="Choose option"
        options={options}
        selectedKey="option-0"
        onSelect={onSelect}
      />,
    );
    await fireEvent.press(screen.getByRole('button', { name: 'Option 1' }));

    const list = screen.getByTestId('selection-picker-list');
    const modalHost = screen.getByTestId('selection-picker-modal-host');
    const backdrop = screen.getByTestId('selection-picker-backdrop', {
      includeHiddenElements: true,
    });
    const ancestors = [];
    let ancestor = list.parent;
    while (ancestor) {
      ancestors.push(ancestor);
      ancestor = ancestor.parent;
    }
    expect(ancestors).toContain(modalHost);
    expect(ancestors).not.toContain(backdrop);

    await fireEvent.scroll(list, {
      nativeEvent: {
        contentOffset: { y: 100 },
        contentSize: { height: 600 },
        layoutMeasurement: { height: 500 },
      },
    });
    await fireEvent.press(screen.getByRole('radio', { name: 'Option 12' }));
    expect(onSelect).toHaveBeenCalledWith('option-11');
  });

  it('dismisses from the full backdrop without dismissing sheet or list interactions', async () => {
    const onClose = jest.fn();
    const onSelect = jest.fn();
    const screen = await renderPickerWithTheme(
      <SelectionPickerModal
        visible
        title="Choose option"
        options={[
          { key: 'one', label: 'One' },
          { key: 'two', label: 'Two' },
        ]}
        selectedKey="one"
        onSelect={onSelect}
        onClose={onClose}
      />,
    );

    await fireEvent.press(screen.getByTestId('selection-picker-modal-host'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Two' }));
    expect(onSelect).toHaveBeenCalledWith('two');
    expect(onClose).not.toHaveBeenCalled();

    await fireEvent.press(
      screen.getByTestId('selection-picker-backdrop', { includeHiddenElements: true }),
    );
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('enables scrolling when native layout constrains a short picker below its requested height', async () => {
    const options = Array.from({ length: 6 }, (_, index) => ({
      key: `option-${index}`,
      label: `Option ${index + 1}`,
    }));
    const screen = await renderPickerWithTheme(
      <SelectionPicker
        title="Choose option"
        options={options}
        selectedKey="option-0"
        onSelect={jest.fn()}
      />,
    );
    await fireEvent.press(screen.getByRole('button', { name: 'Option 1' }));
    expect(screen.getByTestId('selection-picker-list').props.scrollEnabled).toBe(false);

    await act(() => {
      screen.getByTestId('selection-picker-list').props.onLayout({
        nativeEvent: { layout: { x: 0, y: 0, width: 320, height: 200 } },
      });
    });

    expect(screen.getByTestId('selection-picker-list').props.scrollEnabled).toBe(true);
    expect(screen.getByTestId('selection-picker-scroll-cue')).toBeTruthy();
  });

  it('tints empty-prop Lucide elements while preserving an explicit colour', () => {
    const themed = tintIcon(createElement(Search), '#FFFFFF') as ReactElement<{ color?: string }>;
    const explicit = tintIcon(
      createElement(Search, { color: '#D90709' }),
      '#FFFFFF',
    ) as ReactElement<{
      color?: string;
    }>;

    expect(themed.props.color).toBe('#FFFFFF');
    expect(explicit.props.color).toBe('#D90709');
  });

  it('keeps search and sort controls labelled and interactive', async () => {
    const change = jest.fn();
    const sort = jest.fn();
    const screen = await renderWithTheme(
      <SearchSortBar
        value=""
        onChangeText={change}
        placeholder="Search members"
        sortLabel="Change sort"
        sortValue="Name"
        sortIcon={<Text>↕</Text>}
        onSortPress={sort}
      />,
    );
    await fireEvent.changeText(screen.getByPlaceholderText('Search members'), 'Matt');
    await fireEvent.press(screen.getByRole('button', { name: 'Change sort' }));
    expect(change).toHaveBeenCalledWith('Matt');
    expect(sort).toHaveBeenCalledTimes(1);
    expect(StyleSheet.flatten(screen.getByTestId('search-sort-search').props.style).height).toBe(
      44,
    );
    expect(StyleSheet.flatten(screen.getByTestId('search-sort-control').props.style).height).toBe(
      40,
    );
  });

  it('positions snackbars with or without safe-area context', async () => {
    const onDismiss = jest.fn();
    const fallback = await renderWithTheme(
      <Snackbar message="Saved" onDismiss={onDismiss} duration={0} avoidBottomNavigation />,
    );
    expect(fallback.getByRole('alert').props.style).toEqual(
      expect.arrayContaining([expect.objectContaining({ bottom: 96 })]),
    );
    await fallback.unmount();

    const provided = await renderWithTheme(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <Snackbar message="Saved" onDismiss={onDismiss} duration={0} avoidBottomNavigation />
      </SafeAreaProvider>,
    );
    expect(provided.getByRole('alert').props.style).toEqual(
      expect.arrayContaining([expect.objectContaining({ bottom: 130 })]),
    );
  });
});
