import { Link, useRoute } from 'expo-router';
import { useContext, useId, type ReactNode } from 'react';
import { Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import { WikiCatalogueContext } from './wiki-catalogue';
import { useWikiNavigation } from './wiki-navigation';

/** Use the platform stack's ordinary push/pop. Apple's zoom path currently
 * delays native dismissal bookkeeping and loses rapid reopen taps (Expo #42797).
 * Do not add AppleZoom or a JS clone here without rechecking that native issue. */
export function WikiEntryLink({
  entryKey,
  label,
  style,
  onFallback,
  children,
}: {
  entryKey: string;
  label: string;
  style?: StyleProp<ViewStyle>;
  onFallback: () => void;
  children: ReactNode;
}) {
  const token = useId();
  const route = useRoute();
  const sourceLayer = (route.params as { layer?: string } | undefined)?.layer;
  const wiki = useWikiNavigation();
  const catalogue = useContext(WikiCatalogueContext);
  const link = wiki?.entryLink?.(entryKey, token, sourceLayer, catalogue ?? undefined);
  if (!link)
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        style={style}
        onPress={onFallback}
      >
        {children}
      </Pressable>
    );
  // Expo Link injects its own role onto the child. Set the action role on
  // Link too so native accessibility exposes each complete card as a target.
  const card = (
    <Pressable
      accessible
      accessibilityRole="button"
      accessibilityLabel={label}
      collapsable={false}
      style={StyleSheet.flatten(style)}
    >
      {children}
    </Pressable>
  );
  return (
    <Link
      href={link.href}
      role="button"
      push
      asChild
      onPress={(event) => {
        if (!link.prepare()) {
          event.preventDefault();
          return;
        }
      }}
    >
      {card}
    </Link>
  );
}
