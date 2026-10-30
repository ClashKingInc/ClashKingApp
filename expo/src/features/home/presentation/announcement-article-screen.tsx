import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { InlineBackControl } from '../../../ui/native-back-context';
import { ArrowLeft, ArrowRight, CalendarDays } from 'lucide-react-native';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import { CKText, ckSpacing, useCKTheme } from '../../../ui';
import { ckFontFamily } from '../../../ui/tokens';
import type { AppAnnouncement } from '../data';
import { AnnouncementWebView } from './announcement-webview';

export function PostArticleScreen({ post, onBack }: { post: AppAnnouncement; onBack: () => void }) {
  const layout = useAdaptiveLayout();
  const theme = useCKTheme();
  const { locale, isRtl } = useI18n();
  const dateLabel = post.publishedAt
    ? new Intl.DateTimeFormat(toIntlLocale(locale), { dateStyle: 'full' }).format(post.publishedAt)
    : null;
  const articleHtml = post.body?.trim()
    ? buildPostArticleHtml(post, dateLabel, theme, isRtl, layout.isExpanded)
    : null;

  return (
    <SafeAreaView
      edges={layout.isDuo ? ['top', 'bottom', 'left', 'right'] : ['top', 'bottom']}
      style={[styles.page, { backgroundColor: theme.surface }]}
    >
      <AnnouncementHeader onBack={onBack} />
      <View
        style={[styles.articleBody, layout.isExpanded && { maxWidth: layout.readableMaxWidth }]}
      >
        <AnnouncementWebView
          html={articleHtml}
          url={!articleHtml?.trim() ? post.htmlUrl : undefined}
        />
      </View>
    </SafeAreaView>
  );
}

/** Home and the Posts archive share the same article reading surface. */
export function HomeAnnouncementArticleScreen({
  post,
  onBack,
}: {
  post: AppAnnouncement;
  onBack: () => void;
}) {
  return <PostArticleScreen post={post} onBack={onBack} />;
}

export function postArticleHtml(html: string | null, stripHeroImage: boolean): string | null {
  if (!stripHeroImage || !html) return html;
  return html.replace(/<img class="hero" src="[^"]*" alt="">/, '');
}

/** Compose metadata, hero and body in one scrollable reading surface. */
export function buildPostArticleHtml(
  post: AppAnnouncement,
  dateLabel: string | null,
  theme: ReturnType<typeof useCKTheme>,
  isRtl = false,
  expanded = false,
): string {
  const hero =
    post.bannerImageUrl && isHttpsUrl(post.bannerImageUrl)
      ? `<figure class="hero"><img src="${escapeHtml(post.bannerImageUrl)}" alt=""></figure>`
      : '';
  const metadata = dateLabel ? `<time>${escapeHtml(dateLabel)}</time>` : '';
  const subtitle = post.subtitle ? `<p class="subtitle">${escapeHtml(post.subtitle)}</p>` : '';
  const header = `<header>${hero}<div class="intro">${metadata}<h1>${escapeHtml(post.title)}</h1>${subtitle}</div></header>`;
  const body = postArticleHtml(post.body, Boolean(hero)) ?? '';
  const content = /<body[^>]*>/i.test(body)
    ? body
        .replace(/<body[^>]*>/i, (match) => `${match}${header}<main class="article-content">`)
        .replace(/<\/body>/i, '</main></body>')
    : `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>${header}<main class="article-content">${body}</main></body></html>`;
  const css = `<style>
    :root{color-scheme:${theme.background === '#030304' ? 'dark' : 'light'}}
    *{box-sizing:border-box}html,body{margin:0;padding:0;min-height:100%;background:${theme.surface};color:${theme.onSurface}}
    body{font-family:"${ckFontFamily}",-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;line-height:1.7;direction:${isRtl ? 'rtl' : 'ltr'}}
    header,.article-content{max-width:760px;margin:0 auto}header{padding-bottom:8px}
    figure.hero{margin:0 0 28px}figure.hero img{display:block;width:100%;height:auto;max-height:none;object-fit:contain}
    .intro,.article-content{padding-left:22px;padding-right:22px}
    time{display:block;color:${theme.onSurfaceVariant};font-size:13px;font-weight:600;margin-bottom:12px}
    h1{font-size:clamp(30px,6vw,44px);line-height:1.13;margin:0 0 15px;font-weight:800}
    .subtitle{font-size:18px;line-height:1.5;color:${theme.onSurfaceVariant};margin:0 0 22px}
    .article-content{font-size:17px;padding-bottom:52px;overflow-wrap:anywhere}
    .article-content p{margin:0 0 20px}.article-content h1,.article-content h2,.article-content h3{line-height:1.22;margin:34px 0 14px}
    .article-content h1{font-size:28px}.article-content h2{font-size:25px}.article-content h3{font-size:21px}
    .article-content ul,.article-content ol{padding-inline-start:24px;margin:0 0 22px}.article-content li{margin:7px 0}
    .article-content img{display:block;max-width:100%;height:auto;border-radius:16px}
    .article-content figure{margin:26px 0}.article-content figcaption{font-size:13px;color:${theme.onSurfaceVariant};margin-top:8px}
    a{color:${theme.secondary};text-decoration:underline}blockquote{margin:24px 0;padding:4px 0 4px 18px;border-inline-start:3px solid ${theme.primary};color:${theme.onSurfaceVariant}}
    code,pre{font-family:ui-monospace,SFMono-Regular,monospace;background:${theme.surfaceContainerHighest};border-radius:6px}
    code{padding:2px 5px}pre{overflow:auto;padding:16px;margin:20px 0}pre code{padding:0}
    ${expanded ? '.article-content{font-size:20px;line-height:1.75}.subtitle{font-size:21px}time{font-size:15px}.intro,.article-content{padding-left:28px;padding-right:28px}' : ''}
  </style>`;
  return /<\/head>/i.test(content)
    ? content.replace(/<\/head>/i, `${css}</head>`)
    : content.replace(/<body[^>]*>/i, (match) => `${css}${match}`);
}

function isHttpsUrl(value: string): boolean {
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

export function PostDateLabel({ label }: { label: string }) {
  const theme = useCKTheme();
  const { isRtl } = useI18n();
  return (
    <View style={[styles.dateRow, isRtl && styles.rowRtl]}>
      <CalendarDays color={theme.onSurfaceVariant} size={15} />
      <CKText muted role="metadata" style={styles.dateText}>
        {label}
      </CKText>
    </View>
  );
}

function AnnouncementHeader({ title, onBack }: { title?: string; onBack: () => void }) {
  const { isRtl, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={[styles.navigationHeader, isRtl && styles.rowRtl]}>
      <InlineBackControl onBack={onBack}>
        <Pressable
          accessibilityLabel={title ?? materialBackLabel(locale)}
          accessibilityRole="button"
          hitSlop={8}
          onPress={onBack}
          style={styles.back}
        >
          {isRtl ? (
            <ArrowRight color={theme.onSurface} size={24} />
          ) : (
            <ArrowLeft color={theme.onSurface} size={24} />
          )}
        </Pressable>
      </InlineBackControl>
      {title ? (
        <CKText
          numberOfLines={1}
          role="titleLarge"
          style={[styles.navigationTitle, isRtl && styles.rtlText]}
        >
          {title}
        </CKText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1 },
  navigationHeader: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: ckSpacing.md,
    gap: ckSpacing.sm,
  },
  back: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  navigationTitle: { flex: 1 },
  dateRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  dateText: { fontWeight: '600' },
  rowRtl: { flexDirection: 'row-reverse' },
  rtlText: { textAlign: 'right' },
  articleBody: { flex: 1, width: '100%', maxWidth: 900, alignSelf: 'center' },
});
