import { isRecord } from '../../player/models/parsing';

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
    return this.presentationType === 'story' || this.storyUrl !== null;
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

function blocksToHtml(
  value: unknown,
  bannerImageUrl: string | null,
  fallback: unknown,
): string | null {
  let content = '';
  if (isHttpsUrl(bannerImageUrl)) {
    content += `<img class="hero" src="${escapeHtml(bannerImageUrl)}" alt="">`;
  }
  const blocks = Array.isArray(value) ? value : [];
  for (const raw of blocks) {
    if (!isRecord(raw)) continue;
    const type = String(raw.type ?? '');
    if (type === 'heading') content += `<h2>${escapeHtml(raw.text)}</h2>`;
    else if (type === 'paragraph') content += `<p>${escapeHtml(raw.text)}</p>`;
    else if (type === 'bullet_list' && Array.isArray(raw.items)) {
      content += '<ul>';
      for (const item of raw.items) {
        if (String(item).trim()) content += `<li>${escapeHtml(item)}</li>`;
      }
      content += '</ul>';
    } else if (type === 'image' && isHttpsUrl(raw.url)) {
      const source = String(raw.url).trim();
      const caption = escapeHtml(raw.caption);
      content += `<figure><img src="${escapeHtml(source)}" alt="${caption}">`;
      if (caption) content += `<figcaption>${caption}</figcaption>`;
      content += '</figure>';
    }
  }
  if (!content && String(fallback ?? '').trim()) content = `<p>${escapeHtml(fallback)}</p>`;
  if (!content) return null;
  return `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;padding:20px;line-height:1.55;color:#172033;background:#fff}h2{margin-top:1.4em}img{max-width:100%;height:auto;border-radius:16px}.hero{display:block;width:100%;margin-bottom:20px}figure{margin:20px 0}figcaption{opacity:.7;margin-top:8px}@media(prefers-color-scheme:dark){body{color:#f4f6fb;background:#10131a}}</style></head><body>${content}</body></html>`;
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
function isHttpsUrl(value: unknown): boolean {
  try {
    return new URL(String(value ?? '')).protocol === 'https:';
  } catch {
    return false;
  }
}
function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
