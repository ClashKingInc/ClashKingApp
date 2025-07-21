import 'package:clashkingapp/features/player/models/war_stats_filter.dart';

class FilterPreset {
  final String id;
  final String name;
  final WarStatsFilter filter;
  final DateTime createdAt;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.filter,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filter': filter.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    return FilterPreset(
      id: json['id'],
      name: json['name'],
      filter: WarStatsFilter.fromJson(json['filter']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  FilterPreset copyWith({
    String? id,
    String? name,
    WarStatsFilter? filter,
    DateTime? createdAt,
  }) {
    return FilterPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      filter: filter ?? this.filter,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}