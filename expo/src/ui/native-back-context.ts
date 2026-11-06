import {
  createContext,
  createElement,
  useContext,
  useLayoutEffect,
  useMemo,
  useRef,
  type ReactNode,
} from 'react';

export const NativeRailBack = createContext({
  enabled: false,
  depth: 0,
  registerBack:
    (_action: () => void, _depth: number): (() => void) =>
    () => {},
  registerShare:
    (_action: () => void, _label: string, _depth: number): (() => void) =>
    () => {},
});

/** The visible screen can place its share action beneath Back in the Duo rail.
 * Unrelated export/open-in-game actions remain owned by their page controls. */
export function useNativeRailShare(action: (() => void) | undefined, label: string) {
  const { enabled, depth, registerShare } = useContext(NativeRailBack);
  const actionRef = useRef(action);
  useLayoutEffect(() => {
    actionRef.current = action;
  }, [action]);
  const hasAction = !!action;
  useLayoutEffect(
    () =>
      enabled && hasAction ? registerShare(() => actionRef.current?.(), label, depth) : undefined,
    [enabled, hasAction, label, depth, registerShare],
  );
  return enabled && hasAction;
}

/** Use the screen's real close action in the native rail. Some feature pages
 * have an internal history, so a generic router.back() would skip that history. */
export function useNativeRailBack(action?: () => void) {
  const { enabled, depth, registerBack } = useContext(NativeRailBack);
  const actionRef = useRef(action);
  useLayoutEffect(() => {
    actionRef.current = action;
  }, [action]);
  const hasAction = !!action;
  useLayoutEffect(
    () => (enabled && hasAction ? registerBack(() => actionRef.current?.(), depth) : undefined),
    [enabled, hasAction, depth, registerBack],
  );
  return enabled;
}

export function InlineBackControl({
  onBack,
  children,
}: {
  onBack: () => void;
  children: import('react').ReactNode;
}) {
  return useNativeRailBack(onBack) ? null : children;
}

/** Retained native routes remain mounted behind the active route. Only the
 * visible route may supply a Back action to the Duo rail. */
export function NativeBackScope({ active, children }: { active: boolean; children: ReactNode }) {
  const parent = useContext(NativeRailBack);
  const value = useMemo(
    () => ({ ...parent, depth: parent.depth + 1, enabled: parent.enabled && active }),
    [parent, active],
  );
  return createElement(NativeRailBack.Provider, { value }, children);
}
