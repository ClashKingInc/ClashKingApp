import 'dart:convert';

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ClanSearchFilterValue {
  const ClanSearchFilterValue({
    this.warFrequency,
    this.locationId,
    this.minMembers,
    this.maxMembers,
    this.minClanPoints,
    this.minClanLevel,
  });

  final String? warFrequency;
  final int? locationId;
  final int? minMembers;
  final int? maxMembers;
  final int? minClanPoints;
  final int? minClanLevel;

  bool get isEmpty =>
      warFrequency == null &&
      locationId == null &&
      minMembers == null &&
      maxMembers == null &&
      minClanPoints == null &&
      minClanLevel == null;

  String get querySuffix {
    final fields = <String, Object?>{
      'warFrequency': warFrequency,
      'locationId': locationId,
      'minMembers': minMembers,
      'maxMembers': maxMembers,
      'minClanPoints': minClanPoints,
      'minClanLevel': minClanLevel,
    }..removeWhere((_, value) => value == null);
    return fields.entries.map((entry) => '&${entry.key}=${entry.value}').join();
  }
}

class PlayerSearchFilterValue {
  const PlayerSearchFilterValue({
    this.clanTags = const [],
    this.leagueIds = const [],
    this.townHallLevels = const [],
  });

  final List<String> clanTags;
  final List<int> leagueIds;
  final List<int> townHallLevels;

  bool get isEmpty =>
      clanTags.isEmpty && leagueIds.isEmpty && townHallLevels.isEmpty;
}

class ClanSearchFiltersPanel extends StatefulWidget {
  const ClanSearchFiltersPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ClanSearchFilterValue value;
  final ValueChanged<ClanSearchFilterValue> onChanged;

  @override
  State<ClanSearchFiltersPanel> createState() => _ClanSearchFiltersPanelState();
}

class _ClanSearchFiltersPanelState extends State<ClanSearchFiltersPanel> {
  List<_FilterOption> _locations = const [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final response = await ApiService.shared.proxyGet('/locations');
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(ApiService.decodeResponseBody(response));
      final items = decoded is Map ? decoded['items'] : null;
      if (items is! List || !mounted) return;
      setState(() {
        _locations = items
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .map(
              (item) => _FilterOption(
                id: (item['id'] as num?)?.toInt() ?? 0,
                name: item['name']?.toString() ?? '',
              ),
            )
            .where((item) => item.id != 0 && item.name.isNotEmpty)
            .toList(growable: false);
      });
    } catch (_) {}
  }

  void _emit({
    Object? warFrequency = _unchanged,
    Object? locationId = _unchanged,
    Object? minMembers = _unchanged,
    Object? maxMembers = _unchanged,
    Object? minClanPoints = _unchanged,
    Object? minClanLevel = _unchanged,
  }) {
    final old = widget.value;
    widget.onChanged(
      ClanSearchFilterValue(
        warFrequency: identical(warFrequency, _unchanged)
            ? old.warFrequency
            : warFrequency as String?,
        locationId: identical(locationId, _unchanged)
            ? old.locationId
            : locationId as int?,
        minMembers: identical(minMembers, _unchanged)
            ? old.minMembers
            : minMembers as int?,
        maxMembers: identical(maxMembers, _unchanged)
            ? old.maxMembers
            : maxMembers as int?,
        minClanPoints: identical(minClanPoints, _unchanged)
            ? old.minClanPoints
            : minClanPoints as int?,
        minClanLevel: identical(minClanLevel, _unchanged)
            ? old.minClanLevel
            : minClanLevel as int?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final value = widget.value;
    return CKSectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            key: ValueKey('war-frequency-${value.warFrequency}'),
            initialValue: value.warFrequency,
            decoration: InputDecoration(labelText: loc.warFrequency),
            items: [
              DropdownMenuItem(value: null, child: Text(loc.generalNotSet)),
              DropdownMenuItem(
                value: 'always',
                child: Text(loc.clanWarFrequencyAlways),
              ),
              DropdownMenuItem(
                value: 'never',
                child: Text(loc.clanWarFrequencyNever),
              ),
              DropdownMenuItem(
                value: 'oncePerWeek',
                child: Text(loc.clanWarFrequencyOncePerWeek),
              ),
              DropdownMenuItem(
                value: 'moreThanOncePerWeek',
                child: Text(loc.clanWarFrequencyMoreThanOncePerWeek),
              ),
              DropdownMenuItem(
                value: 'lessThanOncePerWeek',
                child: Text(loc.clanWarFrequencyRarely),
              ),
            ],
            onChanged: (next) => _emit(warFrequency: next),
          ),
          const SizedBox(height: CKSpacing.sm),
          DropdownButtonFormField<int?>(
            key: ValueKey('location-${value.locationId}'),
            initialValue: value.locationId,
            isExpanded: true,
            decoration: InputDecoration(labelText: loc.clanLocation),
            items: [
              DropdownMenuItem(value: null, child: Text(loc.generalNotSet)),
              for (final location in _locations)
                DropdownMenuItem(
                  value: location.id,
                  child: Text(location.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (next) => _emit(locationId: next),
          ),
          const SizedBox(height: CKSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NumberFilter(
                  label: loc.clanMinimumMembers,
                  value: value.minMembers,
                  max: 50,
                  onChanged: (next) => _emit(minMembers: next),
                ),
              ),
              const SizedBox(width: CKSpacing.sm),
              Expanded(
                child: _NumberFilter(
                  label: loc.clanMaximumMembers,
                  value: value.maxMembers,
                  max: 50,
                  onChanged: (next) => _emit(maxMembers: next),
                ),
              ),
            ],
          ),
          const SizedBox(height: CKSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NumberFilter(
                  label: loc.clanMinimumPoints,
                  value: value.minClanPoints,
                  max: 100000,
                  onChanged: (next) => _emit(minClanPoints: next),
                ),
              ),
              const SizedBox(width: CKSpacing.sm),
              Expanded(
                child: _NumberFilter(
                  label: loc.clanMinimumLevel,
                  value: value.minClanLevel,
                  max: 100,
                  onChanged: (next) => _emit(minClanLevel: next),
                ),
              ),
            ],
          ),
          if (!value.isEmpty)
            _ResetButton(
              onPressed: () => widget.onChanged(const ClanSearchFilterValue()),
            ),
        ],
      ),
    );
  }
}

class PlayerSearchFiltersPanel extends StatefulWidget {
  const PlayerSearchFiltersPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PlayerSearchFilterValue value;
  final ValueChanged<PlayerSearchFilterValue> onChanged;

  @override
  State<PlayerSearchFiltersPanel> createState() =>
      _PlayerSearchFiltersPanelState();
}

class _PlayerSearchFiltersPanelState extends State<PlayerSearchFiltersPanel> {
  late final TextEditingController _clansController;
  List<_FilterOption> _leagues = const [];

  @override
  void initState() {
    super.initState();
    _clansController = TextEditingController(
      text: widget.value.clanTags.join(', '),
    );
    _loadLeagues();
  }

  @override
  void dispose() {
    _clansController.dispose();
    super.dispose();
  }

  Future<void> _loadLeagues() async {
    try {
      final response = await ApiService.shared.proxyGet('/leaguetiers');
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(ApiService.decodeResponseBody(response));
      final items = decoded is Map ? decoded['items'] : null;
      if (items is! List || !mounted) return;
      setState(() {
        _leagues = items
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .map(
              (item) => _FilterOption(
                id: (item['id'] as num?)?.toInt() ?? 0,
                name: item['name']?.toString() ?? '',
              ),
            )
            .where((item) => item.id != 0 && item.name.isNotEmpty)
            .toList(growable: false);
      });
    } catch (_) {}
  }

  void _emit({
    List<String>? clanTags,
    List<int>? leagueIds,
    List<int>? townHallLevels,
  }) {
    widget.onChanged(
      PlayerSearchFilterValue(
        clanTags: clanTags ?? widget.value.clanTags,
        leagueIds: leagueIds ?? widget.value.leagueIds,
        townHallLevels: townHallLevels ?? widget.value.townHallLevels,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final value = widget.value;
    return CKSectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _clansController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: loc.clanTitle,
              hintText: '#ABC123, #DEF456',
            ),
            onChanged: (raw) => _emit(
              clanTags: raw
                  .split(',')
                  .map((tag) => tag.trim().toUpperCase())
                  .where((tag) => tag.isNotEmpty)
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: CKSpacing.sm),
          DropdownButtonFormField<int?>(
            key: ValueKey('league-${value.leagueIds.join(',')}'),
            initialValue: value.leagueIds.isEmpty
                ? null
                : value.leagueIds.first,
            isExpanded: true,
            decoration: InputDecoration(labelText: loc.gameLeague),
            items: [
              DropdownMenuItem(value: null, child: Text(loc.generalNotSet)),
              for (final league in _leagues)
                DropdownMenuItem(
                  value: league.id,
                  child: Text(league.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (next) =>
                _emit(leagueIds: next == null ? const [] : [next]),
          ),
          const SizedBox(height: CKSpacing.md),
          Text(
            loc.gameTownHall,
            style: CKTypography.of(context, CKTextRole.compactLabel),
          ),
          const SizedBox(height: CKSpacing.xs),
          Wrap(
            spacing: CKSpacing.xs,
            runSpacing: CKSpacing.xs,
            children: [
              for (var level = 18; level >= 10; level--)
                FilterChip(
                  label: Text('${loc.gameTownHall}$level'),
                  selected: value.townHallLevels.contains(level),
                  onSelected: (selected) {
                    final levels = [...value.townHallLevels];
                    selected ? levels.add(level) : levels.remove(level);
                    levels.sort((a, b) => b.compareTo(a));
                    _emit(townHallLevels: levels);
                  },
                ),
            ],
          ),
          if (!value.isEmpty)
            _ResetButton(
              onPressed: () {
                _clansController.clear();
                widget.onChanged(const PlayerSearchFilterValue());
              },
            ),
        ],
      ),
    );
  }
}

class _NumberFilter extends StatelessWidget {
  const _NumberFilter({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final int max;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (raw) {
        final parsed = int.tryParse(raw);
        onChanged(parsed?.clamp(0, max));
      },
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.restart_alt_rounded),
        label: Text(AppLocalizations.of(context)!.generalReset),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.id, required this.name});

  final int id;
  final String name;
}

const _unchanged = Object();
