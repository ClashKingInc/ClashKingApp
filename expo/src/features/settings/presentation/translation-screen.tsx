import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ChevronRight, Languages, MessageCircle } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, PillSurface, useCKTheme } from '../../../ui';
import type { ExternalSettingsActions } from './contracts';
import { SettingsPage } from './settings-components';

export const TRANSLATORS = [
  'AlejandroMoc',
  'athype',
  'bhatzuhaib',
  'ColinSchmale',
  'DeafToDeath',
  'Dinki/Krakakus',
  'dobryakoff',
  'GodOfGods',
  'Joelsuperstar',
  'lucaschuab2015',
  'mango_wz',
  'MixxStar',
  'MechanicaL',
  'MRocha01',
  'Nemo_64',
  'niklas312',
  'niku998',
  'Pottmichel',
  'retrock',
  'SamGo',
  'SudetiZ',
  'Wraxu',
  'zombie23304',
] as const;
const TRANSLATOR_GIF = 'https://www.icegif.com/wp-content/uploads/2023/06/icegif-202.gif';

export function TranslationScreen({
  actions,
  viewportWidth,
  onBack,
}: {
  actions: Pick<ExternalSettingsActions, 'openCrowdin' | 'openDiscord'>;
  viewportWidth?: number;
  onBack?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const measured = useWindowDimensions().width;
  const compact = (viewportWidth ?? measured) < 330;
  return (
    <SettingsPage title={t('translationHelpUsTranslate')} onBack={onBack}>
      <CKText role="screenTitle" style={styles.strong}>
        {t('translationThankYou')}
      </CKText>
      <View style={[styles.hero, compact && styles.compact]}>
        <MobileWebImage
          imageUrl={TRANSLATOR_GIF}
          contentFit="cover"
          errorFallback={
            <View style={[styles.gif, styles.gifFallback]}>
              <Languages color={theme.onSurfaceVariant} size={34} />
            </View>
          }
          style={styles.gif}
        />
        <CKText muted style={styles.heroText}>
          {t('translationThankYouContent')}
        </CKText>
      </View>
      <View style={styles.spacer}>
        <CKText role="titleLarge" style={styles.strong}>
          {t('translationHelpUsTranslate')}
        </CKText>
        <CKText muted>{t('translationHelpTranslateContent')}</CKText>
        <TranslationAction
          icon={<Languages color={theme.primary} />}
          label={t('translationHelpTranslateButton')}
          onPress={actions.openCrowdin}
        />
        <TranslationAction
          icon={<MessageCircle color={theme.primary} />}
          label={t('faqJoinDiscord')}
          onPress={actions.openDiscord}
        />
        <CKText muted role="labelLarge" style={styles.translatorTitle}>
          {t('translationCurrentTranslators')}
        </CKText>
        <View style={styles.translators}>
          {TRANSLATORS.map((translator) => (
            <PillSurface key={translator} style={styles.pill}>
              <CKText muted role="labelMedium" style={styles.semi}>
                {translator}
              </CKText>
            </PillSurface>
          ))}
        </View>
      </View>
    </SettingsPage>
  );
}

function TranslationAction({
  icon,
  label,
  onPress,
}: {
  icon: React.ReactNode;
  label: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable accessibilityRole="link" onPress={onPress} style={styles.action}>
      {icon}
      <CKText role="bodyLarge" style={styles.semi}>
        {label}
      </CKText>
      <ChevronRight color={theme.onSurfaceVariant} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  strong: { fontWeight: '800' },
  semi: { fontWeight: '600' },
  hero: { marginTop: 14, flexDirection: 'row', alignItems: 'flex-start', gap: 16 },
  compact: { flexDirection: 'column' },
  gif: { width: 128, height: 128, borderRadius: 18 },
  gifFallback: { alignItems: 'center', justifyContent: 'center' },
  heroText: { flex: 1, lineHeight: 20 },
  spacer: { marginTop: 30, gap: 7 },
  action: {
    minHeight: 52,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  translatorTitle: { marginTop: 18, marginBottom: 2, fontWeight: '700' },
  translators: { flexDirection: 'row', flexWrap: 'wrap', gap: 7 },
  pill: { paddingHorizontal: 10, paddingVertical: 5 },
});
