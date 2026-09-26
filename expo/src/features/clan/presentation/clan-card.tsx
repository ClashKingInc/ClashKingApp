import { useRef, type ReactNode } from 'react';
import { Pressable, StyleSheet, View, Platform, useWindowDimensions } from 'react-native';
import { useCKAccessibility } from '../../../ui/accessibility';
import { validClanSpringOrigin, type ClanSpringOrigin } from './clan-spring-transition';
import { Bookmark, ChevronRight, Mail, Shield, Users } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  PillSurface,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { ClanRosterItem } from './contracts';
import { clanMemberCapacityLabel } from './contracts';
import { clanTypeLabel } from './presentation-utils';

export function ClanRosterCard({
  item,
  onOpen,
  onLongPress,
  dragTestID,
}: {
  item: ClanRosterItem;
  onOpen: (origin?: ClanSpringOrigin) => void;
  onLongPress?: () => void;
  dragTestID?: string;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const cardRef = useRef<View>(null);
  const badgeRef = useRef<View>(null);
  const nameRef = useRef<View>(null);
  const nameWidth = useRef(0);
  const generation = useRef(0);
  const measured = useRef<ClanSpringOrigin | undefined>(undefined);
  const viewport = useWindowDimensions();
  const { reduceMotion } = useCKAccessibility();
  const capture = () => {
    measured.current = undefined;
    const request = ++generation.current;
    if (Platform.OS !== 'ios' || reduceMotion || viewport.fontScale > 1.2 || !item.badgeUrl) return;
    const rects: Partial<Record<'card' | 'badge' | 'name', ClanSpringOrigin['card']>> = {};
    for (const [part, ref] of [
      ['card', cardRef],
      ['badge', badgeRef],
      ['name', nameRef],
    ] as const) {
      ref.current?.measureInWindow((x, y, width, height) => {
        if (request !== generation.current) return;
        rects[part] = { x, y, width: part === 'name' ? nameWidth.current : width, height };
        if (!rects.card || !rects.badge || !rects.name) return;
        const origin: ClanSpringOrigin = {
          card: rects.card,
          badge: rects.badge,
          name: rects.name,
          viewport,
          badgeUrl: item.badgeUrl,
          title: item.name,
        };
        if (validClanSpringOrigin(origin, viewport.width, viewport.height))
          measured.current = origin;
      });
    }
  };
  return (
    <View ref={cardRef} collapsable={false}>
      <Surface radius={ckRadius.control} style={styles.card}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`Open clan ${item.name}`}
          onPressIn={capture}
          onPress={() => {
            const origin = measured.current;
            measured.current = undefined;
            generation.current += 1;
            onOpen(origin);
          }}
          onLongPress={
            onLongPress
              ? () => {
                  generation.current += 1;
                  measured.current = undefined;
                  onLongPress();
                }
              : undefined
          }
          testID={dragTestID}
          style={styles.pressable}
        >
          <View style={styles.content}>
            <View style={styles.badgeColumn}>
              {item.badgeUrl ? (
                <View ref={badgeRef} collapsable={false}>
                  <MobileWebImage
                    imageUrl={item.badgeUrl}
                    displaySize={{ width: 94, height: 94 }}
                    cachePolicy="memory-disk"
                    style={styles.badge}
                  />
                </View>
              ) : (
                <View style={styles.badgeFallback}>
                  <Users size={32} color={theme.onSurfaceVariant} />
                </View>
              )}
              <View style={styles.memberGap} />
              <ClanIconChip
                label={clanMemberCapacityLabel(item.members)}
                icon={<Users size={14} color={theme.onSurfaceVariant} />}
              />
            </View>
            <View style={styles.copy}>
              <View ref={nameRef} collapsable={false}>
                <CKText
                  role="titleMedium"
                  onTextLayout={(event) => {
                    nameWidth.current = event.nativeEvent.lines[0]?.width ?? 0;
                  }}
                  numberOfLines={1}
                  style={[styles.title, { paddingRight: item.bookmarked ? 28 : 86 }]}
                >
                  {item.name}
                </CKText>
              </View>
              {item.countryCode && item.locationName ? (
                <View style={styles.location}>
                  <MobileWebImage
                    imageUrl={ImageAssets.flag(item.countryCode)}
                    style={styles.flag}
                  />
                  <CKText muted role="labelLarge" numberOfLines={1} style={styles.locationName}>
                    {item.locationName}
                  </CKText>
                </View>
              ) : null}
              <View style={styles.chips}>
                {item.clanPoints > 0 ? (
                  <ClanImageChip
                    label={new Intl.NumberFormat(toIntlLocale(locale)).format(item.clanPoints)}
                    imageUrl={ImageAssets.trophies}
                  />
                ) : null}
                {item.warLeague ? (
                  <ClanImageChip
                    label={item.warLeague}
                    imageUrl={ImageAssets.getWarLeagueImage(item.warLeague)}
                  />
                ) : null}
                {item.type ? (
                  <ClanIconChip
                    label={clanTypeLabel(item.type, t)}
                    icon={<Mail size={14} color={theme.onSurfaceVariant} />}
                  />
                ) : null}
              </View>
            </View>
          </View>
          <View style={styles.trailingStatus}>
            {item.bookmarked ? (
              <Bookmark size={24} color={theme.onSurfaceVariant} />
            ) : (
              <PillSurface style={styles.accountCount}>
                <CKText role="labelMedium" style={styles.accountCountText}>
                  {item.accountCount} {item.accountCount === 1 ? 'account' : 'accounts'}
                </CKText>
              </PillSurface>
            )}
          </View>
          <ChevronRight size={30} color={theme.onSurfaceVariant} style={styles.chevron} />
        </Pressable>
      </Surface>
    </View>
  );
}

function ClanImageChip({ label, imageUrl }: { label: string; imageUrl: string }) {
  const theme = useCKTheme();
  return (
    <ClanChipShell
      label={label}
      leading={
        imageUrl ? (
          <MobileWebImage imageUrl={imageUrl} style={styles.chipImage} />
        ) : (
          <Shield size={14} color={theme.onSurfaceVariant} />
        )
      }
    />
  );
}

function ClanIconChip({ label, icon }: { label: string; icon: ReactNode }) {
  return <ClanChipShell label={label} leading={icon} />;
}

function ClanChipShell({ label, leading }: { label: string; leading: ReactNode }) {
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.chip,
        {
          backgroundColor: colorWithAlpha(theme.surface, 0.5),
          borderColor: colorWithAlpha(theme.outlineVariant, 0.18),
        },
      ]}
    >
      <View style={styles.chipLeading}>{leading}</View>
      <CKText role="labelMedium" numberOfLines={1} style={styles.chipLabel}>
        {label}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { width: '100%' },
  pressable: { position: 'relative' },
  content: {
    paddingTop: 14,
    paddingRight: 44,
    paddingBottom: 14,
    paddingLeft: 14,
    flexDirection: 'row',
  },
  badgeColumn: { alignItems: 'center' },
  badge: { width: 64, height: 64, resizeMode: 'contain' },
  badgeFallback: { width: 64, height: 64, alignItems: 'center', justifyContent: 'center' },
  memberGap: { height: 6 },
  copy: { flex: 1, marginLeft: 12 },
  title: { fontWeight: '800', fontSize: 17 },
  location: { marginTop: 2, flexDirection: 'row', alignItems: 'center' },
  flag: { width: 13, height: 13, resizeMode: 'contain' },
  locationName: { marginLeft: 4, flexShrink: 1 },
  chips: { marginTop: 10, flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  chip: {
    maxWidth: '100%',
    minHeight: 26,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 5,
    borderRadius: ckRadius.pill,
    borderWidth: StyleSheet.hairlineWidth,
  },
  chipLeading: { width: 16, height: 16, alignItems: 'center', justifyContent: 'center' },
  chipImage: { width: 16, height: 16, resizeMode: 'contain' },
  chipLabel: { marginLeft: 5, flexShrink: 1, fontWeight: '700' },
  trailingStatus: { position: 'absolute', top: 14, right: 14 },
  accountCount: { paddingHorizontal: 7, paddingVertical: 4 },
  accountCountText: { fontWeight: '800' },
  chevron: { position: 'absolute', right: 10, top: '50%', marginTop: -15 },
});
