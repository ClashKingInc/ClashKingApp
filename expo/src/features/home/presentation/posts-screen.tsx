import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { InlineBackControl } from '../../../ui/native-back-context';
import { ArrowLeft, ArrowRight, CloudOff, FileText, Play, RefreshCw } from 'lucide-react-native';
import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
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
  ckRadius,
  ckSpacing,
  useCKTheme,
} from '../../../ui';
import { AppAnnouncement, type AnnouncementService } from '../data';
import { OfficialBlogService } from '../data/official-blog-service';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { ProfileTabs } from '../../../ui/profile-tabs';
import { colorWithAlpha } from '../../../ui/tokens';
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
  const openingStoryRef = useRef(false);
  const [storyError, setStoryError] = useState(false);
  const [posts, setPosts] = useState<readonly AppAnnouncement[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const nextOffset = useRef(0);
  const [source, setSource] = useState('all');
  const [error, setError] = useState<unknown>();
  const loadingRef = useRef(false);
  const scrollMetrics = useRef({ height: 0, viewport: 0, offset: 0 });
  const generation = useRef(0);
  const officialBlog = useRef(new OfficialBlogService()).current;
  const officialPage = useRef(1);
  const officialHasMore = useRef(true);
  const ownHasMore = useRef(true);
  const [openingArticle, setOpeningArticle] = useState(false);
  const articleRequest = useRef(0);
  useEffect(
    () => () => {
      articleRequest.current += 1;
    },
    [],
  );
  const { openAnnouncement, presentation } = useAnnouncementPresentation();
  const isGrid = contentWidth - 2 * ckSpacing.lg >= 340;
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
      if (loadingRef.current && !reset) return;
      const requestGeneration = reset ? ++generation.current : generation.current;
      loadingRef.current = true;
      setLoading(true);
      setError(undefined);
      const current = () => requestGeneration === generation.current;
      const append = (items: readonly AppAnnouncement[]) => {
        if (!current()) return;
        setPosts((previous) =>
          [...new Map([...previous, ...items].map((item) => [item.id, item])).values()].sort(
            (a, b) => (b.publishedAt?.getTime() ?? 0) - (a.publishedAt?.getTime() ?? 0),
          ),
        );
      };
      const updateMore = () => {
        if (current()) setHasMore(ownHasMore.current || officialHasMore.current);
      };
      if (reset) {
        articleRequest.current += 1;
        setOpeningArticle(false);
        setPosts([]);
        setStories([]);
        setStoriesLoading(true);
        setStoryError(false);
        void service
          .getPublishedPosts(5, 0, 'story')
          .then((page) => {
            if (current()) setStories(page.items.filter((item) => item.isStory));
          })
          .catch(() => {
            if (current()) setStoryError(true);
          })
          .finally(() => {
            if (current()) setStoriesLoading(false);
          });
        officialPage.current = 1;
        officialHasMore.current = true;
        ownHasMore.current = true;
        nextOffset.current = 0;
        setHasMore(true);
      }
      // Render each source when it completes. A timeout at Supercell must not
      // hold back our own posts or create a retry/error panel for official news.
      await Promise.all([
        ownHasMore.current
          ? service
              .getPublishedPosts(20, nextOffset.current, 'article')
              .then((page) => {
                if (!current()) return;
                append(page.items.filter((item) => !item.isStory));
                nextOffset.current = page.nextOffset;
                ownHasMore.current = page.hasMore;
              })
              .catch((reason: unknown) => {
                if (current()) setError(reason);
              })
              .finally(updateMore)
          : Promise.resolve(),
        officialHasMore.current
          ? officialBlog
              .getPage(officialPage.current, locale)
              .then((page) => {
                if (!current()) return;
                append(page.items);
                officialPage.current += 1;
                officialHasMore.current = page.hasMore;
              })
              .catch(() => {
                // Keep already displayed articles; try this source again on refresh.
                if (current()) officialHasMore.current = false;
              })
              .finally(updateMore)
          : Promise.resolve(),
      ]);
      if (current()) {
        setLoading(false);
        loadingRef.current = false;
      }
    },
    [locale, service, officialBlog],
  );

  useEffect(() => {
    const timer = setTimeout(() => void load(true), 0);
    return () => {
      clearTimeout(timer);
      generation.current += 1;
      articleRequest.current += 1;
    };
  }, [load]);

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
    if (openingStoryRef.current) return;
    openingStoryRef.current = true;
    setOpeningStory(id);
    setStoryError(false);
    try {
      // Revalidate public availability before replaying cached HTML.
      const current = await service.getAnnouncement(id);
      if (!current || !(await openAnnouncement(current))) {
        setStoryError(true);
        // The service also returns null for transport failures. Keep the cached row
        // so a temporary outage does not erase a story the user can retry.
      }
    } catch {
      setStoryError(true);
    } finally {
      openingStoryRef.current = false;
      setOpeningStory(undefined);
    }
  };

  const openPost = async (post: AppAnnouncement) => {
    if (openingArticle) return;
    const request = ++articleRequest.current;
    setOpeningArticle(true);
    setStoryError(false);
    try {
      const article = post.id.startsWith('supercell:') ? await officialBlog.getArticle(post) : post;
      if (request === articleRequest.current)
        await openAnnouncement(article, () => request === articleRequest.current);
    } catch {
      if (request === articleRequest.current && !post.id.startsWith('supercell:'))
        setStoryError(true);
    } finally {
      if (request === articleRequest.current) setOpeningArticle(false);
    }
  };

  const loadNearEnd = useCallback(() => {
    const { height, viewport, offset } = scrollMetrics.current;
    const sourceHasMore =
      source === 'official'
        ? officialHasMore.current
        : source === 'clashking'
          ? ownHasMore.current
          : hasMore;
    // Recheck after a page arrives: a short first page or a source filter
    // may not fill the viewport enough to produce another scroll event.
    if (
      !loadingRef.current &&
      !error &&
      sourceHasMore &&
      viewport > 0 &&
      height - viewport - offset < 400
    )
      void load();
  }, [error, hasMore, load, source]);

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(loadNearEnd, 0);
    return () => clearTimeout(timer);
  }, [loading, loadNearEnd]);

  const visiblePosts = posts.filter(
    (post) =>
      source === 'all' ||
      (source === 'official'
        ? post.id.startsWith('supercell:')
        : !post.id.startsWith('supercell:')),
  );
  const featured = visiblePosts[0];
  const archive = visiblePosts.slice(1);
  const contents =
    visiblePosts.length === 0 && loading ? (
      <PostsLoadingSkeleton isGrid={isGrid} />
    ) : visiblePosts.length === 0 && error ? (
      <EmptyState
        actionLabel={t('generalRetry')}
        icon={<CloudOff color={theme.onSurfaceVariant} size={28} />}
        onAction={() => void load(true)}
        title={t('postsLoadFailed')}
      />
    ) : (
      <>
        {featured ? (
          <PostArchiveCard
            featured
            post={featured}
            intlLocale={localeTag}
            onOpen={() => void openPost(featured)}
          />
        ) : (
          <EmptyState
            icon={<FileText color={theme.onSurfaceVariant} size={28} />}
            title={t('postsEmpty')}
          />
        )}
        {archive.length ? (
          <ResponsiveGrid gap={14} minItemWidth={160} maxColumns={layout.isExpanded ? 3 : 2}>
            {archive.map((post) => (
              <PostArchiveCard
                key={post.id}
                post={post}
                intlLocale={localeTag}
                onOpen={() => void openPost(post)}
              />
            ))}
          </ResponsiveGrid>
        ) : null}
        {error ? (
          <EmptyState
            actionLabel={t('generalRetry')}
            icon={<RefreshCw color={theme.onSurfaceVariant} size={28} />}
            onAction={() => void load()}
            title={t('postsLoadFailed')}
          />
        ) : loading && posts.length > 0 ? (
          <View style={styles.paginationProgress}>
            <ActivityIndicator color={theme.primary} accessibilityLabel={t('generalLoading')} />
          </View>
        ) : null}
      </>
    );

  return (
    <SafeAreaView
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
      style={[styles.safe, { backgroundColor: theme.background }]}
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
        onLayout={({ nativeEvent }) => {
          scrollMetrics.current.viewport = nativeEvent.layout.height;
          loadNearEnd();
        }}
        onContentSizeChange={(_width, height) => {
          scrollMetrics.current.height = height;
          loadNearEnd();
        }}
        onScroll={({ nativeEvent }) => {
          scrollMetrics.current.offset = Math.max(0, nativeEvent.contentOffset.y);
          loadNearEnd();
        }}
        scrollEventThrottle={100}
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
        {openingArticle ? (
          <CKText muted role="bodySmall">
            {t('generalLoading')}
          </CKText>
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
        <ProfileTabs
          variant="underline"
          overflow="fit"
          selectedKey={source}
          onSelect={setSource}
          tabs={[
            { key: 'all', label: t('generalAll') },
            { key: 'official', label: 'Clash of Clans' },
            { key: 'clashking', label: 'ClashKing' },
          ]}
        />
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
  featured = false,
}: {
  post: AppAnnouncement;
  intlLocale: string;
  onOpen: () => void;
  featured?: boolean;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const official = post.id.startsWith('supercell:');
  const dateLabel = post.publishedAt
    ? new Intl.DateTimeFormat(intlLocale, { dateStyle: 'medium' }).format(post.publishedAt)
    : null;
  const sourceLabel = official ? 'Clash of Clans' : 'ClashKing';
  if (featured && post.bannerImageUrl)
    return (
      <PressableSurface
        accessibilityLabel={post.title}
        accessibilityRole="button"
        onPress={onOpen}
        radius={ckRadius.card}
        style={styles.featured}
      >
        <View style={StyleSheet.absoluteFill}>
          <MobileWebImage
            imageUrl={post.bannerImageUrl}
            contentFit="cover"
            style={StyleSheet.absoluteFill}
          />
          <HeroHeaderScrim edgeColor="#0B0B0C" strength={0.8} />
        </View>
        <View style={styles.featuredCopy}>
          <CKText role="metadata" style={styles.heroMetadata}>
            {sourceLabel}
            {dateLabel ? ` · ${dateLabel}` : ''}
          </CKText>
          <CKText role="screenTitle" style={styles.heroTitle}>
            {post.title}
          </CKText>
        </View>
      </PressableSurface>
    );
  return (
    <PressableSurface
      accessibilityLabel={post.title}
      accessibilityRole="button"
      onPress={onOpen}
      radius={ckRadius.tile}
      style={[
        styles.card,
        { backgroundColor: theme.surface, borderColor: colorWithAlpha(theme.outlineVariant, 0.16) },
      ]}
    >
      {post.bannerImageUrl ? (
        <MobileWebImage
          contentFit="cover"
          imageUrl={post.bannerImageUrl}
          style={[styles.cardImage, { backgroundColor: theme.surfaceContainerHighest }]}
          testID="post-archive-image"
          transition={160}
        />
      ) : null}
      <View style={styles.cardCopy}>
        <CKText role="metadata" style={{ color: official ? theme.secondary : theme.primary }}>
          {sourceLabel}
        </CKText>
        <CKText
          role="rowTitle"
          numberOfLines={4}
          style={[styles.cardTitle, isRtl && styles.rtlText]}
        >
          {post.title}
        </CKText>
        {dateLabel ? <PostDateLabel label={dateLabel} /> : null}
        {post.pinnedOnHome ? <PostDotLabel color={theme.primary} label={t('postsPinned')} /> : null}
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
  archive: { gap: ckSpacing.lg, paddingTop: ckSpacing.lg },
  featured: { minHeight: 300, justifyContent: 'flex-end', borderWidth: 0 },
  featuredCopy: { padding: 24, paddingTop: 120, gap: 12 },
  heroMetadata: { color: '#E5E5EA' },
  heroTitle: { color: '#FFFFFF', fontSize: 28, lineHeight: 33 },
  list: { gap: 14 },
  card: { width: '100%', flex: 1 },
  cardImage: { width: '100%', aspectRatio: 16 / 9 },
  cardCopy: { flex: 1, minWidth: 0, gap: 10, padding: 14 },
  cardTitleRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  cardTitle: { fontWeight: '700', lineHeight: 20 },
  cardSubtitle: { lineHeight: 19 },
  labels: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 },
  rowRtl: { flexDirection: 'row-reverse' },
  rtlText: { textAlign: 'right' },
  dotLabel: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 7, height: 7, borderRadius: 4 },
  dotText: { fontWeight: '700' },
  paginationProgress: { alignItems: 'center', paddingVertical: ckSpacing.lg },
  pressed: { opacity: 0.82 },
  disabled: { opacity: 0.5 },
  skeletonCard: { overflow: 'hidden', borderRadius: ckRadius.chip },
  skeletonCopy: { padding: 14, gap: 12 },
  skeletonTitle: { flex: 1, gap: 8 },
});
