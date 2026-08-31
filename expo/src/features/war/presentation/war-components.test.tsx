import { describe, expect, it, jest } from '@jest/globals';
import { fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { CKThemeProvider } from '../../../ui';
import { SelectionModal } from './war-components';

async function renderSelectionModal(optionCount: number) {
  const onClose = jest.fn();
  const onSelect = jest.fn();
  const screen = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <CKThemeProvider preference="dark">
        <SelectionModal
          visible
          title="Filters"
          options={Array.from({ length: optionCount }, (_, index) => ({
            key: `option-${index}`,
            label: `Option ${index + 1}`,
          }))}
          selected="option-0"
          onClose={onClose}
          onSelect={onSelect}
        />
      </CKThemeProvider>
    </SafeAreaProvider>,
  );
  return { screen, onClose, onSelect };
}

describe('war selection modal', () => {
  it('uses the shared capped picker and closes after selecting', async () => {
    const { screen, onClose, onSelect } = await renderSelectionModal(11);

    expect(screen.getByTestId('selection-picker-list').props.scrollEnabled).toBe(true);
    expect(screen.getByTestId('selection-picker-scroll-cue')).toBeTruthy();
    await fireEvent.press(screen.getByRole('radio', { name: 'Option 2' }));

    expect(onSelect).toHaveBeenCalledWith('option-1');
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('shows every short filter option without forcing scrolling', async () => {
    const { screen } = await renderSelectionModal(10);

    expect(screen.getByTestId('selection-picker-list').props.scrollEnabled).toBe(false);
    expect(screen.queryByTestId('selection-picker-scroll-cue')).toBeNull();
    expect(screen.getByRole('radio', { name: 'Option 10' })).toBeTruthy();
  });
});
