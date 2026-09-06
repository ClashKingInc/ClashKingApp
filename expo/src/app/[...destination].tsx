import { ApplicationRoot } from '../core/app/application-root';

// Entity URLs use the Pages SPA fallback; known screens also receive static entries.
export function generateStaticParams() {
  return [
    'players',
    'clans',
    'war',
    'search',
    'posts',
    'rankings',
    'stats',
    'calculators',
    'subscription',
    'todo',
    'ranked',
    'upgrade-tracker',
    'bases-armies',
    'game-assets',
    'accounts',
    'settings',
    'achievements',
    'settings/faq',
    'settings/privacy',
    'settings/translation',
    'settings/licenses',
    'settings/notifications',
  ].map((path) => ({ destination: path.split('/') }));
}

export default ApplicationRoot;
