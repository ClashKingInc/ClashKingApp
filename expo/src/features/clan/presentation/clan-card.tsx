import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
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

export function ClanRosterCard({ item, onOpen }: { item: ClanRosterItem; onOpen: () => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={ckRadius.control} style={styles.card}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`Open clan ${item.name}`}
        onPress={onOpen}
        style={styles.pressable}
      >
        <View style={styles.content}>
          <View style={styles.badgeColumn}>
            {item.badgeUrl ? (
              <MobileWebImage imageUrl={item.badgeUrl} style={styles.badge} />
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
            <CKText
              role="titleMedium"
              numberOfLines={1}
              style={[styles.title, { paddingRight: item.bookmarked ? 28 : 86 }]}
            >
              {item.name}
            </CKText>
            {item.countryCode && item.locationName ? (
              <View style={styles.location}>
                <MobileWebImage imageUrl={ImageAssets.flag(item.countryCode)} style={styles.flag} />
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
