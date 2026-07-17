import 'dart:async';
import 'dart:convert';

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/notification_debug_service.dart';
import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_hero.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/features/pages/data/announcement_presentation_service.dart';

class _NotifGroup {
  static const leagueBattles = 'League battles';
  static const warAttacks = 'War attacks';
  static const warState = 'War state';
  static const warReminders = 'War reminders';
  static const events = 'Events';
  static const announcements =
      AnnouncementPresentationService.notificationPreferenceLabel;
  static const upgradeFinishes = 'Upgrade finishes';
  static const monthlySupport = 'Monthly support';
  static const clanGames = 'Clan Games';
  static const cwl = 'CWL';
  static const raidWeekend = 'Raid Weekend';
  static const warStarts = 'War starts';
  static const warEnds = 'War ends';
  static const seasonStarts = 'Season starts';
  static const specialEvents = 'Special events';
}

class _Timing {
  static const oneHourLeft = '1 hour left';
  static const thirtyMin = '30 minutes left';
  static const fifteenMin = '15 minutes left';
}

String _normalizeTag(String value) => value.replaceAll('#', '').toUpperCase();

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final Set<String> _enabledTypes = {
    _NotifGroup.leagueBattles,
    _NotifGroup.warAttacks,
    _NotifGroup.warState,
    _NotifGroup.warReminders,
    _NotifGroup.events,
    _NotifGroup.announcements,
    _NotifGroup.upgradeFinishes,
    _NotifGroup.monthlySupport,
  };
  final Set<String> _warAttackModes = {'defenses'};
  final Set<String> _eventTypes = {
    _NotifGroup.clanGames,
    _NotifGroup.cwl,
    _NotifGroup.raidWeekend,
  };
  final Set<String> _warReminderTimings = {'1h', '30m', '15m'};
  final Set<String> _warStateTypes = {
    _NotifGroup.warStarts,
    _NotifGroup.warEnds,
  };
  final Set<String> _expandedNotificationOptions = {};
  final Set<String> _selectedAccounts = {};
  final Set<int> _selectedTownHalls = {};
  final Set<String> _selectedClanTags = {};
  final Set<String> _limitedAccountTypes = {};
  final Map<String, Set<String>> _accountsByType = {};
  var _notificationsEnabled = true;
  var _accountScope = _NotificationAccountScope.all;
  var _selectedSampleId = 'leagueDefense';
  var _isSending = false;
  var _isConfiguringPush = false;
  PushNotificationSetupResult? _pushSetupResult;
  String? _pushTokenPreview;

  static const _kPrefsPrefix = 'notif_settings_';

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
    unawaited(_loadPushState());
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final enabledList = prefs.getStringList('${_kPrefsPrefix}enabled_types');
      _notificationsEnabled =
          prefs.getBool('${_kPrefsPrefix}notifications_enabled') ?? true;
      if (enabledList != null) {
        _enabledTypes
          ..clear()
          ..addAll(enabledList);
      }
      final attackModes = prefs.getStringList(
        '${_kPrefsPrefix}war_attack_modes',
      );
      if (attackModes != null) {
        _warAttackModes
          ..clear()
          ..addAll(attackModes);
      }
      final eventTypesList = prefs.getStringList('${_kPrefsPrefix}event_types');
      if (eventTypesList != null) {
        _eventTypes
          ..clear()
          ..addAll(eventTypesList);
      }
      final reminderTimings = prefs.getStringList(
        '${_kPrefsPrefix}reminder_timings',
      );
      if (reminderTimings != null) {
        _warReminderTimings
          ..clear()
          ..addAll(reminderTimings);
      }
      final warStateTypes = prefs.getStringList(
        '${_kPrefsPrefix}war_state_types',
      );
      if (warStateTypes != null) {
        _warStateTypes
          ..clear()
          ..addAll(warStateTypes);
      }
      final scopeIndex = prefs.getInt('${_kPrefsPrefix}account_scope');
      if (scopeIndex != null &&
          scopeIndex < _NotificationAccountScope.values.length) {
        _accountScope = _NotificationAccountScope.values[scopeIndex];
      }
      final accounts = prefs.getStringList('${_kPrefsPrefix}selected_accounts');
      if (accounts != null) {
        _selectedAccounts
          ..clear()
          ..addAll(accounts);
      }
      final townHalls = prefs.getStringList(
        '${_kPrefsPrefix}selected_town_halls',
      );
      if (townHalls != null) {
        _selectedTownHalls
          ..clear()
          ..addAll(townHalls.map(int.tryParse).whereType<int>());
      }
      final clans = prefs.getStringList('${_kPrefsPrefix}selected_clan_tags');
      if (clans != null) {
        _selectedClanTags
          ..clear()
          ..addAll(clans.map(_normalizeTag).where((tag) => tag.isNotEmpty));
      }
      final limitedTypes = prefs.getStringList(
        '${_kPrefsPrefix}limited_account_types',
      );
      if (limitedTypes != null) {
        _limitedAccountTypes
          ..clear()
          ..addAll(limitedTypes);
      }
      final accountsByType = prefs.getString(
        '${_kPrefsPrefix}accounts_by_type',
      );
      if (accountsByType != null) {
        final decoded = jsonDecode(accountsByType);
        if (decoded is Map<String, dynamic>) {
          _accountsByType
            ..clear()
            ..addEntries(
              decoded.entries.map(
                (entry) => MapEntry(
                  entry.key,
                  (entry.value as List<dynamic>)
                      .map((value) => value.toString())
                      .toSet(),
                ),
              ),
            );
        }
      }
    });
    unawaited(_syncPreferences());
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(
        '${_kPrefsPrefix}notifications_enabled',
        _notificationsEnabled,
      ),
      prefs.setStringList(
        '${_kPrefsPrefix}enabled_types',
        _enabledTypes.toList(),
      ),
      prefs.setStringList(
        '${_kPrefsPrefix}war_attack_modes',
        _warAttackModes.toList(),
      ),
      prefs.setStringList('${_kPrefsPrefix}event_types', _eventTypes.toList()),
      prefs.setStringList(
        '${_kPrefsPrefix}reminder_timings',
        _warReminderTimings.toList(),
      ),
      prefs.setStringList(
        '${_kPrefsPrefix}war_state_types',
        _warStateTypes.toList(),
      ),
      prefs.setInt('${_kPrefsPrefix}account_scope', _accountScope.index),
      prefs.setStringList(
        '${_kPrefsPrefix}selected_accounts',
        _selectedAccounts.toList(),
      ),
      prefs.setStringList(
        '${_kPrefsPrefix}selected_town_halls',
        _selectedTownHalls.map((townHall) => townHall.toString()).toList(),
      ),
      prefs.setStringList(
        '${_kPrefsPrefix}selected_clan_tags',
        _selectedClanTags.toList(),
      ),
      prefs.setStringList(
        '${_kPrefsPrefix}limited_account_types',
        _limitedAccountTypes.toList(),
      ),
      prefs.setString(
        '${_kPrefsPrefix}accounts_by_type',
        jsonEncode(
          _accountsByType.map(
            (type, accounts) => MapEntry(type, accounts.toList()),
          ),
        ),
      ),
    ]);
    unawaited(_syncPreferences());
  }

  Future<void> _syncPreferences() async {
    final subscriptions = <Map<String, dynamic>>[];
    for (final type in _enabledTypes) {
      if (type == _NotifGroup.events) {
        for (final event in _eventTypes) {
          _appendSubscriptions(subscriptions, event, const {});
        }
        continue;
      }
      if (type == _NotifGroup.warState) {
        for (final state in _warStateTypes) {
          _appendSubscriptions(subscriptions, state, const {});
        }
        continue;
      }
      final settings = <String, dynamic>{
        if (type == _NotifGroup.warAttacks) 'modes': _warAttackModes.toList(),
        if (type == _NotifGroup.warReminders)
          'timings': _warReminderTimings.toList(),
      };
      _appendSubscriptions(subscriptions, type, settings);
    }
    await PushNotificationService.instance.savePreferences({
      'enabled': _notificationsEnabled,
      'enabled_types': _enabledTypes.map(_notificationTypeKey).toList(),
      'war_attack_modes': _warAttackModes.toList(),
      'event_types': _eventTypes.map(_notificationTypeKey).toList(),
      'reminder_timings': _warReminderTimings.toList(),
      'account_scope': _accountScope == _NotificationAccountScope.selected
          ? 'selected'
          : 'all',
      'selected_accounts': _selectedAccounts.toList(),
      'selected_town_halls': _selectedTownHalls.toList(),
      'selected_clan_tags': _selectedClanTags.toList(),
      'subscriptions': subscriptions,
    });
  }

  void _appendSubscriptions(
    List<Map<String, dynamic>> subscriptions,
    String type,
    Map<String, dynamic> settings,
  ) {
    if (_limitedAccountTypes.contains(type)) {
      for (final playerTag in _accountsByType[type] ?? const <String>{}) {
        subscriptions.add({
          'type': _notificationTypeKey(type),
          'player_tag': playerTag,
          'enabled': true,
          'settings': settings,
        });
      }
    } else {
      subscriptions.add({
        'type': _notificationTypeKey(type),
        'enabled': true,
        'settings': settings,
      });
    }
  }

  String _notificationTypeKey(String type) => switch (type) {
    _NotifGroup.leagueBattles => 'league_battles',
    _NotifGroup.warAttacks => 'war_attacks',
    _NotifGroup.warState => 'war_state',
    _NotifGroup.warReminders => 'war_reminders',
    _NotifGroup.events => 'events',
    _NotifGroup.announcements => 'announcements',
    _NotifGroup.upgradeFinishes => 'upgrade_finishes',
    _NotifGroup.monthlySupport => 'monthly_support',
    _NotifGroup.clanGames => 'clan_games',
    _NotifGroup.cwl => 'cwl',
    _NotifGroup.raidWeekend => 'raid_weekend',
    _NotifGroup.warStarts => 'war_started',
    _NotifGroup.warEnds => 'war_ended',
    _NotifGroup.seasonStarts => 'season_started',
    _NotifGroup.specialEvents => 'special_events',
    _ => type.toLowerCase().replaceAll(' ', '_'),
  };

  Future<void> _loadPushState() async {
    final result = await PushNotificationService.instance.initialize();
    final tokenPreview = await PushNotificationService.instance.tokenPreview();
    if (!mounted) return;
    setState(() {
      _pushSetupResult = result;
      _pushTokenPreview = tokenPreview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final notificationContext = _NotificationContext.fromService(
      cocService,
      profiles: playerService.profiles,
      selectedAccounts: _selectedAccounts,
      selectedTownHalls: _selectedTownHalls,
      selectedClanTags: _selectedClanTags,
    );
    final samples = _samplesForContext(notificationContext);
    final selectedSample = samples.firstWhere(
      (sample) => sample.id == _selectedSampleId,
      orElse: () => samples.first,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.settingsNotificationsTitle ??
              'Notifications',
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _Section(
            title: AppLocalizations.of(context)!.notifDevicePushSetup,
            children: [
              _PushSetupCard(
                result: _pushSetupResult,
                tokenPreview: _pushTokenPreview,
                isConfiguring: _isConfiguringPush,
                notificationsEnabled: _notificationsEnabled,
                onNotificationsChanged: _setNotificationsEnabled,
                onConfigure: _configurePushNotifications,
              ),
            ],
          ),
          _SettingsAvailability(
            enabled: _notificationsEnabled,
            child: _Section(
              title: AppLocalizations.of(context)!.notifChooseAlerts,
              children: [
                _NotificationToggleRow(
                  icon: LucideIcons.shield,
                  title: _NotifGroup.leagueBattles,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifLeagueDefenseDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.leagueBattles),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.leagueBattles, value),
                  audience: _audienceSummary(
                    _NotifGroup.leagueBattles,
                    playerService,
                  ),
                  onAudienceTap: () =>
                      _showAudienceSheet(_NotifGroup.leagueBattles),
                ),
                _NotificationDisclosureRow(
                  icon: LucideIcons.swords,
                  title: _NotifGroup.warAttacks,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifWarAttackOptionsDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.warAttacks),
                  expanded: _expandedNotificationOptions.contains(
                    _NotifGroup.warAttacks,
                  ),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.warAttacks, value),
                  onExpandChanged: (expanded) =>
                      _toggleExpanded(_NotifGroup.warAttacks, expanded),
                  options: _WarAttackModePicker(
                    selectedModes: _warAttackModes,
                    onChanged: (mode, selected) {
                      setState(() {
                        if (selected) {
                          _warAttackModes.add(mode);
                        } else {
                          _warAttackModes.remove(mode);
                        }
                      });
                      unawaited(_savePreferences());
                    },
                  ),
                  audience: _audienceSummary(
                    _NotifGroup.warAttacks,
                    playerService,
                  ),
                  onAudienceTap: () =>
                      _showAudienceSheet(_NotifGroup.warAttacks),
                ),
                _NotificationDisclosureRow(
                  icon: LucideIcons.flag,
                  title: _NotifGroup.warState,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifWarAlertsDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.warState),
                  expanded: _expandedNotificationOptions.contains(
                    _NotifGroup.warState,
                  ),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.warState, value),
                  onExpandChanged: (expanded) =>
                      _toggleExpanded(_NotifGroup.warState, expanded),
                  options: _WarStatePicker(
                    selectedStates: _warStateTypes,
                    onChanged: (state, selected) {
                      setState(() {
                        selected
                            ? _warStateTypes.add(state)
                            : _warStateTypes.remove(state);
                      });
                      unawaited(_savePreferences());
                    },
                    audienceFor: (state) =>
                        _audienceSummary(state, playerService),
                    onAudienceTap: _showAudienceSheet,
                  ),
                ),
                _NotificationDisclosureRow(
                  icon: LucideIcons.alarmClock,
                  title: _NotifGroup.warReminders,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifWarRemindersDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.warReminders),
                  expanded: _expandedNotificationOptions.contains(
                    _NotifGroup.warReminders,
                  ),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.warReminders, value),
                  onExpandChanged: (expanded) =>
                      _toggleExpanded(_NotifGroup.warReminders, expanded),
                  options: _WarReminderTimingPicker(
                    selectedTimings: _warReminderTimings,
                    onChanged: (timings) {
                      setState(() {
                        _warReminderTimings
                          ..clear()
                          ..addAll(timings);
                      });
                      unawaited(_savePreferences());
                    },
                  ),
                  audience: _audienceSummary(
                    _NotifGroup.warReminders,
                    playerService,
                  ),
                  onAudienceTap: () =>
                      _showAudienceSheet(_NotifGroup.warReminders),
                ),
                _NotificationDisclosureRow(
                  icon: LucideIcons.calendarDays,
                  title: _NotifGroup.events,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifEventsDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.events),
                  expanded: _expandedNotificationOptions.contains(
                    _NotifGroup.events,
                  ),
                  onChanged: (value) => _toggleType(_NotifGroup.events, value),
                  onExpandChanged: (expanded) =>
                      _toggleExpanded(_NotifGroup.events, expanded),
                  options: _EventTypePicker(
                    selectedEvents: _eventTypes,
                    onChanged: (event, selected) {
                      setState(() {
                        if (selected) {
                          _eventTypes.add(event);
                        } else {
                          _eventTypes.remove(event);
                        }
                      });
                      unawaited(_savePreferences());
                    },
                    audienceFor: (event) =>
                        _audienceSummary(event, playerService),
                    onAudienceTap: _showAudienceSheet,
                  ),
                ),
                _NotificationToggleRow(
                  icon: LucideIcons.megaphone,
                  title: _NotifGroup.announcements,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifAnnouncementsDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.announcements),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.announcements, value),
                ),
                _NotificationToggleRow(
                  icon: LucideIcons.hammer,
                  title: _NotifGroup.upgradeFinishes,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifUpgradeFinishesDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.upgradeFinishes),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.upgradeFinishes, value),
                  audience: _audienceSummary(
                    _NotifGroup.upgradeFinishes,
                    playerService,
                  ),
                  onAudienceTap: () =>
                      _showAudienceSheet(_NotifGroup.upgradeFinishes),
                ),
                _NotificationToggleRow(
                  icon: LucideIcons.heartHandshake,
                  title: _NotifGroup.monthlySupport,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.notifSupportReminderDescription,
                  enabled: _enabledTypes.contains(_NotifGroup.monthlySupport),
                  onChanged: (value) =>
                      _toggleType(_NotifGroup.monthlySupport, value),
                ),
              ],
            ),
          ),
          if (kDebugMode && NotificationDebugService.isSupportedPlatform)
            _Section(
              title: AppLocalizations.of(context)!.notifTestNotification,
              children: [
                _SamplePicker(
                  samples: samples,
                  selected: selectedSample,
                  onChanged: (sample) {
                    setState(() {
                      _selectedSampleId = sample.id;
                    });
                  },
                ),
                _PreviewCard(
                  sample: selectedSample,
                  accountName: notificationContext.playerName,
                  clanName: notificationContext.clanName,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: FilledButton.icon(
                    onPressed: _isSending ? null : _sendTestNotification,
                    icon: _isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.bellRing),
                    label: Text(
                      AppLocalizations.of(context)!.notifSendTestNotification,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _audienceSummary(String type, PlayerService playerService) {
    if (!_limitedAccountTypes.contains(type)) return 'All linked accounts';
    final selected = _accountsByType[type] ?? const <String>{};
    if (selected.isEmpty) return 'Choose accounts';
    final namesByTag = {
      for (final profile in playerService.profiles)
        _normalizeTag(profile.tag): profile.name,
    };
    final firstName =
        namesByTag[_normalizeTag(selected.first)] ?? selected.first;
    final remaining = selected.length - 1;
    return remaining == 0 ? firstName : '$firstName + $remaining';
  }

  Future<void> _showAudienceSheet(String type) async {
    final cocService = context.read<CocAccountService>();
    final playerService = context.read<PlayerService>();
    final profilesByTag = {
      for (final profile in playerService.profiles)
        _normalizeTag(profile.tag): profile,
    };
    final accounts = cocService.cocAccounts.map((account) {
      final tag = account['player_tag']?.toString() ?? '';
      final profile = profilesByTag[_normalizeTag(tag)];
      final fallbackName = account['name']?.toString();
      final name = profile?.name != null && profile!.name != 'Unknown'
          ? profile.name
          : fallbackName?.isNotEmpty == true
          ? fallbackName!
          : tag;
      final townHall =
          profile?.townHallLevel ??
          int.tryParse(account['townHallLevel']?.toString() ?? '') ??
          1;
      return _AccountOption(
        tag: tag,
        name: name,
        townHallLevel: townHall,
        clanName: profile?.clanOverview.name ?? '',
      );
    }).toList();

    var limited = _limitedAccountTypes.contains(type);
    final selected = {...?_accountsByType[type]};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: 0.82,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose which accounts can receive this alert.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('All accounts')),
                      ButtonSegment(value: true, label: Text('Selected')),
                    ],
                    selected: {limited},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => setSheetState(() {
                      limited = selection.first;
                      if (limited && selected.isEmpty) {
                        selected.addAll(accounts.map((account) => account.tag));
                      }
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: limited
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return _AccountSheetTile(
                              account: account,
                              selected: selected.contains(account.tag),
                              onChanged: (value) => setSheetState(() {
                                value
                                    ? selected.add(account.tag)
                                    : selected.remove(account.tag);
                              }),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'New linked accounts will be included automatically.',
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    onPressed: limited && selected.isEmpty
                        ? null
                        : () {
                            setState(() {
                              if (limited) {
                                _limitedAccountTypes.add(type);
                                _accountsByType[type] = selected;
                              } else {
                                _limitedAccountTypes.remove(type);
                              }
                            });
                            unawaited(_savePreferences());
                            Navigator.of(sheetContext).pop();
                          },
                    child: Text(
                      limited
                          ? 'Use ${selected.length} account${selected.length == 1 ? '' : 's'}'
                          : 'Use all accounts',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleType(String type, bool value) {
    setState(() {
      if (value) {
        _enabledTypes.add(type);
      } else {
        _enabledTypes.remove(type);
        _expandedNotificationOptions.remove(type);
      }
    });
    unawaited(_savePreferences());
    if (value) {
      unawaited(_ensurePushConfiguredForEnabledAlert());
    }
  }

  void _setNotificationsEnabled(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    unawaited(_savePreferences());
    if (value) {
      unawaited(_ensurePushConfiguredForEnabledAlert());
    } else {
      unawaited(
        PushNotificationService.instance.unregisterCurrentDeviceToken(),
      );
    }
  }

  Future<void> _ensurePushConfiguredForEnabledAlert() async {
    if (_pushSetupResult?.canReceivePush == true || _isConfiguringPush) return;
    await _configurePushNotifications();
  }

  void _toggleExpanded(String type, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedNotificationOptions.add(type);
      } else {
        _expandedNotificationOptions.remove(type);
      }
    });
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isSending = true;
    });

    try {
      final cocService = context.read<CocAccountService>();
      final samples = _samplesForContext(
        _NotificationContext.fromService(
          cocService,
          profiles: context.read<PlayerService>().profiles,
          selectedAccounts: _selectedAccounts,
          selectedTownHalls: _selectedTownHalls,
          selectedClanTags: _selectedClanTags,
        ),
      );
      final sample = samples.firstWhere(
        (sample) => sample.id == _selectedSampleId,
        orElse: () => samples.first,
      );
      final result = await NotificationDebugService().showSample(sample);
      if (!mounted) return;
      final title = result['title']?.toString() ?? sample.title;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.notifScheduledMessage(title),
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _configurePushNotifications() async {
    setState(() {
      _isConfiguringPush = true;
    });

    try {
      final result = await PushNotificationService.instance
          .requestPermissionAndRegister();
      final tokenPreview = await PushNotificationService.instance
          .tokenPreview();
      if (!mounted) return;
      setState(() {
        _pushSetupResult = result;
        _pushTokenPreview = tokenPreview;
      });

      final message = switch (result.state) {
        PushNotificationSetupState.ready =>
          'Push notifications are ready on this device.',
        PushNotificationSetupState.permissionRequired =>
          'Allow notifications to receive ClashKing alerts.',
        PushNotificationSetupState.permissionDenied =>
          'Notification permission was denied.',
        PushNotificationSetupState.notConfigured =>
          'Firebase is not configured yet for this build.',
        PushNotificationSetupState.tokenUnavailable =>
          'FCM token is not available yet. Try again in a moment.',
        PushNotificationSetupState.unsupported =>
          'Push notifications are not supported on this platform.',
        PushNotificationSetupState.initializing =>
          'Configuring push notifications…',
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? message)));
    } finally {
      if (mounted) {
        setState(() {
          _isConfiguringPush = false;
        });
      }
    }
  }

  List<NotificationSample> _samplesForContext(_NotificationContext context) {
    final player = context.playerName;
    final clan = context.clanName;
    final opponentClan = context.opponentClanName;
    final league = context.leagueName;
    final th = context.townHallLevel;
    final townHallImage = context.townHallImageUrl;
    final upgradeName = context.upgradeName;
    final upgradeLevel = context.upgradeLevel;
    final upgradeImage = context.upgradeImageUrl;

    final loc = AppLocalizations.of(this.context)!;
    final battlesGroup = loc.notifGroupBattles;
    final remindersGroup = loc.notifGroupReminders;
    final oneHourLeft = loc.notifOneHourLeft;
    final thirtyMin = loc.notifThirtyMinutesLeft;
    final fifteenMin = loc.notifFifteenMinutesLeft;

    return [
      NotificationSample(
        id: 'leagueDefense',
        label: loc.notifLeagueDefense,
        group: battlesGroup,
        title: loc.notifLeagueDefenseResult,
        body: loc.notifLeagueAttackBody(player, 90, 2, league),
        assetUrl: context.leagueIconUrl,
      ),
      NotificationSample(
        id: 'leagueTripled',
        label: loc.notifLeagueTriple,
        group: battlesGroup,
        title: loc.notifLeagueDefenseResult,
        body: loc.notifLeagueAttackBody(player, 100, 3, league),
        assetUrl: context.leagueIconUrl,
      ),
      NotificationSample(
        id: 'warDefense',
        label: loc.notifWarDefense,
        group: battlesGroup,
        title: loc.notifWarAttackOnTh(th),
        body: loc.notifWarDefenseBody(opponentClan, player, 78, 2, clan),
        assetUrl: townHallImage,
      ),
      NotificationSample(
        id: 'warAllAttacks',
        label: loc.notifWarFeed5v5,
        group: battlesGroup,
        title: loc.notifWarAttackResult,
        body: loc.notifWarAttackResultBody(clan, th),
        assetUrl: townHallImage,
      ),
      NotificationSample(
        id: 'warMatched',
        label: loc.notifWarMatched,
        group: _NotifGroup.warState,
        title: loc.notifWarMatched,
        body: loc.notifWarMatchedBody(clan),
        assetUrl: context.clanBadgeUrl,
      ),
      NotificationSample(
        id: 'warStarted',
        label: loc.notifWarStarted,
        group: _NotifGroup.warState,
        title: loc.notifBattleDayStarted,
        body: loc.notifWarStartedBody(clan),
        assetUrl: ImageAssets.sword,
      ),
      NotificationSample(
        id: 'warEnded',
        label: loc.notifWarEnded,
        group: _NotifGroup.warState,
        title: loc.notifWarEnded,
        body: loc.notifWarEndedBody(clan),
        assetUrl: ImageAssets.warClan,
      ),
      NotificationSample(
        id: 'warReminder60',
        label: loc.notifWarReminder1h,
        group: remindersGroup,
        title: oneHourLeft,
        body: loc.notifRemainingWarAttacksBody(player, oneHourLeft),
        assetUrl: ImageAssets.iconClock,
      ),
      NotificationSample(
        id: 'warReminder30',
        label: loc.notifWarReminder30m,
        group: remindersGroup,
        title: thirtyMin,
        body: loc.notifRemainingWarAttacksBody(player, thirtyMin),
        assetUrl: ImageAssets.iconClock,
      ),
      NotificationSample(
        id: 'warReminder15',
        label: loc.notifWarReminder15m,
        group: remindersGroup,
        title: fifteenMin,
        body: loc.notifRemainingWarAttacksBody(player, fifteenMin),
        assetUrl: ImageAssets.iconClock,
      ),
      NotificationSample(
        id: 'clanGamesStarted',
        label: _NotifGroup.clanGames,
        group: _NotifGroup.events,
        title: loc.notifStarted(_NotifGroup.clanGames),
        body: loc.notifClanGamesPointsBody(clan, _NotifGroup.clanGames),
        assetUrl: ImageAssets.clanGamesMedals,
      ),
      NotificationSample(
        id: 'cwlStarted',
        label: loc.notifStarted(_NotifGroup.cwl),
        group: _NotifGroup.events,
        title: loc.notifStarted(_NotifGroup.cwl),
        body: loc.notifCwlPreparationBody(clan),
        assetUrl: ImageAssets.cwlSwordsNoBorder,
      ),
      NotificationSample(
        id: 'raidWeekendStarted',
        label: _NotifGroup.raidWeekend,
        group: _NotifGroup.events,
        title: loc.notifStarted(_NotifGroup.raidWeekend),
        body: loc.notifRaidWeekendBody(clan),
        assetUrl: ImageAssets.raidAttacks,
      ),
      NotificationSample(
        id: 'seasonStarted',
        label: loc.notifSeasonStart,
        group: _NotifGroup.events,
        title: loc.notifNewSeasonStarted,
        body: loc.notifSeasonStartedBody(league, player),
        assetUrl: context.leagueIconUrl,
      ),
      NotificationSample(
        id: 'specialEventStarted',
        label: loc.notifSpecialEvent,
        group: _NotifGroup.events,
        title: loc.notifNewEventLive,
        body: loc.notifNewClashEventBody,
        assetUrl: ImageAssets.darkModeLogo,
      ),
      NotificationSample(
        id: 'monthlySupport',
        label: _NotifGroup.monthlySupport,
        group: loc.notifGroupSupport,
        title: loc.notifSupportClashKing,
        body: loc.notifMonthlySupportBody,
        assetUrl: ImageAssets.darkModeLogo,
      ),
      NotificationSample(
        id: 'upgradeComplete',
        label: loc.notifUpgradeFinished,
        group: loc.notifGroupProgress,
        title: loc.notifUpgradeReadyTitle(upgradeName),
        body: loc.notifUpgradeCompleteBody(upgradeLevel, player),
        assetUrl: upgradeImage,
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      Divider(
                        height: 1,
                        indent: 0,
                        endIndent: 0,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.34,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsAvailability extends StatelessWidget {
  const _SettingsAvailability({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: enabled,
      child: IgnorePointer(
        ignoring: !enabled,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.46,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: child,
        ),
      ),
    );
  }
}

// TODO: Remove after the per-alert audience rollout is validated.
// ignore: unused_element
class _AudienceExplanation extends StatelessWidget {
  const _AudienceExplanation({
    required this.accountScope,
    required this.selectedAccountCount,
    required this.hasAudienceFilters,
  });

  final _NotificationAccountScope accountScope;
  final int selectedAccountCount;
  final bool hasAudienceFilters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEmptySelection =
        accountScope == _NotificationAccountScope.selected &&
        selectedAccountCount == 0;
    final message = hasEmptySelection
        ? 'Choose at least one account to receive account alerts.'
        : hasAudienceFilters
        ? 'Alerts must match the account selection and the filters below.'
        : 'Choose all linked accounts or only specific accounts. Filters below are optional.';
    final accent = hasEmptySelection ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasEmptySelection
                    ? LucideIcons.triangleAlert
                    : LucideIcons.info,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PushSetupCard extends StatelessWidget {
  const _PushSetupCard({
    required this.result,
    required this.tokenPreview,
    required this.isConfiguring,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onConfigure,
  });

  final PushNotificationSetupResult? result;
  final String? tokenPreview;
  final bool isConfiguring;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final setupState = result?.state;
    final isReady = result?.canReceivePush == true;
    final title = !notificationsEnabled
        ? 'Notifications paused'
        : switch (setupState) {
            PushNotificationSetupState.ready => 'Push enabled',
            PushNotificationSetupState.permissionRequired =>
              'Permission needed',
            PushNotificationSetupState.permissionDenied => 'Permission denied',
            PushNotificationSetupState.notConfigured =>
              'Firebase config missing',
            PushNotificationSetupState.tokenUnavailable => 'Token unavailable',
            PushNotificationSetupState.unsupported => 'Unsupported platform',
            PushNotificationSetupState.initializing => 'Checking push setup',
            null => 'Checking push setup',
          };
    final subtitle = !notificationsEnabled
        ? 'Your choices are kept on this device, but alerts are paused.'
        : switch (setupState) {
            PushNotificationSetupState.ready =>
              tokenPreview == null
                  ? 'This device has an FCM token and can receive push alerts.'
                  : 'Token: $tokenPreview',
            PushNotificationSetupState.permissionRequired =>
              'Allow notifications so ClashKing can show war, CWL, and account alerts on this device.',
            PushNotificationSetupState.permissionDenied =>
              'Enable notifications in system settings to receive ClashKing alerts.',
            PushNotificationSetupState.notConfigured =>
              'Add Firebase app config files to enable real push delivery.',
            PushNotificationSetupState.tokenUnavailable =>
              'Firebase is initialized, but no token has been issued yet.',
            PushNotificationSetupState.unsupported =>
              'Push notifications are only available on Android and iOS.',
            PushNotificationSetupState.initializing =>
              'Checking Firebase and notification permissions…',
            null => 'Checking Firebase and notification permissions…',
          };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Receive notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isReady ? Colors.green : colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isReady ? LucideIcons.badgeCheck : LucideIcons.bell,
                    color: isReady ? Colors.green : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result?.message ?? subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (notificationsEnabled)
                        FilledButton.icon(
                          onPressed: isConfiguring ? null : onConfigure,
                          icon: isConfiguring
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.radioTower, size: 18),
                          label: Text(
                            isReady
                                ? 'Refresh registration'
                                : 'Allow notifications',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceButton extends StatelessWidget {
  const _AudienceButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.users,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    this.audience,
    this.onAudienceTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String? audience;
  final VoidCallback? onAudienceTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Icon(icon, size: 22, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (audience != null) ...[
                  const SizedBox(height: 5),
                  _AudienceButton(
                    label: audience!,
                    onPressed: enabled ? onAudienceTap : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NotificationDisclosureRow extends StatelessWidget {
  const _NotificationDisclosureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.expanded,
    required this.onChanged,
    required this.onExpandChanged,
    required this.options,
    this.audience,
    this.onAudienceTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final ValueChanged<bool> onExpandChanged;
  final Widget options;
  final String? audience;
  final VoidCallback? onAudienceTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showOptions = enabled && expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: enabled ? () => onExpandChanged(!expanded) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Icon(icon, size: 22, color: colorScheme.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (audience != null) ...[
                        const SizedBox(height: 5),
                        _AudienceButton(
                          label: audience!,
                          onPressed: enabled ? onAudienceTap : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: showOptions ? 0.5 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  ),
                ),
                const SizedBox(width: 6),
                Switch.adaptive(value: enabled, onChanged: onChanged),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            alignment: Alignment.topLeft,
            curve: Curves.easeOutCubic,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: showOptions
                ? options
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ),
      ],
    );
  }
}

class _WarAttackModePicker extends StatelessWidget {
  const _WarAttackModePicker({
    required this.selectedModes,
    required this.onChanged,
  });

  final Set<String> selectedModes;
  final void Function(String mode, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return _InlineOptions(
      children: [
        _IconSwitchTile(
          icon: LucideIcons.shieldCheck,
          title: AppLocalizations.of(context)!.notifDefensesAgainstYourBase,
          subtitle: AppLocalizations.of(
            context,
          )!.notifDefensesAgainstYourBaseDescription,
          selected: selectedModes.contains('defenses'),
          onChanged: (value) => onChanged('defenses', value),
        ),
        _IconSwitchTile(
          icon: LucideIcons.swords,
          title: AppLocalizations.of(context)!.notifAllAttacks,
          subtitle: AppLocalizations.of(context)!.notifAllAttacksDescription,
          selected: selectedModes.contains('all5v5'),
          onChanged: (value) => onChanged('all5v5', value),
        ),
      ],
    );
  }
}

class _WarReminderTimingPicker extends StatelessWidget {
  const _WarReminderTimingPicker({
    required this.selectedTimings,
    required this.onChanged,
  });

  final Set<String> selectedTimings;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = selectedTimings.toList()
      ..sort((a, b) => _sortValue(b).compareTo(_sortValue(a)));

    return _InlineOptions(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sorted.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final timing in sorted)
                      InputChip(
                        avatar: const Icon(LucideIcons.clock, size: 16),
                        label: Text(_timingLabel(timing)),
                        onDeleted: () {
                          final next = {...selectedTimings}..remove(timing);
                          onChanged(next);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.tonalIcon(
                onPressed: selectedTimings.length >= 3
                    ? null
                    : () => _showTimingSheet(context),
                icon: Icon(
                  selectedTimings.length >= 3
                      ? LucideIcons.circleCheck
                      : LucideIcons.plus,
                ),
                label: Text(
                  selectedTimings.length >= 3
                      ? 'Maximum reminders added'
                      : 'Add reminder',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showTimingSheet(BuildContext context) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => _HourPickerSheet(
        selectedTimings: selectedTimings,
        timingLabel: _timingLabel,
      ),
    );
    if (selection == null) return;
    onChanged({...selectedTimings, selection});
  }

  static int _sortValue(String timing) {
    if (timing.endsWith('h')) {
      return int.tryParse(timing.replaceAll('h', '')) ?? 0;
    }
    return timing == '30m' ? 0 : -1;
  }

  static String _timingLabel(String timing) {
    if (timing.endsWith('h')) {
      final hours = int.tryParse(timing.replaceAll('h', '')) ?? 0;
      return hours == 1 ? _Timing.oneHourLeft : '$hours hours left';
    }
    return timing == '30m' ? _Timing.thirtyMin : _Timing.fifteenMin;
  }
}

class _HourPickerSheet extends StatefulWidget {
  const _HourPickerSheet({
    required this.selectedTimings,
    required this.timingLabel,
  });

  final Set<String> selectedTimings;
  final String Function(String) timingLabel;

  @override
  State<_HourPickerSheet> createState() => _HourPickerSheetState();
}

class _HourPickerSheetState extends State<_HourPickerSheet> {
  late final FixedExtentScrollController _ctrl;
  var _selectedHour = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hourValue = '${_selectedHour}h';
    final hourAlreadySelected = widget.selectedTimings.contains(hourValue);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          Text(
            'Add war reminder',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick an hour value, or use one of the short final reminders.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 156,
            child: CupertinoPicker(
              itemExtent: 38,
              scrollController: _ctrl,
              onSelectedItemChanged: (index) =>
                  setState(() => _selectedHour = index + 1),
              children: [
                for (var hour = 1; hour <= 47; hour++)
                  Center(
                    child: Text(
                      hour == 1 ? _Timing.oneHourLeft : '$hour hours left',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: hourAlreadySelected
                ? null
                : () => Navigator.of(context).pop(hourValue),
            child: Text(
              hourAlreadySelected
                  ? '${widget.timingLabel(hourValue)} already added'
                  : 'Add ${widget.timingLabel(hourValue)}',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.selectedTimings.contains('30m')
                      ? null
                      : () => Navigator.of(context).pop('30m'),
                  child: Text(AppLocalizations.of(context)!.notifThirtyMinutes),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.selectedTimings.contains('15m')
                      ? null
                      : () => Navigator.of(context).pop('15m'),
                  child: Text(
                    AppLocalizations.of(context)!.notifFifteenMinutes,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarStatePicker extends StatelessWidget {
  const _WarStatePicker({
    required this.selectedStates,
    required this.onChanged,
    required this.audienceFor,
    required this.onAudienceTap,
  });

  final Set<String> selectedStates;
  final void Function(String state, bool selected) onChanged;
  final String Function(String state) audienceFor;
  final ValueChanged<String> onAudienceTap;

  @override
  Widget build(BuildContext context) {
    return _InlineOptions(
      children: [
        _ImageSwitchTile(
          imageUrl: ImageAssets.sword,
          title: _NotifGroup.warStarts,
          selected: selectedStates.contains(_NotifGroup.warStarts),
          onChanged: (selected) => onChanged(_NotifGroup.warStarts, selected),
          audience: audienceFor(_NotifGroup.warStarts),
          onAudienceTap: () => onAudienceTap(_NotifGroup.warStarts),
        ),
        _ImageSwitchTile(
          imageUrl: ImageAssets.warClan,
          title: _NotifGroup.warEnds,
          selected: selectedStates.contains(_NotifGroup.warEnds),
          onChanged: (selected) => onChanged(_NotifGroup.warEnds, selected),
          audience: audienceFor(_NotifGroup.warEnds),
          onAudienceTap: () => onAudienceTap(_NotifGroup.warEnds),
        ),
      ],
    );
  }
}

class _EventTypePicker extends StatelessWidget {
  const _EventTypePicker({
    required this.selectedEvents,
    required this.onChanged,
    required this.audienceFor,
    required this.onAudienceTap,
  });

  final Set<String> selectedEvents;
  final void Function(String event, bool selected) onChanged;
  final String Function(String event) audienceFor;
  final ValueChanged<String> onAudienceTap;

  static const _events = [
    (_NotifGroup.clanGames, ImageAssets.clanGamesMedals),
    (_NotifGroup.cwl, ImageAssets.cwlSwordsNoBorder),
    (_NotifGroup.raidWeekend, ImageAssets.raidAttacks),
    (_NotifGroup.seasonStarts, ImageAssets.iconGoldPass),
    (_NotifGroup.specialEvents, ImageAssets.darkModeLogo),
  ];

  @override
  Widget build(BuildContext context) {
    return _InlineOptions(
      children: [
        for (final (event, imageUrl) in _events)
          _ImageSwitchTile(
            imageUrl: imageUrl,
            title: event,
            selected: selectedEvents.contains(event),
            onChanged: (selected) => onChanged(event, selected),
            audience: audienceFor(event),
            onAudienceTap: () => onAudienceTap(event),
          ),
      ],
    );
  }
}

class _InlineOptions extends StatelessWidget {
  const _InlineOptions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _IconSwitchTile extends StatelessWidget {
  const _IconSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsSwitchTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: title,
      subtitle: subtitle,
      selected: selected,
      onChanged: onChanged,
    );
  }
}

class _ImageSwitchTile extends StatelessWidget {
  const _ImageSwitchTile({
    required this.imageUrl,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.audience,
    this.onAudienceTap,
  });

  final String imageUrl;
  final String title;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final String? audience;
  final VoidCallback? onAudienceTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsSwitchTile(
      leading: SizedBox.square(
        dimension: 28,
        child: MobileWebImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => const Icon(LucideIcons.bell),
        ),
      ),
      title: title,
      selected: selected,
      onChanged: onChanged,
      audience: audience,
      onAudienceTap: onAudienceTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.leading,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.subtitle,
    this.audience,
    this.onAudienceTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final String? audience;
  final VoidCallback? onAudienceTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            SizedBox.square(dimension: 30, child: Center(child: leading)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (audience != null) ...[
                    const SizedBox(height: 4),
                    _AudienceButton(
                      label: audience!,
                      onPressed: selected ? onAudienceTap : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(value: selected, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

enum _NotificationAccountScope { all, selected }

// ignore: unused_element
class _PerAlertAccountPicker extends StatelessWidget {
  const _PerAlertAccountPicker({
    required this.enabledTypes,
    required this.limitedTypes,
    required this.accountsByType,
    required this.onScopeChanged,
    required this.onAccountChanged,
  });

  final Set<String> enabledTypes;
  final Set<String> limitedTypes;
  final Map<String, Set<String>> accountsByType;
  final void Function(String type, bool limited) onScopeChanged;
  final void Function(String type, String tag, bool selected) onAccountChanged;

  static const _accountAlerts = [
    _NotifGroup.leagueBattles,
    _NotifGroup.warAttacks,
    _NotifGroup.warState,
    _NotifGroup.warReminders,
    _NotifGroup.events,
    _NotifGroup.upgradeFinishes,
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _accountAlerts
        .where(enabledTypes.contains)
        .toList(growable: false);
    if (visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text('Enable an account alert to choose its accounts.'),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Text(
            'Choose accounts separately for every alert. Town Hall and clan follow each selected account automatically.',
          ),
        ),
        for (final type in visible)
          ExpansionTile(
            leading: const Icon(LucideIcons.userRoundCog),
            title: Text(type),
            subtitle: Text(
              limitedTypes.contains(type)
                  ? '${accountsByType[type]?.length ?? 0} selected'
                  : 'All linked accounts',
            ),
            children: [
              _ScopeSelector(
                value: limitedTypes.contains(type)
                    ? _NotificationAccountScope.selected
                    : _NotificationAccountScope.all,
                onChanged: (scope) => onScopeChanged(
                  type,
                  scope == _NotificationAccountScope.selected,
                ),
              ),
              if (limitedTypes.contains(type)) ...[
                if ((accountsByType[type] ?? const <String>{}).isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Select at least one account for this alert.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                _AccountPicker(
                  selectedAccounts: accountsByType[type] ?? const <String>{},
                  onChanged: (tag, selected) =>
                      onAccountChanged(type, tag, selected),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.value, required this.onChanged});

  final _NotificationAccountScope value;
  final ValueChanged<_NotificationAccountScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_NotificationAccountScope>(
          segments: [
            ButtonSegment(
              value: _NotificationAccountScope.all,
              icon: const Icon(LucideIcons.users),
              label: Text(l10n?.notifScopeAllAccounts ?? 'All accounts'),
            ),
            ButtonSegment(
              value: _NotificationAccountScope.selected,
              icon: const Icon(LucideIcons.userCheck),
              label: Text(l10n?.notifScopeSelected ?? 'Selected'),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.selectedAccounts,
    required this.onChanged,
  });

  final Set<String> selectedAccounts;
  final void Function(String tag, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final accounts = cocService.cocAccounts;
    final profilesByTag = {
      for (final profile in playerService.profiles)
        _normalizeTag(profile.tag): profile,
    };
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(
          l10n?.notifNoAccountsLoadedYet ?? 'No linked accounts loaded yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final accountOptions = accounts.map((account) {
      final tag = account['player_tag']?.toString() ?? '';
      final profile = profilesByTag[_normalizeTag(tag)];
      final accountName = account['name']?.toString();
      final String nameFromAccount = accountName?.isNotEmpty == true
          ? accountName!
          : tag;
      final name = profile != null && profile.name != 'Unknown'
          ? profile.name
          : nameFromAccount;
      final townHall =
          profile?.townHallLevel ?? _parseTownHall(account['townHallLevel']);
      return _AccountOption(tag: tag, name: name, townHallLevel: townHall ?? 1);
    }).toList();
    final selectedCount = accountOptions
        .where((account) => selectedAccounts.contains(account.tag))
        .length;
    final visibleAccounts = accountOptions
        .where((account) => selectedAccounts.contains(account.tag))
        .take(3)
        .toList();
    final String summary;
    if (selectedCount == 0) {
      summary = l10n?.notifNoAccountsSelected ?? 'No accounts selected';
    } else if (selectedCount == 1) {
      summary = accountOptions
          .firstWhere((account) => selectedAccounts.contains(account.tag))
          .name;
    } else {
      summary =
          l10n?.notifAccountsSelected(selectedCount) ??
          '$selectedCount accounts selected';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAccountSheet(context, accountOptions),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              _AccountAvatarStack(accounts: visibleAccounts),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.notifSelectedAccounts ?? 'Selected accounts',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAccountSheet(
    BuildContext context,
    List<_AccountOption> accounts,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  children: [
                    Text(
                      l10n?.notifSelectedAccounts ?? 'Selected accounts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final account in accounts)
                      _AccountSheetTile(
                        account: account,
                        selected: selectedAccounts.contains(account.tag),
                        onChanged: (selected) {
                          onChanged(account.tag, selected);
                          setSheetState(() {});
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static int? _parseTownHall(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _normalizeTag(String value) =>
      value.replaceAll('#', '').toUpperCase();
}

class _AccountOption {
  const _AccountOption({
    required this.tag,
    required this.name,
    required this.townHallLevel,
    this.clanName = '',
  });

  final String tag;
  final String name;
  final int townHallLevel;
  final String clanName;
}

class _AccountAvatarStack extends StatelessWidget {
  const _AccountAvatarStack({required this.accounts});

  final List<_AccountOption> accounts;

  @override
  Widget build(BuildContext context) {
    final visibleAccounts = accounts.take(3).toList();

    if (visibleAccounts.isEmpty) {
      return const SizedBox(
        width: 58,
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(LucideIcons.users),
        ),
      );
    }

    return SizedBox(
      width: 58,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visibleAccounts.length; index++)
            Positioned(
              left: index * 10,
              child: SizedBox.square(
                dimension: 38,
                child: MobileWebImage(
                  imageUrl: ImageAssets.townHall(
                    visibleAccounts[index].townHallLevel,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountSheetTile extends StatelessWidget {
  const _AccountSheetTile({
    required this.account,
    required this.selected,
    required this.onChanged,
  });

  final _AccountOption account;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox.square(
        dimension: 42,
        child: MobileWebImage(
          imageUrl: ImageAssets.townHall(account.townHallLevel),
          fit: BoxFit.contain,
        ),
      ),
      title: Text(
        account.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          'TH${account.townHallLevel}',
          if (account.clanName.isNotEmpty) account.clanName,
          account.tag,
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Switch.adaptive(value: selected, onChanged: onChanged),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.22)
          : null,
      onTap: () => onChanged(!selected),
    );
  }
}

// TODO: Remove after the per-alert audience rollout is validated.
// ignore: unused_element
class _AudienceFilters extends StatelessWidget {
  const _AudienceFilters({
    required this.selectedTownHalls,
    required this.selectedClanTags,
    required this.onTownHallChanged,
    required this.onClanChanged,
    required this.onClear,
  });

  final Set<int> selectedTownHalls;
  final Set<String> selectedClanTags;
  final void Function(int townHall, bool selected) onTownHallChanged;
  final void Function(String clanTag, bool selected) onClanChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profilesByTag = {
      for (final profile in playerService.profiles)
        _normalizeTag(profile.tag): profile,
    };

    final townHalls = <int>{};
    final clansByTag = <String, _ClanAudienceOption>{};
    for (final account in cocService.cocAccounts) {
      final tag = _normalizeTag(account['player_tag']?.toString() ?? '');
      final profile = profilesByTag[tag];
      final townHall =
          profile?.townHallLevel ?? _parseTownHall(account['townHallLevel']);
      if (townHall != null && townHall > 0) {
        townHalls.add(townHall);
      }

      final clanTag = _normalizeTag(
        profile?.clanTag ??
            account['clan_tag']?.toString() ??
            account['clan']?.toString() ??
            '',
      );
      if (clanTag.isEmpty) continue;

      final accountClanName = account['clan_name']?.toString();
      final clanName = profile?.clanOverview.name.isNotEmpty == true
          ? profile!.clanOverview.name
          : accountClanName?.isNotEmpty == true
          ? accountClanName!
          : '#$clanTag';
      clansByTag.putIfAbsent(
        clanTag,
        () => _ClanAudienceOption(tag: clanTag, name: clanName),
      );
    }

    final townHallOptions = townHalls.toList()..sort((a, b) => b.compareTo(a));
    final clanOptions = clansByTag.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final hasFilters =
        selectedTownHalls.isNotEmpty || selectedClanTags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.funnel,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep alerts broad, or restrict them to specific Town Halls and clans.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.28,
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Town Hall',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (townHallOptions.isEmpty)
            _MutedAudienceText(
              text: 'Town Hall filters appear once linked accounts are loaded.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final townHall in townHallOptions)
                  FilterChip(
                    avatar: SizedBox.square(
                      dimension: 22,
                      child: MobileWebImage(
                        imageUrl: ImageAssets.townHall(townHall),
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: Text('TH$townHall'),
                    selected: selectedTownHalls.contains(townHall),
                    onSelected: (selected) =>
                        onTownHallChanged(townHall, selected),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Clan',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (clanOptions.isEmpty)
            _MutedAudienceText(
              text: 'Clan filters appear once linked accounts have clan data.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final clan in clanOptions)
                  FilterChip(
                    avatar: Icon(
                      LucideIcons.shield,
                      size: 18,
                      color: selectedClanTags.contains(clan.tag)
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    label: Text(clan.name),
                    selected: selectedClanTags.contains(clan.tag),
                    onSelected: (selected) => onClanChanged(clan.tag, selected),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static int? _parseTownHall(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _MutedAudienceText extends StatelessWidget {
  const _MutedAudienceText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ClanAudienceOption {
  const _ClanAudienceOption({required this.tag, required this.name});

  final String tag;
  final String name;
}

class _SamplePicker extends StatelessWidget {
  const _SamplePicker({
    required this.samples,
    required this.selected,
    required this.onChanged,
  });

  final List<NotificationSample> samples;
  final NotificationSample selected;
  final ValueChanged<NotificationSample> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showPicker(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.bellRing, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification type',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selected.group} • ${selected.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronDown,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<NotificationSample>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final grouped = <String, List<NotificationSample>>{};
        for (final sample in samples) {
          grouped.putIfAbsent(sample.group, () => []).add(sample);
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              Text(
                'Test notification',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final sample in entry.value)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: SizedBox(
                      width: 34,
                      height: 34,
                      child: MobileWebImage(
                        imageUrl: sample.assetUrl,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(LucideIcons.bell),
                      ),
                    ),
                    title: Text(sample.label),
                    subtitle: Text(sample.title),
                    trailing: sample.id == selected.id
                        ? Icon(
                            LucideIcons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(sample),
                  ),
              ],
            ],
          ),
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.sample,
    required this.accountName,
    required this.clanName,
  });

  final NotificationSample sample;
  final String accountName;
  final String clanName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: MobileWebImage(
                        imageUrl: sample.assetUrl,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => Icon(
                          LucideIcons.bell,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$accountName • $clanName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sample.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sample.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationContext {
  const _NotificationContext({
    required this.playerName,
    required this.playerTag,
    required this.clanName,
    required this.clanBadgeUrl,
    required this.opponentClanName,
    required this.opponentClanBadgeUrl,
    required this.leagueName,
    required this.leagueIconUrl,
    required this.townHallLevel,
    required this.townHallImageUrl,
    required this.upgradeName,
    required this.upgradeLevel,
    required this.upgradeImageUrl,
  });

  final String playerName;
  final String playerTag;
  final String clanName;
  final String clanBadgeUrl;
  final String opponentClanName;
  final String opponentClanBadgeUrl;
  final String leagueName;
  final String leagueIconUrl;
  final int townHallLevel;
  final String townHallImageUrl;
  final String upgradeName;
  final int upgradeLevel;
  final String upgradeImageUrl;

  factory _NotificationContext.fromService(
    CocAccountService service, {
    required List<Player> profiles,
    required Set<String> selectedAccounts,
    required Set<int> selectedTownHalls,
    required Set<String> selectedClanTags,
  }) {
    final String? fallbackTag = service.accounts.isNotEmpty
        ? service.accounts.first
        : null;
    final profilesByTag = {
      for (final profile in profiles) _normalizeTag(profile.tag): profile,
    };
    final accountsByTag = {
      for (final account in service.cocAccounts)
        _normalizeTag(account['player_tag']?.toString() ?? ''): account,
    }..remove('');
    final scopedTags = selectedAccounts.isNotEmpty
        ? selectedAccounts
              .map(_normalizeTag)
              .where((tag) => tag.isNotEmpty)
              .toList()
        : accountsByTag.keys.toList();
    String? filteredTag;
    for (final tag in scopedTags) {
      final profile = profilesByTag[tag];
      final account = accountsByTag[tag] ?? const <String, dynamic>{};
      final profileTownHall = profile?.townHallLevel ?? 0;
      final townHall = profileTownHall > 0
          ? profileTownHall
          : _parseTownHall(account['townHallLevel']);
      final clanTag = _normalizeTag(
        profile?.clanTag ??
            account['clan_tag']?.toString() ??
            account['clan']?.toString() ??
            '',
      );
      final townHallMatches =
          selectedTownHalls.isEmpty ||
          (townHall != null && selectedTownHalls.contains(townHall));
      final clanMatches =
          selectedClanTags.isEmpty ||
          (clanTag.isNotEmpty && selectedClanTags.contains(clanTag));
      if (townHallMatches && clanMatches) {
        filteredTag = tag;
        break;
      }
    }
    final preferredTag = filteredTag?.isNotEmpty == true
        ? filteredTag
        : selectedAccounts.isNotEmpty
        ? selectedAccounts.first
        : service.selectedTag ?? fallbackTag;
    final normalizedPreferredTag = _normalizeTag(preferredTag ?? '');
    final Player? profile = profilesByTag[normalizedPreferredTag];
    final account =
        accountsByTag[normalizedPreferredTag] ?? const <String, dynamic>{};

    final accountName = account['name']?.toString();
    final String playerNameFallback = accountName?.isNotEmpty == true
        ? accountName!
        : 'Magic Jr.';
    final playerName = profile != null && profile.name != 'Unknown'
        ? profile.name
        : playerNameFallback;
    final playerTag = preferredTag ?? profile?.tag ?? '#2J8V28GV0';
    final String clanNameFallback =
        account['clan_name']?.toString().isNotEmpty == true
        ? account['clan_name'].toString()
        : 'your clan';
    final clanName = profile?.clanOverview.name.isNotEmpty == true
        ? profile!.clanOverview.name
        : clanNameFallback;
    final clanBadgeUrl =
        profile?.clanOverview.badgeUrls.medium.isNotEmpty == true
        ? profile!.clanOverview.badgeUrls.medium
        : ImageAssets.warClan;
    final opponentClanName =
        _validWarName(profile?.warData?.opponent?.name) ?? 'Pine Riders';
    final opponentClanBadgeUrl =
        _validImageUrl(profile?.warData?.opponent?.badgeUrls.medium) ??
        clanBadgeUrl;
    final leagueName = profile?.league.isNotEmpty == true
        ? profile!.league
        : 'Legend League';
    final leagueIconUrl = profile?.leagueUrl.isNotEmpty == true
        ? profile!.leagueUrl
        : ImageAssets.legendBlazon;
    final int? parsedTownHall = _parseTownHall(account['townHallLevel']);
    final townHallLevel = (profile?.townHallLevel ?? 0) > 0
        ? profile!.townHallLevel
        : parsedTownHall ?? 18;
    final hero = (profile?.heroes ?? const <PlayerHero>[])
        .where((hero) => hero.isUnlocked)
        .fold<PlayerHero?>(null, (best, hero) {
          if (best == null) return hero;
          return hero.level >= best.level ? hero : best;
        });

    return _NotificationContext(
      playerName: playerName,
      playerTag: playerTag,
      clanName: clanName,
      clanBadgeUrl: clanBadgeUrl,
      opponentClanName: opponentClanName,
      opponentClanBadgeUrl: opponentClanBadgeUrl,
      leagueName: leagueName,
      leagueIconUrl: leagueIconUrl,
      townHallLevel: townHallLevel,
      townHallImageUrl: ImageAssets.townHall(townHallLevel),
      upgradeName: hero?.name ?? 'Archer Queen',
      upgradeLevel: (hero?.level ?? 105) + 1,
      upgradeImageUrl:
          hero?.imageUrl ?? ImageAssets.getHeroImage('Archer Queen'),
    );
  }

  static String? _validWarName(String? value) {
    if (value == null || value.isEmpty || value == 'No name') {
      return null;
    }
    return value;
  }

  static String? _validImageUrl(String? value) {
    if (value == null ||
        value.isEmpty ||
        value == 'No medium' ||
        value == 'No small' ||
        value == 'No large') {
      return null;
    }
    return value;
  }

  static int? _parseTownHall(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _normalizeTag(String value) =>
      value.replaceAll('#', '').toUpperCase();
}
