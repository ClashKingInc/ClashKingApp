// Portable editorial rendering shared by the native reader and public post pages.
export function blocksToHtml(
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
    if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) continue;
    const block = raw as Record<string, unknown>;
    const type = String(block.type ?? '');
    if (type === 'markdown') content += markdownToHtml(String(block.text ?? ''));
    else if (type === 'heading') content += `<h2>${escapeHtml(block.text)}</h2>`;
    else if (type === 'paragraph') content += `<p>${escapeHtml(block.text)}</p>`;
    else if (type === 'bullet_list' && Array.isArray(block.items)) {
      content += '<ul>';
      for (const item of block.items) {
        if (String(item).trim()) content += `<li>${escapeHtml(item)}</li>`;
      }
      content += '</ul>';
    } else if (type === 'image' && isHttpsUrl(block.url)) {
      const source = String(block.url).trim();
      const caption = escapeHtml(block.caption);
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
