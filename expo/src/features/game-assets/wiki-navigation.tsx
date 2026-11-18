import type { WikiEntry } from './wiki-catalogue';
import { createContext, useContext } from 'react';
import type { UpgradeTrackerItem, UpgradeTrackerSnapshot } from '../upgrade-tracker/models';

export interface WikiNavigation {
  openItem(item: UpgradeTrackerItem, snapshot?: UpgradeTrackerSnapshot): void;
  openEntry(key: string): void;
  entryLink?(
    key: string,
    token: string,
    sourceLayer?: string,
    catalogue?: readonly WikiEntry[],
  ): {
    href: { pathname: '/detail'; params: { layer: string } };
    prepare(): boolean;
  };
  openSection?(category: string, catalogue?: readonly WikiEntry[]): void;
}
export const WikiNavigationContext = createContext<WikiNavigation | null>(null);
export const useWikiNavigation = () => useContext(WikiNavigationContext);
