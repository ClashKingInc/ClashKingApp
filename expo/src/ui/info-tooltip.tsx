import { modalOrientations } from "./modal-orientations";
import { useRef, useState, type ReactNode } from 'react';
import { Modal, Pressable, View, useWindowDimensions, type ViewInstance, type StyleProp, type ViewStyle } from 'react-native';
import { Info } from 'lucide-react-native';
import { CKText } from './text';
import { Surface } from './surfaces';
import { useCKTheme } from './theme';

export function InfoTooltip({
  label,
  message,
  icon,
  triggerContent,
  triggerStyle,
}: {
  label: string;
  message: string;
  icon?: ReactNode;
  triggerContent?: ReactNode;
  triggerStyle?: StyleProp<ViewStyle>;
}) {
  const theme = useCKTheme();
  const trigger = useRef<ViewInstance>(null);
  const [anchor, setAnchor] = useState<{ x: number; y: number; width: number; height: number }>();
  const window = useWindowDimensions();
  const width = Math.min(200, window.width - 24);
  return (
    <>
      <Pressable
        ref={trigger}
        accessibilityRole="button"
        accessibilityLabel={label}
        accessibilityState={{ expanded: !!anchor }}
        hitSlop={8}
        onPress={() =>
          trigger.current?.measureInWindow((x, y, w, h) => setAnchor({ x, y, width: w, height: h }))
        }
        style={[{ width: 32, height: 32, alignItems: 'center', justifyContent: 'center' }, triggerStyle]}
      >
        {triggerContent ?? <Info size={17} color={theme.onSurfaceVariant} />}
      </Pressable>
      <Modal supportedOrientations={modalOrientations}
        visible={!!anchor}
        transparent
        animationType="fade"
        onRequestClose={() => setAnchor(undefined)}
      >
        <Pressable accessible={false} onPress={() => setAnchor(undefined)} style={{ flex: 1 }}>
          <Surface
            accessibilityViewIsModal
            style={{
              position: 'absolute',
              width,
              left: Math.max(
                12,
                Math.min(
                  window.width - width - 12,
                  (anchor?.x ?? 0) + (anchor?.width ?? 0) - width,
                ),
              ),
              top: Math.max(
                12,
                Math.min(window.height - 70, (anchor?.y ?? 0) + (anchor?.height ?? 0) + 5),
              ),
              padding: 12,
              borderRadius: 12,
              backgroundColor: theme.surfaceContainerHighest,
              borderWidth: 0,
            }}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              {icon}
              <CKText role="metadata" style={{ flexShrink: 1 }}>
                {message}
              </CKText>
            </View>
          </Surface>
        </Pressable>
      </Modal>
    </>
  );
}
