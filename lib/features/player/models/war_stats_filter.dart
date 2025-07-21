class WarStatsFilter {
  final String? season;
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
  final Map<String, dynamic>? metadata;

  const WarStatsFilter({
    this.season,
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
    this.metadata,
  });

  factory WarStatsFilter.fromJson(Map<String, dynamic> json) {
    return WarStatsFilter(
      season: json['season'],
      startDate: json['timestamp_start'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp_start'] * 1000)
          : null,
      endDate: json['timestamp_end'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp_end'] * 1000)
          : null,
      ownTownHall: json['own_th'] is List && (json['own_th'] as List).length == 1
          ? (json['own_th'] as List)[0]
          : null,
      enemyTownHall: json['enemy_th'] is List && (json['enemy_th'] as List).length == 1
          ? (json['enemy_th'] as List)[0]
          : null,
      ownTownHalls: json['own_th'] is List ? List<int>.from(json['own_th']) : null,
      enemyTownHalls: json['enemy_th'] is List ? List<int>.from(json['enemy_th']) : null,
      sameTownHall: json['same_th'] ?? false,
      warType: json['type'] is List && (json['type'] as List).length == 1
          ? (json['type'] as List)[0]
          : "all",
      warTypes: json['type'] is List ? List<String>.from(json['type']) : null,
      freshAttacksOnly: json['fresh_only'],
      allowedStars: json['stars'] is List ? List<int>.from(json['stars']) : null,
      minDestruction: json['min_destruction']?.toDouble(),
      maxDestruction: json['max_destruction']?.toDouble(),
      minMapPosition: json['map_position_min'],
      maxMapPosition: json['map_position_max'],
      limit: json['limit'] ?? 50,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'limit': limit,
      'same_th': sameTownHall,
    };
    
    if (warTypes != null && warTypes!.isNotEmpty && !warTypes!.contains('all')) {
      data['type'] = warTypes;
    } else if (warType != "all") {
      data['type'] = warType;
    }

    if (season != null) {
      data['season'] = season;
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
    if (metadata != null) {
      data['metadata'] = metadata;
    }

    return data;
  }

  WarStatsFilter copyWith({
    String? season,
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
    Map<String, dynamic>? metadata,
  }) {
    return WarStatsFilter(
      season: season ?? this.season,
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
      metadata: metadata ?? this.metadata,
    );
  }

  /// Default filter for mobile app
  static WarStatsFilter defaultFilter() {
    return WarStatsFilter(
      startDate: DateTime.now().subtract(const Duration(days: 180)), // 6 months ago
      endDate: DateTime.now(),
      warType: "all",
      limit: 50,
    );
  }

  /// Check if any filters are active (not default)
  bool hasActiveFilters() {
    return season != null ||
        startDate != null ||
        endDate != null ||
        ownTownHall != null ||
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
    
    if (season != null) {
      filters.add("Season $season");
    }
    
    // Add date range filter display
    if (startDate != null && endDate != null) {
      final start = "${startDate!.day}/${startDate!.month}/${startDate!.year}";
      final end = "${endDate!.day}/${endDate!.month}/${endDate!.year}";
      filters.add("$start - $end");
    } else if (startDate != null) {
      final start = "${startDate!.day}/${startDate!.month}/${startDate!.year}";
      filters.add("From $start");
    } else if (endDate != null) {
      final end = "${endDate!.day}/${endDate!.month}/${endDate!.year}";
      filters.add("Until $end");
    }
    
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