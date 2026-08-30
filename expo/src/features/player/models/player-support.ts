import { ImageAssets } from '@/core/assets/image-assets';
import { int, record, string, type JsonRecord } from './parsing';

export class PlayerAchievement {
  constructor(
    readonly name: string,
    readonly stars: number,
    readonly value: number,
    readonly target: number,
    readonly info: string,
    readonly completionInfo: string,
    readonly village: string,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerAchievement(
      string(json.name, 'No name'),
      int(json.stars),
      int(json.value),
      int(json.target),
      string(json.info),
      string(json.completionInfo),
      string(json.village, 'home'),
    );
  }
}
export class PlayerSeasonPass {
  constructor(
    readonly season: string,
    readonly points: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerSeasonPass(string(json.season), int(json.points));
  }
}
export class PlayerClanGames {
  constructor(
    readonly season: string,
    readonly points: number,
    readonly clanTag: string,
  ) {}
  static fromJson(season: string, json: JsonRecord) {
    return new PlayerClanGames(season, int(json.points), string(json.clan));
  }
}
export interface ClanBadgeUrls {
  small: string;
  medium: string;
  large: string;
}
export class PlayerClanOverview {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly clanLevel: number,
    readonly badgeUrls: ClanBadgeUrls,
  ) {}
  static fromJson(json: JsonRecord) {
    const badge = record(json.badgeUrls);
    return new PlayerClanOverview(string(json.tag), string(json.name), int(json.clanLevel), {
      small: string(badge.small),
      medium: string(badge.medium),
      large: string(badge.large),
    });
  }
  static empty() {
    return new PlayerClanOverview('', '', 0, { small: '', medium: '', large: '' });
  }
}
export interface PlayerCardOptionsJson {
  warTab?: unknown;
  todoPage?: unknown;
  upgradeTrackerHome?: unknown;
  rankedHome?: unknown;
}
export class PlayerCardOptions {
  constructor(
    readonly showInWarTab = true,
    readonly showInTodoPage = true,
    readonly showUpgradeTrackerOnHome = true,
    readonly showRankedOnHome = true,
  ) {}
  get isDefault() {
    return (
      this.showInWarTab &&
      this.showInTodoPage &&
      this.showUpgradeTrackerOnHome &&
      this.showRankedOnHome
    );
  }
  static fromJson(json: PlayerCardOptionsJson) {
    return new PlayerCardOptions(
      json.warTab !== false,
      json.todoPage !== false,
      json.upgradeTrackerHome !== false,
      json.rankedHome !== false,
    );
  }
  toJson() {
    return {
      warTab: this.showInWarTab,
      todoPage: this.showInTodoPage,
      upgradeTrackerHome: this.showUpgradeTrackerOnHome,
      rankedHome: this.showRankedOnHome,
    };
  }
  copyWith(
    value: Partial<{
      showInWarTab: boolean;
      showInTodoPage: boolean;
      showUpgradeTrackerOnHome: boolean;
      showRankedOnHome: boolean;
    }>,
  ) {
    return new PlayerCardOptions(
      value.showInWarTab ?? this.showInWarTab,
      value.showInTodoPage ?? this.showInTodoPage,
      value.showUpgradeTrackerOnHome ?? this.showUpgradeTrackerOnHome,
      value.showRankedOnHome ?? this.showRankedOnHome,
    );
  }
}
export const playerClanBadge = (tag: string) => ImageAssets.clanBadgeForTag(tag);
