import { StyleSheet, View } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import { materialBackLabel, useI18n } from '../../i18n';
import { CKText, HeaderIconButton, useCKTheme } from '../../ui';
import { CalculatorTitleTarget } from './calculator-fireball-playground';

export function CalculatorHeader({ onBack, compact }: { onBack: () => void; compact: boolean }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return <View style={styles.header}>
    <HeaderIconButton label={materialBackLabel(locale)} onPress={onBack} icon={<ArrowLeft color={theme.onSurface} size={22} />} />
    <View pointerEvents="box-none" style={styles.titleBox}>
      <CalculatorTitleTarget label={t('calculatorsTitle')}>
        <CKText role="titleLarge" style={[styles.title, compact && styles.compactTitle]}>{t('calculatorsTitle')}</CKText>
      </CalculatorTitleTarget>
    </View>
  </View>;
}
const styles = StyleSheet.create({
  header: { height: 76, justifyContent: 'center' },
  titleBox: { position: 'absolute', left: 52, right: 52, top: 0, bottom: 0, alignItems: 'center', justifyContent: 'center' },
  title: { fontSize: 22, lineHeight: 28, fontWeight: '700', textAlign: 'center' },
  compactTitle: { fontSize: 20, lineHeight: 26 },
});
