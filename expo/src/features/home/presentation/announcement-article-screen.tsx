import { ArrowLeft, ArrowRight, CalendarDays } from 'lucide-react-native';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import type { AppAnnouncement } from '../data';
import { AnnouncementWebView } from './announcement-webview';

export function PostArticleScreen({ post, onBack }: { post: AppAnnouncement; onBack: () => void }) {
  const theme = useCKTheme();
  const { locale, isRtl } = useI18n();
  const hasImage = Boolean(post.bannerImageUrl);
  const articleHtml = postArticleHtml(post.body, hasImage);
  const dateLabel = post.publishedAt
    ? new Intl.DateTimeFormat(toIntlLocale(locale), { dateStyle: 'full' }).format(post.publishedAt)
    : null;

  return (
    <SafeAreaView style={[styles.page, { backgroundColor: theme.surface }]}>
      <AnnouncementHeader onBack={onBack} />
      <View
        style={[
          styles.articleHeader,
          hasImage && {
            backgroundColor: theme.surfaceContainerHighest,
            borderBottomColor: theme.outlineVariant,
            borderBottomWidth: StyleSheet.hairlineWidth,
          },
        ]}
      >
        <View style={styles.articleHeaderInner}>
          {hasImage ? (
            <MobileWebImage
              contentFit="cover"
              imageUrl={post.bannerImageUrl!}
              style={styles.articleHero}
              testID="post-article-hero-image"
              transition={160}
            />
          ) : null}
          <View style={[styles.articleCopy, hasImage ? styles.articleCopyWithImage : undefined]}>
            <CKText
              role={hasImage ? 'screenTitle' : 'titleLarge'}
              style={[styles.articleTitle, isRtl && styles.rtlText]}
            >
              {post.title}
            </CKText>
            {dateLabel ? <PostDateLabel label={dateLabel} /> : null}
            {post.subtitle ? (
              <CKText
                muted
                role={hasImage ? 'titleSmall' : 'bodyLarge'}
                style={[styles.subtitle, isRtl && styles.rtlText]}
              >
                {post.subtitle}
              </CKText>
            ) : null}
          </View>
        </View>
      </View>
      <View style={styles.articleBody}>
        <AnnouncementWebView
          html={articleHtml}
          url={!articleHtml?.trim() ? post.htmlUrl : undefined}
        />
      </View>
    </SafeAreaView>
  );
}

/** Home opens the compact Flutter announcement page; the Posts archive keeps its richer article chrome. */
export function HomeAnnouncementArticleScreen({
  post,
  onBack,
}: {
  post: AppAnnouncement;
  onBack: () => void;
}) {
  const theme = useCKTheme();
  return (
    <SafeAreaView style={[styles.page, { backgroundColor: theme.surface }]}>
      <AnnouncementHeader title={post.title} onBack={onBack} />
      <View style={styles.articleBody}>
        <AnnouncementWebView html={post.body} url={!post.body?.trim() ? post.htmlUrl : undefined} />
      </View>
    </SafeAreaView>
  );
}

export function postArticleHtml(html: string | null, stripHeroImage: boolean): string | null {
  if (!stripHeroImage || !html) return html;
  return html.replace(/<img class="hero" src="[^"]*" alt="">/, '');
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
  articleHeader: { width: '100%' },
  articleHeaderInner: { width: '100%', maxWidth: 900, alignSelf: 'center' },
  articleHero: {
    width: '100%',
    height: 240,
    borderBottomLeftRadius: ckRadius.chip,
    borderBottomRightRadius: ckRadius.chip,
    backgroundColor: '#00000010',
  },
  articleCopy: { paddingHorizontal: 20, paddingTop: 8, paddingBottom: 12, gap: 10 },
  articleCopyWithImage: { paddingTop: 18, paddingBottom: 20, gap: 14 },
  articleTitle: { fontWeight: '800', lineHeight: 28 },
  subtitle: { lineHeight: 22 },
  dateRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  dateText: { fontWeight: '600' },
  rowRtl: { flexDirection: 'row-reverse' },
  rtlText: { textAlign: 'right' },
  articleBody: { flex: 1, width: '100%', maxWidth: 900, alignSelf: 'center' },
});
