type JsonRecord = Record<string, unknown>;

const FALLBACK_BADGE = 'https://assets.clashk.ing/clashkinglogo.png';

export function buildWarWidgetPayload(value: unknown, clanTag: string, now = new Date()): string {
  const data = record(value);
  const updatedAt = `Updated at ${clock(now)}`;
  const warInfo = record(data.war_info);
  const currentWar = record(warInfo.currentWarInfo);
  const currentState = nullableString(currentWar.state) ?? nullableString(warInfo.state) ?? '';
  if (
    data.isInWar === true ||
    currentState === 'preparation' ||
    currentState === 'inWar' ||
    currentState === 'warEnded'
  ) {
    return JSON.stringify(regularWarPayload(warInfo, updatedAt, now));
  }
  if (data.isInCwl === true && isRecord(data.league_info)) {
    return JSON.stringify(cwlWarPayload(data, updatedAt, clanTag, now));
  }
  if ((nullableString(warInfo.state) ?? 'notInWar') === 'accessDenied') {
    return JSON.stringify({
      updatedAt,
      timeState: '',
      state: 'accessDenied',
      mode: 'war',
      statusIcon: '🔒',
      primaryText: 'War Log Private',
      secondaryText: '',
      colorTheme: 'warning',
    });
  }
  return JSON.stringify({
    updatedAt,
    timeState: '',
    state: 'notInWar',
    mode: 'war',
    statusIcon: '😴',
    primaryText: 'Not in War',
    secondaryText: '',
    colorTheme: 'neutral',
  });
}

export function buildWarWidgetErrorPayload(now = new Date()): string {
  return JSON.stringify({
    updatedAt: `Error at ${clock(now)}`,
    timeState: 'Refresh failed',
    state: 'error',
    mode: 'war',
    statusIcon: '⚠️',
    primaryText: 'Unable to load war data',
    secondaryText: 'Tap to open ClashKing',
    colorTheme: 'warning',
  });
}

export function buildNotInClanWidgetPayload(now = new Date()): string {
  return JSON.stringify({
    updatedAt: `Updated at ${clock(now)}`,
    timeState: '',
    state: 'notInClan',
    mode: 'war',
  });
}

function regularWarPayload(warInfo: JsonRecord, updatedAt: string, now: Date) {
  const war = record(warInfo.currentWarInfo);
  const state = nullableString(war.state) ?? 'unknown';
  const clan = record(war.clan);
  const opponent = record(war.opponent);
  const clanStars = integer(clan.stars);
  const opponentStars = integer(opponent.stars);
  const teamSize = integer(war.teamSize);
  const display = displayForWar(state, clanStars, opponentStars, war, now, false);
  return {
    state,
    mode: 'war',
    updatedAt,
    ...display,
    clan: sidePayload(clan, teamSize * 2, teamSize * 3, clanStars, 'Unknown', true),
    opponent: sidePayload(opponent, teamSize * 2, teamSize * 3, opponentStars, 'Unknown', true),
  };
}

function cwlWarPayload(data: JsonRecord, updatedAt: string, clanTag: string, now: Date) {
  const wars = array(data.war_league_infos).map(record).filter(hasWarIdentity);
  const active = selectCwlWar(wars, clanTag);
  if (active === undefined) {
    return {
      updatedAt,
      timeState: 'CWL Period',
      state: 'cwl',
      mode: 'cwl',
      score: '-',
      statusIcon: '🏅',
      primaryText: 'CWL Period',
      secondaryText: 'No active wars',
      colorTheme: 'neutral',
      clan: null,
      opponent: null,
    };
  }
  const originalClan = record(active.clan);
  const originalOpponent = record(active.opponent);
  const ourFirst = normalizeTag(string(originalClan.tag)) === normalizeTag(clanTag);
  const clan = ourFirst ? originalClan : originalOpponent;
  const opponent = ourFirst ? originalOpponent : originalClan;
  const clanStars = integer(clan.stars);
  const opponentStars = integer(opponent.stars);
  const teamSize = integer(active.teamSize) || 15;
  const state = string(active.state);
  const display = displayForWar(state, clanStars, opponentStars, active, now, true);
  const league = record(data.league_info);
  const leagueClan = array(league.clans)
    .map(record)
    .find((entry) => string(entry.tag) === clanTag);
  return {
    state: 'cwl',
    mode: 'cwl',
    updatedAt,
    ...display,
    clan: sidePayload(clan, teamSize, teamSize * 3, clanStars, 'CWL Clan', false),
    cwlRank: leagueClan === undefined ? null : (nullableInteger(leagueClan.rank) ?? null),
    cwlLeague: nullableString(league.season) ?? 'unknown',
    opponent: sidePayload(opponent, teamSize, teamSize * 3, opponentStars, 'CWL Opponent', false),
  };
}

function displayForWar(
  state: string,
  clanStars: number,
  opponentStars: number,
  war: JsonRecord,
  now: Date,
  cwl: boolean,
) {
  let timeState = cwl ? 'CWL' : '';
  let score = '';
  let statusIcon = cwl ? '🏅' : '⚔️';
  let primaryText = '';
  let secondaryText = '';
  let colorTheme = cwl ? 'cwl' : 'active';
  if (state === 'preparation') {
    statusIcon = cwl ? '🏅' : '🛡️';
    primaryText = cwl ? 'CWL Preparation' : 'War Preparation';
    colorTheme = cwl ? 'cwl' : 'preparation';
    const start = date(war.startTime);
    if (start !== undefined) {
      timeState = futureTimeLabel('Starts', start, now);
      primaryText = timeState;
    }
  } else if (state === 'inWar') {
    secondaryText = `${clanStars} - ${opponentStars}`;
    colorTheme =
      clanStars > opponentStars ? 'winning' : clanStars < opponentStars ? 'losing' : 'tied';
    const end = date(war.endTime);
    if (end !== undefined) {
      timeState = futureTimeLabel('Ends', end, now, true);
      primaryText = timeState;
    }
    score = secondaryText;
  } else if (state === 'warEnded') {
    const won = clanStars > opponentStars;
    statusIcon = won ? '🏆' : cwl ? '🥈' : '💔';
    primaryText = won ? (cwl ? 'CWL Victory!' : 'Victory!') : cwl ? 'CWL Complete' : 'Defeat';
    secondaryText = `${clanStars} - ${opponentStars}`;
    colorTheme = won ? 'victory' : cwl ? 'cwl' : 'defeat';
    timeState = cwl ? 'CWL War Ended' : 'War Ended';
    score = secondaryText;
  }
  return { timeState, score, statusIcon, primaryText, secondaryText, colorTheme };
}

function sidePayload(
  side: JsonRecord,
  attackMaximum: number,
  maxStars: number,
  stars: number,
  fallbackName: string,
  fallbackBadge: boolean,
) {
  const badgeUrls = record(side.badgeUrls);
  const badge =
    nullableString(badgeUrls.small) ??
    nullableString(badgeUrls.medium) ??
    nullableString(badgeUrls.large);
  return {
    name: nullableString(side.name) ?? fallbackName,
    badgeUrlMedium: fallbackBadge ? (badge ?? FALLBACK_BADGE) : badge,
    percent: `${number(side.destructionPercentage).toFixed(2)}%`,
    attacks: `${integer(side.attacks)}/${attackMaximum}`,
    stars,
    maxStars,
  };
}

function selectCwlWar(wars: JsonRecord[], clanTag: string): JsonRecord | undefined {
  const matches = (war: JsonRecord) => {
    const tag = normalizeTag(clanTag);
    return (
      normalizeTag(string(record(war.clan).tag)) === tag ||
      normalizeTag(string(record(war.opponent).tag)) === tag
    );
  };
  for (const state of ['inWar', 'preparation']) {
    const found = wars.find((war) => string(war.state) === state && matches(war));
    if (found !== undefined) return found;
  }
  return wars
    .filter((war) => string(war.state) === 'warEnded' && matches(war))
    .sort((left, right) => string(right.endTime).localeCompare(string(left.endTime)))[0];
}

function futureTimeLabel(prefix: 'Starts' | 'Ends', target: Date, now: Date, left = false) {
  const minutes = Math.trunc((target.getTime() - now.getTime()) / 60_000);
  const hours = Math.trunc(minutes / 60);
  if (hours > 0)
    return left ? `${hours}h ${minutes % 60}m left` : `${prefix} in ${hours}h ${minutes % 60}m`;
  return `${prefix} at ${clock(target)}`;
}

function clock(value: Date) {
  return `${String(value.getHours()).padStart(2, '0')}:${String(value.getMinutes()).padStart(2, '0')}`;
}

function normalizeTag(value: string) {
  return value.startsWith('#') ? value : `#${value}`;
}

function hasWarIdentity(value: JsonRecord) {
  return string(value.state) !== 'unknown' || isRecord(value.clan) || isRecord(value.opponent);
}

function record(value: unknown): JsonRecord {
  return isRecord(value) ? value : {};
}
function array(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}
function string(value: unknown): string {
  return value == null ? '' : String(value);
}
function nullableString(value: unknown): string | null {
  return value == null ? null : String(value);
}
function number(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}
function integer(value: unknown): number {
  return Math.trunc(number(value));
}
function nullableInteger(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : undefined;
}
function date(value: unknown): Date | undefined {
  if (typeof value !== 'string') return undefined;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? undefined : parsed;
}
function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
