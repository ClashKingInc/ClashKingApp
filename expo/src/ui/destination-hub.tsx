import { useState } from 'react';
import { ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { ArrowLeft } from 'lucide-react-native';
import { DestinationGrid, type DestinationGridGroup } from './destination-grid';
import { HeaderIconButton } from './header';
import { CKText } from './text';
import { useCKTheme } from './theme';
import { materialBackLabel, useI18n } from '../i18n';

/** All groups stay visible; enlarged accessibility type retains a scroll escape. */
export function DestinationHub({ title, groups, onBack }: { title: string; groups: readonly DestinationGridGroup[]; onBack: () => void }) {
  const theme = useCKTheme();
  const { locale } = useI18n();
  const insets = useSafeAreaInsets();
  const { width, height, fontScale } = useWindowDimensions();
  const [viewport, setViewport] = useState(0), [content, setContent] = useState(0);
  const columns = Math.max(1, Math.min(3, Math.floor((Math.min(width - 32, 1120) + 8) / (88 * Math.max(1, fontScale) + 8))));
  const rows = groups.reduce((total, group) => total + Math.ceil(group.items.length / columns), 0);
  const tileHeight = Math.max(50, Math.min(76, Math.floor((height - insets.top - insets.bottom - 102 - groups.length * 30 - Math.max(0, rows - groups.length) * 8) / Math.max(1, rows))));
  return <SafeAreaView edges={['left', 'right']} style={{ flex: 1, backgroundColor: theme.background }}>
    <ScrollView onLayout={event => setViewport(event.nativeEvent.layout.height)} onContentSizeChange={(_, height) => setContent(height)} scrollEnabled={content > viewport + 1} showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingTop: insets.top + 4, paddingBottom: insets.bottom + 12, paddingHorizontal: Math.max(16, (width - 1120) / 2), gap: 12 }}>
      <View style={styles.header}>
        <HeaderIconButton label={materialBackLabel(locale)} onPress={onBack} icon={<ArrowLeft size={22} color={theme.onSurface} />} />
        <CKText role="screenTitle" style={styles.title}>{title}</CKText>
        <View pointerEvents="none" style={{ width: 48 }} />
      </View>
      <DestinationGrid compact featured tileHeight={tileHeight} initialWidth={Math.min(width - 32, 1120)} groups={groups} />
    </ScrollView>
  </SafeAreaView>;
}
const styles = StyleSheet.create({ header: { flexDirection: 'row', alignItems: 'center', gap: 14, minHeight: 64 }, title: { flex: 1, fontSize: 22, lineHeight: 28, fontWeight: '700', textAlign: 'center' } });
