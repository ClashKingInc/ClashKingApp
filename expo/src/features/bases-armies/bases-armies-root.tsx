import { ArrowLeft, Grid3X3 } from 'lucide-react-native';
import { Platform, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../core/assets/image-assets';
import { materialBackLabel, useI18n } from '../../i18n';
import {
  CKText,
  HeaderIconButton,
  MobileWebImage,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';

/** Flutter's current Bases & Armies page is an intentionally static Discord-sync preview. */
export function BasesArmiesRoot({ onBack }: { readonly onBack: () => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const horizontal = Platform.OS === 'web' && width >= 900 ? Math.max(16, (width - 1200) / 2) : 16;

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <View style={[styles.header, { backgroundColor: theme.surface, paddingTop: insets.top }]}>
        <HeaderIconButton
          glass={false}
          icon={<ArrowLeft color={theme.onSurface} size={24} />}
          label={materialBackLabel(locale)}
          onPress={onBack}
        />
        <View style={styles.headerText}>
          <CKText role="sectionTitle" numberOfLines={1}>
            {t('sideBasesArmiesTitle')}
          </CKText>
          <CKText muted role="bodySmall" numberOfLines={1}>
            {t('sideBasesArmiesSubtitle')}
          </CKText>
        </View>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingHorizontal: horizontal, paddingBottom: insets.bottom + 28 },
        ]}
      >
        <Surface muted radius={18} style={styles.tease}>
          <Grid3X3 color={theme.onSurface} size={30} />
          <View style={styles.teaseCopy}>
            <CKText role="sectionTitle">{t('sideBotSyncTarget')}</CKText>
            <CKText muted role="bodyMedium">
              {t('sideBotSyncTargetBody')}
            </CKText>
          </View>
        </Surface>

        <SectionTitle title={t('sideSavedBases')} />
        <SavedLink title={t('sideWarBaseSlots')} body={t('sideWarBaseSlotsBody')} />
        <SavedLink title={t('sideLegendBaseSlots')} body={t('sideLegendBaseSlotsBody')} />

        <SectionTitle title={t('sideSavedArmies')} />
        <SavedLink title={t('sideArmyLinks')} body={t('sideArmyLinksBody')} />
      </ScrollView>
    </SafeAreaView>
  );
}

function SectionTitle({ title }: { readonly title: string }) {
  return (
    <CKText role="sectionTitle" style={styles.sectionTitle}>
      {title}
    </CKText>
  );
}

function SavedLink({ title, body }: { readonly title: string; readonly body: string }) {
  const theme = useCKTheme();
  return (
    <View style={styles.linkRow}>
      <View
        style={[
          styles.imageBox,
          { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.5) },
        ]}
      >
        <MobileWebImage
          imageUrl={ImageAssets.clanCastle}
          style={styles.image}
          contentFit="contain"
        />
      </View>
      <View style={styles.linkCopy}>
        <CKText role="rowTitle" numberOfLines={1}>
          {title}
        </CKText>
        <CKText muted role="bodySmall" numberOfLines={1}>
          {body}
        </CKText>
      </View>
      <CKText role="labelLarge">sync</CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(128,128,128,0.2)',
  },
  headerText: { flex: 1 },
  headerSpacer: { width: 44 },
  content: { width: '100%', maxWidth: 1200, alignSelf: 'center', paddingTop: 12 },
  tease: { flexDirection: 'row', alignItems: 'flex-start', padding: 18, gap: 14 },
  teaseCopy: { flex: 1, gap: 6 },
  sectionTitle: { marginTop: 18, marginBottom: 8 },
  linkRow: { minHeight: 62, flexDirection: 'row', alignItems: 'center', paddingVertical: 7 },
  imageBox: { width: 40, height: 40, borderRadius: 8, overflow: 'hidden' },
  image: { width: 40, height: 40 },
  linkCopy: { flex: 1, marginHorizontal: 12, gap: 2 },
});
