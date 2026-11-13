// Public post reader. Native app links remain separate from /share/posts/*.
const storeLinks = /* CK_STORE_LINKS */ {};
const readerLocales = /* CK_READER_LOCALES */ {};
function readerLanguage(request, url) {
  const choices = [
    url.searchParams.get('locale'),
    ...(request.headers.get('Accept-Language') ?? '')
      .split(',')
      .map((value) => {
        const [tag, quality] = value.trim().split(';q=');
        return { tag, quality: quality === undefined ? 1 : Number(quality) };
      })
      .filter((value) => value.quality > 0)
      .sort((a, b) => b.quality - a.quality)
      .map((value) => value.tag),
  ];
  for (const choice of choices) {
    if (!choice) continue;
    const locale = choice.toLowerCase().replaceAll('_', '-');
    for (const candidate of [locale, locale.split('-')[0]]) {
      if (Object.hasOwn(readerLocales, candidate)) return candidate;
    }
  }
  return 'en';
}
const escapePreview = (value) =>
  String(value ?? '').replace(
    /[&<>"']/g,
    (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char],
  );
const safeImage = (value) => {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && !url.username && !url.password ? url.href : null;
  } catch {
    return null;
  }
};
const responseHeaders = {
  'Content-Type': 'text/html; charset=utf-8',
  'Cache-Control': 'no-store',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'no-referrer',
  Vary: 'Accept-Language',
};

function postDocument(post, id, status, locale) {
  const t = readerLocales[locale];
  const title = post?.title ?? (status === 404 ? t.apiErrorNotFound : t.postsLoadFailed);
  const description = post?.subtitle ?? (status === 404 ? t.apiErrorNotFound : t.generalTryAgain);
  const canonical = 'https://app.clashk.ing/share/posts/' + encodeURIComponent(id);
  const image = safeImage(post?.banner_image_url) ?? 'https://app.clashk.ing/icons/Icon-512.png';
  const story = Boolean(post?.story_url);
  const iosId = storeLinks['App Store']?.match(/\/id(\d+)/)?.[1];
  const stores = Object.entries(storeLinks)
    .map(
      ([name, href]) =>
        `<a class="download" href="${escapePreview(href)}" aria-label="${escapePreview(name)}" rel="noopener noreferrer"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 3v12m-5-5 5 5 5-5M5 16v4h14v-4"/></svg>${name === 'App Store' ? 'iOS' : 'Android'}</a>`,
    )
    .join('');
  // Reuse the native reader's escaped Markdown/block renderer. Never place
  // author HTML in this page's origin; interactive content has its own sandbox.
  const article = post ? blocksToHtml(post.body_blocks, null, post.subtitle) : null;
  const body = article?.match(/<body[^>]*>([\s\S]*)<\/body>/i)?.[1] ?? '';
  const frameUrl = `/share/posts/${encodeURIComponent(id)}/story?locale=${encodeURIComponent(locale)}`;
  const content = !post
    ? `<p role="status">${escapePreview(description)}</p>`
    : story
      ? `<section class="story-stage" aria-label="${escapePreview(title)}"><iframe id="story" title="${escapePreview(title)}" src="${frameUrl}" sandbox="allow-scripts" referrerpolicy="no-referrer" allow="autoplay" ></iframe><div id="finished" hidden><p>${escapePreview(t.postsStoryFinished)}</p><button id="replay" type="button">${escapePreview(t.postsWatchAgain)}</button></div></section>`
      : `<article>${safeImage(post.banner_image_url) ? `<img class="cover" src="${escapePreview(image)}" alt="">` : ''}<h1>${escapePreview(title)}</h1>${body}</article>`;
  return `<!doctype html><html lang="${locale}" dir="${['ar', 'he', 'ur'].includes(locale.split('-')[0]) ? 'rtl' : 'ltr'}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><title>${escapePreview(title)} · ClashKing</title><link rel="icon" href="/favicon.png"><link rel="canonical" href="${canonical}"><meta name="description" content="${escapePreview(description)}"><meta property="og:type" content="article"><meta property="og:site_name" content="ClashKing"><meta property="og:title" content="${escapePreview(title)}"><meta property="og:description" content="${escapePreview(description)}"><meta property="og:url" content="${canonical}"><meta property="og:image" content="${escapePreview(image)}"><meta name="twitter:card" content="summary_large_image"><meta name="twitter:image" content="${escapePreview(image)}">${iosId ? `<meta name="apple-itunes-app" content="app-id=${iosId}">` : ''}${status !== 200 ? '<meta name="robots" content="noindex">' : ''}
<style>*{box-sizing:border-box}html{color-scheme:dark}body{margin:0;background:#09090b;color:#fafafa;font:16px/1.6 system-ui,sans-serif}a{color:inherit}button{font:inherit;cursor:pointer}.downloads{display:flex;justify-content:center;flex-wrap:wrap;gap:12px;margin-top:28px}.download{display:inline-flex;align-items:center;gap:8px;min-height:44px;padding:10px 18px;border-radius:24px;background:#ffffff0e;border:1px solid #ffffff26;text-decoration:none;font-weight:600;font-size:14px}.download:hover{background:#ffffff18}.download:focus-visible{outline:2px solid #72b6ff;outline-offset:3px}.page{padding:24px max(16px,env(safe-area-inset-right)) max(24px,env(safe-area-inset-bottom)) max(16px,env(safe-area-inset-left));max-width:820px;margin:auto}h1{font-size:clamp(26px,5vw,38px);line-height:1.15}article img{display:block;max-width:100%;height:auto;border-radius:16px}article h2{line-height:1.25;margin-top:32px}article pre{overflow:auto}article a{color:#72b6ff;overflow-wrap:anywhere}article blockquote{margin-left:0;padding-left:16px;border-left:3px solid #777}article figure{margin:24px 0}article figcaption{color:#bbb;font-size:14px}.story-stage{position:relative;margin:auto;width:min(100%,calc(100svh - 150px));aspect-ratio:1;border-radius:24px;overflow:hidden;background:#111529}iframe{display:block;width:100%;height:100%;border:0}iframe[hidden]{display:none}#finished{position:absolute;inset:0;background:#111529;display:flex;flex-direction:column;justify-content:center;align-items:center}#finished[hidden]{display:none}#replay{border:0;border-radius:24px;padding:12px 24px;background:#cf080a;color:white}.story-caption{font-size:16px;margin:22px 0 0}.story-summary{color:#bbb;margin-top:8px}@media(prefers-color-scheme:light){html{color-scheme:light}body{background:#f5f5f6;color:#151517}.download{background:white;border-color:#ddd}.download:hover{background:#e9e9ed}.story-summary{color:#606068!important}}</style></head><body><main class="page">${content}${post && story ? `<h1 class="story-caption">${escapePreview(title)}</h1><p class="story-summary">${escapePreview(description)}</p>` : ''}<footer class="downloads">${stores}</footer></main>${story ? `<script>const frame=document.getElementById('story');const finished=document.getElementById('finished');window.addEventListener('message',event=>{if(event.source!==frame.contentWindow)return;let message;try{message=typeof event.data==='string'?JSON.parse(event.data):event.data}catch{return}if(message?.type==='complete'||message?.type==='close'){finished.hidden=false;frame.hidden=true}});document.getElementById('replay').addEventListener('click',()=>{finished.hidden=true;frame.hidden=false;frame.src=${JSON.stringify(frameUrl)}});</script>` : ''}</body></html>`;
}

async function storyDocument(post, locale) {
  const t = readerLocales[locale];
  const url = new URL(post.story_url);
  // Only the application's published, immutable story objects are proxied.
  if (
    url.origin !== 'https://posts.clashk.ing' ||
    url.username ||
    url.password ||
    !url.pathname.startsWith('/admin-stories/') ||
    !url.pathname.endsWith('.html') ||
    url.search ||
    url.hash
  )
    return new Response(t.postsLoadFailed, { status: 404 });
  const response = await fetch(url.href, {
    redirect: 'manual',
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) return new Response(t.postsLoadFailed, { status: 502 });
  if (Number(response.headers.get('Content-Length')) > 25 * 1024 * 1024)
    return new Response(t.postsLoadFailed, { status: 502 });
  const bytes = await response.arrayBuffer();
  if (bytes.byteLength > 25 * 1024 * 1024) return new Response(t.postsLoadFailed, { status: 502 });
  let html = new TextDecoder().decode(bytes);
  const bootstrap = `<style>html{-webkit-text-size-adjust:100%;text-size-adjust:100%}</style><script>window.ReactNativeWebView=window.AnnouncementStory={postMessage:message=>parent.postMessage(String(message),'*')};${ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT}</script>`;
  html = /<head\b[^>]*>/i.test(html)
    ? html.replace(/<head\b[^>]*>/i, (match) => match + bootstrap)
    : bootstrap + html;
  return new Response(html, {
    headers: {
      ...responseHeaders,
      'Content-Security-Policy':
        "sandbox allow-scripts; default-src 'none'; script-src 'unsafe-inline' blob:; style-src 'unsafe-inline'; img-src https: data: blob:; font-src https: data:; media-src https: data: blob:; connect-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'",
    },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const locale = readerLanguage(request, url);
    const t = readerLocales[locale];
    const match = /^\/(?:share\/)?posts\/([^/]+)(\/story)?\/?$/.exec(url.pathname);
    if (!match) return env.ASSETS.fetch(request);
    if (request.method !== 'GET' && request.method !== 'HEAD')
      return new Response(null, { status: 405, headers: { Allow: 'GET, HEAD' } });
    let id;
    try {
      id = decodeURIComponent(match[1]);
    } catch {
      return new Response(t.apiErrorNotFound, { status: 404 });
    }
    if (!/^[a-zA-Z0-9_-]{1,200}$/.test(id))
      return new Response(t.apiErrorNotFound, { status: 404 });
    let post = null,
      status = 200;
    try {
      // Each request checks publication again. No private cookies, credentials,
      // or arbitrary query parameters are forwarded to the public API.
      const response = await fetch(
        'https://api.clashk.ing/v2/app/announcements/' +
          encodeURIComponent(id) +
          '?locale=' +
          encodeURIComponent(locale),
        {
          headers: { Accept: 'application/json', 'User-Agent': 'ClashKing-Post-Reader/1.0' },
          redirect: 'manual',
          signal: AbortSignal.timeout(5000),
        },
      );
      if (response.status === 404 || response.status === 403) status = 404;
      else if (!response.ok) status = 503;
      else {
        const body = await response.json();
        const value = body.item;
        if (
          !value ||
          !['live', 'expired'].includes(value.status) ||
          !value.published_at ||
          typeof value.title !== 'string'
        )
          status = 404;
        else post = value;
      }
      if (match[2]) {
        if (!post?.story_url)
          return new Response(t.apiErrorNotFound, { status: status === 200 ? 404 : status });
        if (request.method === 'HEAD') return new Response(null, { headers: responseHeaders });
        return await storyDocument(post, locale);
      }
    } catch {
      status = 503;
      post = null;
    }
    const html = postDocument(post, id, status, locale);
    return new Response(request.method === 'HEAD' ? null : html, {
      status,
      headers: {
        ...responseHeaders,
        'Content-Language': locale,
        'Content-Security-Policy':
          "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src https: data:; frame-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
      },
    });
  },
};
