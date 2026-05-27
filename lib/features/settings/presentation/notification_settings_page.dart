import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/notification_debug_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_hero.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final Set<String> _enabledTypes = {
    'League battles',
    'War attacks',
    'War state',
    'War reminders',
    'Events',
    'Upgrade finishes',
    'Monthly support',
  };
  final Set<String> _warAttackModes = {'defenses'};
  final Set<String> _eventTypes = {'Clan Games', 'CWL', 'Raid Weekend'};
  final Set<String> _warReminderTimings = {'1h', '30m', '15m'};
  final Set<String> _expandedNotificationOptions = {};
  final Set<String> _selectedAccounts = {};
  var _accountScope = _NotificationAccountScope.all;
  var _selectedSampleId = NotificationDebugService.fallbackSamples.first.id;
  var _isSending = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final notificationContext = _NotificationContext.fromService(
      cocService,
      profiles: playerService.profiles,
      selectedAccounts: _selectedAccounts,
    );
    final samples = _samplesForContext(notificationContext);
    final selectedSample = samples.firstWhere(
      (sample) => sample.id == _selectedSampleId,
      orElse: () => samples.first,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _Section(
            title: 'Choose alerts',
            children: [
              _NotificationToggleRow(
                icon: LucideIcons.shield,
                title: 'League battles',
                subtitle:
                    'Defense results with attacker, stars, percentage, and league context.',
                enabled: _enabledTypes.contains('League battles'),
                onChanged: (value) => _toggleType('League battles', value),
              ),
              _NotificationDisclosureRow(
                icon: LucideIcons.swords,
                title: 'War attacks',
                subtitle:
                    'War attack results, defense alerts, and 5v5 attack feed options.',
                enabled: _enabledTypes.contains('War attacks'),
                expanded: _expandedNotificationOptions.contains('War attacks'),
                onChanged: (value) => _toggleType('War attacks', value),
                onExpandChanged: (expanded) =>
                    _toggleExpanded('War attacks', expanded),
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
                  },
                ),
              ),
              _NotificationToggleRow(
                icon: LucideIcons.flag,
                title: 'War state',
                subtitle: 'War matched, battle day started, and war ended.',
                enabled: _enabledTypes.contains('War state'),
                onChanged: (value) => _toggleType('War state', value),
              ),
              _NotificationDisclosureRow(
                icon: LucideIcons.alarmClock,
                title: 'War reminders',
                subtitle: 'Custom reminders before war ends.',
                enabled: _enabledTypes.contains('War reminders'),
                expanded: _expandedNotificationOptions.contains(
                  'War reminders',
                ),
                onChanged: (value) => _toggleType('War reminders', value),
                onExpandChanged: (expanded) =>
                    _toggleExpanded('War reminders', expanded),
                options: _WarReminderTimingPicker(
                  selectedTimings: _warReminderTimings,
                  onChanged: (timings) {
                    setState(() {
                      _warReminderTimings
                        ..clear()
                        ..addAll(timings);
                    });
                  },
                ),
              ),
              _NotificationDisclosureRow(
                icon: LucideIcons.calendarDays,
                title: 'Events',
                subtitle: 'Clan Games, CWL, Raid Weekend, and season events.',
                enabled: _enabledTypes.contains('Events'),
                expanded: _expandedNotificationOptions.contains('Events'),
                onChanged: (value) => _toggleType('Events', value),
                onExpandChanged: (expanded) =>
                    _toggleExpanded('Events', expanded),
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
                  },
                ),
              ),
              _NotificationToggleRow(
                icon: LucideIcons.hammer,
                title: 'Upgrade finishes',
                subtitle:
                    'Troops, heroes, pets, spells, equipment, and buildings.',
                enabled: _enabledTypes.contains('Upgrade finishes'),
                onChanged: (value) => _toggleType('Upgrade finishes', value),
              ),
              _NotificationToggleRow(
                icon: LucideIcons.heartHandshake,
                title: 'Monthly support',
                subtitle: 'Monthly reminder to support ClashKing.',
                enabled: _enabledTypes.contains('Monthly support'),
                onChanged: (value) => _toggleType('Monthly support', value),
              ),
            ],
          ),
          _Section(
            title: 'Account scope',
            children: [
              _ScopeSelector(
                value: _accountScope,
                onChanged: (value) {
                  setState(() {
                    _accountScope = value;
                  });
                },
              ),
              if (_accountScope == _NotificationAccountScope.selected)
                _AccountPicker(
                  selectedAccounts: _selectedAccounts,
                  onChanged: (tag, selected) {
                    setState(() {
                      if (selected) {
                        _selectedAccounts.add(tag);
                      } else {
                        _selectedAccounts.remove(tag);
                      }
                    });
                  },
                ),
            ],
          ),
          if (kDebugMode)
            _Section(
              title: 'Test notification',
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
                    label: const Text('Send test notification'),
                  ),
                ),
              ],
            ),
        ],
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
      final sample =
          _samplesForContext(
            _NotificationContext.fromService(
              cocService,
              profiles: context.read<PlayerService>().profiles,
              selectedAccounts: _selectedAccounts,
            ),
          ).firstWhere(
            (sample) => sample.id == _selectedSampleId,
            orElse: () => NotificationDebugService.fallbackSamples.first,
          );
      final result = await NotificationDebugService().showSample(sample);
      if (!mounted) return;
      final title = result['title']?.toString() ?? sample.title;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scheduled: $title')));
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

    return [
      NotificationSample(
        id: 'leagueDefense',
        label: 'League defense',
        group: 'Battles',
        title: 'League defense result',
        body: 'Lord Clasher attacked $player • 90% • 2 stars • $league',
        assetUrl: context.leagueIconUrl,
      ),
      NotificationSample(
        id: 'leagueTripled',
        label: 'League triple',
        group: 'Battles',
        title: 'League defense result',
        body: 'Lord Clasher attacked $player • 100% • 3 stars • $league',
        assetUrl: context.leagueIconUrl,
      ),
      NotificationSample(
        id: 'warDefense',
        label: 'War defense',
        group: 'Battles',
        title: 'War attack on TH$th',
        body: '$opponentClan attacked $player • 78% • 2 stars • $clan defense',
        assetUrl: townHallImage,
      ),
      NotificationSample(
        id: 'warAllAttacks',
        label: '5v5 war feed',
        group: 'Battles',
        title: 'War attack result',
        body: '$clan attacked Pine Riders TH$th • 100% • 3 stars',
        assetUrl: townHallImage,
      ),
      NotificationSample(
        id: 'warMatched',
        label: 'War matched',
        group: 'War state',
        title: 'War matched',
        body: '$clan matched with Pine Riders. Preparation day started.',
        assetUrl: context.clanBadgeUrl,
      ),
      NotificationSample(
        id: 'warStarted',
        label: 'War started',
        group: 'War state',
        title: 'Battle day started',
        body: '$clan vs Pine Riders is live. Good luck.',
        assetUrl: ImageAssets.sword,
      ),
      NotificationSample(
        id: 'warEnded',
        label: 'War ended',
        group: 'War state',
        title: 'War ended',
        body: '$clan 86 - 82 Pine Riders. Final results are available.',
        assetUrl: ImageAssets.warClan,
      ),
      NotificationSample(
        id: 'warReminder60',
        label: 'War reminder: 1h',
        group: 'Reminders',
        title: '1 hour left',
        body: '$player has remaining war attacks. 1 hour left.',
        assetUrl: ImageAssets.iconClock,
      ),
      NotificationSample(
        id: 'warReminder30',
        label: 'War reminder: 30m',
        group: 'Reminders',
        title: '30 minutes left',
        body: '$player has remaining war attacks. 30 minutes left.',
        assetUrl: ImageAssets.iconClock,
      ),
      NotificationSample(
        id: 'warReminder15',
        label: 'War reminder: 15m',
        group: 'Reminders',
        title: '15 minutes left',
        body: '$player has remaining war attacks. 15 minutes left.',
        assetUrl: ImageAssets.iconClock,
      ),
      NotificationSample(
        id: 'clanGamesStarted',
        label: 'Clan Games',
        group: 'Events',
        title: 'Clan Games started',
        body: '$clan can start earning Clan Games points.',
        assetUrl: ImageAssets.clanGamesMedals,
      ),
      NotificationSample(
        id: 'cwlStarted',
        label: 'CWL started',
        group: 'Events',
        title: 'CWL started',
        body: '$clan can begin Clan War League preparation.',
        assetUrl: ImageAssets.cwlSwordsNoBorder,
      ),
      NotificationSample(
        id: 'raidWeekendStarted',
        label: 'Raid Weekend',
        group: 'Events',
        title: 'Raid Weekend started',
        body: '$clan can start Capital Raid attacks.',
        assetUrl: ImageAssets.raidAttacks,
      ),
      NotificationSample(
        id: 'seasonStarted',
        label: 'Season start',
        group: 'Events',
        title: 'New season started',
        body: '$league season has started for $player.',
        assetUrl: context.leagueIconUrl,
      ),
      NotificationSample(
        id: 'specialEventStarted',
        label: 'Special event',
        group: 'Events',
        title: 'A new event is live',
        body: 'A new Clash event is available.',
        assetUrl: ImageAssets.darkModeLogo,
      ),
      NotificationSample(
        id: 'monthlySupport',
        label: 'Monthly support',
        group: 'Support',
        title: 'Support ClashKing',
        body:
            'Monthly support helps keep ClashKing available and improving. Thank you.',
        assetUrl: ImageAssets.darkModeLogo,
      ),
      NotificationSample(
        id: 'upgradeComplete',
        label: 'Upgrade finished',
        group: 'Progress',
        title: '$upgradeName is ready',
        body: 'Level $upgradeLevel finished for $player. Upgrade complete.',
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

class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final ValueChanged<bool> onExpandChanged;
  final Widget options;

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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: showOptions ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
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
            duration: const Duration(milliseconds: 180),
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
          title: 'Defenses against your base',
          subtitle: 'Only hits where this account is defending.',
          selected: selectedModes.contains('defenses'),
          onChanged: (value) => onChanged('defenses', value),
        ),
        _IconSwitchTile(
          icon: LucideIcons.swords,
          title: 'All attacks',
          subtitle: 'Every hit in 5v5 wars only.',
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
    final colorScheme = Theme.of(context).colorScheme;
    var selectedHour = 1;
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final hourValue = '${selectedHour}h';
              final hourAlreadySelected = selectedTimings.contains(hourValue);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text(
                    'Add war reminder',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                      scrollController: FixedExtentScrollController(),
                      onSelectedItemChanged: (index) {
                        setSheetState(() {
                          selectedHour = index + 1;
                        });
                      },
                      children: [
                        for (var hour = 1; hour <= 47; hour++)
                          Center(
                            child: Text(
                              hour == 1 ? '1 hour left' : '$hour hours left',
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
                          ? '${_timingLabel(hourValue)} already added'
                          : 'Add ${_timingLabel(hourValue)}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: selectedTimings.contains('30m')
                              ? null
                              : () => Navigator.of(context).pop('30m'),
                          child: const Text('30 minutes'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: selectedTimings.contains('15m')
                              ? null
                              : () => Navigator.of(context).pop('15m'),
                          child: const Text('15 minutes'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
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
      return hours == 1 ? '1 hour left' : '$hours hours left';
    }
    return timing == '30m' ? '30 minutes left' : '15 minutes left';
  }
}

class _EventTypePicker extends StatelessWidget {
  const _EventTypePicker({
    required this.selectedEvents,
    required this.onChanged,
  });

  final Set<String> selectedEvents;
  final void Function(String event, bool selected) onChanged;

  static const _events = [
    ('Clan Games', ImageAssets.clanGamesMedals),
    ('CWL', ImageAssets.cwlSwordsNoBorder),
    ('Raid Weekend', ImageAssets.raidAttacks),
    ('Season starts', ImageAssets.iconGoldPass),
    ('Special events', ImageAssets.darkModeLogo),
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
  });

  final String imageUrl;
  final String title;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSwitchTile(
      leading: SizedBox.square(
        dimension: 28,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => const Icon(LucideIcons.bell),
        ),
      ),
      title: title,
      selected: selected,
      onChanged: onChanged,
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
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;

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

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.value, required this.onChanged});

  final _NotificationAccountScope value;
  final ValueChanged<_NotificationAccountScope> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isIOS) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<_NotificationAccountScope>(
            groupValue: value,
            children: const {
              _NotificationAccountScope.all: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Text('All accounts'),
              ),
              _NotificationAccountScope.selected: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Text('Selected'),
              ),
            },
            onValueChanged: (selection) {
              if (selection != null) onChanged(selection);
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_NotificationAccountScope>(
          segments: const [
            ButtonSegment(
              value: _NotificationAccountScope.all,
              icon: Icon(LucideIcons.users),
              label: Text('All accounts'),
            ),
            ButtonSegment(
              value: _NotificationAccountScope.selected,
              icon: Icon(LucideIcons.userCheck),
              label: Text('Selected'),
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

    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(
          'No linked accounts loaded yet.',
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
      final name = profile != null && profile.name != 'Unknown'
          ? profile.name
          : accountName?.isNotEmpty == true
          ? accountName!
          : tag;
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
    final summary = selectedCount == 0
        ? 'No accounts selected'
        : selectedCount == 1
        ? accountOptions
              .firstWhere((account) => selectedAccounts.contains(account.tag))
              .name
        : '$selectedCount accounts selected';

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
                      'Selected accounts',
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
                      'Selected accounts',
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
  });

  final String tag;
  final String name;
  final int townHallLevel;
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
                child: CachedNetworkImage(
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
        child: CachedNetworkImage(
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
        'TH${account.townHallLevel} • ${account.tag}',
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
                      child: CachedNetworkImage(
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
                      child: CachedNetworkImage(
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
  }) {
    final preferredTag = selectedAccounts.isNotEmpty
        ? selectedAccounts.first
        : service.selectedTag ??
              (service.accounts.isNotEmpty ? service.accounts.first : null);
    final normalizedPreferredTag = _normalizeTag(preferredTag ?? '');
    final matchingProfiles = profiles.where(
      (profile) => _normalizeTag(profile.tag) == normalizedPreferredTag,
    );
    final Player? profile = matchingProfiles.isNotEmpty
        ? matchingProfiles.first
        : null;
    final account = service.cocAccounts.firstWhere(
      (account) =>
          _normalizeTag(account['player_tag']?.toString() ?? '') ==
          normalizedPreferredTag,
      orElse: () => const <String, dynamic>{},
    );

    final accountName = account['name']?.toString();
    final playerName = profile != null && profile.name != 'Unknown'
        ? profile.name
        : accountName?.isNotEmpty == true
        ? accountName!
        : 'Magic Jr.';
    final playerTag = preferredTag ?? profile?.tag ?? '#2J8V28GV0';
    final clanName = profile?.clanOverview.name.isNotEmpty == true
        ? profile!.clanOverview.name
        : account['clan_name']?.toString().isNotEmpty == true
        ? account['clan_name'].toString()
        : 'your clan';
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
    final townHallLevel = (profile?.townHallLevel ?? 0) > 0
        ? profile!.townHallLevel
        : _parseTownHall(account['townHallLevel']) != null
        ? _parseTownHall(account['townHallLevel'])!
        : 18;
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
