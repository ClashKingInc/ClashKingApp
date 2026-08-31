import { useEffect, useState } from 'react';
import { View } from 'react-native';
import { Building2 } from 'lucide-react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
import { ErrorState, LoadingScreen, useCKTheme } from '../../../ui';
import type { Clan } from '../models';
import { ClanCapitalScreen } from './clan-capital-screen';

/** Runtime adapter for the shell; exported separately so authenticated-root owns navigation. */
export function ClanCapitalRoot({ clan, goBack }: { clan: Clan; goBack: () => void }) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const theme = useCKTheme();
  const [revision, setRevision] = useState(0);
  const [loading, setLoading] = useState(clan.clanCapitalRaid === null);
  const [error, setError] = useState<unknown>();

  useEffect(() => runtime.clans.subscribe(() => setRevision((value) => value + 1)), [runtime]);

  const load = async () => {
    setLoading(true);
    setError(undefined);
    try {
      await runtime.clans.loadCapitalData([clan.tag], 100, { throwOnError: true });
      runtime.clans.linkCapitalToClans();
    } catch (nextError) {
      setError(nextError);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (clan.clanCapitalRaid !== null) return;
    let active = true;
    void runtime.clans
      .loadCapitalData([clan.tag], 100, { throwOnError: true })
      .then(() => runtime.clans.linkCapitalToClans())
      .catch((nextError: unknown) => {
        if (active) setError(nextError);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [clan, runtime]);

  const current = runtime.clans.getClanByTag(clan.tag) ?? clan;
  void revision;
  if (loading) return <LoadingScreen label={t('loadingCapitalRaids')} />;
  if (error) {
    return (
      <View style={{ flex: 1, padding: 16, justifyContent: 'center' }}>
        <ErrorState
          title={t('searchErrorClanLoadFailed')}
          icon={<Building2 color={theme.error} />}
          actionLabel={t('generalRetry')}
          onAction={() => void load()}
        />
      </View>
    );
  }
  return (
    <ClanCapitalScreen
      clan={current}
      goBack={goBack}
      linkedPlayerTags={runtime.accounts.accounts.map((account) => account.playerTag)}
    />
  );
}
