import { Platform, Share } from 'react-native';

import { appLinkPath, type AppLink } from './app-link';

const PUBLIC_APP_ORIGIN = 'https://app.clashk.ing';

export function sharePageUrl(link: AppLink): string {
  return `${PUBLIC_APP_ORIGIN}${appLinkPath(link)}`;
}

export async function sharePageLink(link: AppLink, title: string): Promise<void> {
  const url = sharePageUrl(link);
  await Share.share(Platform.OS === 'ios' ? { title, url } : { title, message: url });
}
