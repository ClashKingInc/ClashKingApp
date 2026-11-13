// Pages advanced mode: only post URLs run server code. All other requests keep
// the static landing, association files and OAuth handlers unchanged.
const escapeHtml = (value) =>
  String(value).replace(
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
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const match = /^\/posts\/([^/]+)\/?$/.exec(url.pathname);
    if (!match) return env.ASSETS.fetch(request);
    if (request.method !== 'GET' && request.method !== 'HEAD')
      return new Response(null, { status: 405, headers: { Allow: 'GET, HEAD' } });
    let id;
    try {
      id = decodeURIComponent(match[1]);
    } catch {
      return new Response('Not found', { status: 404 });
    }
    if (!/^[a-zA-Z0-9_-]{1,200}$/.test(id)) return new Response('Not found', { status: 404 });
    const canonical = 'https://app.clashk.ing/posts/' + encodeURIComponent(id);
    const landing = await env.ASSETS.fetch(new Request(new URL('/', url), request));
    let html = await landing.text();
    let status = 200;
    let title = 'Post unavailable';
    let description = 'This post is no longer available. Open ClashKing to see the latest updates.';
    let image = 'https://app.clashk.ing/icons/Icon-512.png';
    try {
      // Fixed origin, no cookies or forwarded authorization. The API remains
      // authoritative for publication; never cache a previously public post.
      const response = await fetch(
        'https://api.clashk.ing/v2/app/announcements/' + encodeURIComponent(id) + '?locale=en',
        {
          headers: { Accept: 'application/json' },
          signal: AbortSignal.timeout(5000),
          redirect: 'manual',
        },
      );
      if (response.status === 404 || response.status === 403) status = 404;
      else if (!response.ok) status = 503;
      else {
        const body = await response.json();
        const post = body.item;
        if (
          !post ||
          !['live', 'expired'].includes(post.status) ||
          !post.published_at ||
          typeof post.title !== 'string'
        )
          status = 404;
        else {
          title = post.title;
          description =
            typeof post.subtitle === 'string' ? post.subtitle : 'Read this update in ClashKing.';
          image = safeImage(post.banner_image_url) ?? image;
        }
      }
    } catch {
      status = 503;
    }
    if (status === 503) {
      title = 'ClashKing updates';
      description = 'This update could not be loaded right now. Please try again shortly.';
    }
    html = html
      .replace(/<title>.*?<\/title>/s, '<title>' + escapeHtml(title) + ' · ClashKing</title>')
      .replace(/<meta\s+(?:name="(?:description|twitter:[^"]+)"|property="og:[^"]+")[^>]*>\s*/g, '')
      .replace(/<link rel="canonical"[^>]*>\s*/g, '')
      .replace(
        '</head>',
        `<link rel="canonical" href="${canonical}"><meta name="description" content="${escapeHtml(description)}"><meta property="og:type" content="article"><meta property="og:site_name" content="ClashKing"><meta property="og:title" content="${escapeHtml(title)}"><meta property="og:description" content="${escapeHtml(description)}"><meta property="og:url" content="${canonical}"><meta property="og:image" content="${escapeHtml(image)}"><meta name="twitter:card" content="summary_large_image">${status !== 200 ? '<meta name="robots" content="noindex">' : ''}</head>`,
      )
      .replace(
        '<h1>ClashKing</h1>',
        '<h1>' + escapeHtml(title) + '</h1><p class="intro">' + escapeHtml(description) + '</p>',
      )
      .replace('href="clashking:///"', 'href="clashking:///posts/' + encodeURIComponent(id) + '"');
    return new Response(request.method === 'HEAD' ? null : html, {
      status,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
        'X-Content-Type-Options': 'nosniff',
        'Referrer-Policy': 'no-referrer',
      },
    });
  },
};
