import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { InlineBackControl } from '../../../ui/native-back-context';
import {
  ArrowLeft,
  ArrowRight,
  ChevronLeft,
  ChevronRight,
  CloudOff,
  FileText,
  Play,
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
  SkeletonContent,
  Skeleton,
  centeredContentPadding,
  ckBreakpoints,
  ckRadius,
  ckSpacing,
  useCKTheme,
} from '../../../ui';
import { AppAnnouncement, type AnnouncementService } from '../data';
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
  const layout = useAdaptiveLayout();
  const [contentWidth, setContentWidth] = useState(windowWidth);
  const [stories, setStories] = useState<readonly AppAnnouncement[]>([]);
  const [storiesLoading, setStoriesLoading] = useState(false);
  const [openingStory, setOpeningStory] = useState<string>();
  const [storyError, setStoryError] = useState(false);
  const [posts, setPosts] = useState<readonly AppAnnouncement[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [nextOffset, setNextOffset] = useState(0);
  const [error, setError] = useState<unknown>();
  const loadingRef = useRef(false);
  const generation = useRef(0);
  const { openAnnouncement, presentation } = useAnnouncementPresentation();
  const isDesktopWeb = Platform.OS === 'web' && windowWidth >= ckBreakpoints.desktop;
  const isGrid = isDesktopWeb || layout.isExpanded;
  // The outer SafeAreaView measurement still includes the Duo rail. Its list
  // children do not, so compare safe width to safe width when centering cards.
  const horizontalPadding = centeredContentPadding(
    layout.isDuo ? layout.usableWidth : contentWidth,
    layout.isExpanded ? layout.contentMaxWidth : layout.isDuo ? layout.contentMaxWidth : 1200,
    ckSpacing.lg,
  );
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
        setStories([]);
        setStoriesLoading(true);
        setStoryError(false);
        // Stories have their own server-filtered cursor. Article density must
        // not determine which of the five latest updates can be replayed.
        void service
          .getPublishedPosts(5, 0, 'story')
          .then((page) => {
            if (requestGeneration === generation.current)
              setStories(page.items.filter((item) => item.isStory));
          })
          .catch(() => {
            if (requestGeneration === generation.current) setStoryError(true);
          })
          .finally(() => {
            if (requestGeneration === generation.current) setStoriesLoading(false);
          });
        setNextOffset(0);
        setHasMore(true);
      }
      try {
        const page = await service.getPublishedPosts(20, offset, 'article');
        if (requestGeneration !== generation.current) return;
        const articles = page.items.filter((item) => !item.isStory);
        setPosts((current) => (reset ? articles : [...current, ...articles]));
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
      else if (active) setStoryError(true);
    });
    return () => {
      active = false;
    };
  }, [initialPostId, openAnnouncement, service]);

  const replayStory = async (id: string) => {
    if (openingStory) return;
    setOpeningStory(id);
    setStoryError(false);
    try {
      // Revalidate public availability before replaying cached HTML.
      const current = await service.getAnnouncement(id);
      if (!current || !(await openAnnouncement(current))) {
        setStoryError(true);
        if (!current) setStories((items) => items.filter((item) => item.id !== id));
      }
    } catch {
      setStoryError(true);
    } finally {
      setOpeningStory(undefined);
    }
  };

  const contents =
    posts.length === 0 && loading ? (
      <PostsLoadingSkeleton isGrid={isGrid} />
    ) : posts.length === 0 && error ? (
      <EmptyState
        actionLabel={t('generalRetry')}
        icon={<CloudOff color={theme.onSurfaceVariant} size={28} />}
        onAction={() => void load(true)}
        title={t('postsLoadFailed')}
      />
    ) : posts.length === 0 && !hasMore ? (
      <EmptyState
        icon={<FileText color={theme.onSurfaceVariant} size={28} />}
        title={t('postsEmpty')}
      />
    ) : (
      <>
        {posts.length && isGrid ? (
          <ResponsiveGrid
            gap={16}
            maxColumns={layout.isExpanded ? layout.columns(340, 3) : 2}
            minItemWidth={layout.isExpanded ? 340 : 360}
          >
            {posts.map((post) => (
              <PostArchiveCard
                key={post.id}
                intlLocale={localeTag}
                onOpen={() => void openAnnouncement(post)}
                post={post}
              />
            ))}
          </ResponsiveGrid>
        ) : posts.length ? (
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
        ) : null}
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
          <InlineBackControl onBack={onBack}>
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
          </InlineBackControl>
        ) : null}
        <CKText skeleton={false} role="screenTitle">
          {t('postsTitle')}
        </CKText>
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
        {storiesLoading && stories.length === 0 ? (
          <View
            style={styles.storyRow}
            accessibilityLabel={t('generalLoading')}
            accessibilityRole="progressbar"
          >
            {[0, 1, 2].map((key) => (
              <Skeleton key={key} height={62} width={62} radius={31} />
            ))}
          </View>
        ) : null}
        {stories.length > 0 ? (
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={[styles.storyRow, isRtl && styles.rowRtl]}
          >
            {stories.map((story) => (
              <Pressable
                key={story.id}
                accessibilityRole="button"
                accessibilityLabel={story.title}
                accessibilityState={{ disabled: !!openingStory, busy: openingStory === story.id }}
                disabled={!!openingStory}
                onPress={() => void replayStory(story.id)}
                style={({ pressed }) => [styles.storyCircle, pressed && styles.pressed]}
              >
                <View
                  style={[
                    styles.storyImage,
                    { borderColor: theme.primary, backgroundColor: theme.surfaceContainerHighest },
                  ]}
                >
                  {story.bannerImageUrl ? (
                    <MobileWebImage
                      imageUrl={story.bannerImageUrl}
                      contentFit="cover"
                      style={styles.storyArtwork}
                    />
                  ) : (
                    <Play size={24} color={theme.onSurface} />
                  )}
                </View>
                <CKText role="labelSmall" numberOfLines={2} style={styles.storyTitle}>
                  {story.title}
                </CKText>
              </Pressable>
            ))}
          </ScrollView>
        ) : null}
        {storyError ? (
          <CKText
            accessibilityRole="alert"
            muted
            role="bodySmall"
            style={{ marginBottom: ckSpacing.md }}
          >
            {t('postsLoadFailed')}
          </CKText>
        ) : null}
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
  const showLabels = post.isCurrent() || post.pinnedOnHome;

  return (
    <PressableSurface
      accessibilityLabel={post.title}
      accessibilityRole="button"
      onPress={onOpen}
      radius={ckRadius.chip}
      style={[styles.card, isRtl && styles.rowRtl]}
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
      <View style={styles.cardCopy}>
        <View testID="post-card-title-row" style={[styles.cardTitleRow, isRtl && styles.rowRtl]}>
          <CKText
            numberOfLines={2}
            role="rowTitle"
            style={[styles.cardTitle, isRtl && styles.rtlText]}
          >
            {post.title}
          </CKText>
          {isRtl ? (
            <ChevronLeft color={theme.onSurfaceVariant} size={20} />
          ) : (
            <ChevronRight color={theme.onSurfaceVariant} size={20} />
          )}
        </View>
        {dateLabel ? <PostDateLabel label={dateLabel} /> : null}
        {post.subtitle ? (
          <CKText
            muted
            numberOfLines={2}
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
  const layout = useAdaptiveLayout();
  const cards = [true, false, true, false];
  return isGrid ? (
    <ResponsiveGrid
      gap={16}
      maxColumns={layout.isExpanded ? layout.columns(340, 3) : 2}
      minItemWidth={layout.isExpanded ? 340 : 360}
    >
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
  const { t, locale } = useI18n();
  const placeholder = new AppAnnouncement(
    'pending',
    t('generalLoading'),
    t('generalLoading'),
    null,
    null,
    showImage ? 'pending' : null,
    null,
    null,
    null,
    'article',
    'pending',
    new Date(0),
  );
  return (
    <SkeletonContent>
      <PostArchiveCard post={placeholder} intlLocale={toIntlLocale(locale)} onOpen={() => {}} />
    </SkeletonContent>
  );
}

const styles = StyleSheet.create({
  storyRow: { flexDirection: 'row', gap: 12, paddingBottom: 20 },
  storyCircle: { width: 68, alignItems: 'center', gap: 6 },
  storyImage: {
    width: 62,
    height: 62,
    borderRadius: 31,
    borderWidth: 2,
    padding: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  storyArtwork: { width: 52, height: 52, borderRadius: 26 },
  storyTitle: { textAlign: 'center' },
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
  archive: { gap: ckSpacing.lg },
  list: { gap: 14 },
  card: { width: '100%', flexDirection: 'row', alignItems: 'flex-start', gap: 12, padding: 14 },
  cardImage: { width: 68, height: 68, borderRadius: 12 },
  cardCopy: { flex: 1, minWidth: 0, gap: 7 },
  cardTitleRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  cardTitle: { flex: 1, fontWeight: '700', lineHeight: 23 },
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
