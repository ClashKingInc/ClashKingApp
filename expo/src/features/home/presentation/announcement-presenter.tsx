import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import { Modal, Platform } from 'react-native';

import type { AppAnnouncement, AnnouncementStoryCacheService } from '../data';
import { isTrustedHttpsUrl, sharedAnnouncementStoryCache } from '../data';
import { HomeAnnouncementArticleScreen, PostArticleScreen } from './announcement-article-screen';
import { AnnouncementStoryModal } from './announcement-story-modal';

export function announcementStoryWebUrl(announcement: AppAnnouncement): string | null {
  if (isTrustedHttpsUrl(announcement.storyUrl)) return announcement.storyUrl;
  return isTrustedHttpsUrl(announcement.htmlUrl) ? announcement.htmlUrl : null;
}

export function openAnnouncementStoryWindow(
  announcement: AppAnnouncement,
  openWindow: (url: string) => unknown = (url) =>
    typeof window === 'undefined' ? null : window.open(url, '_blank', 'noopener,noreferrer'),
): boolean {
  const url = announcementStoryWebUrl(announcement);
  return url !== null && openWindow(url) !== null;
}

type Presentation =
  | { readonly type: 'article'; readonly announcement: AppAnnouncement; readonly compact: boolean }
  | {
      readonly type: 'story';
      readonly announcement: AppAnnouncement;
      readonly preparedUri: string;
    };

export function useAnnouncementPresentation(
  cache: AnnouncementStoryCacheService = sharedAnnouncementStoryCache,
): {
  readonly openAnnouncement: (
    announcement: AppAnnouncement,
    canDisplay?: () => boolean,
  ) => Promise<boolean>;
  readonly openHomeAnnouncement: (
    announcement: AppAnnouncement,
    canDisplay?: () => boolean,
  ) => Promise<boolean>;
  readonly openPreparedStory: (
    announcement: AppAnnouncement,
    preparedUri: string,
    canDisplay?: () => boolean,
  ) => Promise<boolean>;
  readonly closeAnnouncement: () => void;
  readonly presentation: ReactNode;
} {
  const [presentation, setPresentation] = useState<Presentation>();
  const mounted = useRef(true);
  const request = useRef(0);
  const storyCompletion = useRef<((displayed: boolean) => void) | null>(null);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      storyCompletion.current?.(false);
      storyCompletion.current = null;
    };
  }, []);

  const closeAnnouncement = useCallback(() => {
    request.current += 1;
    storyCompletion.current?.(true);
    storyCompletion.current = null;
    setPresentation(undefined);
  }, []);

  const displayPreparedStory = useCallback(
    (announcement: AppAnnouncement, preparedUri: string, canDisplay?: () => boolean) => {
      if (!mounted.current || (canDisplay && !canDisplay())) return Promise.resolve(false);
      setPresentation({ type: 'story', announcement, preparedUri });
      return new Promise<boolean>((resolve) => {
        storyCompletion.current = resolve;
      });
    },
    [],
  );
  const open = useCallback(
    async (
      announcement: AppAnnouncement,
      canDisplay?: () => boolean,
      compact = false,
    ): Promise<boolean> => {
      storyCompletion.current?.(false);
      storyCompletion.current = null;
      const currentRequest = ++request.current;
      if (announcement.isStory) {
        if (Platform.OS === 'web') return openAnnouncementStoryWindow(announcement);
        const preparedUri = await cache.prepare(announcement);
        if (
          preparedUri === null ||
          !mounted.current ||
          currentRequest !== request.current ||
          (canDisplay && !canDisplay())
        ) {
          return false;
        }
        return displayPreparedStory(announcement, preparedUri, canDisplay);
      }

      setPresentation({ type: 'article', announcement, compact });
      return true;
    },
    [cache, displayPreparedStory],
  );

  const openAnnouncement = useCallback(
    (announcement: AppAnnouncement, canDisplay?: () => boolean) =>
      open(announcement, canDisplay, false),
    [open],
  );
  const openHomeAnnouncement = useCallback(
    (announcement: AppAnnouncement, canDisplay?: () => boolean) =>
      open(announcement, canDisplay, true),
    [open],
  );
  const openPreparedStory = useCallback(
    (announcement: AppAnnouncement, preparedUri: string, canDisplay?: () => boolean) => {
      storyCompletion.current?.(false);
      storyCompletion.current = null;
      request.current += 1;
      return displayPreparedStory(announcement, preparedUri, canDisplay);
    },
    [displayPreparedStory],
  );

  return {
    openAnnouncement,
    openHomeAnnouncement,
    openPreparedStory,
    closeAnnouncement,
    presentation:
      presentation?.type === 'story' ? (
        <AnnouncementStoryModal
          announcement={presentation.announcement}
          onFinish={closeAnnouncement}
          preparedUri={presentation.preparedUri}
        />
      ) : presentation?.type === 'article' ? (
        <Modal
          animationType="slide"
          onRequestClose={closeAnnouncement}
          presentationStyle="fullScreen"
          visible
        >
          {presentation.compact ? (
            <HomeAnnouncementArticleScreen
              onBack={closeAnnouncement}
              post={presentation.announcement}
            />
          ) : (
            <PostArticleScreen onBack={closeAnnouncement} post={presentation.announcement} />
          )}
        </Modal>
      ) : null,
  };
}
