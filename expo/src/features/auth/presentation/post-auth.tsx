import { useCallback, useEffect, useState } from 'react';
import { View } from 'react-native';

import { useI18n } from '../../../i18n';
import { ErrorState, LoadingScreen } from '../../../ui';
import { verifiedAccountDestination, type PostAuthPresentationProps } from './contracts';

export function PostAuthGate({
  loadAccounts,
  onDestination,
  onFailure,
}: PostAuthPresentationProps) {
  const { t } = useI18n();
  const [error, setError] = useState<unknown>();
  const [attempt, setAttempt] = useState(0);
  const run = useCallback(async () => {
    try {
      const accounts = await loadAccounts();
      onDestination(verifiedAccountDestination(accounts));
    } catch (nextError) {
      if (onFailure) {
        onFailure(nextError);
        return;
      }
      setError(nextError);
    }
  }, [loadAccounts, onDestination, onFailure]);
  useEffect(() => {
    // Authentication completion is the external event that starts account bootstrap.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void run();
  }, [run, attempt]);

  if (error) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', padding: 24 }}>
        <ErrorState
          title={t('generalError')}
          body={String(error)}
          actionLabel={t('generalRetry')}
          onAction={() => {
            setError(undefined);
            setAttempt((value) => value + 1);
          }}
        />
      </View>
    );
  }
  return <LoadingScreen label={t('generalLoading')} />;
}
