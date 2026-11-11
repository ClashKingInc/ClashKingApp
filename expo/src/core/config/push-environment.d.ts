import type { ApiEnvironment } from './api-config';
export function pushEnvironment(environment: ApiEnvironment, pushApiV2BaseUrlOverride?: string): 'production' | 'sandbox';
