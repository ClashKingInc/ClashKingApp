import {
  ArrowLeft,
  ArrowRight,
  ChevronLeft,
  ChevronRight,
  CloudOff,
  FileText,
  RefreshCw,
} from 'lucide-react-native';
import { useCallback, useEffect, useRef, useState } from 'react';
import {
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  PressableSurface,
  ResponsiveGrid,
  Skeleton,
  centeredContentPadding,
  ckBreakpoints,
  ckRadius,
  ckSpacing,
  useCKTheme,
} from '../../../ui';
import type { AnnouncementService, AppAnnouncement } from '../data';
import { PostDateLabel } from './announcement-article-screen';
import { useAnnouncementPresentation } from './announcement-presenter';

export interface PostsScreenProps {
  readonly service: AnnouncementService;
  readonly onBack?: () => void;
  readonly initialPostId?: string;
}

export function PostsScreen({ service, onBack, initialPostId }: PostsScreenProps) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const { width: windowWidth } = useWindowDimensions();
  const [contentWidth, setContentWidth] = useState(windowWidth);
  const [posts, setPosts] = useState<readonly AppAnnouncement[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [nextOffset, setNextOffset] = useState(0);
  const [error, setError] = useState<unknown>();
  const loadingRef = useRef(false);
  const generation = useRef(0);
  const { openAnnouncement, presentation } = useAnnouncementPresentation();
  const isDesktopWeb = Platform.OS === 'web' && windowWidth >= ckBreakpoints.desktop;
  const horizontalPadding = centeredContentPadding(contentWidth, 1200, ckSpacing.lg);
  const localeTag = toIntlLocale(locale);

  const load = useCallback(
    async (reset = false) => {
      if (loadingRef.current) return;
      loadingRef.current = true;
      setLoading(true);
      setError(undefined);
      const requestGeneration = reset ? ++generation.current : generation.current;
      const offset = reset ? 0 : nextOffset;
      if (reset) {
        setPosts([]);
        setNextOffset(0);
        setHasMore(true);
      }
      try {
        const page = await service.getPublishedPosts(20, offset);
        if (requestGeneration !== generation.current) return;
        setPosts((current) => (reset ? page.items : [...current, ...page.items]));
        setNextOffset(page.nextOffset);
        setHasMore(page.hasMore);
      } catch (nextError) {
        if (requestGeneration === generation.current) setError(nextError);
      } finally {
        if (requestGeneration === generation.current) setLoading(false);
        loadingRef.current = false;
      }
    },
    [nextOffset, service],
  );

  useEffect(() => {
    const timer = setTimeout(() => void load(true), 0);
    return () => clearTimeout(timer);
  }, [service]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!initialPostId) return;
    let active = true;
    void service.getAnnouncement(initialPostId).then((post) => {
      if (active && post) void openAnnouncement(post, () => active);
    });
    return () => {
      active = false;
    };
  }, [initialPostId, openAnnouncement, service]);

  const contents =
    posts.length === 0 && loading ? (
      <PostsLoadingSkeleton isGrid={isDesktopWeb} />
    ) : posts.length === 0 && error ? (
      <EmptyState
        actionLabel={t('generalRetry')}
        icon={<CloudOff color={theme.onSurfaceVariant} size={28} />}
        onAction={() => void load(true)}
        title={t('postsLoadFailed')}
      />
    ) : posts.length === 0 ? (
      <EmptyState
        icon={<FileText color={theme.onSurfaceVariant} size={28} />}
        title={t('postsEmpty')}
      />
    ) : (
      <>
        {isDesktopWeb ? (
          <ResponsiveGrid gap={16} maxColumns={2} minItemWidth={360}>
            {posts.map((post) => (
              <PostArchiveCard
                key={post.id}
                intlLocale={localeTag}
                onOpen={() => void openAnnouncement(post)}
                post={post}
              />
            ))}
          </ResponsiveGrid>
        ) : (
          <View style={styles.list}>
            {posts.map((post) => (
              <PostArchiveCard
                key={post.id}
                intlLocale={localeTag}
                onOpen={() => void openAnnouncement(post)}
                post={post}
              />
            ))}
          </View>
        )}
        {error ? (
          <EmptyState
            actionLabel={t('generalRetry')}
            icon={<RefreshCw color={theme.onSurfaceVariant} size={28} />}
            onAction={() => void load()}
            title={t('postsLoadFailed')}
          />
        ) : hasMore ? (
          <View style={styles.loadMoreRow}>
            <Pressable
              accessibilityRole="button"
              disabled={loading}
              onPress={() => void load()}
              style={({ pressed }) => [
                styles.loadMore,
                { backgroundColor: theme.surfaceContainerHighest },
                pressed && styles.pressed,
                loading && styles.disabled,
              ]}
            >
              <CKText role="rowTitle">{loading ? t('generalLoading') : t('postsLoadMore')}</CKText>
            </Pressable>
          </View>
        ) : null}
      </>
    );

  return (
    <SafeAreaView
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
      style={[styles.safe, { backgroundColor: theme.surface }]}
    >
      <View style={styles.header}>
        {onBack ? (
          <Pressable
            accessibilityLabel={materialBackLabel(locale)}
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
        ) : null}
        <CKText role="screenTitle">{t('postsTitle')}</CKText>
      </View>
      <ScrollView
        alwaysBounceVertical
        contentContainerStyle={[
          styles.content,
          { paddingHorizontal: horizontalPadding, paddingBottom: 32 },
        ]}
        refreshControl={
          <RefreshControl refreshing={loading && posts.length > 0} onRefresh={() => load(true)} />
        }
      >
        <CKText muted role="bodyMedium">
          {t('postsDescription')}
        </CKText>
        <View style={styles.archive}>{contents}</View>
      </ScrollView>
      {presentation}
    </SafeAreaView>
  );
}

function PostArchiveCard({
  post,
  intlLocale,
  onOpen,
}: {
  post: AppAnnouncement;
  intlLocale: string;
  onOpen: () => void;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const hasImage = Boolean(post.bannerImageUrl);
  const dateLabel = post.publishedAt
    ? new Intl.DateTimeFormat(intlLocale, { dateStyle: 'medium' }).format(post.publishedAt)
    : null;
  const showLabels = post.isCurrent() || post.isStory || post.pinnedOnHome;

  return (
    <PressableSurface
      accessibilityLabel={post.title}
      accessibilityRole="button"
      onPress={onOpen}
      radius={ckRadius.chip}
      style={styles.card}
    >
      {hasImage ? (
        <MobileWebImage
          contentFit="cover"
          imageUrl={post.bannerImageUrl!}
          style={[styles.cardImage, { backgroundColor: theme.surfaceContainerHighest }]}
          testID="post-archive-image"
          transition={160}
        />
      ) : null}
      <View style={[styles.cardCopy, { paddingTop: hasImage ? 14 : 16 }]}>
        <View testID="post-card-title-row" style={[styles.cardTitleRow, isRtl && styles.rowRtl]}>
          <CKText
            numberOfLines={2}
            role="titleLarge"
            style={[styles.cardTitle, isRtl && styles.rtlText]}
          >
            {post.title}
          </CKText>
          {isRtl ? (
            <ChevronLeft color={theme.onSurfaceVariant} size={30} />
          ) : (
            <ChevronRight color={theme.onSurfaceVariant} size={30} />
          )}
        </View>
        {dateLabel ? <PostDateLabel label={dateLabel} /> : null}
        {post.subtitle ? (
          <CKText
            muted
            numberOfLines={hasImage ? 2 : 3}
            role="bodyMedium"
            style={[styles.cardSubtitle, isRtl && styles.rtlText]}
          >
            {post.subtitle}
          </CKText>
        ) : null}
        {showLabels ? (
          <View style={[styles.labels, isRtl && styles.rowRtl]}>
            {post.isCurrent() ? (
              <PostDotLabel color={theme.primary} label={t('postsCurrent')} />
            ) : null}
            {post.isStory ? <PostDotLabel color={theme.tertiary} label={t('postsStory')} /> : null}
            {post.pinnedOnHome ? (
              <PostDotLabel color={theme.secondary} label={t('postsPinned')} />
            ) : null}
          </View>
        ) : null}
      </View>
    </PressableSurface>
  );
}

function PostDotLabel({ color, label }: { color: string; label: string }) {
  const { isRtl } = useI18n();
  return (
    <View style={[styles.dotLabel, isRtl && styles.rowRtl]}>
      <View style={[styles.dot, { backgroundColor: color }]} />
      <CKText muted role="labelSmall" style={styles.dotText}>
        {label}
      </CKText>
    </View>
  );
}

function PostsLoadingSkeleton({ isGrid }: { isGrid: boolean }) {
  const cards = [true, false, true, false];
  return isGrid ? (
    <ResponsiveGrid gap={16} maxColumns={2} minItemWidth={360}>
      {cards.map((showImage, index) => (
        <PostSkeletonCard key={index} showImage={showImage} />
      ))}
    </ResponsiveGrid>
  ) : (
    <View style={styles.list}>
      {cards.slice(0, 3).map((_, index) => (
        <PostSkeletonCard key={index} showImage={index === 0} />
      ))}
    </View>
  );
}

function PostSkeletonCard({ showImage }: { showImage: boolean }) {
  return (
    <View style={styles.skeletonCard}>
      {showImage ? <Skeleton height={188} radius={0} /> : null}
      <View style={styles.skeletonCopy}>
        <View style={styles.cardTitleRow}>
          <View style={styles.skeletonTitle}>
            <Skeleton height={24} radius={6} />
            <Skeleton height={24} radius={6} width={180} />
          </View>
          <Skeleton height={30} radius={ckRadius.pill} width={30} />
        </View>
        <Skeleton height={14} radius={6} width={108} />
        <Skeleton height={16} radius={6} />
        <Skeleton height={16} radius={6} width={220} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  header: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: ckSpacing.md,
    gap: ckSpacing.sm,
  },
  back: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  content: { paddingTop: ckSpacing.lg },
  archive: { marginTop: ckSpacing.lg, gap: ckSpacing.lg },
  list: { gap: 14 },
  card: { width: '100%' },
  cardImage: { width: '100%', height: 188 },
  cardCopy: { paddingHorizontal: 14, paddingBottom: 16, gap: 10 },
  cardTitleRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  cardTitle: { flex: 1, fontWeight: '700', lineHeight: 27 },
  cardSubtitle: { lineHeight: 19 },
  labels: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 },
  rowRtl: { flexDirection: 'row-reverse' },
  rtlText: { textAlign: 'right' },
  dotLabel: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 7, height: 7, borderRadius: 4 },
  dotText: { fontWeight: '700' },
  loadMoreRow: { alignItems: 'center' },
  loadMore: {
    minHeight: 44,
    paddingHorizontal: 20,
    justifyContent: 'center',
    borderRadius: ckRadius.pill,
  },
  pressed: { opacity: 0.82 },
  disabled: { opacity: 0.5 },
  skeletonCard: { overflow: 'hidden', borderRadius: ckRadius.chip },
  skeletonCopy: { padding: 14, gap: 12 },
  skeletonTitle: { flex: 1, gap: 8 },
});
