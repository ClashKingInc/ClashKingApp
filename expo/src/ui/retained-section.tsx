import { memo, type ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

/** Keep a visited section's local controls mounted without rebuilding its body
 * for unrelated parent responses. The next activation receives current inputs;
 * internal subscriptions/effects remain live, so this is not a lifecycle pause. */
export function RetainedSection({
  active,
  render,
  testID,
  style,
}: {
  active: boolean;
  render: () => ReactNode;
  testID?: string;
  style?: StyleProp<ViewStyle>;
}) {
  return (
    <View
      testID={testID}
      style={[style, !active && styles.hidden]}
      pointerEvents={active ? 'auto' : 'none'}
      accessibilityElementsHidden={!active}
      importantForAccessibility={active ? 'auto' : 'no-hide-descendants'}
    >
      <SectionBody active={active} render={render} />
    </View>
  );
}

const SectionBody = memo(
  function SectionBody({ render }: { active: boolean; render: () => ReactNode }) {
    return <>{render()}</>;
  },
  // Process deactivation once so native scroll handlers detach. Only an
  // already-inactive body may ignore later parent input changes.
  (previous, next) =>
    (!previous.active && !next.active) ||
    (previous.active === next.active && previous.render === next.render),
);

const styles = StyleSheet.create({ hidden: { display: 'none' } });
