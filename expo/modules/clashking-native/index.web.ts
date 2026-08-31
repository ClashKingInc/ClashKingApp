import type { ClashKingNativeModule } from './types';

export * from './types';

const unsupportedOperation = (property: string | symbol): never => {
  throw new Error(`ClashKingNative.${String(property)} is unavailable on web.`);
};

const ClashKingNative = new Proxy({} as ClashKingNativeModule, {
  get: (_target, property) => () => unsupportedOperation(property),
});

export default ClashKingNative;
