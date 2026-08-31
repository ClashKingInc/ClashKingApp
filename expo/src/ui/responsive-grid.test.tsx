import { render } from '@testing-library/react-native';
import { Text } from 'react-native';

import { ResponsiveGrid } from './responsive-grid';

describe('ResponsiveGrid', () => {
  afterEach(() => jest.restoreAllMocks());

  it('preserves children with duplicate semantic keys without forwarding duplicate wrapper keys', async () => {
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => undefined);

    const screen = await render(
      <ResponsiveGrid>
        <Text key="1000000:army-1000000">First army item</Text>
        <Text key="1000000:army-1000000">Second army item</Text>
      </ResponsiveGrid>,
    );

    expect(screen.getByText('First army item')).toBeTruthy();
    expect(screen.getByText('Second army item')).toBeTruthy();
    expect(
      consoleError.mock.calls.some((call) =>
        call.some(
          (value) => typeof value === 'string' && value.includes('Encountered two children'),
        ),
      ),
    ).toBe(false);
  });

  it('keeps repeated unkeyed elements instead of deduplicating grid content', async () => {
    const screen = await render(
      <ResponsiveGrid>
        <Text>Repeated</Text>
        <Text>Repeated</Text>
      </ResponsiveGrid>,
    );

    expect(screen.getAllByText('Repeated')).toHaveLength(2);
  });
});
