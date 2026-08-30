import { requireNativeModule } from 'expo';

import type { ClashKingNativeModule } from './types';

export * from './types';

export default requireNativeModule<ClashKingNativeModule>('ClashKingNative');
