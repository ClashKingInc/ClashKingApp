import { ClanAdaptiveCards, ClanModalViewport, ClanTabEmpty } from './clan-tab-components';
import { modalOrientations } from '../../../ui/modal-orientations';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Modal, Pressable, StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CalendarPicker,
  DateNavigator,
  SkeletonContent,
  MobileWebImage,
  PressableSurface,
  ckColors,
  useCKTheme,
} from '../../../ui';
import type { ClanCompetitiveDay } from '../models/clan-competitive';
import { ClanMember } from '../models/clan-core';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';

const signed = (value: number) => `${value >= 0 ? '+' : ''}${value.toLocaleString()}`;

export function ClanCompetitiveTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t, locale } = useI18n(),
    theme = useCKTheme();
  const [data, setData] = useState<ClanCompetitiveDay>();
  const [today] = useState(() =>
    new Date(Date.now() - (5 * 60) * 60_000).toISOString().slice(0, 10),
  );
  const [day, setDay] = useState(today);
  const [dateOpen, setDateOpen] = useState(false);
  const selectedDate = new Date(`${day}T12:00:00`);
  const earliest = new Date(2020, 0, 1, 12);
  const selectDate = (date: Date) => {
    setDay(
      `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`,
    );
    setError(false);
    setLoading(true);
    setDateOpen(false);
  };
  const moveDay = (offset: number) => {
    const next = new Date(selectedDate);
    next.setDate(next.getDate() + offset);
    selectDate(next);
  };
  const [error, setError] = useState(false),
    [loading, setLoading] = useState(true);
  const generation = useRef(0);
  const load = useCallback(async () => {
    const request = ++generation.current;
    setLoading(true);
    setError(false);
    try {
      const next = await actions.loadCompetitiveDay(model.clan, day);
      if (generation.current === request) setData(next);
    } catch {
      if (generation.current === request) setError(true);
    } finally {
      if (generation.current === request) setLoading(false);
    }
  }, [actions, model.clan, day]);
  useEffect(() => {
    const requestState = generation;
    const request = ++requestState.current;
    void actions
      .loadCompetitiveDay(model.clan, day)
      .then((next) => {
        if (requestState.current === request) setData(next);
      })
      .catch(() => {
        if (requestState.current === request) setError(true);
      })
      .finally(() => {
        if (requestState.current === request) setLoading(false);
      });
    return () => {
      requestState.current++;
    };
  }, [actions, model.clan, day]);
  const open = async (tag: string) => {
    if (actions.openPlayerTag) return actions.openPlayerTag(tag);
    try {
      actions.openPlayer(await actions.loadPlayer(tag));
    } catch {
      actions.showMessage(t('generalError'));
    }
  };
  if (error)
    return (
      <ClanTabEmpty
        title={t('generalError')}
        body={t('generalTryAgain')}
        onRetry={() => void load()}
      />
    );
  // Placeholder rows are presentation-only: reuse the real member card tree,
  // without adding invented statistics to the service's cached response.
  const rows =
    data?.legends ??
    (model.clan.memberList.length
      ? model.clan.memberList.slice(0, 3)
      : [0, 1, 2].map(() =>
          ClanMember.fromJson({ name: 'Player name', tag: '', townHallLevel: 16 }),
        )
    ).map((member) => ({
      member,
      globalRank: 100,
      trophies: 5000,
      stats: {
        tag: member.tag,
        attackTrophies: 100,
        defenseTrophies: -100,
        netTrophies: 0,
        attacks: 8,
        defenses: 8,
      },
    }));
  return (
    <View style={styles.page} testID="clan-competitive-page">
      <DateNavigator
        label={selectedDate.toLocaleDateString(toIntlLocale(locale), { dateStyle: 'long' })}
        onPrevious={() => moveDay(-1)}
        onNext={() => moveDay(1)}
        previousDisabled={loading || selectedDate <= earliest}
        nextDisabled={loading || day >= today}
        onPressLabel={() => setDateOpen(true)}
        accessibilityLabel={t('rankingsSnapshotDate')}
      />
      {dateOpen ? (
        <Modal
          supportedOrientations={modalOrientations}
          transparent
          animationType="slide"
          onRequestClose={() => setDateOpen(false)}
        >
          <ClanModalViewport>
            <Pressable style={styles.overlay} onPress={() => setDateOpen(false)}>
              <Pressable
                style={[styles.sheet, { backgroundColor: theme.surface }]}
                onPress={() => undefined}
              >
                <CalendarPicker
                  start={selectedDate}
                  minimum={earliest}
                  maximum={new Date(`${today}T12:00:00`)}
                  onChange={selectDate}
                />
              </Pressable>
            </Pressable>
          </ClanModalViewport>
        </Modal>
      ) : null}
      {rows.length ? (
        <SkeletonContent loading={!data && loading} style={{ gap: 12 }}>
          <ClanAdaptiveCards>
            {rows.map(({ member, globalRank, trophies, stats }) => (
              <PressableSurface
                key={member.tag}
                style={styles.player}
                onPress={() => void open(member.tag)}
              >
                <View style={styles.identity}>
                  <MobileWebImage
                    imageUrl={ImageAssets.townHall(member.townHallLevel)}
                    style={styles.hall}
                  />
                  <View style={styles.name}>
                    <CKText role="rowTitle">{member.name}</CKText>
                    <CKText role="metadata" muted>
                      {member.tag}
                      {globalRank ? ` · #${globalRank.toLocaleString()}` : ''}
                    </CKText>
                  </View>
                  <View style={styles.trophies}>
                    <MobileWebImage
                      imageUrl={ImageAssets.getLeagueImage(member.league.name)}
                      style={styles.icon}
                    />
                    <CKText role="rowTitle">{trophies?.toLocaleString() ?? '—'}</CKText>
                  </View>
                </View>
                {stats ? (
                  <View style={styles.metrics}>
                    <View style={styles.metric}>
                      <MobileWebImage imageUrl={ImageAssets.sword} style={styles.icon} />
                      <CKText>
                        {signed(stats.attackTrophies)} · {stats.attacks}/8
                      </CKText>
                    </View>
                    <View style={styles.metric}>
                      <MobileWebImage imageUrl={ImageAssets.shield} style={styles.icon} />
                      <CKText>
                        {signed(stats.defenseTrophies)} · {stats.defenses}/8
                      </CKText>
                    </View>
                    <CKText
                      role="rowTitle"
                      style={{
                        color: stats.netTrophies >= 0 ? ckColors.donationGreen : ckColors.lossRed,
                      }}
                    >
                      {signed(stats.netTrophies)}
                    </CKText>
                  </View>
                ) : (
                  <CKText muted>{t('generalNoDataAvailable')}</CKText>
                )}
              </PressableSurface>
            ))}
          </ClanAdaptiveCards>
        </SkeletonContent>
      ) : null}
      {data && !rows.length ? <ClanTabEmpty title={t('generalNoDataAvailable')} /> : null}
    </View>
  );
}
const styles = StyleSheet.create({
  page: { padding: 16, gap: 12 },
  loading: { padding: 32, alignItems: 'center' },
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#0008' },
  sheet: { padding: 24, borderTopLeftRadius: 28, borderTopRightRadius: 28 },
  player: { padding: 14, gap: 12, borderWidth: 0, borderRadius: 20 },
  identity: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  name: { flex: 1, gap: 3 },
  hall: { width: 40, height: 40 },
  icon: { width: 22, height: 22 },
  trophies: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  metrics: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  metric: { flexDirection: 'row', alignItems: 'center', gap: 5 },
});
