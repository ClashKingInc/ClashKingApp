import 'dart:convert';

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
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
    this.leagueIds = const [],
    this.minTownHallLevel,
    this.maxTownHallLevel,
  });

  final List<int> leagueIds;
  final int? minTownHallLevel;
  final int? maxTownHallLevel;

  List<int> get townHallLevels {
    if (minTownHallLevel == null && maxTownHallLevel == null) return const [];
    final minimum = minTownHallLevel ?? 1;
    final maximum = maxTownHallLevel ?? 18;
    return [for (var level = minimum; level <= maximum; level++) level];
  }

  bool get isEmpty =>
      leagueIds.isEmpty && minTownHallLevel == null && maxTownHallLevel == null;
}

class ClanSearchFiltersPanel extends StatefulWidget {
  const ClanSearchFiltersPanel({
    super.key,
    required this.value,
    required this.onChanged,
    this.apiService,
  });

  final ClanSearchFilterValue value;
  final ValueChanged<ClanSearchFilterValue> onChanged;
  final ApiService? apiService;

  @override
  State<ClanSearchFiltersPanel> createState() => _ClanSearchFiltersPanelState();
}

class _ClanSearchFiltersPanelState extends State<ClanSearchFiltersPanel> {
  List<RankingLocation> _locations = const [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final response = await (widget.apiService ?? ApiService.shared).proxyGet(
        '/locations',
      );
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(ApiService.decodeResponseBody(response));
      final items = decoded is Map ? decoded['items'] : null;
      if (items is! List || !mounted) return;
      final locations =
          items
              .whereType<Map>()
              .map(
                (item) =>
                    RankingLocation.fromJson(Map<String, dynamic>.from(item)),
              )
              .where(
                (location) =>
                    location.id != null && location.hasValidCountryCode,
              )
              .toList(growable: false)
            ..sort((a, b) => a.name.compareTo(b.name));
      setState(() => _locations = locations);
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
    final memberRange = RangeValues(
      (value.minMembers ?? 0).toDouble(),
      (value.maxMembers ?? 50).toDouble(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterDropdown(
                sortBy: value.warFrequency ?? '',
                fillWidth: true,
                leadingIcon: Icons.security_rounded,
                sortByOptions: {
                  loc.generalNotSet: '',
                  loc.clanWarFrequencyAlways: 'always',
                  loc.clanWarFrequencyNever: 'never',
                  loc.clanWarFrequencyOncePerWeek: 'oncePerWeek',
                  loc.clanWarFrequencyMoreThanOncePerWeek:
                      'moreThanOncePerWeek',
                  loc.clanWarFrequencyRarely: 'lessThanOncePerWeek',
                },
                updateSortBy: (next) =>
                    _emit(warFrequency: next.isEmpty ? null : next),
              ),
            ),
            const SizedBox(width: CKSpacing.sm),
            Expanded(
              child: FilterDropdown(
                sortBy:
                    _locations.any(
                      (location) => location.id == value.locationId,
                    )
                    ? value.locationId.toString()
                    : '',
                fillWidth: true,
                leadingIcon: Icons.public_rounded,
                sortByOptions: {
                  loc.generalNotSet: '',
                  for (final location in _locations)
                    <Widget>[
                      SizedBox.square(
                        dimension: 20,
                        child: MobileWebImage(
                          imageUrl: ImageAssets.flag(location.countryCode!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]: location.id
                        .toString(),
                },
                updateSortBy: (next) => _emit(locationId: int.tryParse(next)),
              ),
            ),
          ],
        ),
        const SizedBox(height: CKSpacing.md),
        _RangeFilter(
          label: '${loc.clanMinimumMembers} – ${loc.clanMaximumMembers}',
          value: memberRange,
          min: 0,
          max: 50,
          divisions: 50,
          valueLabel:
              '${memberRange.start.round()} – ${memberRange.end.round()}',
          onChanged: (next) => _emit(
            minMembers: next.start == 0 ? null : next.start.round(),
            maxMembers: next.end == 50 ? null : next.end.round(),
          ),
        ),
        _SliderFilter(
          label: loc.clanMinimumPoints,
          value: (value.minClanPoints ?? 0).toDouble(),
          max: 100000,
          divisions: 100,
          valueLabel: '${value.minClanPoints ?? 0}',
          onChanged: (next) =>
              _emit(minClanPoints: next == 0 ? null : next.round()),
        ),
        _SliderFilter(
          label: loc.clanMinimumLevel,
          value: (value.minClanLevel ?? 1).toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          valueLabel: '${value.minClanLevel ?? 1}',
          onChanged: (next) =>
              _emit(minClanLevel: next == 1 ? null : next.round()),
        ),
        if (!value.isEmpty)
          _ResetButton(
            onPressed: () => widget.onChanged(const ClanSearchFilterValue()),
          ),
      ],
    );
  }
}

class PlayerSearchFiltersPanel extends StatefulWidget {
  const PlayerSearchFiltersPanel({
    super.key,
    required this.value,
    required this.onChanged,
    this.apiService,
  });

  final PlayerSearchFilterValue value;
  final ValueChanged<PlayerSearchFilterValue> onChanged;
  final ApiService? apiService;

  @override
  State<PlayerSearchFiltersPanel> createState() =>
      _PlayerSearchFiltersPanelState();
}

class _PlayerSearchFiltersPanelState extends State<PlayerSearchFiltersPanel> {
  List<_FilterOption> _leagues = const [];

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    try {
      final response = await (widget.apiService ?? ApiService.shared).proxyGet(
        '/leaguetiers',
      );
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
    List<int>? leagueIds,
    Object? minTownHallLevel = _unchanged,
    Object? maxTownHallLevel = _unchanged,
  }) {
    final old = widget.value;
    widget.onChanged(
      PlayerSearchFilterValue(
        leagueIds: leagueIds ?? old.leagueIds,
        minTownHallLevel: identical(minTownHallLevel, _unchanged)
            ? old.minTownHallLevel
            : minTownHallLevel as int?,
        maxTownHallLevel: identical(maxTownHallLevel, _unchanged)
            ? old.maxTownHallLevel
            : maxTownHallLevel as int?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final value = widget.value;
    final townHallRange = RangeValues(
      (value.minTownHallLevel ?? 1).toDouble(),
      (value.maxTownHallLevel ?? 18).toDouble(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterDropdown(
          sortBy:
              value.leagueIds.isNotEmpty &&
                  _leagues.any((league) => league.id == value.leagueIds.first)
              ? value.leagueIds.first.toString()
              : '',
          fillWidth: true,
          leadingIcon: Icons.military_tech_rounded,
          sortByOptions: {
            loc.generalNotSet: '',
            for (final league in _leagues) league.name: league.id.toString(),
          },
          updateSortBy: (next) =>
              _emit(leagueIds: next.isEmpty ? const [] : [int.parse(next)]),
        ),
        const SizedBox(height: CKSpacing.md),
        _RangeFilter(
          label: loc.gameTownHall,
          value: townHallRange,
          min: 1,
          max: 18,
          divisions: 17,
          valueLabel:
              '${loc.gameTownHall} ${townHallRange.start.round()} – ${loc.gameTownHall} ${townHallRange.end.round()}',
          onChanged: (next) => _emit(
            minTownHallLevel: next.start == 1 ? null : next.start.round(),
            maxTownHallLevel: next.end == 18 ? null : next.end.round(),
          ),
        ),
        if (!value.isEmpty)
          _ResetButton(
            onPressed: () => widget.onChanged(const PlayerSearchFilterValue()),
          ),
      ],
    );
  }
}

class _RangeFilter extends StatelessWidget {
  const _RangeFilter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });
  final String label;
  final RangeValues value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _FilterLabel(label: label, value: valueLabel),
      RangeSlider(
        values: value,
        min: min,
        max: max,
        divisions: divisions,
        labels: RangeLabels('${value.start.round()}', '${value.end.round()}'),
        onChanged: onChanged,
      ),
    ],
  );
}

class _SliderFilter extends StatelessWidget {
  const _SliderFilter({
    required this.label,
    required this.value,
    this.min = 0,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _FilterLabel(label: label, value: valueLabel),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: valueLabel,
        onChanged: onChanged,
      ),
    ],
  );
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: CKTypography.of(context, CKTextRole.compactLabel),
        ),
      ),
      Text(value, style: CKTypography.of(context, CKTextRole.metadata)),
    ],
  );
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.restart_alt_rounded),
      label: Text(AppLocalizations.of(context)!.generalReset),
    ),
  );
}

class _FilterOption {
  const _FilterOption({required this.id, required this.name});
  final int id;
  final String name;
}

const _unchanged = Object();
