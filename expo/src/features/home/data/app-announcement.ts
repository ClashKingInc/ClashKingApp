import { isRecord } from '../../player/models/parsing';
import { blocksToHtml } from './announcement-content';

export { markdownToHtml } from './announcement-content';

export class AppAnnouncement {
  constructor(
    readonly id: string,
    readonly title: string,
    readonly subtitle: string,
    readonly version: string | null,
    readonly body: string | null,
    readonly bannerImageUrl: string | null,
    readonly htmlUrl: string | null,
    readonly storyUrl: string | null,
    readonly targetRoute: string | null,
    readonly presentationType = 'article',
    readonly status = 'live',
    readonly publishedAt: Date | null = null,
    readonly showOnHome = false,
    readonly pinnedOnHome = false,
    readonly startsAt: Date | null = null,
    readonly endsAt: Date | null = null,
  ) {}

  get hasReadableBody(): boolean {
    return Boolean(this.storyUrl || this.body?.trim() || this.htmlUrl?.trim());
  }
  get isStory(): boolean {
    return this.presentationType === 'story' || Boolean(this.storyUrl?.trim());
  }
  isCurrent(now = new Date()): boolean {
    return (
      this.status === 'live' && (this.endsAt === null || this.endsAt.getTime() > now.getTime())
    );
  }
  get presentationKey(): string {
    return `${this.id}:${this.version ?? this.startsAt?.toISOString() ?? '1'}`;
  }

  static fromJson(value: unknown): AppAnnouncement {
    if (!isRecord(value)) throw new TypeError('Invalid announcement');
    const bannerImageUrl = optionalString(value.banner_image_url);
    return new AppAnnouncement(
      String(value.id ?? ''),
      String(value.title ?? ''),
      String(value.subtitle ?? ''),
      optionalString(value.version),
      optionalString(value.body) ?? blocksToHtml(value.body_blocks, bannerImageUrl, value.subtitle),
      bannerImageUrl,
      optionalString(value.html_url),
      optionalString(value.story_url),
      optionalString(value.target_route),
      optionalString(value.presentation_type) ?? 'article',
      optionalString(value.status) ?? 'live',
      parseDate(value.published_at),
      value.show_on_home === true,
      value.pinned_on_home === true,
      parseDate(value.starts_at),
      parseDate(value.ends_at),
    );
  }
}

function optionalString(value: unknown): string | null {
  const text = value === null || value === undefined ? '' : String(value).trim();
  return text || null;
}
function parseDate(value: unknown): Date | null {
  const text = optionalString(value);
  if (!text) return null;
  const date = new Date(text);
  return Number.isNaN(date.getTime()) ? null : date;
}
