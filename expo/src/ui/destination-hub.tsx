import { useState } from 'react';
import { ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { ArrowLeft } from 'lucide-react-native';
import { DestinationGrid, type DestinationGridGroup } from './destination-grid';
import { HeaderIconButton } from './header';
import { CKText } from './text';
import { useCKTheme } from './theme';
import { materialBackLabel, useI18n } from '../i18n';
import { useAdaptiveLayout } from './adaptive-layout';

/** All groups stay visible; enlarged accessibility type retains a scroll escape. */
export function DestinationHub({
  title,
  groups,
  onBack,
}: {
  title: string;
  groups: readonly DestinationGridGroup[];
  onBack: () => void;
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const { locale } = useI18n();
  const insets = useSafeAreaInsets();
  const { width, height, fontScale } = useWindowDimensions();
  const [viewport, setViewport] = useState(0),
    [content, setContent] = useState(0);
  // Compact iPhone/Android retain the original three-column calculation.
  const contentWidth = layout.isExpanded || layout.isDuo ? layout.contentMaxWidth : width;
  const maxColumns = layout.isExpanded ? layout.columns(layout.isTablet ? 218 : 180, 4) : 3;
  const tileMinimumWidth = layout.isExpanded ? (layout.isTablet ? 218 : 180) : 88;
  const columns = Math.max(
    1,
    Math.min(
      maxColumns,
      Math.floor(
        (Math.min(contentWidth - 32, 1120) + 8) / (tileMinimumWidth * Math.max(1, fontScale) + 8),
      ),
    ),
  );
  const rows = groups.reduce((total, group) => total + Math.ceil(group.items.length / columns), 0);
  const compactTileHeight = Math.max(
    50,
    Math.min(
      76,
      Math.floor(
        (height -
          insets.top -
          insets.bottom -
          102 -
          groups.length * 30 -
          Math.max(0, rows - groups.length) * 8) /
          Math.max(1, rows),
      ),
    ),
  );
  // A tablet launcher is readable navigation, not a six-column phone grid.
  // Short landscape windows scroll instead of shrinking artwork and labels.
  const tileHeight = layout.isExpanded ? (layout.isTablet ? 120 : 100) : compactTileHeight;
  return (
    <SafeAreaView edges={['left', 'right']} style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView
        onLayout={(event) => setViewport(event.nativeEvent.layout.height)}
        onContentSizeChange={(_, height) => setContent(height)}
        scrollEnabled={content > viewport + 1}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{
          paddingTop: insets.top + 4,
          paddingBottom: insets.bottom + 12,
          paddingHorizontal:
            layout.isExpanded || layout.isDuo
              ? Math.max(16, (layout.usableWidth - layout.contentMaxWidth) / 2 + 16)
              : Math.max(16, (width - 1120) / 2),
          gap: 12,
        }}
      >
        <View style={styles.header}>
          <HeaderIconButton
            label={materialBackLabel(locale)}
            onPress={onBack}
            icon={<ArrowLeft size={22} color={theme.onSurface} />}
          />
          <CKText
            role="screenTitle"
            style={[
              styles.title,
              layout.isExpanded && { fontSize: layout.isTablet ? 30 : 26, lineHeight: 36 },
            ]}
          >
            {title}
          </CKText>
          <View pointerEvents="none" style={{ width: 48 }} />
        </View>
        <DestinationGrid
          maxColumns={maxColumns}
          minItemWidth={tileMinimumWidth}
          compact
          featured
          roomy={layout.isExpanded}
          tileHeight={tileHeight}
          initialWidth={Math.min(
            contentWidth - 32,
            layout.isExpanded ? layout.contentMaxWidth : 1120,
          )}
          groups={groups}
        />
      </ScrollView>
    </SafeAreaView>
  );
}
const styles = StyleSheet.create({
  header: { flexDirection: 'row', alignItems: 'center', gap: 14, minHeight: 64 },
  title: { flex: 1, fontSize: 22, lineHeight: 28, fontWeight: '700', textAlign: 'center' },
});
