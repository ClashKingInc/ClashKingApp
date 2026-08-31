import { ImageAssets } from '../../../core/assets/image-assets';
import { bool, int, nullableString, record, records, string, type JsonRecord } from './parsing';
import type { CapitalHistoryItems } from './clan-capital-history';
import type { ClanJoinLeave } from './clan-join-leave';
import type { ClanWarLog } from './clan-war-log';
import type { ClanWarStats } from './clan-war-stats';

const OFFICIAL_ASSET_HOST = 'https://api-assets.clashofclans.com';
const ASSET_PROXY_HOST = 'https://assets-proxy.clashk.ing';

export function cocAssetsProxyUrl(url: string): string {
  return url.startsWith(OFFICIAL_ASSET_HOST)
    ? url.replace(OFFICIAL_ASSET_HOST, ASSET_PROXY_HOST)
    : url;
}

export class ClanBadgeUrls {
  constructor(
    readonly small: string,
    readonly medium: string,
    readonly large: string,
  ) {}

  get smallest(): string {
    return this.small || this.medium || this.large;
  }

  static fromJson(value: unknown): ClanBadgeUrls {
    const json = record(value);
    return new ClanBadgeUrls(
      cocAssetsProxyUrl(string(json.small)),
      cocAssetsProxyUrl(string(json.medium)),
      cocAssetsProxyUrl(string(json.large)),
    );
  }

  static empty(): ClanBadgeUrls {
    return new ClanBadgeUrls('', '', '');
  }
}

export class ClanLeague {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly smallIconUrl: string | null,
    readonly mediumIconUrl: string | null,
    readonly tinyIconUrl: string | null,
  ) {}

  static fromJson(json: JsonRecord): ClanLeague {
    const icons = record(json.iconUrls);
    return new ClanLeague(
      int(json.id),
      string(json.name),
      nullableString(icons.small),
      nullableString(icons.medium),
      nullableString(icons.tiny),
    );
  }

  static unranked(): ClanLeague {
    return new ClanLeague(0, 'Unranked', null, null, null);
  }
}

export class ClanLocation {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly isCountry: boolean,
    readonly countryCode: string | null,
  ) {}

  static fromJson(json: JsonRecord): ClanLocation {
    return new ClanLocation(
      int(json.id),
      string(json.name),
      bool(json.isCountry),
      nullableString(json.countryCode),
    );
  }
}

export class ClanDistrict {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly districtHallLevel: number,
  ) {}

  static fromJson(json: JsonRecord): ClanDistrict {
    return new ClanDistrict(int(json.id), string(json.name), int(json.districtHallLevel));
  }
}

export class ClanCapital {
  constructor(
    readonly capitalHallLevel: number,
    readonly districts: readonly ClanDistrict[],
  ) {}

  static fromJson(json: JsonRecord): ClanCapital {
    return new ClanCapital(
      int(json.capitalHallLevel),
      records(json.districts).map(ClanDistrict.fromJson),
    );
  }
}

export class ClanChatLanguage {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly languageCode: string,
  ) {}

  static fromJson(json: JsonRecord): ClanChatLanguage {
    return new ClanChatLanguage(int(json.id), string(json.name), string(json.languageCode));
  }
}

export class ClanMember {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly role: string,
    readonly townHallLevel: number,
    readonly expLevel: number,
    readonly trophies: number,
    readonly donations: number,
    readonly donationsReceived: number,
    readonly builderBaseTrophies: number,
    readonly league: ClanLeague,
    readonly builderBaseLeague: ClanLeague | null,
  ) {}

  static fromJson(json: JsonRecord): ClanMember {
    // This is an explicit Flutter compatibility rule: the clan member endpoint
    // renamed league to leagueTier while standalone player responses retain league.
    const rawLeague = json.leagueTier ?? json.league;
    return new ClanMember(
      string(json.tag),
      string(json.name),
      string(json.role),
      int(json.townHallLevel),
      int(json.expLevel),
      int(json.trophies),
      int(json.donations),
      int(json.donationsReceived),
      int(json.builderBaseTrophies),
      Object.keys(record(rawLeague)).length
        ? ClanLeague.fromJson(record(rawLeague))
        : ClanLeague.unranked(),
      Object.keys(record(json.builderBaseLeague)).length
        ? ClanLeague.fromJson(record(json.builderBaseLeague))
        : null,
    );
  }

  static empty(): ClanMember {
    return new ClanMember('', '', '', 0, 0, 0, 0, 0, 0, ClanLeague.unranked(), null);
  }
}

export interface WarCwlLike {
  readonly tag: string;
}

export class Clan {
  warCwl: WarCwlLike | null = null;
  joinLeave: ClanJoinLeave | null = null;
  clanCapitalRaid: CapitalHistoryItems | null = null;
  clanWarLog: ClanWarLog | null = null;
  clanWarStats: ClanWarStats | null = null;

  constructor(
    readonly tag: string,
    readonly name: string,
    readonly type: string,
    readonly description: string,
    readonly location: ClanLocation | null,
    readonly isFamilyFriendly: boolean,
    readonly badgeUrls: ClanBadgeUrls,
    readonly clanLevel: number,
    readonly clanPoints: number,
    readonly clanBuilderBasePoints: number,
    readonly clanCapitalPoints: number,
    readonly capitalLeague: ClanLeague | null,
    readonly requiredTrophies: number,
    readonly warFrequency: string,
    readonly warWinStreak: number,
    readonly warWins: number,
    readonly warTies: number,
    readonly warLosses: number,
    readonly isWarLogPublic: boolean,
    readonly warLeague: ClanLeague | null,
    readonly members: number,
    readonly memberList: ClanMember[],
    readonly labels: readonly ClanLeague[],
    readonly requiredBuilderBaseTrophies: number,
    readonly requiredTownhallLevel: number,
    readonly clanCapital: ClanCapital | null,
    readonly chatLanguage: ClanChatLanguage | null,
  ) {}

  static fromJson(json: JsonRecord): Clan {
    return new Clan(
      string(json.tag),
      string(json.name),
      string(json.type),
      string(json.description),
      Object.keys(record(json.location)).length
        ? ClanLocation.fromJson(record(json.location))
        : null,
      bool(json.isFamilyFriendly),
      ClanBadgeUrls.fromJson(json.badgeUrls),
      int(json.clanLevel),
      int(json.clanPoints),
      int(json.clanBuilderBasePoints),
      int(json.clanCapitalPoints),
      Object.keys(record(json.capitalLeague)).length
        ? ClanLeague.fromJson(record(json.capitalLeague))
        : null,
      int(json.requiredTrophies),
      string(json.warFrequency, 'unknown'),
      int(json.warWinStreak),
      int(json.warWins),
      int(json.warTies),
      int(json.warLosses),
      bool(json.isWarLogPublic, true),
      Object.keys(record(json.warLeague)).length
        ? ClanLeague.fromJson(record(json.warLeague))
        : null,
      int(json.members),
      records(json.memberList).map(ClanMember.fromJson),
      records(json.labels).map(ClanLeague.fromJson),
      int(json.requiredBuilderBaseTrophies),
      int(json.requiredTownhallLevel),
      Object.keys(record(json.clanCapital)).length
        ? ClanCapital.fromJson(record(json.clanCapital))
        : null,
      Object.keys(record(json.chatLanguage)).length
        ? ClanChatLanguage.fromJson(record(json.chatLanguage))
        : null,
    );
  }

  linkWar(warCwl: WarCwlLike): void {
    this.warCwl = warCwl;
  }

  linkJoinLeave(joinLeave: ClanJoinLeave): void {
    this.joinLeave = joinLeave;
  }
}

export class JoinLeaveClan {
  constructor(
    readonly name: string,
    readonly tag: string,
    readonly badge: string,
  ) {}

  static fromJson(json: JsonRecord): JoinLeaveClan {
    const tag = string(json.tag);
    return new JoinLeaveClan(string(json.name), tag, ImageAssets.clanBadgeForTag(tag));
  }
}
