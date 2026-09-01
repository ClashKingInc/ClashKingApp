import { useMemo, useState, type ReactNode } from 'react';
import {
  FlatList,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { Check, ChevronDown, ChevronsUpDown, Search, X } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { tintIcon } from './icon-slot';
import { Surface } from './surfaces';
import { CKText } from './text';
import { ckControlHeight, ckRadius, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

export interface SelectionPickerOption<T extends string = string> {
  readonly key: T;
  readonly label: string;
  readonly icon?: ReactNode;
  readonly subtitle?: string;
  readonly searchText?: string;
  readonly disabled?: boolean;
}

export function SelectionPicker<T extends string>({
  options,
  selectedKey,
  onSelect,
  title,
  accessibilityLabel,
  searchPlaceholder,
  clearSearchAccessibilityLabel,
  leading,
  positionLabel,
  fillWidth = false,
  plain = false,
  onOpen,
  externallyManaged = false,
}: {
  options: readonly SelectionPickerOption<T>[];
  selectedKey: T;
  onSelect: (key: T) => void;
  title: string;
  accessibilityLabel?: string;
  searchPlaceholder?: string;
  clearSearchAccessibilityLabel?: string;
  leading?: ReactNode;
  positionLabel?: string;
  fillWidth?: boolean;
  plain?: boolean;
  onOpen?: () => void;
  externallyManaged?: boolean;
}) {
  const theme = useCKTheme();
  const [visible, setVisible] = useState(false);
  const selected = options.find((option) => option.key === selectedKey) ?? options[0];
  const controlContent = (
    <>
      {tintIcon(leading ?? selected?.icon, theme.onSurfaceVariant)}
      <CKText role="rowTitle" numberOfLines={1} style={styles.grow}>
        {selected?.label}
      </CKText>
      {positionLabel ? (
        <View
          testID="destination-picker-position"
          style={[styles.positionHint, { backgroundColor: colorWithAlpha(theme.onSurface, 0.07) }]}
        >
          <CKText muted role="labelSmall">
            {positionLabel}
          </CKText>
        </View>
      ) : null}
      {positionLabel ? (
        <ChevronsUpDown color={theme.onSurfaceVariant} size={18} />
      ) : (
        <ChevronDown color={theme.onSurfaceVariant} size={18} />
      )}
    </>
  );
  return (
    <View style={fillWidth ? styles.grow : undefined}>
      <Pressable
        accessibilityLabel={accessibilityLabel ?? selected?.label}
        accessibilityRole="button"
        accessibilityState={{ expanded: visible }}
        onPress={() => {
          onOpen?.();
          if (!externallyManaged) setVisible(true);
        }}
        style={({ pressed }) => pressed && styles.pressed}
      >
        {plain ? (
          <View
            testID="selection-picker-plain-control"
            style={[styles.control, styles.plainControl]}
          >
            {controlContent}
          </View>
        ) : (
          <Surface
            radius={ckRadius.chip}
            style={styles.control}
            testID="destination-picker-control"
          >
            {controlContent}
          </Surface>
        )}
      </Pressable>
      {!externallyManaged ? (
        <SelectionPickerModal
          visible={visible}
          title={title}
          options={options}
          selectedKey={selectedKey}
          searchPlaceholder={searchPlaceholder}
          clearSearchAccessibilityLabel={clearSearchAccessibilityLabel}
          onClose={() => setVisible(false)}
          onSelect={(key) => {
            onSelect(key);
            setVisible(false);
          }}
        />
      ) : null}
    </View>
  );
}

export function SelectionPickerModal<T extends string>({
  visible,
  title,
  options,
  selectedKey,
  searchPlaceholder,
  clearSearchAccessibilityLabel,
  onSelect,
  onClose,
}: {
  visible: boolean;
  title: string;
  options: readonly SelectionPickerOption<T>[];
  selectedKey: T;
  searchPlaceholder?: string;
  clearSearchAccessibilityLabel?: string;
  onSelect: (key: T) => void;
  onClose: () => void;
}) {
  const theme = useCKTheme();
  const { height: viewportHeight } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const [query, setQuery] = useState('');
  const [listEndState, setListEndState] = useState({ key: '', atEnd: false });
  const [listLayoutState, setListLayoutState] = useState({ key: '', height: 0 });
  const filtered = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase();
    if (!needle) return options;
    return options.filter((option) =>
      `${option.label} ${option.searchText ?? ''}`.toLocaleLowerCase().includes(needle),
    );
  }, [options, query]);
  const contentHeight = Math.max(1, filtered.length) * 50;
  const availableHeight = Math.max(1, viewportHeight - insets.top - insets.bottom - 24);
  const sheetChromeHeight = searchPlaceholder ? 121 : 65;
  const maximumVisibleOptions = 10;
  const maximumSheetHeight = availableHeight * 0.88;
  const listHeight = Math.min(
    contentHeight,
    maximumVisibleOptions * 50,
    Math.max(50, maximumSheetHeight - sheetChromeHeight),
  );
  const listStateKey = `${visible ? 'open' : 'closed'}:${query}:${filtered
    .map((option) => option.key)
    .join('\u0000')}`;
  const renderedListHeight = listLayoutState.key === listStateKey ? listLayoutState.height : null;
  const atListEnd = listEndState.key === listStateKey && listEndState.atEnd;
  const effectiveListHeight = Math.min(listHeight, renderedListHeight ?? listHeight);
  const canScroll = contentHeight > effectiveListHeight + 1;
  const close = () => {
    setQuery('');
    onClose();
  };
  return (
    <Modal
      animationType="fade"
      navigationBarTranslucent
      onRequestClose={close}
      presentationStyle="overFullScreen"
      statusBarTranslucent
      transparent
      visible={visible}
    >
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.keyboardAvoider}
      >
        <View
          style={[
            styles.overlay,
            { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 12 },
          ]}
        >
          <Pressable
            accessibilityRole="none"
            onPress={close}
            style={styles.backdropHitTarget}
            testID="selection-picker-backdrop"
          />
          <View
            accessibilityViewIsModal
            onAccessibilityEscape={close}
            style={styles.modalHost}
            testID="selection-picker-modal-host"
          >
            <Surface
              radius={ckRadius.tile}
              style={[
                styles.sheet,
                {
                  height: Math.min(maximumSheetHeight, sheetChromeHeight + listHeight),
                  maxHeight: maximumSheetHeight,
                },
              ]}
            >
              <CKText role="titleMedium" style={styles.titleRow}>
                {title}
              </CKText>
              {searchPlaceholder ? (
                <View
                  style={[
                    styles.search,
                    { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.72) },
                  ]}
                >
                  <Search color={theme.onSurfaceVariant} size={19} />
                  <TextInput
                    accessibilityLabel={searchPlaceholder}
                    autoCapitalize="none"
                    autoCorrect={false}
                    onChangeText={setQuery}
                    placeholder={searchPlaceholder}
                    placeholderTextColor={theme.onSurfaceVariant}
                    style={[styles.searchInput, { color: theme.onSurface }]}
                    value={query}
                  />
                  {query ? (
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={clearSearchAccessibilityLabel ?? searchPlaceholder}
                      onPress={() => setQuery('')}
                    >
                      <X color={theme.onSurfaceVariant} size={19} />
                    </Pressable>
                  ) : null}
                </View>
              ) : null}
              <View
                style={[styles.listViewport, { height: listHeight }]}
                testID="selection-picker-list-viewport"
              >
                <FlatList
                  data={filtered}
                  initialNumToRender={16}
                  keyboardShouldPersistTaps="handled"
                  keyExtractor={(option) => option.key}
                  maxToRenderPerBatch={16}
                  renderItem={({ item: option }) => {
                    const selected = option.key === selectedKey;
                    return (
                      <Pressable
                        accessibilityLabel={option.label}
                        accessibilityRole="radio"
                        accessibilityState={{ checked: selected, disabled: option.disabled }}
                        disabled={option.disabled}
                        key={option.key}
                        onPress={() => {
                          setQuery('');
                          onSelect(option.key);
                        }}
                        style={[
                          styles.option,
                          selected && {
                            backgroundColor: colorWithAlpha(theme.primary, 0.13),
                          },
                          option.disabled && styles.disabled,
                        ]}
                      >
                        {tintIcon(option.icon, selected ? theme.primary : theme.onSurfaceVariant)}
                        <View style={styles.grow}>
                          <CKText
                            numberOfLines={1}
                            style={selected ? styles.selectedLabel : undefined}
                          >
                            {option.label}
                          </CKText>
                          {option.subtitle ? (
                            <CKText muted role="bodySmall" numberOfLines={1}>
                              {option.subtitle}
                            </CKText>
                          ) : null}
                        </View>
                        {selected ? <Check color={theme.primary} size={20} /> : null}
                      </Pressable>
                    );
                  }}
                  onLayout={(event) =>
                    setListLayoutState({
                      key: listStateKey,
                      height: event.nativeEvent.layout.height,
                    })
                  }
                  onScroll={(event) => {
                    const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
                    setListEndState({
                      key: listStateKey,
                      atEnd: contentOffset.y + layoutMeasurement.height >= contentSize.height - 2,
                    });
                  }}
                  scrollEnabled={canScroll}
                  scrollEventThrottle={32}
                  style={styles.scroll}
                  testID="selection-picker-list"
                  windowSize={7}
                />
                {canScroll && !atListEnd ? (
                  <View
                    accessible={false}
                    pointerEvents="none"
                    style={[
                      styles.scrollCue,
                      { backgroundColor: colorWithAlpha(theme.onSurface, 0.08) },
                    ]}
                    testID="selection-picker-scroll-cue"
                  >
                    <ChevronDown color={theme.onSurfaceVariant} size={18} />
                  </View>
                ) : null}
              </View>
            </Surface>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  grow: { flex: 1 },
  keyboardAvoider: { flex: 1 },
  pressed: { opacity: 0.72 },
  control: {
    minHeight: ckControlHeight.compact,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
  },
  plainControl: { minWidth: 120, paddingHorizontal: 4 },
  positionHint: {
    minWidth: 34,
    minHeight: 24,
    paddingHorizontal: 7,
    borderRadius: ckRadius.pill,
    alignItems: 'center',
    justifyContent: 'center',
  },
  overlay: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
    backgroundColor: '#00000066',
  },
  backdropHitTarget: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
  },
  modalHost: { width: '100%', maxWidth: 520 },
  sheet: { padding: 14, gap: 12 },
  titleRow: { paddingHorizontal: 4 },
  search: {
    minHeight: ckControlHeight.compact,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    borderRadius: ckRadius.control,
    paddingHorizontal: 12,
  },
  searchInput: { flex: 1, minHeight: ckControlHeight.compact, fontSize: 16 },
  listViewport: { flexShrink: 1, minHeight: 50, position: 'relative', overflow: 'hidden' },
  scroll: { flex: 1 },
  scrollCue: {
    position: 'absolute',
    bottom: 4,
    left: '50%',
    width: 42,
    height: 22,
    marginLeft: -21,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: ckRadius.pill,
  },
  option: {
    minHeight: 50,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: ckRadius.control,
  },
  selectedLabel: { fontWeight: '700' },
  disabled: { opacity: 0.46 },
});
