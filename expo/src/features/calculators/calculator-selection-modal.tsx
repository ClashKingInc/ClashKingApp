import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { modalOrientations } from '../../ui/modal-orientations';
import { useState, type ReactNode } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Check, X } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { materialCloseLabel, useI18n } from '../../i18n';
import { CKText, MobileWebImage, Surface, colorWithAlpha, useCKTheme } from '../../ui';
import { LevelSlider } from '../../ui/level-slider';

export interface CalculatorSelectionItem {
  key: string;
  label: string;
  imageUrl: string;
  selected: boolean;
  level: number;
  minimum: number;
  maximum: number;
  steps?: readonly number[];
  detail?: string;
}

/** Shared selection and level editing for equipment and damage sources. */
export function CalculatorSelectionModal({
  visible,
  title,
  items,
  onClose,
  onToggle,
  onLevelChange,
  children,
  actions,
  testID,
  inline = false,
}: {
  visible: boolean;
  title: string;
  items: readonly CalculatorSelectionItem[];
  onClose: () => void;
  onToggle: (key: string) => void;
  onLevelChange: (key: string, level: number) => void;
  children?: ReactNode;
  actions?: ReactNode;
  testID?: string;
  inline?: boolean;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const scrollItems = inline && !layout.isExpanded;
  const { height } = useWindowDimensions();
  const [activeKey, setActiveKey] = useState(items[0]?.key);
  const active = items.find((item) => item.key === activeKey) ?? items[0];
  const content = (
    <ScrollView
      keyboardShouldPersistTaps="handled"
      scrollEnabled={!inline || !layout.isExpanded}
      contentContainerStyle={{ gap: 18, paddingBottom: 4 }}
    >
      {!inline ? actions : null}
      <ScrollView
        horizontal={scrollItems}
        scrollEnabled={!inline || !layout.isExpanded}
        showsHorizontalScrollIndicator={false}
      >
        <View style={{ flexDirection: 'row', flexWrap: scrollItems ? 'nowrap' : 'wrap', gap: 8 }}>
          {inline && actions ? (
            <View style={{ width: layout.isExpanded ? 104 : 84 }}>{actions}</View>
          ) : null}
          {items.map((item) => (
            <Pressable
              key={item.key}
              accessibilityRole="checkbox"
              accessibilityLabel={item.label}
              accessibilityState={{ checked: item.selected }}
              onPress={() => {
                setActiveKey(item.key);
                onToggle(item.key);
              }}
              style={{
                width: layout.isExpanded ? 96 : 72,
                height: layout.isExpanded ? 116 : 84,
                alignItems: 'center',
                justifyContent: 'center',
                gap: 2,
                borderRadius: 16,
                backgroundColor: colorWithAlpha(
                  item.selected ? theme.secondary : theme.onSurface,
                  item.selected ? 0.15 : 0.05,
                ),
              }}
            >
              <View
                pointerEvents="none"
                style={{
                  position: 'absolute',
                  top: 5,
                  right: 5,
                  width: 16,
                  height: 16,
                  borderRadius: 5,
                  borderWidth: item.selected ? 0 : 1,
                  borderColor: theme.outlineVariant,
                  backgroundColor: item.selected ? theme.secondary : 'transparent',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {item.selected ? <Check size={12} color={theme.onSecondary} /> : null}
              </View>
              <MobileWebImage
                imageUrl={item.imageUrl}
                style={{
                  width: layout.isExpanded ? 58 : 42,
                  height: layout.isExpanded ? 58 : 42,
                  opacity: item.selected ? 1 : 0.6,
                }}
              />
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`${item.label} · ${t('sideLevel', { level: item.level })}`}
                hitSlop={4}
                onPress={(event) => {
                  event.stopPropagation();
                  setActiveKey(item.key);
                }}
                style={{
                  paddingHorizontal: 8,
                  paddingVertical: layout.isExpanded ? 6 : 3,
                  minHeight: layout.isExpanded ? 36 : undefined,
                  borderRadius: 12,
                  backgroundColor: colorWithAlpha(
                    theme.onSurface,
                    active?.key === item.key ? 0.13 : 0.04,
                  ),
                }}
              >
                <CKText role="metadata">{item.level}</CKText>
              </Pressable>
            </Pressable>
          ))}
        </View>
      </ScrollView>
      {active ? (
        <View style={{ gap: 4 }}>
          <LevelSlider
            key={active.key}
            label={active.label}
            value={active.level}
            minimum={active.minimum}
            maximum={active.maximum}
            steps={active.steps}
            onChange={(value) => onLevelChange(active.key, value)}
          />
          {active.detail ? (
            <CKText muted role="metadata">
              {active.detail}
            </CKText>
          ) : null}
        </View>
      ) : null}
      {children}
    </ScrollView>
  );
  if (inline) return visible ? <View testID={testID}>{content}</View> : null;
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <View
        style={{
          flex: 1,
          justifyContent: 'center',
          padding: 16,
          paddingTop: insets.top + 16,
          paddingBottom: insets.bottom + 16,
          backgroundColor: '#00000066',
        }}
      >
        <Pressable accessibilityRole="none" onPress={onClose} style={StyleSheet.absoluteFill} />
        <Surface
          accessibilityViewIsModal
          onAccessibilityEscape={onClose}
          testID={testID}
          style={{
            width: '100%',
            maxWidth: 560,
            alignSelf: 'center',
            height: Math.min(620, height - insets.top - insets.bottom - 32),
            padding: 16,
            gap: 16,
          }}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
            <CKText role="titleSmall" style={{ flex: 1 }}>
              {title}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={onClose}
              hitSlop={8}
              style={{ padding: 6 }}
            >
              <X size={22} color={theme.onSurface} />
            </Pressable>
          </View>
          {content}
        </Surface>
      </View>
    </Modal>
  );
}
