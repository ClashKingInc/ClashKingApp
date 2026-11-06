import { Stack } from 'expo-router';
import { materialBackLabel, useI18n } from '../i18n';
import { primaryTabRoutes } from '../navigation';
import type { PrimaryRouteId } from './retained-pager';
import { useCKTheme } from '../ui/theme';
import { isDuoDevice } from '../ui/adaptive-layout';
import { useDuoPortraitBottomBar } from './duo-navigation-mode';
import { PrimaryTabBar } from './primary-tab-bar';
export { isDuoDevice } from '../ui/adaptive-layout';

type Actions = { select: (route: PrimaryRouteId) => void };
let actions: Actions | null = null;
export function registerDuoNavigationActions(next: Actions) {
  actions = next;
  return () => {
    if (actions === next) actions = null;
  };
}
const icons = { home: 'CKTabHome', players: 'CKTabPlayers', clans: 'CKTabClans', war: 'CKTabWar' };

/** Detail destinations are not primary tabs. Native toolbar shortcuts remain
 * available without suggesting that Home/Players/Clans/War is selected. */
export function DuoDetailShortcuts({
  back,
  share,
}: {
  back?: () => void;
  share?: { action: () => void; label: string };
}) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const portraitBottomBar = useDuoPortraitBottomBar();
  if (!isDuoDevice) return null;
  if (portraitBottomBar) {
    return <PrimaryTabBar onSelect={(route) => actions?.select(route)} t={t} isRtl={isRtl} />;
  }
  return (
    <>
      <Stack.Screen
        options={{ headerTransparent: true, headerTitle: '', headerBackVisible: false }}
      />
      <Stack.Toolbar placement="left">
        {/* The rail mirrors native Duo navigation: Back then Share directly
          below status controls; flexible space keeps primary tabs at the foot. */}
        {back ? (
          <Stack.Toolbar.Button
            accessibilityLabel={materialBackLabel(locale)}
            icon={isRtl ? 'chevron.right' : 'chevron.left'}
            separateBackground
            tintColor={theme.onSurface}
            onPress={back}
          />
        ) : null}
        {share ? (
          <Stack.Toolbar.Button
            accessibilityLabel={share.label}
            icon="square.and.arrow.up"
            separateBackground
            tintColor={theme.onSurface}
            onPress={share.action}
          />
        ) : null}
      </Stack.Toolbar>
      <Stack.Toolbar placement="bottom">
        {primaryTabRoutes.map((route) => (
          <Stack.Toolbar.Button
            key={route.id}
            accessibilityLabel={t(route.labelKey)}
            selected={false}
            tintColor={theme.onSurface}
            onPress={() => actions?.select(route.id as PrimaryRouteId)}
          >
            <Stack.Toolbar.Icon
              xcasset={icons[route.id as PrimaryRouteId]}
              renderingMode="template"
            />
          </Stack.Toolbar.Button>
        ))}
      </Stack.Toolbar>
    </>
  );
}
