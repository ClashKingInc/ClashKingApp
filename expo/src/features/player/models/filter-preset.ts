import { WarStatsFilter } from './war-stats-filter';
import { int, record, string, type JsonRecord } from './parsing';
export class FilterPreset {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly filter: WarStatsFilter,
    readonly createdAt: Date,
  ) {}
  toJson(): JsonRecord {
    return {
      id: this.id,
      name: this.name,
      filter: this.filter.toJson(),
      createdAt: this.createdAt.getTime(),
    };
  }
  static fromJson(json: JsonRecord) {
    return new FilterPreset(
      string(json.id),
      string(json.name),
      WarStatsFilter.fromJson(record(json.filter)),
      json.createdAt == null ? new Date() : new Date(int(json.createdAt)),
    );
  }
  copyWith(value: Partial<{ id: string; name: string; filter: WarStatsFilter; createdAt: Date }>) {
    return new FilterPreset(
      value.id ?? this.id,
      value.name ?? this.name,
      value.filter ?? this.filter,
      value.createdAt ?? this.createdAt,
    );
  }
}
