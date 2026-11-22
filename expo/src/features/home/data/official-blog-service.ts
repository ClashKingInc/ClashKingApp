import { AppAnnouncement } from './app-announcement';

const origin = 'https://supercell.com';
const gamePath = '/en/games/clashofclans';
// These are the language routes published by Supercell's archive selector.
// Unsupported app languages use English; a failed supported route is not retried in English.
export function officialBlogLanguage(locale: string): string {
  const normalized = locale.toLowerCase().replaceAll('_', '-');
  const language = normalized.split('-')[0]!;
  if (language === 'zh') return /hant|tw|hk|mo/.test(normalized) ? 'zh' : 'zh-hans';
  return ['de', 'es', 'fr', 'id', 'it', 'ja', 'ko', 'pt', 'pl'].includes(language)
    ? language
    : 'en';
}
function blogPath(locale: string): string {
  const language = officialBlogLanguage(locale);
  return `${gamePath}${language === 'en' ? '' : `/${language}`}/blog`;
}

/** Read the page's structured JSON directly: no backend, disk cache, or build ID to expire. */
async function pageData(path: string): Promise<Record<string, unknown>> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    const response = await fetch(`${origin}${path}/`, {
      signal: controller.signal,
      cache: 'no-store',
      credentials: 'omit',
    });
    if (!response.ok) throw new Error(`Official blog: ${response.status}`);
    const html = await response.text();
    const data = /<script\b[^>]*\bid=["']__NEXT_DATA__["'][^>]*>([\s\S]*?)<\/script>/i.exec(html);
    if (!data) throw new Error('Official blog data unavailable');
    const parsed = JSON.parse(data[1]!) as { props?: { pageProps?: Record<string, unknown> } };
    if (!parsed.props?.pageProps) throw new Error('Invalid official blog data');
    return parsed.props.pageProps;
  } finally {
    clearTimeout(timeout);
  }
}

function record(value: unknown): Record<string, unknown> {
  return typeof value === 'object' && value !== null ? (value as Record<string, unknown>) : {};
}
function escape(value: unknown): string {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
function safeUrl(value: unknown): string | null {
  if (typeof value !== 'string' || !value) return null;
  try {
    const url = new URL(value, origin);
    return url.protocol === 'https:' ? url.href : null;
  } catch {
    return null;
  }
}
function articlePath(value: unknown): string {
  const url = new URL(String(value), origin);
  if (
    url.origin !== origin ||
    !/^\/en\/games\/clashofclans\/(?:[a-z-]+\/)?blog\//.test(url.pathname)
  )
    throw new Error('Invalid official article URL');
  return url.pathname.replace(/\/$/, '');
}

export class OfficialBlogService {
  async getPage(page = 1, locale = 'en') {
    const path = blogPath(locale);
    const data = await pageData(page === 1 ? path : `${path}/page/${page}`);
    if (!Array.isArray(data.articles) || !Array.isArray(data.pageNumbers))
      throw new Error('Invalid official blog archive');
    const items = data.articles.map((raw) => {
      const item = record(raw);
      const path = articlePath(item.linkUrl);
      const date = new Date(String(item.publishDate));
      if (!item.title || Number.isNaN(date.getTime())) throw new Error('Invalid official article');
      return new AppAnnouncement(
        `supercell:${path}`,
        String(item.title),
        'Clash of Clans',
        null,
        null,
        safeUrl(record(item.thumbnail).imgUrl),
        `${origin}${path}/`,
        null,
        null,
        'article',
        'published',
        date,
      );
    });
    return { items, hasMore: data.pageNumbers.some((n) => Number(n) > page) };
  }

  async getArticle(post: AppAnnouncement): Promise<AppAnnouncement> {
    const path = articlePath(post.htmlUrl);
    const data = await pageData(path);
    if (!Array.isArray(data.bodyCollection)) throw new Error('Official article body unavailable');
    const body = data.bodyCollection.map(renderBlock).join('');
    if (!body.trim()) throw new Error('Official article body empty');
    return new AppAnnouncement(
      post.id,
      post.title,
      post.subtitle,
      null,
      body,
      safeUrl(data.hero) ?? post.bannerImageUrl,
      post.htmlUrl,
      null,
      null,
      'article',
      'published',
      post.publishedAt,
    );
  }
}

function renderBlock(value: unknown): string {
  const block = record(value);
  if (block.__typename === 'TextBlock') return renderRichText(record(block.text).json);
  // Keep unsupported editorial blocks visible as links rather than silently dropping media.
  const url = safeUrl(block.url ?? block.videoUrl ?? record(block.image).url);
  if (url) return `<p><a href="${escape(url)}">${escape(block.title || url)}</a></p>`;
  throw new Error('Unsupported official article block');
}

function renderRichText(value: unknown): string {
  const node = record(value);
  const children = Array.isArray(node.content) ? node.content.map(renderRichText).join('') : '';
  const type = String(node.nodeType ?? '');
  if (type === 'text') {
    let text = escape(node.value).replaceAll('\n', '<br>');
    for (const mark of Array.isArray(node.marks) ? node.marks : []) {
      const tag = (
        {
          bold: 'strong',
          italic: 'em',
          underline: 'u',
          code: 'code',
          strikethrough: 's',
          superscript: 'sup',
          subscript: 'sub',
        } as Record<string, string>
      )[String(record(mark).type)];
      if (tag) text = `<${tag}>${text}</${tag}>`;
    }
    return text;
  }
  if (type.startsWith('embedded-')) {
    const target = record(record(node.data).target);
    const fields = record(target.fields);
    const file = record(fields.file);
    const url = safeUrl(file.url ?? target.url ?? fields.url);
    if (!url) throw new Error('Unsupported embedded article content');
    return String(file.contentType ?? '').startsWith('image/')
      ? `<figure><img src="${escape(url)}" alt="${escape(fields.title)}"></figure>`
      : `<p><a href="${escape(url)}">${escape(fields.title || url)}</a></p>`;
  }
  if (type === 'hr') return '<hr>';
  if (type === 'hyperlink') {
    const url = safeUrl(record(node.data).uri);
    return url ? `<a href="${escape(url)}">${children}</a>` : children;
  }
  const tag = (
    {
      paragraph: 'p',
      'heading-1': 'h1',
      'heading-2': 'h2',
      'heading-3': 'h3',
      'heading-4': 'h4',
      'heading-5': 'h5',
      'heading-6': 'h6',
      'unordered-list': 'ul',
      'ordered-list': 'ol',
      'list-item': 'li',
      blockquote: 'blockquote',
      table: 'table',
      'table-row': 'tr',
      'table-cell': 'td',
      'table-header-cell': 'th',
    } as Record<string, string>
  )[type];
  if (tag === 'table') return `<div class="table-scroll"><table>${children}</table></div>`;
  return tag ? `<${tag}>${children}</${tag}>` : children;
}
