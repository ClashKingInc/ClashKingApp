import { modalOrientations } from './modal-orientations';
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
import { GlassControlSurface, GlassSurface } from './glass';
import { CKText } from './text';
import { ckControlHeight, ckRadius, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';
import { isAdaptiveIOSDevice, useAdaptiveLayout } from './adaptive-layout';
import { ReservedRegionLayout } from './reserved-region-layout';

export interface SelectionPickerOption<T extends string = string> {
  readonly key: T;
  readonly label: string;
  readonly icon?: ReactNode;
  readonly subtitle?: string;
  readonly searchText?: string;
  readonly disabled?: boolean;
  readonly trailingAction?: {
    readonly label: string;
    readonly icon: ReactNode;
    readonly onPress: () => void;
  };
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
  wrapLabel = false,
  iconOnly = false,
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
  /** Opt in for identity pickers where truncating a full name loses important context. */
  wrapLabel?: boolean;
  /** Hide only the selected label; menu labels and accessibility stay intact. */
  iconOnly?: boolean;
  onOpen?: () => void;
  externallyManaged?: boolean;
}) {
  const theme = useCKTheme();
  const [visible, setVisible] = useState(false);
  const selected = options.find((option) => option.key === selectedKey) ?? options[0];
  const controlContent = (
    <>
      {tintIcon(leading ?? selected?.icon, theme.onSurfaceVariant)}
      {!iconOnly ? (
        <CKText
          role="rowTitle"
          numberOfLines={wrapLabel ? undefined : 1}
          // A parent can stretch a picker without setting fillWidth. Always
          // consume spare row width so trailing controls stay at the far edge.
          // Keep an auto basis: flex:1 uses a zero basis and can hide labels in
          // intrinsically sized controls. fillWidth only sizes the outer host.
          style={styles.controlLabel}
        >
          {selected?.label}
        </CKText>
      ) : null}
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
  const trigger = (
    <Pressable
      accessibilityLabel={accessibilityLabel ?? selected?.label}
      accessibilityRole="button"
      accessibilityState={{ expanded: visible }}
      onPress={() => {
        onOpen?.();
        if (!externallyManaged) setVisible(true);
      }}
      style={({ pressed }) => [
        styles.control,
        plain && styles.plainControl,
        pressed && styles.pressed,
      ]}
    >
      {controlContent}
    </Pressable>
  );
  return (
    <View style={fillWidth ? styles.fillControl : undefined}>
      {plain ? (
        <View testID="selection-picker-plain-control">{trigger}</View>
      ) : (
        <GlassControlSurface style={styles.controlGlass} testID="destination-picker-control">
          {trigger}
        </GlassControlSurface>
      )}
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

type SelectionPickerModalProps<T extends string> = {
  visible: boolean;
  title: string;
  options: readonly SelectionPickerOption<T>[];
  selectedKey: T;
  /** Multi-select checkbox semantics; the caller controls when the sheet closes. */
  selectedKeys?: readonly T[];
  searchPlaceholder?: string;
  clearSearchAccessibilityLabel?: string;
  onSelect: (key: T) => void;
  onClose: () => void;
  optionHeight?: number;
};

export function SelectionPickerModal<T extends string>(props: SelectionPickerModalProps<T>) {
  const [query, setQuery] = useState('');
  const close = () => {
    setQuery('');
    props.onClose();
  };
  const content = (
    <SelectionPickerContent {...props} query={query} setQuery={setQuery} close={close} />
  );
  return (
    <Modal
      supportedOrientations={modalOrientations}
      animationType="fade"
      navigationBarTranslucent
      onRequestClose={close}
      presentationStyle="overFullScreen"
      statusBarTranslucent
      transparent
      visible={props.visible}
    >
      {isAdaptiveIOSDevice ? (
        <View style={styles.fullScrim}>
          <ReservedRegionLayout>{content}</ReservedRegionLayout>
        </View>
      ) : (
        content
      )}
    </Modal>
  );
}

function SelectionPickerContent<T extends string>({
  visible,
  title,
  options,
  selectedKey,
  selectedKeys,
  searchPlaceholder,
  clearSearchAccessibilityLabel,
  onSelect,
  optionHeight = 50,
  query,
  setQuery,
  close,
}: SelectionPickerModalProps<T> & {
  query: string;
  setQuery: (value: string) => void;
  close: () => void;
}) {
  const theme = useCKTheme();
  const { height: windowHeight } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const viewportHeight = isAdaptiveIOSDevice ? layout.height : windowHeight;
  const insets = useSafeAreaInsets();
  const [listEndState, setListEndState] = useState({ key: '', atEnd: false });
  const [listLayoutState, setListLayoutState] = useState({ key: '', height: 0 });
  const filtered = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase();
    if (!needle) return options;
    return options.filter((option) =>
      `${option.label} ${option.searchText ?? ''}`.toLocaleLowerCase().includes(needle),
    );
  }, [options, query]);
  const contentHeight = Math.max(1, filtered.length) * optionHeight;
  const availableHeight = Math.max(1, viewportHeight - insets.top - insets.bottom - 24);
  const sheetChromeHeight = searchPlaceholder ? 121 : 65;
  const maximumVisibleOptions = 10;
  const maximumSheetHeight = availableHeight * 0.88;
  const listHeight = Math.min(
    contentHeight,
    maximumVisibleOptions * optionHeight,
    Math.max(50, maximumSheetHeight - sheetChromeHeight),
  );
  const listStateKey = `${visible ? 'open' : 'closed'}:${query}:${filtered
    .map((option) => option.key)
    .join('\u0000')}`;
  const renderedListHeight = listLayoutState.key === listStateKey ? listLayoutState.height : null;
  const atListEnd = listEndState.key === listStateKey && listEndState.atEnd;
  const effectiveListHeight = Math.min(listHeight, renderedListHeight ?? listHeight);
  const canScroll = contentHeight > effectiveListHeight + 1;
  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={styles.keyboardAvoider}
    >
      <View
        style={[
          styles.overlay,
          isAdaptiveIOSDevice && { backgroundColor: 'transparent' },
          { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 12 },
          isAdaptiveIOSDevice && {
            paddingLeft: insets.left + 20,
            paddingRight: insets.right + 20,
          },
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
          <GlassSurface
            cornerRadius={ckRadius.tile}
            testID="selection-picker-sheet"
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
                  const selected = selectedKeys
                    ? selectedKeys.includes(option.key)
                    : option.key === selectedKey;
                  return (
                    <Pressable
                      accessibilityLabel={option.label}
                      accessibilityRole={selectedKeys ? 'checkbox' : 'radio'}
                      accessibilityState={{ checked: selected, disabled: option.disabled }}
                      disabled={option.disabled}
                      key={option.key}
                      onPress={() => {
                        if (!selectedKeys) setQuery('');
                        onSelect(option.key);
                      }}
                      style={[
                        styles.option,
                        { minHeight: optionHeight },
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
                      {option.trailingAction ? (
                        <Pressable
                          accessibilityRole="button"
                          accessibilityLabel={option.trailingAction.label}
                          hitSlop={8}
                          onPress={(event) => {
                            event.stopPropagation();
                            option.trailingAction?.onPress();
                          }}
                          style={styles.trailingAction}
                        >
                          {option.trailingAction.icon}
                        </Pressable>
                      ) : null}
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
                // Option subtitles and large text can make rows taller than
                // the estimate. Never disable native scrolling from that estimate.
                scrollEnabled
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
          </GlassSurface>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  grow: { flex: 1 },
  controlLabel: { flexGrow: 1, flexShrink: 1, flexBasis: 'auto', minWidth: 0 },
  // Fill available width without flex-basis:0 collapsing the control's
  // intrinsic height in a native, vertically measured pager/scroll page.
  fillControl: { flexGrow: 1, flexShrink: 0, minHeight: ckControlHeight.compact },
  keyboardAvoider: { flex: 1 },
  fullScrim: { flex: 1, backgroundColor: '#00000066' },
  pressed: { opacity: 0.72 },
  control: {
    minHeight: ckControlHeight.compact,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
  },
  controlGlass: { minHeight: ckControlHeight.compact },
  plainControl: { minWidth: 120, paddingHorizontal: 4 },
  positionHint: {
    flexShrink: 0,
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
  trailingAction: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  disabled: { opacity: 0.46 },
});
