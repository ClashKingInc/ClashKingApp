import { useEffect, useState, type ReactNode } from 'react';
import { View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ArrowLeft } from 'lucide-react-native';
import { materialBackLabel, useI18n } from '../../i18n';
import { ErrorState, ProfileHeaderAction, useCKTheme } from '../../ui';

/** The route is already on the stack; resolving data must never push another one. */
export function DeferredDestination<T>({
  load,
  initial,
  pending,
  children,
  onBack,
}: {
  load: () => Promise<T>;
  initial?: T;
  pending: ReactNode;
  children: (value: T) => ReactNode;
  onBack: () => void;
}) {
  const theme = useCKTheme();
  const { t, locale } = useI18n();
  const [result, setResult] = useState<{ value: T } | undefined>(() =>
    initial === undefined ? undefined : { value: initial },
  );
  const [failed, setFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    let active = true;
    // Commit the destination before starting service work. There is no minimum
    // loading duration; cached responses can replace the skeleton immediately.
    const frame = requestAnimationFrame(() => {
      void load().then(
        (value) => {
          if (active) setResult({ value });
        },
        () => {
          if (active) setFailed(true);
        },
      );
    });
    return () => {
      active = false;
      cancelAnimationFrame(frame);
    };
  }, [load, attempt]);
  if (result) return children(result.value);
  if (!failed) return pending;
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
      <View style={{ paddingHorizontal: 16 }}>
        <ProfileHeaderAction
          icon={<ArrowLeft color={theme.onSurface} />}
          label={materialBackLabel(locale)}
          onPress={onBack}
        />
      </View>
      <ErrorState
        title={t('generalError')}
        body={t('generalTryAgain')}
        actionLabel={t('generalRetry')}
        onAction={() => {
          setFailed(false);
          setAttempt((value) => value + 1);
        }}
      />
    </SafeAreaView>
  );
}
