import { ApplicationRoot } from '../core/app/application-root';

// Entity URLs use the Pages SPA fallback; known screens also receive static entries.
export function generateStaticParams() {
  return [
    'search',
    'posts',
    'rankings',
    'stats',
    'calculators',
    'todo',
    'ranked',
    'legends',
    'upgrade-tracker',
    'bases-armies',
    'game-assets',
    'accounts',
    'profile',
    'settings',
    'achievements',
    'esports',
    'settings/faq',
    'settings/privacy',
    'settings/translation',
    'settings/licenses',
    'settings/notifications',
  ].map((path) => ({ destination: path.split('/') }));
}

export default ApplicationRoot;
