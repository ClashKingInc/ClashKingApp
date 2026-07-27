import 'dart:async';

import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/models/notification_preferences.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/notification_debug_service.dart';
import 'package:clashkingapp/core/services/notification_preferences_service.dart';
import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, this.preferencesService});

  final NotificationPreferencesService? preferencesService;

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final NotificationPreferencesService _preferencesService;
  NotificationPreferences _settings = const NotificationPreferences();
  PushNotificationSetupResult? _pushSetupResult;
  String? _pushTokenPreview;
  var _loading = true;
  var _saving = false;
  var _configuringPush = false;
  var _sendingSample = false;

  @override
  void initState() {
    super.initState();
    _preferencesService =
        widget.preferencesService ?? NotificationPreferencesService();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    NotificationPreferences local;
    try {
      local = await _preferencesService.loadLocal();
    } catch (_) {
      local = const NotificationPreferences();
    }
    if (!mounted) return;
    setState(() => _settings = local);

    try {
      final remote = await _preferencesService.load();
      if (!mounted) return;
      setState(() => _settings = remote);
    } catch (_) {
      // The local V2 snapshot is the offline fallback. It contains only the
      // current contract and is replaced after the next successful GET/PUT.
    }

    final pushResult = _settings.deviceEnabled
        ? await PushNotificationService.instance.initialize()
        : PushNotificationService.instance.lastResult;
    final tokenPreview = await PushNotificationService.instance.tokenPreview();
    if (!mounted) return;
    setState(() {
      _pushSetupResult = pushResult;
      _pushTokenPreview = tokenPreview;
      _loading = false;
    });
  }

  Future<void> _save(
    NotificationPreferences next, {
    NotificationPreferences? rollback,
  }) async {
    if (_saving) return;
    final previous = rollback ?? _settings;
    setState(() {
      _settings = next;
      _saving = true;
    });
    try {
      final saved = await _preferencesService.save(next);
      if (!mounted) return;
      setState(() => _settings = saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings could not be saved.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDeviceEnabled(bool enabled) async {
    if (_saving || _configuringPush) return;
    final previous = _settings;
    if (enabled) {
      setState(() => _configuringPush = true);
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
        if (!result.canReceivePush) {
          _showPushResult(result);
          return;
        }
      } finally {
        if (mounted) setState(() => _configuringPush = false);
      }
    }

    await _save(_settings.copyWith(deviceEnabled: enabled), rollback: previous);
  }

  void _showPushResult(PushNotificationSetupResult result) {
    final message = switch (result.state) {
      PushNotificationSetupState.ready =>
        'Push notifications are ready on this device.',
      PushNotificationSetupState.permissionRequired =>
        'Allow notifications to receive ClashKing alerts.',
      PushNotificationSetupState.permissionDenied =>
        'Notification permission was denied.',
      PushNotificationSetupState.notConfigured =>
        'Firebase is not configured for this build.',
      PushNotificationSetupState.tokenUnavailable =>
        'A push token is not available yet.',
      PushNotificationSetupState.unsupported =>
        'Push notifications are not supported on this platform.',
      PushNotificationSetupState.initializing =>
        'Configuring push notifications…',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message ?? message)));
  }

  Future<void> _setCategory(NotificationCategory category, bool enabled) async {
    await _save(_settings.withCategory(category, enabled));
  }

  Future<void> _setReminderTimings(Set<int> values) async {
    final normalized = values.toList()..sort((a, b) => b.compareTo(a));
    await _save(_settings.copyWith(reminderTimings: normalized));
  }

  Future<void> _setAccount(String tag, bool enabled) async {
    final normalizedTag = _normalizeTag(tag);
    if (!enabled &&
        _settings.accounts.length <= 1 &&
        _settings.accounts.any(
          (account) => _normalizeTag(account.playerTag) == normalizedTag,
        )) {
      return;
    }

    final accounts = [..._settings.accounts]
      ..removeWhere(
        (account) => _normalizeTag(account.playerTag) == normalizedTag,
      );
    if (enabled) {
      accounts.add(
        NotificationAccount(
          playerTag: tag.startsWith('#') ? tag : '#$tag',
          source: _sourceForTag(tag),
        ),
      );
    }
    await _save(_settings.copyWith(accounts: accounts));
  }

  NotificationAccountSource _sourceForTag(String tag) {
    final normalizedTag = _normalizeTag(tag);
    final verified = context.read<CocAccountService>().verifiedAccounts.any(
      (account) =>
          _normalizeTag(account['player_tag']?.toString() ?? '') ==
          normalizedTag,
    );
    return verified
        ? NotificationAccountSource.verified
        : NotificationAccountSource.bookmarked;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
              children: [
                _Section(
                  title: AppLocalizations.of(context)!.notifDevicePushSetup,
                  children: [
                    _PushSetupCard(
                      result: _pushSetupResult,
                      tokenPreview: _pushTokenPreview,
                      busy: _saving || _configuringPush,
                      enabled: _settings.deviceEnabled,
                      onChanged: _setDeviceEnabled,
                    ),
                  ],
                ),
                _SettingsAvailability(
                  enabled: _settings.deviceEnabled && !_saving,
                  child: _Section(
                    title: AppLocalizations.of(context)!.notifChooseAlerts,
                    children: [
                      _categoryRow(
                        NotificationCategory.leagueBattles,
                        LucideIcons.shield,
                        AppLocalizations.of(context)!.notifGroupLeagueBattles,
                        AppLocalizations.of(
                          context,
                        )!.notifLeagueDefenseDescription,
                      ),
                      _categoryRow(
                        NotificationCategory.warAttacks,
                        LucideIcons.swords,
                        AppLocalizations.of(context)!.notifGroupWarAttacks,
                        AppLocalizations.of(
                          context,
                        )!.notifWarAttackOptionsDescription,
                      ),
                      _categoryRow(
                        NotificationCategory.warState,
                        LucideIcons.flag,
                        AppLocalizations.of(context)!.notifGroupWarState,
                        AppLocalizations.of(context)!.notifWarAlertsDescription,
                      ),
                      _WarReminderRow(
                        enabled: _settings.warReminders,
                        selectedTimings: _settings.reminderTimings.toSet(),
                        onEnabledChanged: (enabled) => _setCategory(
                          NotificationCategory.warReminders,
                          enabled,
                        ),
                        onTimingsChanged: _setReminderTimings,
                      ),
                      _categoryRow(
                        NotificationCategory.events,
                        LucideIcons.calendarDays,
                        AppLocalizations.of(context)!.notifGroupEvents,
                        AppLocalizations.of(context)!.notifEventsDescription,
                      ),
                      _categoryRow(
                        NotificationCategory.announcements,
                        LucideIcons.megaphone,
                        AppLocalizations.of(
                          context,
                        )!.notifGroupAppAnnouncements,
                        AppLocalizations.of(
                          context,
                        )!.notifAnnouncementsDescription,
                      ),
                      _categoryRow(
                        NotificationCategory.upgradeFinishes,
                        LucideIcons.hammer,
                        AppLocalizations.of(context)!.notifGroupUpgradeFinishes,
                        AppLocalizations.of(
                          context,
                        )!.notifUpgradeFinishesDescription,
                      ),
                      _categoryRow(
                        NotificationCategory.monthlySupport,
                        LucideIcons.heartHandshake,
                        AppLocalizations.of(context)!.notifGroupMonthlySupport,
                        AppLocalizations.of(
                          context,
                        )!.notifSupportReminderDescription,
                      ),
                    ],
                  ),
                ),
                _SettingsAvailability(
                  enabled: _settings.deviceEnabled && !_saving,
                  child: _AccountSection(
                    choices: _accountChoices(context),
                    selectedTags: _settings.accounts
                        .map((account) => _normalizeTag(account.playerTag))
                        .toSet(),
                    onUseAllAccounts: () =>
                        _save(_settings.copyWith(accounts: const [])),
                    onChanged: _setAccount,
                  ),
                ),
                if (kDebugMode && NotificationDebugService.isSupportedPlatform)
                  _DebugNotificationSection(
                    sending: _sendingSample,
                    onSend: _sendTestNotification,
                  ),
              ],
            ),
    );
  }

  Widget _categoryRow(
    NotificationCategory category,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return _NotificationToggleRow(
      key: ValueKey('notification-${category.name}'),
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: _settings.enabled(category),
      onChanged: (enabled) => _setCategory(category, enabled),
    );
  }

  List<_AccountChoice> _accountChoices(BuildContext context) {
    final choices = <String, _AccountChoice>{};
    for (final account in context.watch<CocAccountService>().verifiedAccounts) {
      final tag = account['player_tag']?.toString() ?? '';
      if (tag.isEmpty) continue;
      choices[_normalizeTag(tag)] = _AccountChoice(
        tag: tag,
        name: account['name']?.toString() ?? tag,
        townHallLevel:
            int.tryParse(account['townHallLevel']?.toString() ?? '') ?? 1,
        source: NotificationAccountSource.verified,
      );
    }
    for (final player in context.watch<BookmarkService>().players) {
      choices.putIfAbsent(
        _normalizeTag(player.tag),
        () => _AccountChoice(
          tag: player.tag,
          name: player.name,
          townHallLevel: player.townHallLevel,
          source: NotificationAccountSource.bookmarked,
        ),
      );
    }
    for (final selected in _settings.accounts) {
      choices.putIfAbsent(
        _normalizeTag(selected.playerTag),
        () => _AccountChoice(
          tag: selected.playerTag,
          name: selected.playerTag,
          townHallLevel: 1,
          source: selected.source,
        ),
      );
    }
    final result = choices.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<void> _sendTestNotification() async {
    setState(() => _sendingSample = true);
    final sample = NotificationSample(
      id: 'notificationSettings',
      label: 'Notification settings',
      group: 'ClashKing',
      title: 'ClashKing notifications',
      body: 'Push notifications are configured for this device.',
      assetUrl: ImageAssets.darkModeLogo,
    );
    try {
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
      if (mounted) setState(() => _sendingSample = false);
    }
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      Divider(
                        height: 1,
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
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.46,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }
}

class _PushSetupCard extends StatelessWidget {
  const _PushSetupCard({
    required this.result,
    required this.tokenPreview,
    required this.busy,
    required this.enabled,
    required this.onChanged,
  });

  final PushNotificationSetupResult? result;
  final String? tokenPreview;
  final bool busy;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ready = result?.canReceivePush == true;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ready ? LucideIcons.badgeCheck : LucideIcons.bell,
            color: ready ? Colors.green : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'Push enabled' : 'Receive notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enabled
                      ? tokenPreview == null
                            ? 'This device can receive enabled alerts.'
                            : 'Token: $tokenPreview'
                      : 'Your alert choices are kept, but delivery is paused on this device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            key: const ValueKey('notification-device-enabled'),
            value: enabled,
            onChanged: busy ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          SizedBox(width: 30, child: Icon(icon, size: 22)),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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

class _WarReminderRow extends StatefulWidget {
  const _WarReminderRow({
    required this.enabled,
    required this.selectedTimings,
    required this.onEnabledChanged,
    required this.onTimingsChanged,
  });

  final bool enabled;
  final Set<int> selectedTimings;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<Set<int>> onTimingsChanged;

  @override
  State<_WarReminderRow> createState() => _WarReminderRowState();
}

class _WarReminderRowState extends State<_WarReminderRow> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: widget.enabled
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Icon(LucideIcons.alarmClock, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.notifGroupWarReminders,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.notifWarRemindersDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                ),
                const SizedBox(width: 6),
                Switch.adaptive(
                  key: const ValueKey('notification-warReminders'),
                  value: widget.enabled,
                  onChanged: widget.onEnabledChanged,
                ),
              ],
            ),
          ),
        ),
        if (widget.enabled && _expanded)
          _ReminderTimingPicker(
            selectedTimings: widget.selectedTimings,
            onChanged: widget.onTimingsChanged,
          ),
      ],
    );
  }
}

class _ReminderTimingPicker extends StatelessWidget {
  const _ReminderTimingPicker({
    required this.selectedTimings,
    required this.onChanged,
  });

  final Set<int> selectedTimings;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = selectedTimings.toList()..sort((a, b) => b.compareTo(a));
    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sorted.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in sorted)
                    InputChip(
                      label: Text(_timingLabel(minutes)),
                      onDeleted: () =>
                          onChanged({...selectedTimings}..remove(minutes)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            FilledButton.tonalIcon(
              onPressed: selectedTimings.length >= 3
                  ? null
                  : () async {
                      final selected = await showModalBottomSheet<int>(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => _ReminderTimingSheet(
                          selectedTimings: selectedTimings,
                        ),
                      );
                      if (selected != null) {
                        onChanged({...selectedTimings, selected});
                      }
                    },
              icon: const Icon(LucideIcons.plus),
              label: Text(
                selectedTimings.length >= 3
                    ? 'Maximum reminders added'
                    : 'Add reminder',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTimingSheet extends StatefulWidget {
  const _ReminderTimingSheet({required this.selectedTimings});

  final Set<int> selectedTimings;

  @override
  State<_ReminderTimingSheet> createState() => _ReminderTimingSheetState();
}

class _ReminderTimingSheetState extends State<_ReminderTimingSheet> {
  late final FixedExtentScrollController _controller;
  var _selectedHour = 1;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMinutes = _selectedHour * 60;
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
          const SizedBox(height: 12),
          SizedBox(
            height: 156,
            child: CupertinoPicker(
              itemExtent: 38,
              scrollController: _controller,
              onSelectedItemChanged: (index) =>
                  setState(() => _selectedHour = index + 1),
              children: [
                for (var hour = 1; hour <= 47; hour++)
                  Center(child: Text(hour == 1 ? '1 hour' : '$hour hours')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.selectedTimings.contains(selectedMinutes)
                ? null
                : () => Navigator.of(context).pop(selectedMinutes),
            child: Text('Add ${_timingLabel(selectedMinutes)}'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final minutes in [30, 15]) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.selectedTimings.contains(minutes)
                        ? null
                        : () => Navigator.of(context).pop(minutes),
                    child: Text('$minutes minutes'),
                  ),
                ),
                if (minutes == 30) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.choices,
    required this.selectedTags,
    required this.onUseAllAccounts,
    required this.onChanged,
  });

  final List<_AccountChoice> choices;
  final Set<String> selectedTags;
  final VoidCallback onUseAllAccounts;
  final void Function(String tag, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allAccounts = selectedTags.isEmpty;
    final selectedCount = allAccounts ? choices.length : selectedTags.length;

    return _Section(
      title: l10n.notifAudienceSectionTitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(
            l10n.notifAudienceSheetDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _AudienceScopeOption(
          icon: LucideIcons.usersRound,
          title: l10n.notifScopeAllLinkedAccounts,
          subtitle: l10n.notifAudienceAllSubtitle(choices.length),
          selected: allAccounts,
          onTap: allAccounts ? null : onUseAllAccounts,
        ),
        _AudienceScopeOption(
          icon: LucideIcons.userRoundCheck,
          title: l10n.notifScopeSelectedAccounts,
          subtitle: choices.isEmpty
              ? l10n.notifAudienceSelectedEmpty
              : l10n.notifAudienceSelectedSubtitle(selectedCount),
          selected: !allAccounts,
          onTap: allAccounts && choices.isNotEmpty
              ? () => onChanged(choices.first.tag, true)
              : null,
        ),
        if (allAccounts)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Text(
              l10n.notifAudienceAllInlineNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (choices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(l10n.notifNoAccountsLoadedYet),
          )
        else if (!allAccounts)
          for (final choice in choices)
            Builder(
              key: ValueKey('notification-account-${choice.tag}'),
              builder: (context) {
                final selected = selectedTags.contains(
                  _normalizeTag(choice.tag),
                );
                final isLastSelected = selected && selectedTags.length == 1;
                return _AudienceAccountRow(
                  choice: choice,
                  selected: selected,
                  onChanged: isLastSelected
                      ? null
                      : (enabled) => onChanged(choice.tag, enabled),
                );
              },
            ),
      ],
    );
  }
}

class _AudienceScopeOption extends StatelessWidget {
  const _AudienceScopeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: selected ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(icon, size: 20, color: accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: 22,
              child: selected
                  ? Icon(
                      LucideIcons.check,
                      size: 20,
                      color: colorScheme.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceAccountRow extends StatelessWidget {
  const _AudienceAccountRow({
    required this.choice,
    required this.selected,
    required this.onChanged,
  });

  final _AccountChoice choice;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sourceLabel = choice.source == NotificationAccountSource.verified
        ? l10n.notifAccountVerified
        : l10n.notifAccountBookmarked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          Image.network(
            ImageAssets.townHall(choice.townHallLevel),
            width: 38,
            height: 38,
            errorBuilder: (_, _, _) =>
                const Icon(LucideIcons.userRound, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${choice.tag} • $sourceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: selected, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AccountChoice {
  const _AccountChoice({
    required this.tag,
    required this.name,
    required this.townHallLevel,
    required this.source,
  });

  final String tag;
  final String name;
  final int townHallLevel;
  final NotificationAccountSource source;
}

class _DebugNotificationSection extends StatelessWidget {
  const _DebugNotificationSection({
    required this.sending,
    required this.onSend,
  });

  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: AppLocalizations.of(context)!.notifTestNotification,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: sending ? null : onSend,
            icon: sending
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
    );
  }
}

String _normalizeTag(String value) =>
    value.replaceAll('#', '').trim().toUpperCase();

String _timingLabel(int minutes) {
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour before' : '$hours hours before';
  }
  return '$minutes minutes before';
}
