import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats_filter.dart';

class ClanWarStatsFilterDialog extends StatefulWidget {
  final ClanWarStatsFilter initialFilter;
  final Function(ClanWarStatsFilter) onApply;

  const ClanWarStatsFilterDialog({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<ClanWarStatsFilterDialog> createState() =>
      _ClanWarStatsFilterDialogState();
}

class _ClanWarStatsFilterDialogState extends State<ClanWarStatsFilterDialog> {
  late ClanWarStatsFilter _filter;
  late TextEditingController _minDestructionController;
  late TextEditingController _maxDestructionController;
  late TextEditingController _minMapPositionController;
  late TextEditingController _maxMapPositionController;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _minDestructionController = TextEditingController(
      text: _filter.minDestruction?.toString() ?? '',
    );
    _maxDestructionController = TextEditingController(
      text: _filter.maxDestruction?.toString() ?? '',
    );
    _minMapPositionController = TextEditingController(
      text: _filter.minMapPosition?.toString() ?? '',
    );
    _maxMapPositionController = TextEditingController(
      text: _filter.maxMapPosition?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minDestructionController.dispose();
    _maxDestructionController.dispose();
    _minMapPositionController.dispose();
    _maxMapPositionController.dispose();
    super.dispose();
  }

  void _updateFilter(ClanWarStatsFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  void _resetFilters() {
    setState(() {
      _filter = ClanWarStatsFilter.defaultFilter();
      _minDestructionController.clear();
      _maxDestructionController.clear();
      _minMapPositionController.clear();
      _maxMapPositionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          AppLocalizations.of(context)?.generalFilters ?? 'Clan War Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Section
            _buildSectionTitle('Date Range'),
            _buildDateRangePicker(),

            const SizedBox(height: 20),

            // War Type Section
            _buildSectionTitle('War Type'),
            _buildWarTypeDropdown(),

            const SizedBox(height: 20),

            // Town Hall Section
            _buildSectionTitle('Town Hall'),
            _buildTownHallFilters(),

            const SizedBox(height: 20),

            // Performance Section
            _buildSectionTitle('Performance'),
            _buildPerformanceFilters(),

            const SizedBox(height: 20),

            // Map Position Section
            _buildSectionTitle('Map Position'),
            _buildMapPositionFilters(),

            const SizedBox(height: 20),

            // Advanced Options
            _buildSectionTitle('Advanced'),
            _buildAdvancedOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetFilters,
          child: Text(AppLocalizations.of(context)?.generalRetry ?? 'Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)?.generalCancel ?? 'Cancel'),
        ),
        ElevatedButton(
            onPressed: () {
              // Update filter with text field values
              final updatedFilter = _filter.copyWith(
                minDestruction: _minDestructionController.text.isNotEmpty
                    ? double.tryParse(_minDestructionController.text)
                    : null,
                maxDestruction: _maxDestructionController.text.isNotEmpty
                    ? double.tryParse(_maxDestructionController.text)
                    : null,
                minMapPosition: _minMapPositionController.text.isNotEmpty
                    ? int.tryParse(_minMapPositionController.text)
                    : null,
                maxMapPosition: _maxMapPositionController.text.isNotEmpty
                    ? int.tryParse(_maxMapPositionController.text)
                    : null,
              );

              widget.onApply(updatedFilter);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)?.generalApply ?? 'Apply',
                style: Theme.of(context).textTheme.labelSmall)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      children: [
        ListTile(
          title: Text('Start Date'),
          subtitle:
              Text(_filter.startDate?.toString().split(' ')[0] ?? 'Not set'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _filter.startDate ??
                  DateTime.now().subtract(const Duration(days: 180)),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _updateFilter(_filter.copyWith(startDate: picked));
            }
          },
        ),
        ListTile(
          title: Text('End Date'),
          subtitle:
              Text(_filter.endDate?.toString().split(' ')[0] ?? 'Not set'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _filter.endDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _updateFilter(_filter.copyWith(endDate: picked));
            }
          },
        ),
      ],
    );
  }

  Widget _buildWarTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _filter.warType,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Wars')),
        DropdownMenuItem(value: 'random', child: Text('Random Wars')),
        DropdownMenuItem(value: 'cwl', child: Text('CWL Wars')),
        DropdownMenuItem(value: 'friendly', child: Text('Friendly Wars')),
      ],
      onChanged: (value) {
        if (value != null) {
          _updateFilter(_filter.copyWith(warType: value));
        }
      },
      decoration: const InputDecoration(
        labelText: 'War Type',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTownHallFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _filter.ownTownHall,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any TH')),
                  ...List.generate(16, (i) => i + 1).map(
                      (th) => DropdownMenuItem(value: th, child: Text('TH$th')))
                ],
                onChanged: (value) {
                  _updateFilter(_filter.copyWith(ownTownHall: value));
                },
                decoration: const InputDecoration(
                  labelText: 'Attacker TH',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _filter.enemyTownHall,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any TH')),
                  ...List.generate(16, (i) => i + 1).map(
                      (th) => DropdownMenuItem(value: th, child: Text('TH$th')))
                ],
                onChanged: (value) {
                  _updateFilter(_filter.copyWith(enemyTownHall: value));
                },
                decoration: const InputDecoration(
                  labelText: 'Defender TH',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Same Town Hall Only'),
          subtitle: const Text(
              'Only show attacks where attacker and defender have the same TH level'),
          value: _filter.sameTownHall,
          onChanged: (value) {
            _updateFilter(_filter.copyWith(sameTownHall: value ?? false));
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceFilters() {
    return Column(
      children: [
        // Stars filter
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _filter.minStars,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ...List.generate(4, (i) => i).map((stars) =>
                      DropdownMenuItem(value: stars, child: Text('$stars ⭐')))
                ],
                onChanged: (value) {
                  _updateFilter(_filter.copyWith(minStars: value));
                },
                decoration: const InputDecoration(
                  labelText: 'Min Stars',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _filter.maxStars,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ...List.generate(4, (i) => i).map((stars) =>
                      DropdownMenuItem(value: stars, child: Text('$stars ⭐')))
                ],
                onChanged: (value) {
                  _updateFilter(_filter.copyWith(maxStars: value));
                },
                decoration: const InputDecoration(
                  labelText: 'Max Stars',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Destruction percentage filter
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minDestructionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Destruction %',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxDestructionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Destruction %',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPositionFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minMapPositionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Min Position',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _maxMapPositionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Position',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Fresh Attacks Only'),
          subtitle: const Text('Only show first attacks on each base'),
          value: _filter.freshAttacksOnly ?? false,
          onChanged: (value) {
            _updateFilter(_filter.copyWith(freshAttacksOnly: value));
          },
        ),
        ListTile(
          title: const Text('Result Limit'),
          subtitle: Text('${_filter.limit} results'),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: _filter.limit.toDouble(),
              min: 10,
              max: 200,
              divisions: 19,
              onChanged: (value) {
                _updateFilter(_filter.copyWith(limit: value.toInt()));
              },
            ),
          ),
        ),
      ],
    );
  }
}
