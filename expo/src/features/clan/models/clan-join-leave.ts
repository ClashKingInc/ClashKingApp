import { JoinLeaveClan } from './clan-core';
import { apiDateOrEpoch, int, record, records, string, type JsonRecord } from './parsing';

export class JoinLeaveEvent {
  constructor(
    readonly type: string,
    readonly clan: JoinLeaveClan | null,
    readonly time: Date,
    readonly tag: string,
    readonly name: string,
    readonly th: number,
  ) {}

  static fromJson(json: JsonRecord): JoinLeaveEvent {
    const clan = record(json.clan);
    return new JoinLeaveEvent(
      string(json.type),
      Object.keys(clan).length ? JoinLeaveClan.fromJson(clan) : null,
      apiDateOrEpoch(json.time),
      string(json.tag),
      string(json.name),
      int(json.townHallLevel, int(json.th)),
    );
  }
}

export class ClanJoinLeave {
  constructor(
    readonly clanTag: string,
    readonly available: number,
    readonly uniquePlayers: number,
    readonly joinLeaveList: readonly JoinLeaveEvent[],
  ) {}

  static fromJson(json: JsonRecord): ClanJoinLeave {
    // join_leave_list is a deliberate Flutter fallback for the prior response shape.
    const items = Array.isArray(json.items) ? json.items : json.join_leave_list;
    return new ClanJoinLeave(
      string(json.clan_tag),
      int(json.available),
      int(json.uniquePlayers),
      records(items).map(JoinLeaveEvent.fromJson),
    );
  }

  static empty(): ClanJoinLeave {
    return new ClanJoinLeave('', 0, 0, []);
  }

  appendPage(page: ClanJoinLeave): ClanJoinLeave {
    const seen = new Set<string>();
    const combined: JoinLeaveEvent[] = [];
    for (const event of [...this.joinLeaveList, ...page.joinLeaveList]) {
      const key = `${event.time.toISOString()}|${event.type}|${event.tag}`;
      if (!seen.has(key)) {
        seen.add(key);
        combined.push(event);
      }
    }
    return new ClanJoinLeave(
      this.clanTag || page.clanTag,
      page.available,
      page.uniquePlayers,
      combined,
    );
  }
}
