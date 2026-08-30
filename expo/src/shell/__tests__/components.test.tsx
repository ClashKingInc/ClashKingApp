import React from 'react';
import { Text, View } from 'react-native';
import { fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { CKThemeProvider } from '../../ui';
import { DesktopSidebar } from '../desktop-sidebar';
import {
  NavigationShell,
  shouldCompleteSecondaryBackPan,
  shouldStartSecondaryBackPan,
  type NavigationShellProps,
} from '../navigation-shell';
import { RetainedPrimaryPager } from '../retained-pager';
import { fallbackTabBarBottomPadding } from '../primary-tab-bar';

const mockPagerSetPage = jest.fn();
const mockPagerSetPageWithoutAnimation = jest.fn();
const mockDrawerOpen = jest.fn();
const mockDrawerClose = jest.fn();

type MockDrawerProgress = { value: number };
type MockDrawerMethods = { openDrawer: () => void; closeDrawer: () => void };
type MockDrawerProps = {
  children?: React.ReactNode | ((progress?: MockDrawerProgress) => React.ReactNode);
  renderNavigationView: (progress: MockDrawerProgress) => React.ReactNode;
  animationSpeed?: number;
  contentContainerStyle?: object;
  drawerBackgroundColor?: string;
  keyboardDismissMode?: number;
  drawerLockMode?: number;
  drawerPosition?: number;
  drawerType?: number;
  drawerWidth?: number;
  edgeWidth?: number;
  hideStatusBar?: boolean;
  minSwipeDistance?: number;
  onDrawerClose?: () => void;
  onDrawerOpen?: () => void;
  overlayColor?: string;
};

jest.mock('expo-glass-effect', () => {
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    GlassView: MockView,
    isGlassEffectAPIAvailable: () => false,
    isLiquidGlassAvailable: () => false,
  };
});

jest.mock('lucide-react-native', () => {
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return new Proxy(
    { __esModule: true },
    {
      get: (target, property) =>
        property in target ? target[property as keyof typeof target] : MockView,
    },
  );
});

jest.mock('react-native-gesture-handler/ReanimatedDrawerLayout', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  const MockDrawer = ReactModule.forwardRef<MockDrawerMethods, MockDrawerProps>((props, ref) => {
    ReactModule.useImperativeHandle(ref, () => ({
      openDrawer: mockDrawerOpen,
      closeDrawer: mockDrawerClose,
    }));
    const { children, renderNavigationView, ...rest } = props;
    const progress = { value: 0 };
    const renderedChildren = typeof children === 'function' ? children(progress) : children;
    return (
      <MockView {...rest} testID="reanimated-drawer-layout">
        {renderNavigationView(progress)}
        {renderedChildren}
      </MockView>
    );
  });
  return {
    __esModule: true,
    default: MockDrawer,
    DrawerKeyboardDismissMode: { NONE: 0, ON_DRAG: 1 },
    DrawerLockMode: { UNLOCKED: 0, LOCKED_CLOSED: 1, LOCKED_OPEN: 2 },
    DrawerPosition: { LEFT: 0, RIGHT: 1 },
    DrawerType: { FRONT: 0, BACK: 1, SLIDE: 2 },
  };
});

jest.mock('react-native-pager-view', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    default: ReactModule.forwardRef((props: object, ref) => {
      ReactModule.useImperativeHandle(ref, () => ({
        setPage: mockPagerSetPage,
        setPageWithoutAnimation: mockPagerSetPageWithoutAnimation,
      }));
      return <MockView {...props} />;
    }),
  };
});

const t = (key: string) => key;
const screens = {
  home: <Text>home-screen</Text>,
  players: <Text>players-screen</Text>,
  clans: <Text>clans-screen</Text>,
  war: <Text>war-screen</Text>,
};

function StatefulHome() {
  const [count, setCount] = React.useState(0);
  return <Text onPress={() => setCount((value) => value + 1)}>count:{count}</Text>;
}

function StatefulSecondary({ label, onMount }: { label: string; onMount?: () => void }) {
  const [count, setCount] = React.useState(0);
  React.useEffect(() => onMount?.(), [onMount]);
  return <Text onPress={() => setCount((value) => value + 1)}>{`${label}:${count}`}</Text>;
}

async function providers(node: React.ReactElement) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 1200, height: 800 },
        insets: { top: 0, left: 0, right: 0, bottom: 0 },
      }}
    >
      <CKThemeProvider preference="light">{node}</CKThemeProvider>
    </SafeAreaProvider>,
  );
}

describe('navigation shell components', () => {
  it('keeps native PageView content mounted while exposing only the active tab', async () => {
    const onSelect = jest.fn();
    const view = await providers(
      <RetainedPrimaryPager
        selected="home"
        screens={screens}
        onSelect={onSelect}
        swipeEnabled={false}
      />,
    );
    expect(view.getByTestId('primary-page-home')).toBeTruthy();
    expect(
      view.getByTestId('primary-page-players', { includeHiddenElements: true }).props
        .accessibilityElementsHidden,
    ).toBe(true);
    await view.rerender(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 1200, height: 800 },
          insets: { top: 0, left: 0, right: 0, bottom: 0 },
        }}
      >
        <CKThemeProvider preference="light">
          <RetainedPrimaryPager
            selected="players"
            screens={screens}
            onSelect={onSelect}
            swipeEnabled={false}
          />
        </CKThemeProvider>
      </SafeAreaProvider>,
    );
    expect(
      view.getByTestId('primary-page-home', { includeHiddenElements: true }).props
        .accessibilityElementsHidden,
    ).toBe(true);
    expect(view.getByTestId('primary-page-players').props.accessibilityElementsHidden).toBe(false);
  });

  it('keeps the logical native page selected when the app locale changes direction', async () => {
    mockPagerSetPage.mockClear();
    mockPagerSetPageWithoutAnimation.mockClear();
    const retainedScreens = { ...screens, players: <StatefulHome /> };
    const view = await providers(
      <RetainedPrimaryPager
        selected="players"
        screens={retainedScreens}
        onSelect={jest.fn()}
        isRtl={false}
      />,
    );
    await fireEvent.press(view.getByText('count:0'));

    await view.rerender(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 1200, height: 800 },
          insets: { top: 0, left: 0, right: 0, bottom: 0 },
        }}
      >
        <CKThemeProvider preference="light">
          <RetainedPrimaryPager
            selected="players"
            screens={retainedScreens}
            onSelect={jest.fn()}
            isRtl
          />
        </CKThemeProvider>
      </SafeAreaProvider>,
    );

    expect(mockPagerSetPageWithoutAnimation).toHaveBeenCalledWith(1);
    expect(mockPagerSetPage).not.toHaveBeenCalled();
    expect(view.getByText('count:1')).toBeTruthy();
  });

  it('filters desktop utilities by gates and reports active selection', async () => {
    const onPrimary = jest.fn();
    const onUtility = jest.fn();
    const view = await providers(
      <DesktopSidebar
        selectedPrimary="home"
        features={{ posts: true }}
        t={t as never}
        avatar={<View />}
        displayName="User"
        productLabel="ClashKing web"
        hasUser
        onPrimary={onPrimary}
        onUtility={onUtility}
      />,
    );
    expect(view.getByText('postsTitle')).toBeTruthy();
    expect(view.queryByText('generalStats')).toBeNull();
    expect(view.getByText('todoTitle')).toBeTruthy();
    expect(view.getByText('navigationHome').parent?.props.accessibilityState.selected).toBe(true);
    await fireEvent.press(view.getByText('todoTitle'));
    expect(onUtility).toHaveBeenCalledWith(expect.objectContaining({ id: 'todo' }), false);
  });

  it('selects desktop at 900px and resets nested content before a primary route', async () => {
    const onPrimarySelect = jest.fn();
    const onResetDesktopContent = jest.fn();
    const props: NavigationShellProps = {
      selectedPrimary: 'home',
      primaryScreens: screens,
      features: {},
      t: t as never,
      isRtl: false,
      avatar: <View />,
      displayName: 'User',
      followerCount: 0,
      productLabel: 'ClashKing web',
      hasUser: true,
      profileMenuLabel: 'profile',
      closeDrawerLabel: 'close',
      onPrimarySelect,
      onUtilityNavigate: jest.fn(),
      onResetDesktopContent,
      onSearch: jest.fn(),
      onAchievements: jest.fn(),
      onAddAccount: jest.fn(),
      onAccounts: jest.fn(),
      viewportWidth: 900,
      platform: 'web',
    };
    const view = await providers(<NavigationShell {...props} />);
    expect(view.getByTestId('desktop-navigation-shell')).toBeTruthy();
    await fireEvent.press(view.getByText('searchTabPlayers'));
    expect(onResetDesktopContent).toHaveBeenCalledTimes(1);
    expect(onPrimarySelect).toHaveBeenCalledWith('players');
  });

  it('replaces primary desktop chrome for Flutter-style utility pages', async () => {
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        selectedUtility="settings"
        secondaryContent={<Text>settings-screen</Text>}
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl={false}
        avatar={<View />}
        displayName="User"
        followerCount={null}
        productLabel="ClashKing web"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={jest.fn()}
        onSearch={jest.fn()}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={1200}
        platform="web"
      />,
    );
    expect(view.getByText('settings-screen')).toBeTruthy();
    expect(view.queryByText('searchGlobalHint')).toBeNull();
    expect(view.getByText('generalSettings').parent?.props.accessibilityState.selected).toBe(true);
  });

  it('covers the full desktop shell for Flutter global-search presentation', async () => {
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        selectedUtility="search"
        secondaryFullScreen
        secondaryContent={<Text>search-screen</Text>}
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl={false}
        avatar={<View />}
        displayName="User"
        followerCount={null}
        productLabel="ClashKing web"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={jest.fn()}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={1200}
        platform="web"
      />,
    );
    expect(view.getByTestId('desktop-fullscreen-secondary')).toBeTruthy();
    expect(view.getByText('search-screen')).toBeTruthy();
    expect(
      view.getByTestId('desktop-sidebar', { includeHiddenElements: true }).parent?.props
        .accessibilityElementsHidden,
    ).toBe(true);
  });

  it('covers retained primary content with an inert full-screen mobile utility', async () => {
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        selectedUtility="settings"
        secondaryContent={<Text>settings-screen</Text>}
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl={false}
        avatar={<View />}
        displayName="User"
        followerCount={0}
        productLabel="ClashKing"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={jest.fn()}
        onSearch={jest.fn()}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={390}
        platform="ios"
      />,
    );
    expect(view.getByTestId('mobile-utility-shell')).toBeTruthy();
    expect(view.getByText('settings-screen')).toBeTruthy();
    expect(view.queryByTestId('mobile-navigation-shell')).toBeNull();
    expect(
      view.getByTestId('retained-primary-shell', { includeHiddenElements: true }).props
        .accessibilityElementsHidden,
    ).toBe(true);
    expect(view.getByTestId('primary-page-home', { includeHiddenElements: true })).toBeTruthy();
  });

  it('uses a continuously interactive narrow-edge drawer and opens it from the avatar', async () => {
    mockDrawerOpen.mockClear();
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl={false}
        avatar={<View />}
        displayName="User"
        followerCount={0}
        productLabel="ClashKing"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={jest.fn()}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={390}
        platform="ios"
      />,
    );
    const drawer = view.getByTestId('reanimated-drawer-layout');
    expect(drawer.props.edgeWidth).toBe(20);
    expect(drawer.props.minSwipeDistance).toBe(8);
    expect(drawer.props.drawerLockMode).toBe(0);
    expect(drawer.props.drawerPosition).toBe(0);
    await fireEvent.press(view.getByRole('button', { name: 'profile' }));
    expect(mockDrawerOpen).toHaveBeenCalledTimes(1);
    expect(fallbackTabBarBottomPadding(24)).toBe(24);
    expect(fallbackTabBarBottomPadding(0)).toBe(10);
  });

  it('mirrors the drawer edge in RTL and locks it closed on a secondary route', async () => {
    mockDrawerClose.mockClear();
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        selectedUtility="settings"
        secondaryContent={<Text>settings-screen</Text>}
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl
        avatar={<View />}
        displayName="User"
        followerCount={0}
        productLabel="ClashKing"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={jest.fn()}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={390}
        platform="ios"
      />,
    );
    const drawer = view.getByTestId('reanimated-drawer-layout');
    expect(drawer.props.drawerPosition).toBe(1);
    expect(drawer.props.drawerLockMode).toBe(1);
    expect(drawer.props.edgeWidth).toBe(20);
    expect(mockDrawerClose).toHaveBeenCalled();
  });

  it('waits for the drawer to close before navigating', async () => {
    mockDrawerClose.mockClear();
    const onUtilityNavigate = jest.fn();
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl={false}
        avatar={<View />}
        displayName="User"
        followerCount={0}
        productLabel="ClashKing"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={onUtilityNavigate}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={390}
        platform="ios"
      />,
    );
    await fireEvent.press(view.getByText('generalSettings'));
    expect(mockDrawerClose).toHaveBeenCalledTimes(1);
    expect(onUtilityNavigate).not.toHaveBeenCalled();
    await fireEvent(view.getByTestId('reanimated-drawer-layout'), 'drawerClose');
    expect(onUtilityNavigate).toHaveBeenCalledWith(expect.objectContaining({ id: 'settings' }), {
      replace: false,
    });
  });

  it('reserves the leading-edge gesture for popping mobile secondary pages', () => {
    expect(
      shouldStartSecondaryBackPan({
        pageX: 12,
        dx: 28,
        dy: 3,
        viewportWidth: 390,
        edgeWidth: 20,
        isRtl: false,
      }),
    ).toBe(true);
    expect(
      shouldStartSecondaryBackPan({
        pageX: 21,
        dx: 80,
        dy: 2,
        viewportWidth: 390,
        edgeWidth: 20,
        isRtl: false,
      }),
    ).toBe(false);
    expect(
      shouldStartSecondaryBackPan({
        pageX: 120,
        dx: 80,
        dy: 2,
        viewportWidth: 390,
        edgeWidth: 20,
        isRtl: false,
      }),
    ).toBe(false);
    expect(
      shouldStartSecondaryBackPan({
        pageX: 380,
        dx: -28,
        dy: 3,
        viewportWidth: 390,
        edgeWidth: 20,
        isRtl: true,
      }),
    ).toBe(true);
    expect(
      shouldCompleteSecondaryBackPan({
        dx: 94,
        velocityX: 0,
        viewportWidth: 390,
        isRtl: false,
      }),
    ).toBe(true);
    expect(
      shouldCompleteSecondaryBackPan({
        dx: 18,
        velocityX: 0.55,
        viewportWidth: 390,
        isRtl: false,
      }),
    ).toBe(true);
    expect(
      shouldCompleteSecondaryBackPan({
        dx: 18,
        velocityX: 0.1,
        viewportWidth: 390,
        isRtl: false,
      }),
    ).toBe(false);
  });

  it('retains lower secondary scenes while exposing only the top scene', async () => {
    const common: NavigationShellProps = {
      selectedPrimary: 'home',
      selectedUtility: 'settings',
      primaryScreens: screens,
      features: {},
      t: t as never,
      isRtl: false,
      avatar: <View />,
      displayName: 'User',
      followerCount: 0,
      productLabel: 'ClashKing',
      hasUser: true,
      profileMenuLabel: 'profile',
      closeDrawerLabel: 'close',
      onPrimarySelect: jest.fn(),
      onUtilityNavigate: jest.fn(),
      onSecondaryBack: jest.fn(),
      onAchievements: jest.fn(),
      onAddAccount: jest.fn(),
      onAccounts: jest.fn(),
      viewportWidth: 390,
      platform: 'ios',
    };
    const firstMount = jest.fn();
    const first = {
      key: 'first',
      content: <StatefulSecondary label="first" onMount={firstMount} />,
    };
    const view = await providers(
      <NavigationShell {...common} secondaryContent={first.content} secondaryLayers={[first]} />,
    );
    await fireEvent.press(view.getByText('first:0'));
    expect(view.getByText('first:1')).toBeTruthy();
    expect(firstMount).toHaveBeenCalledTimes(1);

    const second = { key: 'second', content: <StatefulSecondary label="second" /> };
    await view.rerender(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 1200, height: 800 },
          insets: { top: 0, left: 0, right: 0, bottom: 0 },
        }}
      >
        <CKThemeProvider preference="light">
          <NavigationShell
            {...common}
            secondaryContent={second.content}
            secondaryLayers={[first, second]}
          />
        </CKThemeProvider>
      </SafeAreaProvider>,
    );
    expect(view.getByText('first:1', { includeHiddenElements: true })).toBeTruthy();
    const underlay = view.getByTestId('mobile-secondary-underlay-0', {
      includeHiddenElements: true,
    });
    expect(underlay.props.pointerEvents).toBe('none');
    expect(underlay.props.accessibilityElementsHidden).toBe(true);
    expect(view.getByText('second:0')).toBeTruthy();
    expect(firstMount).toHaveBeenCalledTimes(1);

    await view.rerender(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 1200, height: 800 },
          insets: { top: 0, left: 0, right: 0, bottom: 0 },
        }}
      >
        <CKThemeProvider preference="light">
          <NavigationShell {...common} secondaryContent={first.content} secondaryLayers={[first]} />
        </CKThemeProvider>
      </SafeAreaProvider>,
    );
    expect(view.getByText('first:1')).toBeTruthy();
    expect(firstMount).toHaveBeenCalledTimes(1);
  });

  it('mounts only the active secondary scene and its interactive-pop predecessor', async () => {
    const view = await providers(
      <NavigationShell
        selectedPrimary="home"
        selectedUtility="settings"
        secondaryContent={<Text>third</Text>}
        secondaryLayers={[
          { key: 'first', content: <Text>first</Text> },
          { key: 'second', content: <Text>second</Text> },
          { key: 'third', content: <Text>third</Text> },
        ]}
        primaryScreens={screens}
        features={{}}
        t={t as never}
        isRtl={false}
        avatar={<View />}
        displayName="User"
        followerCount={0}
        productLabel="ClashKing"
        hasUser
        profileMenuLabel="profile"
        closeDrawerLabel="close"
        onPrimarySelect={jest.fn()}
        onUtilityNavigate={jest.fn()}
        onSecondaryBack={jest.fn()}
        onAchievements={jest.fn()}
        onAddAccount={jest.fn()}
        onAccounts={jest.fn()}
        viewportWidth={390}
        platform="ios"
      />,
    );

    expect(view.queryByText('first', { includeHiddenElements: true })).toBeNull();
    expect(view.getByText('second', { includeHiddenElements: true })).toBeTruthy();
    expect(view.getByText('third')).toBeTruthy();
  });

  it('retains primary screen state while a secondary route covers it', async () => {
    const retainedScreens = { ...screens, home: <StatefulHome /> };
    const common: NavigationShellProps = {
      selectedPrimary: 'home',
      primaryScreens: retainedScreens,
      features: {},
      t: t as never,
      isRtl: false,
      avatar: <View />,
      displayName: 'User',
      followerCount: 0,
      productLabel: 'ClashKing',
      hasUser: true,
      profileMenuLabel: 'profile',
      closeDrawerLabel: 'close',
      onPrimarySelect: jest.fn(),
      onUtilityNavigate: jest.fn(),
      onAchievements: jest.fn(),
      onAddAccount: jest.fn(),
      onAccounts: jest.fn(),
      viewportWidth: 390,
      platform: 'ios',
    };
    const view = await providers(<NavigationShell {...common} />);
    await fireEvent.press(view.getByText('count:0'));
    expect(view.getByText('count:1')).toBeTruthy();
    await view.rerender(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 1200, height: 800 },
          insets: { top: 0, left: 0, right: 0, bottom: 0 },
        }}
      >
        <CKThemeProvider preference="light">
          <NavigationShell
            {...common}
            selectedUtility="settings"
            secondaryContent={<Text>settings-screen</Text>}
          />
        </CKThemeProvider>
      </SafeAreaProvider>,
    );
    expect(view.getByText('count:1', { includeHiddenElements: true })).toBeTruthy();
  });
});
