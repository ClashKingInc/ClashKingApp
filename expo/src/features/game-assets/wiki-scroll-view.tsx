import {
  createContext,
  useContext,
  useRef,
  useState,
  type ComponentProps,
  type ComponentRef,
  type Ref,
  type RefObject,
} from 'react';
import Reanimated, {
  useAnimatedScrollHandler,
  useSharedValue,
  type SharedValue,
} from 'react-native-reanimated';
import { View, ScrollView, type ViewInstance } from 'react-native';

type ScrollContext = {
  y: SharedValue<number>;
  content: RefObject<ViewInstance | null>;
  layoutRevision: string;
};
const Context = createContext<ScrollContext | null>(null);
export const useWikiScroll = () => useContext(Context);

/** Table anchors are measured against content, never against a moving viewport. */
export function WikiScrollView({
  children,
  scrollRef,
  contentContainerStyle,
  ...props
}: ComponentProps<typeof ScrollView> & { scrollRef?: Ref<ComponentRef<typeof ScrollView>> }) {
  const y = useSharedValue(0);
  const content = useRef<ViewInstance>(null);
  const [layoutRevision, setLayoutRevision] = useState('');
  const onScroll = useAnimatedScrollHandler((event) => {
    y.set(event.contentOffset.y);
  });
  return (
    <Context.Provider value={{ y, content, layoutRevision }}>
      <View style={{ flex: 1 }}>
        <Reanimated.ScrollView
          contentInsetAdjustmentBehavior="never"
          automaticallyAdjustContentInsets={false}
          {...props}
          ref={scrollRef}
          onScroll={onScroll}
          scrollEventThrottle={16}
        >
          <View
            ref={content}
            collapsable={false}
            style={contentContainerStyle}
            onLayout={({ nativeEvent: { layout } }) =>
              setLayoutRevision(`${layout.width}:${layout.height}`)
            }
          >
            {children}
          </View>
        </Reanimated.ScrollView>
      </View>
    </Context.Provider>
  );
}
