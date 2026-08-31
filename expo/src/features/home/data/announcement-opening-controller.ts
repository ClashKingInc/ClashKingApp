import type { AppAnnouncement } from './app-announcement';

export interface OpeningAnnouncementEligibility {
  readonly platform: string;
  readonly featureEnabled: boolean;
  readonly routeCurrent: boolean;
  readonly announcement: AppAnnouncement | null;
}

export function supportsEmbeddedAnnouncementStories(platform: string): boolean {
  return platform !== 'web';
}

export function isOpeningAnnouncementEligible({
  platform,
  featureEnabled,
  routeCurrent,
  announcement,
}: OpeningAnnouncementEligibility): boolean {
  return (
    supportsEmbeddedAnnouncementStories(platform) &&
    featureEnabled &&
    routeCurrent &&
    announcement !== null &&
    announcement.storyUrl !== null
  );
}

export interface AnnouncementOpeningControllerOptions {
  readonly platform: string;
  readonly featureEnabled: () => boolean;
  readonly routeCurrent: () => boolean;
  readonly openingAnnouncement: Promise<AppAnnouncement | null>;
  readonly shouldPresent: (announcement: AppAnnouncement) => Promise<boolean>;
  readonly prepareStory: (announcement: AppAnnouncement) => Promise<string | null>;
  readonly presentStory: (announcement: AppAnnouncement, preparedUri: string) => Promise<boolean>;
  readonly markDismissed: (announcement: AppAnnouncement) => Promise<void>;
}

export class AnnouncementOpeningController {
  constructor(private readonly options: AnnouncementOpeningControllerOptions) {}

  async tryPresent(): Promise<boolean> {
    if (
      !supportsEmbeddedAnnouncementStories(this.options.platform) ||
      !this.options.featureEnabled() ||
      !this.options.routeCurrent()
    ) {
      return false;
    }

    const announcement = await this.options.openingAnnouncement;
    if (
      announcement === null ||
      !isOpeningAnnouncementEligible({
        platform: this.options.platform,
        featureEnabled: this.options.featureEnabled(),
        routeCurrent: this.options.routeCurrent(),
        announcement,
      }) ||
      !(await this.options.shouldPresent(announcement))
    ) {
      return false;
    }

    const preparedUri = await this.options.prepareStory(announcement);
    if (preparedUri === null || !this.options.routeCurrent()) return false;

    const displayed = await this.options.presentStory(announcement, preparedUri);
    if (!displayed) return false;
    await this.options.markDismissed(announcement);
    return true;
  }
}
