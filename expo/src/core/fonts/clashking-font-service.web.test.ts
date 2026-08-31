import * as Font from 'expo-font';

import { loadClashKingFont } from './clashking-font-service.web';

jest.mock('expo-font', () => ({
  loadAsync: jest.fn(async () => undefined),
}));

describe('ClashKing web font loading', () => {
  test('registers the downloaded font as a web resource', async () => {
    jest.spyOn(globalThis, 'fetch').mockResolvedValue({
      status: 200,
      arrayBuffer: async () => new Uint8Array([1, 2, 3]).buffer,
    } as Response);
    jest.spyOn(URL, 'createObjectURL').mockReturnValue('blob:clashking-font');
    jest.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined);

    await expect(loadClashKingFont()).resolves.toBe(true);

    expect(Font.loadAsync).toHaveBeenCalledWith('ClashKing', {
      uri: 'blob:clashking-font',
    });
    expect(URL.revokeObjectURL).not.toHaveBeenCalled();
  });
});
