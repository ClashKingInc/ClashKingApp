import ClashKingNative from '../../../modules/clashking-native/index.web';
import nativePackage from '../../../modules/clashking-native/package.json';

describe('ClashKing native web entrypoint', () => {
  it('lets Metro select the platform-specific entrypoint', () => {
    expect(nativePackage.main).toBe('index');
  });

  it('can be imported without loading an Expo native module', () => {
    expect(ClashKingNative).toBeDefined();
  });

  it('fails clearly if a native-only method is called on web', () => {
    expect(() => ClashKingNative.reloadWidgets()).toThrow(
      'ClashKingNative.reloadWidgets is unavailable on web.',
    );
  });
});
