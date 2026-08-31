import { useEffect, useMemo, useState } from 'react';
import { Animated, Easing, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import {
  Castle,
  ChevronLeft,
  ChevronRight,
  ChartNoAxesColumnIncreasing,
  Hourglass,
  Medal,
  Sparkles,
  Tag,
  Trophy,
  type LucideIcon,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n, type I18nValue } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  ckColors,
  colorWithAlpha,
  useCKAccessibility,
  useCKTheme,
} from '../../../ui';
import type { HomeAnnouncement } from './contracts';

export interface HomeBannerItem {
  readonly id: string;
  readonly title: string;
  readonly subtitle: string;
  readonly imageUrl: string;
  readonly color: string;
  readonly highlighted: boolean;
  readonly fallbackIcon: 'trophy' | 'medal' | 'hourglass' | 'rank' | 'castle' | 'tag' | 'sparkles';
  readonly announcement?: HomeAnnouncement;
  readonly sortKey?: Date;
}

export function buildHomeBannerItems(
  now: Date,
  announcements: readonly HomeAnnouncement[],
  t: I18nValue['t'],
  dark: boolean,
): HomeBannerItem[] {
  const event = (
    id: string,
    title: string,
    imageUrl: string,
    color: string,
    fallbackIcon: HomeBannerItem['fallbackIcon'],
    window: { start: Date; end: Date },
  ): HomeBannerItem => {
    const active = now >= window.start && now < window.end;
    const target = active ? window.end : window.start;
    return {
      id,
      title,
      imageUrl,
      color,
      highlighted: false,
      fallbackIcon,
      sortKey: target,
      subtitle: active
        ? t('todoEventEndsIn', { duration: remaining(target.getTime() - now.getTime()) })
        : t('todoEventStartsIn', { duration: remaining(target.getTime() - now.getTime()) }),
    };
  };
  const events = [
    event(
      'clan-games',
      t('todoEventClanGames'),
      ImageAssets.clanGamesMedals,
      ckColors.donationGreen,
      'trophy',
      monthly(now, 22, 8, 28, 8),
    ),
    event(
      'cwl',
      t('todoEventCwl'),
      ImageAssets.cwlSwordsNoBorder,
      ckColors.capitalPurple,
      'medal',
      monthly(now, 1, 0, 13, 0),
    ),
    event(
      'season',
      t('todoEventSeasonEnds'),
      ImageAssets.iconGoldPass,
      ckColors.warGold,
      'hourglass',
      season(now),
    ),
    event(
      'league-reset',
      t('todoEventLeagueReset'),
      ImageAssets.legendBlazonNoPadding,
      ckColors.legendBlue,
      'rank',
      season(now),
    ),
    event(
      'raid',
      t('todoEventRaidWeekend'),
      ImageAssets.raidAttacks,
      ckColors.builderBlue,
      'castle',
      raid(now),
    ),
  ].sort((a, b) => a.sortKey!.getTime() - b.sortKey!.getTime());
  return [
    ...announcements.map((announcement) => ({
      id: announcement.id,
      title: announcement.title,
      subtitle: announcement.subtitle,
      imageUrl: announcement.imageUrl ?? ImageAssets.builderWave,
      color: ckColors.warGold,
      highlighted: true,
      fallbackIcon: 'sparkles' as const,
      announcement,
      sortKey: announcement.startsAt,
    })),
    {
      id: 'creator-code',
      title: t('todoUseCodeClashKing'),
      subtitle: t('todoUseCodeClashKingDescription'),
      imageUrl: dark ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo,
      color: ckColors.primaryRed,
      highlighted: false,
      fallbackIcon: 'tag',
    },
    ...events,
  ];
}

function monthly(now: Date, startDay: number, startHour: number, endDay: number, endHour: number) {
  let start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), startDay, startHour));
  let end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), endDay, endHour));
  if (now >= end) {
    start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, startDay, startHour));
    end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, endDay, endHour));
  }
  return { start, end };
}

function seasonEnd(year: number, month: number) {
  const last = new Date(Date.UTC(year, month + 1, 0));
  const daysBack = (last.getUTCDay() + 6) % 7;
  return new Date(Date.UTC(year, month, last.getUTCDate() - daysBack, 5));
}

function season(now: Date) {
  let end = seasonEnd(now.getUTCFullYear(), now.getUTCMonth());
  if (now >= end) end = seasonEnd(now.getUTCFullYear(), now.getUTCMonth() + 1);
  return { start: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)), end };
}

function raid(now: Date) {
  const day = now.getUTCDay();
  let daysUntilFriday = (5 - day + 7) % 7;
  if (day === 5 && now.getUTCHours() >= 7) daysUntilFriday = 0;
  let start = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysUntilFriday, 7),
  );
  let end = new Date(start.getTime() + 3 * 86400000);
  if (now >= end) {
    start = new Date(start.getTime() + 7 * 86400000);
    end = new Date(start.getTime() + 3 * 86400000);
  }
  return { start, end };
}

function remaining(milliseconds: number) {
  const minutes = Math.max(0, Math.floor(milliseconds / 60000));
  if (minutes >= 1440)
    return `${Math.floor(minutes / 1440)}d ${Math.floor((minutes % 1440) / 60)}h`;
  if (minutes >= 60) return `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
  return `${minutes}m`;
}

function BannerCard({
  item,
  featured,
  mobile,
  isRtl,
  onPress,
}: {
  item: HomeBannerItem;
  featured?: boolean;
  mobile?: boolean;
  isRtl: boolean;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessible
      accessibilityRole={onPress ? 'button' : undefined}
      accessibilityLabel={`${item.title}, ${item.subtitle}`}
      disabled={!onPress}
      onPress={onPress}
      style={[
        styles.banner,
        mobile ? styles.mobileBanner : featured ? styles.featured : styles.event,
        isRtl && styles.rowRtl,
        {
          backgroundColor: colorWithAlpha(
            item.highlighted ? ckColors.warGold : item.color,
            featured ? 0.18 : 0.12,
          ),
          borderColor: colorWithAlpha(item.color, item.highlighted ? 0.58 : 0.32),
        },
      ]}
    >
      {item.highlighted ? <HighlightSweep color={item.color} /> : null}
      <View
        style={[
          styles.iconCircle,
          featured && styles.featuredIconCircle,
          mobile && styles.mobileIconCircle,
          { backgroundColor: colorWithAlpha(theme.surface, 0.76) },
        ]}
      >
        <MobileWebImage
          imageUrl={item.imageUrl}
          style={styles.image}
          errorFallback={
            <BannerFallback kind={item.fallbackIcon} color={item.color} size={featured ? 34 : 22} />
          }
        />
      </View>
      <View style={styles.copy}>
        <CKText
          role={mobile ? 'labelLarge' : featured ? 'titleSmall' : 'labelMedium'}
          style={styles.heavy}
          numberOfLines={1}
        >
          {item.title}
        </CKText>
        <CKText
          muted
          role={mobile ? 'labelMedium' : featured ? 'bodyMedium' : 'labelSmall'}
          numberOfLines={1}
        >
          {item.subtitle}
        </CKText>
      </View>
      {onPress ? (
        isRtl ? (
          <ChevronLeft size={featured || mobile ? 17 : 13} color={theme.onSurfaceVariant} />
        ) : (
          <ChevronRight size={featured || mobile ? 17 : 13} color={theme.onSurfaceVariant} />
        )
      ) : null}
    </Pressable>
  );
}

function BannerFallback({
  kind,
  color,
  size,
}: {
  kind: HomeBannerItem['fallbackIcon'];
  color: string;
  size: number;
}) {
  const icons: Record<HomeBannerItem['fallbackIcon'], LucideIcon> = {
    trophy: Trophy,
    medal: Medal,
    hourglass: Hourglass,
    rank: ChartNoAxesColumnIncreasing,
    castle: Castle,
    tag: Tag,
    sparkles: Sparkles,
  };
  const Icon = icons[kind];
  return <Icon color={color} size={size} />;
}

function HighlightSweep({ color }: { color: string }) {
  const { reduceMotion } = useCKAccessibility();
  const [progress] = useState(() => new Animated.Value(0));
  useEffect(() => {
    if (reduceMotion) {
      progress.setValue(0.5);
      return;
    }
    const animation = Animated.loop(
      Animated.timing(progress, {
        toValue: 1,
        duration: 2800,
        easing: Easing.inOut(Easing.quad),
        useNativeDriver: true,
      }),
    );
    animation.start();
    return () => animation.stop();
  }, [progress, reduceMotion]);
  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.highlight,
        {
          backgroundColor: colorWithAlpha(color, reduceMotion ? 0.06 : 0.11),
          transform: [
            { translateX: progress.interpolate({ inputRange: [0, 1], outputRange: [-180, 520] }) },
            { rotate: '-12deg' },
          ],
        },
      ]}
    />
  );
}

export function HomeEventBanner({
  announcements,
  desktop,
  onOpen,
}: {
  announcements: readonly HomeAnnouncement[];
  desktop: boolean;
  onOpen: (announcement: HomeAnnouncement) => void;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const items = useMemo(
    () => buildHomeBannerItems(new Date(), announcements, t, theme.background === '#030304'),
    [announcements, t, theme.background],
  );
  const [index, setIndex] = useState(0);
  const [availableWidth, setAvailableWidth] = useState(680);
  const safeIndex = Math.min(index, Math.max(0, items.length - 1));
  const action = (item: HomeBannerItem) =>
    item.announcement && isHomeAnnouncementOpenable(item.announcement)
      ? () => onOpen(item.announcement!)
      : undefined;
  if (desktop) {
    const featured = items.find((item) => !item.sortKey && !item.announcement) ?? items[0]!;
    const rest = items.filter((item) => item !== featured).slice(0, 8);
    const columns =
      availableWidth >= 920
        ? Math.min(rest.length, 5)
        : availableWidth >= 620
          ? Math.min(rest.length, 3)
          : Math.min(rest.length, 2);
    const cellWidth = columns > 0 ? (availableWidth - 8 * (columns - 1)) / columns : availableWidth;
    return (
      <View
        style={styles.desktop}
        onLayout={(event) => setAvailableWidth(event.nativeEvent.layout.width)}
      >
        <BannerCard item={featured} featured isRtl={isRtl} onPress={action(featured)} />
        <View style={styles.eventGrid}>
          {rest.map((item) => (
            <View key={item.id} style={{ width: cellWidth }}>
              <BannerCard item={item} isRtl={isRtl} onPress={action(item)} />
            </View>
          ))}
        </View>
      </View>
    );
  }
  return (
    <View
      style={styles.mobile}
      onLayout={(event) => setAvailableWidth(event.nativeEvent.layout.width)}
    >
      <ScrollView
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        style={isRtl ? styles.rtlScroll : undefined}
        onMomentumScrollEnd={(event) =>
          setIndex(
            Math.min(
              Math.max(0, items.length - 1),
              Math.max(
                0,
                Math.round(
                  event.nativeEvent.contentOffset.x /
                    Math.max(1, event.nativeEvent.layoutMeasurement.width),
                ),
              ),
            ),
          )
        }
      >
        {items.map((item) => (
          <View
            key={item.id}
            style={[{ width: availableWidth, paddingHorizontal: 1 }, isRtl && styles.rtlItem]}
          >
            <BannerCard item={item} mobile isRtl={isRtl} onPress={action(item)} />
          </View>
        ))}
      </ScrollView>
      <View style={styles.dots}>
        {items.map((item, dot) => (
          <View
            key={item.id}
            style={[
              styles.dot,
              { backgroundColor: dot === safeIndex ? theme.primary : theme.outlineVariant },
            ]}
          />
        ))}
      </View>
    </View>
  );
}

export function isHomeAnnouncementOpenable(announcement: HomeAnnouncement): boolean {
  return Boolean(
    announcement.storyUrl?.trim() || announcement.html?.trim() || announcement.htmlUrl?.trim(),
  );
}

const styles = StyleSheet.create({
  heavy: { fontWeight: '900' },
  copy: { flex: 1, gap: 2 },
  mobile: { gap: 8 },
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: StyleSheet.hairlineWidth,
    overflow: 'hidden',
  },
  featured: { height: 94, borderRadius: 22, paddingHorizontal: 18, paddingVertical: 14, gap: 16 },
  mobileBanner: { height: 64, borderRadius: 18, padding: 12, gap: 12 },
  event: { height: 62, borderRadius: 14, paddingHorizontal: 10, gap: 8 },
  iconCircle: { width: 34, height: 34, borderRadius: 17, padding: 5 },
  featuredIconCircle: { width: 58, height: 58, borderRadius: 29, padding: 8 },
  mobileIconCircle: { width: 40, height: 40, borderRadius: 20, padding: 6 },
  image: { width: '100%', height: '100%', resizeMode: 'contain' },
  desktop: { gap: 8 },
  eventGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  dots: { flexDirection: 'row', justifyContent: 'center', gap: 6 },
  dot: { width: 6, height: 6, borderRadius: 3 },
  rowRtl: { flexDirection: 'row-reverse' },
  rtlScroll: { transform: [{ scaleX: -1 }] },
  rtlItem: { transform: [{ scaleX: -1 }] },
  highlight: { position: 'absolute', top: -30, bottom: -30, width: 84 },
});
