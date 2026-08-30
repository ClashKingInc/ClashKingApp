import ClashKingNative from '../../../modules/clashking-native/index.web';

describe('ClashKing native web entrypoint', () => {
  it('can be imported without loading an Expo native module', () => {
    expect(ClashKingNative).toBeDefined();
  });

  it('fails clearly if a native-only method is called on web', () => {
    expect(() => ClashKingNative.reloadWidgets()).toThrow(
      'ClashKingNative.reloadWidgets is unavailable on web.',
    );
  });
});
