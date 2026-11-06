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
    if (type === 'markdown') content += markdownToHtml(String(raw.text ?? ''));
    else if (type === 'heading') content += `<h2>${escapeHtml(raw.text)}</h2>`;
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
  return `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>${content}</body></html>`;
}

/** Render the common editorial Markdown subset without allowing author HTML or unsafe URLs. */
export function markdownToHtml(markdown: string): string {
  const lines = markdown.replaceAll('\r\n', '\n').split('\n');
  const output: string[] = [];
  let paragraph: string[] = [];
  let list: 'ul' | 'ol' | null = null;
  let code: string[] | null = null;
  const flushParagraph = () => {
    if (paragraph.length) output.push(`<p>${inlineMarkdown(paragraph.join(' '))}</p>`);
    paragraph = [];
  };
  const closeList = () => {
    if (list) output.push(`</${list}>`);
    list = null;
  };
  for (const line of lines) {
    if (/^\s*```/.test(line)) {
      flushParagraph();
      closeList();
      if (code) {
        output.push(`<pre><code>${escapeHtml(code.join('\n'))}</code></pre>`);
        code = null;
      } else code = [];
      continue;
    }
    if (code) {
      code.push(line);
      continue;
    }
    if (!line.trim()) {
      flushParagraph();
      closeList();
      continue;
    }
    const heading = /^(#{1,6})\s+(.+)$/.exec(line);
    if (heading) {
      flushParagraph();
      closeList();
      const level = heading[1]!.length;
      output.push(`<h${level}>${inlineMarkdown(heading[2]!)}</h${level}>`);
      continue;
    }
    const bullet = /^\s*[-*+]\s+(.+)$/.exec(line);
    const numbered = /^\s*\d+\.\s+(.+)$/.exec(line);
    if (bullet || numbered) {
      flushParagraph();
      const kind = bullet ? 'ul' : 'ol';
      if (list !== kind) {
        closeList();
        output.push(`<${kind}>`);
        list = kind;
      }
      output.push(`<li>${inlineMarkdown((bullet ?? numbered)![1]!)}</li>`);
      continue;
    }
    if (/^>\s?/.test(line)) {
      flushParagraph();
      closeList();
      output.push(`<blockquote>${inlineMarkdown(line.replace(/^>\s?/, ''))}</blockquote>`);
      continue;
    }
    flushParagraphIfImage(line);
  }
  if (code) output.push(`<pre><code>${escapeHtml(code.join('\n'))}</code></pre>`);
  flushParagraph();
  closeList();
  return output.join('');

  function flushParagraphIfImage(line: string) {
    const image = /^!\[([^\]]*)\]\((https:\/\/[^\s)]+)\)$/.exec(line.trim());
    if (image && isHttpsUrl(image[2])) {
      flushParagraph();
      closeList();
      output.push(
        `<figure><img src="${escapeHtml(image[2])}" alt="${escapeHtml(image[1])}"></figure>`,
      );
    } else paragraph.push(line.trim());
  }
}

function inlineMarkdown(value: string): string {
  const token = /`([^`]+)`|\*\*([^*]+)\*\*|\*([^*]+)\*|\[([^\]]+)\]\(([^\s)]+)\)/g;
  let html = '';
  let previous = 0;
  for (const match of value.matchAll(token)) {
    const index = match.index ?? previous;
    html += escapeHtml(value.slice(previous, index));
    if (match[1] !== undefined) html += `<code>${escapeHtml(match[1])}</code>`;
    else if (match[2] !== undefined) html += `<strong>${escapeHtml(match[2])}</strong>`;
    else if (match[3] !== undefined) html += `<em>${escapeHtml(match[3])}</em>`;
    else if (match[4] !== undefined && match[5] !== undefined) {
      html += isHttpsUrl(match[5])
        ? `<a href="${escapeHtml(match[5])}">${escapeHtml(match[4])}</a>`
        : escapeHtml(match[4]);
    }
    previous = index + match[0].length;
  }
  return html + escapeHtml(value.slice(previous));
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
