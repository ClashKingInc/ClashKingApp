import { Platform, Share } from 'react-native';

import { appLinkPath, type AppLink } from './app-link';

const PUBLIC_APP_ORIGIN = 'https://app.clashk.ing';

export function sharePageUrl(link: AppLink): string {
  // /share is deliberately outside iOS and Android's native link paths.
  // A shared post opens its web reader; opening the app is an explicit action.
  const webReader = link.kind === 'page' && link.page === 'posts' && link.params?.postId;
  return `${PUBLIC_APP_ORIGIN}${webReader ? '/share' : ''}${appLinkPath(link)}`;
}

export async function sharePageLink(link: AppLink, title: string): Promise<void> {
  const url = sharePageUrl(link);
  await Share.share(Platform.OS === 'ios' ? { title, url } : { title, message: url });
}
