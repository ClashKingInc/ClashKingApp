import { useEffect, useState, type ReactNode } from 'react';
import { View } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { materialBackLabel, useI18n } from '../../i18n';
import { ErrorState, PageSkeleton, ProfileHeaderAction, useCKTheme } from '../../ui';
import type { SearchDestinationResult } from './search-root';

/** The pushed route owns its fetch and keeps the same native identity when ready. */
export function SearchDestination({
  load,
  render,
  onBack,
}: {
  load: () => Promise<SearchDestinationResult>;
  render: (result: SearchDestinationResult) => ReactNode;
  onBack: () => void;
}) {
  const [result, setResult] = useState<SearchDestinationResult>();
  const [failed, setFailed] = useState(false);
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { t, locale } = useI18n();
  useEffect(() => {
    let active = true;
    void load().then(
      (value) => {
        if (active) setResult(value);
      },
      () => {
        if (active) setFailed(true);
      },
    );
    return () => {
      active = false;
    };
  }, [load]);
  if (result) return render(result);
  return (
    <View style={{ flex: 1, paddingTop: insets.top, backgroundColor: theme.background }}>
      <View style={{ paddingHorizontal: 16 }}>
        <ProfileHeaderAction
          label={materialBackLabel(locale)}
          onPress={onBack}
          icon={<ArrowLeft color={theme.onSurface} />}
        />
      </View>
      {failed ? (
        <ErrorState
          title={t('generalError')}
          actionLabel={materialBackLabel(locale)}
          onAction={onBack}
        />
      ) : (
        <PageSkeleton kind="profile" />
      )}
    </View>
  );
}
