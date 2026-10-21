import { Asset } from 'expo-asset';

// Bundled editorial artwork is available on native and local web, independently
// of a CDN release. Each scene has its own composition rather than a shared cover.
export const COMPETITIVE_PROFILE_COVER = Asset.fromModule(
  require('../../../assets/clashking/competitive/profile-elixir-workshop.webp'),
).uri;

export const COMPETITIVE_TOURNAMENT_COVER = Asset.fromModule(
  require('../../../assets/clashking/competitive/tournament-war-arena.webp'),
).uri;

export const COMPETITIVE_ESPORTS_COVER = Asset.fromModule(
  require('../../../assets/clashking/competitive/esports-trophy-clean.png'),
).uri;
