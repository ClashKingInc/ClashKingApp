enum NotificationCategory {
  legendAttacks,
  legendDefenses,
  warAttacks,
  warState,
  warReminders,
  events,
  announcements,
  monthlySupport,
}

enum NotificationAccountSource {
  verified,
  bookmarked;

  static NotificationAccountSource fromWire(String value) => switch (value) {
    'verified' => NotificationAccountSource.verified,
    'bookmarked' => NotificationAccountSource.bookmarked,
    _ => throw FormatException('Unsupported notification account source'),
  };
}

class NotificationAccount {
  const NotificationAccount({
    required this.playerTag,
    required this.source,
    this.active = true,
  });

  final String playerTag;
  final NotificationAccountSource source;
  final bool active;

  factory NotificationAccount.fromJson(Map<String, dynamic> json) {
    final playerTag = json['playerTag'];
    final source = json['source'];
    final active = json['active'];
    if (playerTag is! String || playerTag.isEmpty || source is! String) {
      throw const FormatException('Invalid notification account');
    }
    return NotificationAccount(
      playerTag: playerTag,
      source: NotificationAccountSource.fromWire(source),
      active: active is bool ? active : true,
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.deviceId = '',
    this.environment = 'production',
    this.notificationsEnabled = false,
    this.legendAttacks = false,
    this.legendDefenses = false,
    this.warAttacks = false,
    this.warState = false,
    this.warReminders = false,
    this.events = false,
    this.announcements = false,
    this.monthlySupport = false,
    this.reminderTimings = const [],
    this.accounts = const [],
  });

  final String deviceId;
  final String environment;
  final bool notificationsEnabled;
  final bool legendAttacks;
  final bool legendDefenses;
  final bool warAttacks;
  final bool warState;
  final bool warReminders;
  final bool events;
  final bool announcements;
  final bool monthlySupport;
  final List<int> reminderTimings;
  final List<NotificationAccount> accounts;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool readBool(String key) {
      final value = json[key];
      if (value is! bool) {
        throw FormatException('Invalid $key');
      }
      return value;
    }

    final deviceId = json['deviceId'];
    final environment = json['environment'];
    final reminderTimings = json['reminderTimings'];
    final accounts = json['accounts'];
    if (deviceId is! String ||
        environment is! String ||
        reminderTimings is! List ||
        accounts is! List) {
      throw const FormatException('Invalid notification preferences');
    }

    final minutes = reminderTimings
        .map((value) {
          if (value is! num || value.toInt() != value) {
            throw const FormatException('Invalid reminder timing');
          }
          return value.toInt();
        })
        .toList(growable: false);
    if (minutes.length > 3 ||
        minutes.any((value) => value < 1 || value > 2820) ||
        minutes.toSet().length != minutes.length) {
      throw const FormatException('Invalid reminder timings');
    }
    final parsedAccounts = accounts
        .map((value) {
          if (value is! Map) {
            throw const FormatException('Invalid notification account');
          }
          return NotificationAccount.fromJson(Map<String, dynamic>.from(value));
        })
        .toList(growable: false);

    return NotificationPreferences(
      deviceId: deviceId,
      environment: environment,
      notificationsEnabled: readBool('notificationsEnabled'),
      legendAttacks: readBool('legendAttacksEnabled'),
      legendDefenses: readBool('legendDefensesEnabled'),
      warAttacks: readBool('warAttacksEnabled'),
      warState: readBool('warStateEnabled'),
      warReminders: readBool('warRemindersEnabled'),
      events: readBool('eventsEnabled'),
      announcements: readBool('announcementsEnabled'),
      monthlySupport: readBool('monthlySupportEnabled'),
      reminderTimings: minutes,
      accounts: parsedAccounts,
    );
  }

  Map<String, dynamic> toPutJson({
    required String deviceId,
    required String environment,
  }) {
    return {
      'deviceId': deviceId,
      'environment': environment,
      'notificationsEnabled': notificationsEnabled,
      'legendAttacksEnabled': legendAttacks,
      'legendDefensesEnabled': legendDefenses,
      'warAttacksEnabled': warAttacks,
      'warStateEnabled': warState,
      'warRemindersEnabled': warReminders,
      'eventsEnabled': events,
      'announcementsEnabled': announcements,
      'monthlySupportEnabled': monthlySupport,
      'reminderTimings': reminderTimings,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      ...toPutJson(deviceId: deviceId, environment: environment),
      'accounts': accounts
          .map(
            (account) => {
              'playerTag': account.playerTag,
              'source': account.source.name,
              'active': account.active,
            },
          )
          .toList(growable: false),
    };
  }

  bool enabled(NotificationCategory category) => switch (category) {
    NotificationCategory.legendAttacks => legendAttacks,
    NotificationCategory.legendDefenses => legendDefenses,
    NotificationCategory.warAttacks => warAttacks,
    NotificationCategory.warState => warState,
    NotificationCategory.warReminders => warReminders,
    NotificationCategory.events => events,
    NotificationCategory.announcements => announcements,
    NotificationCategory.monthlySupport => monthlySupport,
  };

  NotificationPreferences withCategory(
    NotificationCategory category,
    bool enabled,
  ) => switch (category) {
    NotificationCategory.legendAttacks => copyWith(legendAttacks: enabled),
    NotificationCategory.legendDefenses => copyWith(legendDefenses: enabled),
    NotificationCategory.warAttacks => copyWith(warAttacks: enabled),
    NotificationCategory.warState => copyWith(warState: enabled),
    NotificationCategory.warReminders => copyWith(warReminders: enabled),
    NotificationCategory.events => copyWith(events: enabled),
    NotificationCategory.announcements => copyWith(announcements: enabled),
    NotificationCategory.monthlySupport => copyWith(monthlySupport: enabled),
  };

  NotificationPreferences copyWith({
    String? deviceId,
    String? environment,
    bool? notificationsEnabled,
    bool? legendAttacks,
    bool? legendDefenses,
    bool? warAttacks,
    bool? warState,
    bool? warReminders,
    bool? events,
    bool? announcements,
    bool? monthlySupport,
    List<int>? reminderTimings,
    List<NotificationAccount>? accounts,
  }) {
    return NotificationPreferences(
      deviceId: deviceId ?? this.deviceId,
      environment: environment ?? this.environment,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      legendAttacks: legendAttacks ?? this.legendAttacks,
      legendDefenses: legendDefenses ?? this.legendDefenses,
      warAttacks: warAttacks ?? this.warAttacks,
      warState: warState ?? this.warState,
      warReminders: warReminders ?? this.warReminders,
      events: events ?? this.events,
      announcements: announcements ?? this.announcements,
      monthlySupport: monthlySupport ?? this.monthlySupport,
      reminderTimings: reminderTimings ?? this.reminderTimings,
      accounts: accounts ?? this.accounts,
    );
  }
}
