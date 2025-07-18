class ClanWarStatsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? ownTownHall;
  final int? enemyTownHall;
  final List<int>? ownTownHalls;
  final List<int>? enemyTownHalls;
  final bool sameTownHall;
  final String warType;
  final List<String>? warTypes;
  final bool? freshAttacksOnly;
  final int? minStars;
  final int? maxStars;
  final List<int>? allowedStars;
  final double? minDestruction;
  final double? maxDestruction;
  final int? minMapPosition;
  final int? maxMapPosition;
  final int limit;

  const ClanWarStatsFilter({
    this.startDate,
    this.endDate,
    this.ownTownHall,
    this.enemyTownHall,
    this.ownTownHalls,
    this.enemyTownHalls,
    this.sameTownHall = false,
    this.warType = "all",
    this.warTypes,
    this.freshAttacksOnly,
    this.minStars,
    this.maxStars,
    this.allowedStars,
    this.minDestruction,
    this.maxDestruction,
    this.minMapPosition,
    this.maxMapPosition,
    this.limit = 50,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'limit': limit,
      'same_th': sameTownHall,
    };
    
    if (warTypes != null && warTypes!.isNotEmpty) {
      data['type'] = warTypes;
    } else {
      data['type'] = warType;
    }

    if (startDate != null) {
      data['timestamp_start'] = startDate!.millisecondsSinceEpoch ~/ 1000;
    }
    if (endDate != null) {
      data['timestamp_end'] = endDate!.millisecondsSinceEpoch ~/ 1000;
    }
    if (ownTownHalls != null && ownTownHalls!.isNotEmpty) {
      data['own_th'] = ownTownHalls;
    } else if (ownTownHall != null) {
      data['own_th'] = ownTownHall;
    }
    if (enemyTownHalls != null && enemyTownHalls!.isNotEmpty) {
      data['enemy_th'] = enemyTownHalls;
    } else if (enemyTownHall != null) {
      data['enemy_th'] = enemyTownHall;
    }
    if (freshAttacksOnly != null) {
      data['fresh_only'] = freshAttacksOnly;
    }
    if (allowedStars != null && allowedStars!.isNotEmpty) {
      data['stars'] = allowedStars;
    } else {
      if (minStars != null) {
        data['min_stars'] = minStars;
      }
      if (maxStars != null) {
        data['max_stars'] = maxStars;
      }
    }
    if (minDestruction != null) {
      data['min_destruction'] = minDestruction;
    }
    if (maxDestruction != null) {
      data['max_destruction'] = maxDestruction;
    }
    if (minMapPosition != null) {
      data['map_position_min'] = minMapPosition;
    }
    if (maxMapPosition != null) {
      data['map_position_max'] = maxMapPosition;
    }

    return data;
  }

  ClanWarStatsFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? ownTownHall,
    int? enemyTownHall,
    List<int>? ownTownHalls,
    List<int>? enemyTownHalls,
    bool? sameTownHall,
    String? warType,
    List<String>? warTypes,
    bool? freshAttacksOnly,
    int? minStars,
    int? maxStars,
    List<int>? allowedStars,
    double? minDestruction,
    double? maxDestruction,
    int? minMapPosition,
    int? maxMapPosition,
    int? limit,
  }) {
    return ClanWarStatsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ownTownHall: ownTownHall ?? this.ownTownHall,
      enemyTownHall: enemyTownHall ?? this.enemyTownHall,
      ownTownHalls: ownTownHalls ?? this.ownTownHalls,
      enemyTownHalls: enemyTownHalls ?? this.enemyTownHalls,
      sameTownHall: sameTownHall ?? this.sameTownHall,
      warType: warType ?? this.warType,
      warTypes: warTypes ?? this.warTypes,
      freshAttacksOnly: freshAttacksOnly ?? this.freshAttacksOnly,
      minStars: minStars ?? this.minStars,
      maxStars: maxStars ?? this.maxStars,
      allowedStars: allowedStars ?? this.allowedStars,
      minDestruction: minDestruction ?? this.minDestruction,
      maxDestruction: maxDestruction ?? this.maxDestruction,
      minMapPosition: minMapPosition ?? this.minMapPosition,
      maxMapPosition: maxMapPosition ?? this.maxMapPosition,
      limit: limit ?? this.limit,
    );
  }

  /// Default filter for mobile app
  static ClanWarStatsFilter defaultFilter() {
    return ClanWarStatsFilter(
      startDate: DateTime.now().subtract(const Duration(days: 180)), // 6 months ago
      endDate: DateTime.now(),
      warType: "all",
      limit: 50,
    );
  }

  /// Check if any filters are active (not default)
  bool hasActiveFilters() {
    return ownTownHall != null ||
        enemyTownHall != null ||
        (ownTownHalls != null && ownTownHalls!.isNotEmpty) ||
        (enemyTownHalls != null && enemyTownHalls!.isNotEmpty) ||
        sameTownHall ||
        warType != "all" ||
        (warTypes != null && warTypes!.isNotEmpty) ||
        freshAttacksOnly != null ||
        minStars != null ||
        maxStars != null ||
        (allowedStars != null && allowedStars!.isNotEmpty) ||
        minDestruction != null ||
        maxDestruction != null ||
        minMapPosition != null ||
        maxMapPosition != null;
  }

  /// Get filter summary text
  String getFilterSummary() {
    List<String> filters = [];
    
    if (ownTownHalls != null && ownTownHalls!.isNotEmpty) {
      if (ownTownHalls!.length == 1) {
        filters.add("TH${ownTownHalls!.first} attacks");
      } else {
        filters.add("TH${ownTownHalls!.join(', ')} attacks");
      }
    } else if (ownTownHall != null) {
      filters.add("TH$ownTownHall attacks");
    }
    
    if (enemyTownHalls != null && enemyTownHalls!.isNotEmpty) {
      if (enemyTownHalls!.length == 1) {
        filters.add("vs TH${enemyTownHalls!.first}");
      } else {
        filters.add("vs TH${enemyTownHalls!.join(', ')}");
      }
    } else if (enemyTownHall != null) {
      filters.add("vs TH$enemyTownHall");
    }
    
    if (sameTownHall) filters.add("Same TH only");
    
    if (warTypes != null && warTypes!.isNotEmpty) {
      if (warTypes!.length == 1) {
        filters.add("${warTypes!.first.toUpperCase()} wars");
      } else {
        filters.add("${warTypes!.map((w) => w.toUpperCase()).join(', ')} wars");
      }
    } else if (warType != "all") {
      filters.add("${warType.toUpperCase()} wars");
    }
    
    if (freshAttacksOnly == true) filters.add("Fresh attacks only");
    
    if (allowedStars != null && allowedStars!.isNotEmpty) {
      if (allowedStars!.length == 1) {
        filters.add("${allowedStars!.first} ⭐ only");
      } else {
        filters.add("${allowedStars!.join(', ')} ⭐ only");
      }
    } else if (minStars != null || maxStars != null) {
      if (minStars != null && maxStars != null) {
        filters.add("$minStars-$maxStars stars");
      } else if (minStars != null) {
        filters.add("$minStars+ stars");
      } else {
        filters.add("≤$maxStars stars");
      }
    }
    
    if (minDestruction != null || maxDestruction != null) {
      if (minDestruction != null && maxDestruction != null) {
        filters.add("${minDestruction!.toStringAsFixed(0)}-${maxDestruction!.toStringAsFixed(0)}% destruction");
      } else if (minDestruction != null) {
        filters.add("${minDestruction!.toStringAsFixed(0)}%+ destruction");
      } else {
        filters.add("≤${maxDestruction!.toStringAsFixed(0)}% destruction");
      }
    }
    
    return filters.isEmpty ? "No filters applied" : filters.join(", ");
  }
}