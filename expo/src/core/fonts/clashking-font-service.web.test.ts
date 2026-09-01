import * as Font from 'expo-font';

import { CLASHKING_FONT_SOURCE } from './clashking-font-contract';
import { loadClashKingFont } from './clashking-font-service.web';

jest.mock('expo-font', () => ({
  loadAsync: jest.fn(async () => undefined),
}));

describe('ClashKing web font loading', () => {
  test('registers the bundled font without a network request', async () => {
    const fetchSpy = jest.spyOn(globalThis, 'fetch');

    await expect(loadClashKingFont()).resolves.toBe(true);

    expect(Font.loadAsync).toHaveBeenCalledWith('ClashKing', CLASHKING_FONT_SOURCE);
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
