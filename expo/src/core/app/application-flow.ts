import type { PostAuthDestination } from '../../features/auth/presentation';
import type { AppStartupResult } from './startup-coordinator';

export type ApplicationScene =
  | { readonly kind: 'startup' }
  | { readonly kind: 'login'; readonly prefillEmail?: string }
  | { readonly kind: 'register' }
  | { readonly kind: 'verify-email'; readonly email: string }
  | { readonly kind: 'forgot-password' }
  | { readonly kind: 'reset-password'; readonly email: string }
  | { readonly kind: 'account-setup' }
  | { readonly kind: 'home' }
  | { readonly kind: 'maintenance' }
  | { readonly kind: 'error'; readonly networkError: boolean };

export function sceneForStartupResult(result: AppStartupResult): ApplicationScene {
  switch (result.destination) {
    case 'login':
      return { kind: 'login' };
    case 'account-setup':
      return { kind: 'account-setup' };
    case 'home':
      return { kind: 'home' };
    case 'maintenance':
      return { kind: 'maintenance' };
    case 'error':
      return { kind: 'error', networkError: result.networkError };
  }
}

export function sceneForPostAuthDestination(destination: PostAuthDestination): ApplicationScene {
  return destination === 'home' ? { kind: 'home' } : { kind: 'account-setup' };
}
