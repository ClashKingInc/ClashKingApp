import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:clashkingapp/features/player/models/filter_preset.dart';
import 'package:clashkingapp/features/player/services/filter_preset_service.dart';
import 'package:clashkingapp/features/player/services/performance_analysis_service.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:intl/intl.dart';

class WarStatsFilterDialog extends StatefulWidget {
  final WarStatsFilter initialFilter;
  final Function(WarStatsFilter) onApply;
  final PlayerWarStats? warStats;

  const WarStatsFilterDialog({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.warStats,
  });

  @override
  State<WarStatsFilterDialog> createState() => _WarStatsFilterDialogState();
}

class _WarStatsFilterDialogState extends State<WarStatsFilterDialog> {
  late WarStatsFilter _filter;
  late TextEditingController _minMapPositionController;
  late TextEditingController _maxMapPositionController;
  late TextEditingController _limitController;

  // Track selected Town Hall levels for members and enemies
  Map<int, bool> attackerThSelection = {};
  Map<int, bool> defenderThSelection = {};

  // Track selected war types and stars
  Map<String, bool> warTypeSelection = {};
  Map<int, bool> starSelection = {};

  // Track season selection
  String? selectedSeason;
  int? selectedYear;
  int? selectedMonth;

  // Track collapsible sections
  bool _isAdvancedExpanded = false;
  bool _isTimeFiltersExpanded = false;
  bool _isWarSettingsExpanded = false;
  bool _isPerformanceExpanded = false;

  // Track All Time checkbox state
  bool _isAllTimeSelected = false;

  // Saved presets management
  List<FilterPreset> _savedPresets = [];
  bool _isLoadingPresets = false;

  // Performance analysis suggestions
  List<FilterPreset> _performanceSuggestions = [];

  // Inline message display
  String? _inlineMessage;
  bool _isInlineError = false;

  @override
  void initState() {
    super.initState();
    // Default the dialog to show "All" (10000) limit, even if initial filter uses 50
    _filter = widget.initialFilter.copyWith(
      limit: widget.initialFilter.limit == 50 ? 1000 : widget.initialFilter.limit,
    );
    _minMapPositionController = TextEditingController(
      text: _filter.minMapPosition?.toString() ?? '',
    );
    _maxMapPositionController = TextEditingController(
      text: _filter.maxMapPosition?.toString() ?? '',
    );
    _limitController = TextEditingController(
      text: _filter.limit == 10000 ? '' : _filter.limit.toString(),
    );

    // Initialize TH selections
    for (int i = 1; i <= GameDataService.getMaxTownHallLevel(); i++) {
      attackerThSelection[i] =
          _filter.ownTownHalls?.contains(i) ?? (_filter.ownTownHall == i);
      defenderThSelection[i] =
          _filter.enemyTownHalls?.contains(i) ?? (_filter.enemyTownHall == i);
    }

    // Initialize war type selections
    warTypeSelection = {
      'all': _filter.warTypes?.contains('all') ?? (_filter.warType == 'all'),
      'random':
          _filter.warTypes?.contains('random') ?? (_filter.warType == 'random'),
      'cwl': _filter.warTypes?.contains('cwl') ?? (_filter.warType == 'cwl'),
      'friendly': _filter.warTypes?.contains('friendly') ??
          (_filter.warType == 'friendly'),
    };

    // Initialize star selections
    for (int i = 0; i <= 3; i++) {
      starSelection[i] = _filter.allowedStars?.contains(i) ?? false;
    }

    // Initialize season selection
    selectedSeason = _filter.season;
    if (selectedSeason != null) {
      final parts = selectedSeason!.split('-');
      selectedYear = int.parse(parts[0]);
      selectedMonth = int.parse(parts[1]);
    }

    // Load saved presets
    _loadSavedPresets();

    // Performance suggestions will be generated in didChangeDependencies

    // Initialize All Time state based on current filter
    _isAllTimeSelected = _filter.startDate == null &&
        _filter.endDate == null &&
        _filter.season == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Generate performance analysis suggestions
    if (widget.warStats != null && _performanceSuggestions.isEmpty) {
      _performanceSuggestions = PerformanceAnalysisService.analyzePerformance(
        widget.warStats!,
        localizations: AppLocalizations.of(context),
      );
    }
  }

  @override
  void dispose() {
    _minMapPositionController.dispose();
    _maxMapPositionController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  /// Load saved filter presets
  Future<void> _loadSavedPresets() async {
    setState(() {
      _isLoadingPresets = true;
    });

    try {
      final presets = await FilterPresetService.instance.getPresets();
      setState(() {
        _savedPresets = presets;
        _isLoadingPresets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPresets = false;
      });
    }
  }

  /// Show inline error message in the dialog
  void _showInlineError(String message) {
    setState(() {
      _inlineMessage = message;
      _isInlineError = true;
    });
    // Auto-clear after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
          _isInlineError = false;
        });
      }
    });
  }

  /// Show inline success message in the dialog
  void _showInlineSuccess(String message) {
    setState(() {
      _inlineMessage = message;
      _isInlineError = false;
    });
    // Auto-clear after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
          _isInlineError = false;
        });
      }
    });
  }

  /// Clear inline message
  void _clearInlineMessage() {
    setState(() {
      _inlineMessage = null;
      _isInlineError = false;
    });
  }

  /// Show dialog to save current filter as preset
  Future<void> _showSavePresetDialog() async {
    if (!_filter.hasActiveFilters()) {
      _showInlineError(AppLocalizations.of(context)!.presetsApplyFirst);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SavePresetDialog(
        filter: _filter,
      ),
    );
    
    // Only show success message and reload if preset was actually saved
    if (result != null && context.mounted) {
      _showInlineSuccess(AppLocalizations.of(context)!.presetsSaveSuccess(result));
      await _loadSavedPresets();
    }
  }

  /// Apply a saved preset
  Future<void> _applySavedPreset(FilterPreset preset) async {
    setState(() {
      _filter = preset.filter;

      // Update UI state to match the preset filter
      attackerThSelection.clear();
      defenderThSelection.clear();
      warTypeSelection.clear();
      starSelection.clear();

      // Initialize TH selections
      for (int i = 1; i <= GameDataService.getMaxTownHallLevel(); i++) {
        attackerThSelection[i] =
            _filter.ownTownHalls?.contains(i) ?? (_filter.ownTownHall == i);
        defenderThSelection[i] =
            _filter.enemyTownHalls?.contains(i) ?? (_filter.enemyTownHall == i);
      }

      // Initialize war type selections
      final savedWarTypes = _filter.warTypes ?? [];
      final isAllWars = savedWarTypes.isEmpty;

      warTypeSelection['all'] = isAllWars;
      warTypeSelection['cwl'] = savedWarTypes.contains('cwl');
      warTypeSelection['random'] = savedWarTypes.contains('random');
      warTypeSelection['friendly'] = savedWarTypes.contains('friendly');

      // Initialize star selections
      for (int i = 0; i <= 3; i++) {
        starSelection[i] = _filter.allowedStars?.contains(i) ?? false;
      }

      // Initialize season selection
      selectedSeason = _filter.season;
      if (selectedSeason != null) {
        final parts = selectedSeason!.split('-');
        selectedYear = int.parse(parts[0]);
        selectedMonth = int.parse(parts[1]);
      } else {
        selectedYear = null;
        selectedMonth = null;
      }

      // Update text controllers
      _minMapPositionController.text = _filter.minMapPosition?.toString() ?? '';
      _maxMapPositionController.text = _filter.maxMapPosition?.toString() ?? '';
    });
  }

  void _updateFilter(WarStatsFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  void _resetFilters() {
    setState(() {
      _filter = WarStatsFilter.defaultFilter();
      _minMapPositionController.clear();
      _maxMapPositionController.clear();

      // Reset All Time state
      _isAllTimeSelected = true;

      // Reset TH selections
      for (int i = 1; i <= GameDataService.getMaxTownHallLevel(); i++) {
        attackerThSelection[i] = false;
        defenderThSelection[i] = false;
      }

      // Reset war type selections (default to 'all')
      warTypeSelection = {
        'all': true,
        'random': false,
        'cwl': false,
        'friendly': false,
      };

      // Reset star selections
      for (int i = 0; i <= 3; i++) {
        starSelection[i] = false;
      }

      // Reset season selection
      selectedSeason = null;
      selectedYear = null;
      selectedMonth = null;

      // Reset destruction range and limit
      _filter = _filter.copyWith(
        minDestruction: null, 
        maxDestruction: null, 
        limit: null,
        startDate: null,
        endDate: null,
        season: null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.generalFilters ??
                        'War Stats Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inline message display
                    if (_inlineMessage != null) 
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isInlineError 
                              ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.8)
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isInlineError 
                                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isInlineError ? Icons.error_outline : Icons.check_circle_outline,
                              color: _isInlineError 
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _inlineMessage!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _isInlineError 
                                      ? Theme.of(context).colorScheme.onErrorContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _clearInlineMessage,
                              icon: Icon(
                                Icons.close,
                                color: _isInlineError 
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    // Preset Filters
                    _buildPresetFilters(),

                    // Time Filters Card (Collapsible)
                    _buildCollapsibleSectionCard(
                      title: AppLocalizations.of(context)?.filtersTimeFilters ??
                          'Time Filters',
                      icon: Icons.schedule,
                      isExpanded: _isTimeFiltersExpanded,
                      onToggle: () {
                        setState(() {
                          _isTimeFiltersExpanded = !_isTimeFiltersExpanded;
                        });
                      },
                      child: Column(
                        children: [
                          _buildSubsectionTitle(
                              AppLocalizations.of(context)?.filtersSeason ??
                                  'Season'),
                          _buildSeasonSelector(),
                          const SizedBox(height: 16),
                          _buildSubsectionTitle(
                              AppLocalizations.of(context)?.filtersDateRange ??
                                  'Date Range'),
                          _buildDateRangePicker(),
                        ],
                      ),
                    ),

                    // War Settings Card (Collapsible)
                    _buildCollapsibleSectionCard(
                      title: AppLocalizations.of(context)?.filtersWarSettings ??
                          'War Settings',
                      icon: Icons.military_tech,
                      isExpanded: _isWarSettingsExpanded,
                      onToggle: () {
                        setState(() {
                          _isWarSettingsExpanded = !_isWarSettingsExpanded;
                        });
                      },
                      child: Column(
                        children: [
                          _buildSubsectionTitle(
                              AppLocalizations.of(context)?.filtersWarType ??
                                  'War Type'),
                          _buildWarTypeDropdown(),
                          const SizedBox(height: 16),
                          _buildSubsectionTitle(
                              AppLocalizations.of(context)?.filtersTownHall ??
                                  'Town Hall'),
                          _buildTownHallFilters(),
                        ],
                      ),
                    ),

                    // Performance Card (Collapsible)
                    _buildCollapsibleSectionCard(
                      title: AppLocalizations.of(context)?.filtersPerformance ??
                          'Performance',
                      icon: Icons.star,
                      isExpanded: _isPerformanceExpanded,
                      onToggle: () {
                        setState(() {
                          _isPerformanceExpanded = !_isPerformanceExpanded;
                        });
                      },
                      child: _buildPerformanceFilters(),
                    ),

                    // Advanced Card (Collapsible)
                    _buildCollapsibleSectionCard(
                      title: AppLocalizations.of(context)?.filtersAdvanced ??
                          'Advanced',
                      icon: Icons.settings,
                      isExpanded: _isAdvancedExpanded,
                      onToggle: () {
                        setState(() {
                          _isAdvancedExpanded = !_isAdvancedExpanded;
                        });
                      },
                      child: Column(
                        children: [
                          _buildSubsectionTitle(
                              AppLocalizations.of(context)?.warPositionMap ??
                                  'Map Position'),
                          _buildMapPositionFilters(),
                          const SizedBox(height: 16),
                          _buildSubsectionTitle(
                              AppLocalizations.of(context)?.filtersOptions ??
                                  'Options'),
                          _buildAdvancedOptions(),
                        ],
                      ),
                    ),
                    // Performance Analysis Suggestions
                    if (_performanceSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!
                                .performanceAnalysisSuggestions,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .performanceAnalysisSuggestions),
                                    content: Text(AppLocalizations.of(context)!
                                        .performanceAnalysisTooltip),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(AppLocalizations.of(context)
                                                ?.generalOk ??
                                            'OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _performanceSuggestions
                            .map((suggestion) =>
                                _buildPerformanceSuggestionChip(suggestion))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer with action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row with Reset button
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                            AppLocalizations.of(context)?.generalReset ??
                                'Reset'),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Second row with Cancel and Apply buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                            AppLocalizations.of(context)?.generalCancel ??
                                'Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Get selected TH levels
                          final selectedAttackerTH = attackerThSelection.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList();
                          final selectedDefenderTH = defenderThSelection.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList();

                          // Get selected war types
                          final selectedWarTypes = warTypeSelection.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList();

                          // Get selected stars
                          final selectedStars = starSelection.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList();

                          // Update filter with all selections
                          final DateTime? finalStartDate = _isAllTimeSelected ? null : _filter.startDate;
                          final DateTime? finalEndDate = _isAllTimeSelected ? null : _filter.endDate;
                          final String? finalSeason = _isAllTimeSelected ? null : selectedSeason;
                          
                          final updatedFilter = _filter.copyWith(
                            season: finalSeason,
                            startDate: finalStartDate,
                            endDate: finalEndDate,
                            clearStartDate: _isAllTimeSelected,
                            clearEndDate: _isAllTimeSelected,
                            clearSeason: _isAllTimeSelected,
                            ownTownHalls: selectedAttackerTH.isNotEmpty
                                ? selectedAttackerTH
                                : null,
                            enemyTownHalls: selectedDefenderTH.isNotEmpty
                                ? selectedDefenderTH
                                : null,
                            warTypes: selectedWarTypes.isNotEmpty &&
                                    !selectedWarTypes.contains('all')
                                ? selectedWarTypes
                                : null,
                            allowedStars:
                                selectedStars.isNotEmpty ? selectedStars : null,
                            minDestruction: _filter.minDestruction,
                            maxDestruction: _filter.maxDestruction,
                            minMapPosition: _minMapPositionController
                                    .text.isNotEmpty
                                ? int.tryParse(_minMapPositionController.text)
                                : null,
                            maxMapPosition: _maxMapPositionController
                                    .text.isNotEmpty
                                ? int.tryParse(_maxMapPositionController.text)
                                : null,
                            limit: _filter.limit,
                          );

                          widget.onApply(updatedFilter);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                            AppLocalizations.of(context)?.generalApply ??
                                'Apply',
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    final bool isAllTime = _isAllTimeSelected;

    return Column(
      children: [
        // Date range pickers
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: isAllTime
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _filter.startDate ??
                              DateTime.now()
                                  .subtract(const Duration(days: 180)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          // Clear season when setting specific dates
                          setState(() {
                            _isAllTimeSelected = false;
                            selectedSeason = null;
                            selectedYear = null;
                            selectedMonth = null;
                          });
                          _updateFilter(_filter.copyWith(startDate: picked));
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(
                            alpha: (isAllTime || selectedSeason != null)
                                ? 0.1
                                : 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: isAllTime
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)?.filtersStartDate ??
                                'Start Date',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                          alpha: (isAllTime ||
                                                  selectedSeason != null)
                                              ? 0.4
                                              : 0.8),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAllTime
                            ? (AppLocalizations.of(context)?.generalAll ??
                                'All Time')
                            : (selectedSeason != null
                                ? (AppLocalizations.of(context)
                                        ?.filtersSeason ??
                                    'Season Selected')
                                : (_filter.startDate != null
                                        ? _formatDate(_filter.startDate!) :
                                    (AppLocalizations.of(context)
                                            ?.generalNotSet ??
                                        'Not set'))),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isAllTime
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6)
                                  : null,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: isAllTime
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _filter.endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          // Clear season when setting specific dates
                          setState(() {
                            _isAllTimeSelected = false;
                            selectedSeason = null;
                            selectedYear = null;
                            selectedMonth = null;
                          });
                          _updateFilter(_filter.copyWith(endDate: picked));
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(
                            alpha: (isAllTime || selectedSeason != null)
                                ? 0.1
                                : 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: isAllTime
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)?.filtersEndDate ??
                                'End Date',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                          alpha: (isAllTime ||
                                                  selectedSeason != null)
                                              ? 0.4
                                              : 0.8),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAllTime
                            ? (AppLocalizations.of(context)?.generalAll ??
                                'All Time')
                            : (selectedSeason != null
                                ? (AppLocalizations.of(context)
                                        ?.filtersSeason ??
                                    'Season Selected')
                                : (_filter.endDate != null
                                        ? _formatDate(_filter.endDate!) :
                                    (AppLocalizations.of(context)
                                            ?.generalNotSet ??
                                        'Not set'))),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isAllTime
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6)
                                  : null,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // All Time option
        InkWell(
          onTap: () {
            if (!isAllTime) {
              // When checking, clear dates and season for all time, and set limit to All
              setState(() {
                _isAllTimeSelected = true;
                selectedSeason = null;
                selectedYear = null;
                selectedMonth = null;
              });
              _limitController.text = '';
              final newFilter = _filter.copyWith(
                startDate: null,
                endDate: null,
                season: null,
                limit: 10000, // Set to "All" when All Time is selected
                clearStartDate: true,
                clearEndDate: true,
                clearSeason: true,
              );
              _updateFilter(newFilter);
            } else {
              // When unchecking, set to default date range (last 180 days)
              setState(() {
                _isAllTimeSelected = false;
                selectedSeason = null;
                selectedYear = null;
                selectedMonth = null;
              });
              _limitController.text = '1000';
              _updateFilter(_filter.copyWith(
                startDate: DateTime.now().subtract(const Duration(days: 180)),
                endDate: DateTime.now(),
                season: null,
                limit: 1000, // Set back to default limit
              ));
            }
          },
          child: Row(
            children: [
              Checkbox(
                value: isAllTime,
                onChanged: (value) {

                  if (value == true) {
                    // When checking, clear dates and season for all time
                    setState(() {
                      _isAllTimeSelected = true;
                      selectedSeason = null;
                      selectedYear = null;
                      selectedMonth = null;
                    });
                    _limitController.text = '';
                    _updateFilter(_filter.copyWith(
                      startDate: null,
                      endDate: null,
                      season: null,
                      limit: 10000, // Set to "All" when All Time is selected
                      clearStartDate: true,
                      clearEndDate: true,
                      clearSeason: true,
                    ));
                  } else if (value == false) {
                    // When unchecking, set to default date range (last 180 days)
                    setState(() {
                      _isAllTimeSelected = false;
                      selectedSeason = null;
                      selectedYear = null;
                      selectedMonth = null;
                    });
                    _limitController.text = '1000';
                    _updateFilter(_filter.copyWith(
                      startDate:
                          DateTime.now().subtract(const Duration(days: 180)),
                      endDate: DateTime.now(),
                      season: null,
                      limit: 1000, // Set back to default limit
                    ));
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.generalAllTime ?? 'All Time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarTypeDropdown() {
    final warTypeOptions = [
      {
        'value': 'all',
        'label': AppLocalizations.of(context)!.filtersAllWars,
        'icon': Icons.all_inclusive
      },
      {
        'value': 'random',
        'label': AppLocalizations.of(context)!.warFiltersRandom,
        'icon': Icons.shuffle
      },
      {
        'value': 'cwl',
        'label': AppLocalizations.of(context)!.cwlTitle,
        'icon': Icons.emoji_events
      },
      {
        'value': 'friendly',
        'label': AppLocalizations.of(context)!.warFiltersFriendly,
        'icon': Icons.handshake
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: warTypeOptions.map((option) {
        final value = option['value'] as String;
        final isSelected = warTypeSelection[value] ?? false;

        return FilterChip(
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              warTypeSelection[value] = selected;

              // If "All Wars" is selected, deselect others
              if (value == 'all' && selected) {
                warTypeSelection.updateAll((key, value) => key == 'all');
              }
              // If any specific war type is selected, deselect "All Wars"
              else if (value != 'all' && selected) {
                warTypeSelection['all'] = false;
              }
              // If all specific types are deselected, select "All Wars"
              else if (!selected && !warTypeSelection.values.any((v) => v)) {
                warTypeSelection['all'] = true;
              }
            });
          },
          avatar: Icon(
            option['icon'] as IconData,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
          label: Text(
            option['label'] as String,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          selectedColor: Theme.of(context).colorScheme.secondaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildTownHallFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.filtersAttackerTh ?? 'Attacker TH',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4.0,
          runSpacing: 4.0,
          children: attackerThSelection.keys.map((thLevel) {
            return FilterChip(
              showCheckmark: false,
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              labelPadding: const EdgeInsets.all(0),
              label: MobileWebImage(
                imageUrl: ImageAssets.townHall(thLevel),
                height: 24,
              ),
              selected: attackerThSelection[thLevel]!,
              onSelected: (bool selected) {
                setState(() {
                  attackerThSelection[thLevel] = selected;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)?.filtersDefenderTh ?? 'Defender TH',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4.0,
          runSpacing: 4.0,
          children: defenderThSelection.keys.map((thLevel) {
            return FilterChip(
              showCheckmark: false,
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              labelPadding: const EdgeInsets.all(0),
              label: MobileWebImage(
                imageUrl: ImageAssets.townHall(thLevel),
                height: 24,
              ),
              selected: defenderThSelection[thLevel]!,
              onSelected: (bool selected) {
                setState(() {
                  defenderThSelection[thLevel] = selected;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _filter.sameTownHall,
              onChanged: (value) {
                _updateFilter(_filter.copyWith(sameTownHall: value ?? false));
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.filtersSameTownHallOnly ??
                    'Same Town Hall Only',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceFilters() {
    return Column(
      children: [
        // Stars filter with chips
        Text(
          AppLocalizations.of(context)?.warStarsTitle ?? 'Stars',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [0, 1, 2, 3].map((stars) {
            final isSelected = starSelection[stars] ?? false;
            return StarFilterChip(
              stars: stars,
              isSelected: isSelected,
              onTap: (selected) {
                setState(() {
                  starSelection[stars] = selected;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // Destruction percentage filter
        _buildDestructionSlider(),
      ],
    );
  }

  Widget _buildDestructionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.filtersDestructionPercentage ??
              'Destruction Percentage',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(
            _filter.minDestruction ?? 0,
            _filter.maxDestruction ?? 100,
          ),
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '${(_filter.minDestruction ?? 0).toInt()}%',
            '${(_filter.maxDestruction ?? 100).toInt()}%',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _updateFilter(_filter.copyWith(
                minDestruction: values.start,
                maxDestruction: values.end,
              ));
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_filter.minDestruction ?? 0).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${(_filter.maxDestruction ?? 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _minMapPositionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Max',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _maxMapPositionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonSelector() {
    final months = _generateMonths();
    final bool isDisabled = _isAllTimeSelected;

    // Get display text for the current selection
    String displayText;
    if (isDisabled) {
      displayText = AppLocalizations.of(context)!.generalAll;
    } else if (selectedYear != null && selectedMonth != null) {
      final monthName = months[selectedMonth!] ?? selectedMonth.toString();
      displayText = '$monthName $selectedYear';
    } else if (selectedYear != null) {
      displayText = selectedYear.toString();
    } else if (selectedMonth != null) {
      final monthName = months[selectedMonth!] ?? selectedMonth.toString();
      displayText = monthName;
    } else {
      displayText = AppLocalizations.of(context)!.generalAll;
    }

    return InkWell(
      onTap: isDisabled ? null : () => _showSeasonPicker(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: isDisabled ? 0.1 : 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: isDisabled 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.filtersSeason ?? 'Season',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: isDisabled ? 0.4 : 0.8),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDisabled 
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                              : null,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: isDisabled ? 0.3 : 0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeasonPicker() {
    final years = _generateYears();
    final months = _generateMonths();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)?.filtersSelectYear ??
                          'Select Season',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Year Selection
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  AppLocalizations.of(context)?.filtersYear ??
                                      'Year',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  children: [
                                    ListTile(
                                      title: Text(AppLocalizations.of(context)!
                                          .generalAll),
                                      selected: selectedYear == null,
                                      onTap: () {
                                        setState(() {
                                          _isAllTimeSelected = false;
                                          selectedYear = null;
                                          _updateSeasonString();
                                          // Clear date range when selecting season
                                          _updateFilter(_filter.copyWith(
                                              startDate: null, endDate: null));
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                    ...years.map((year) => ListTile(
                                          title: Text(year.toString()),
                                          selected: selectedYear == year,
                                          onTap: () {
                                            setState(() {
                                              _isAllTimeSelected = false;
                                              selectedYear = year;
                                              _updateSeasonString();
                                              // Clear date range when selecting season
                                              _updateFilter(_filter.copyWith(
                                                  startDate: null,
                                                  endDate: null));
                                            });
                                            setModalState(() {});
                                          },
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                        // Month Selection
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  AppLocalizations.of(context)?.filtersMonth ??
                                      'Month',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  children: [
                                    ListTile(
                                      title: Text(AppLocalizations.of(context)!
                                          .generalAll),
                                      selected: selectedMonth == null,
                                      onTap: () {
                                        setState(() {
                                          _isAllTimeSelected = false;
                                          selectedMonth = null;
                                          _updateSeasonString();
                                          // Clear date range when selecting season
                                          _updateFilter(_filter.copyWith(
                                              startDate: null, endDate: null));
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                    ...months.entries.map((entry) => ListTile(
                                          title: Text(entry.value),
                                          selected: selectedMonth == entry.key,
                                          onTap: () {
                                            setState(() {
                                              _isAllTimeSelected = false;
                                              selectedMonth = entry.key;
                                              _updateSeasonString();
                                              // Clear date range when selecting season
                                              _updateFilter(_filter.copyWith(
                                                  startDate: null,
                                                  endDate: null));
                                            });
                                            setModalState(() {});
                                          },
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                              AppLocalizations.of(context)?.generalCancel ??
                                  'Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                              AppLocalizations.of(context)?.generalOk ?? 'OK'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Format date for display using localized format
  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.toString()).format(date);
  }

  void _updateSeasonString() {
    if (selectedYear != null && selectedMonth != null) {
      selectedSeason =
          '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
    } else {
      selectedSeason = null;
    }
  }

  List<int> _generateYears() {
    final now = DateTime.now();
    final years = <int>[];

    // Generate last 3 years
    for (int i = 0; i < 3; i++) {
      years.add(now.year - i);
    }

    return years;
  }

  Map<int, String> _generateMonths() {
    final dateFormat =
        DateFormat.MMMM(Localizations.localeOf(context).languageCode);
    return {
      1: dateFormat.format(DateTime(2024, 1, 1)),
      2: dateFormat.format(DateTime(2024, 2, 1)),
      3: dateFormat.format(DateTime(2024, 3, 1)),
      4: dateFormat.format(DateTime(2024, 4, 1)),
      5: dateFormat.format(DateTime(2024, 5, 1)),
      6: dateFormat.format(DateTime(2024, 6, 1)),
      7: dateFormat.format(DateTime(2024, 7, 1)),
      8: dateFormat.format(DateTime(2024, 8, 1)),
      9: dateFormat.format(DateTime(2024, 9, 1)),
      10: dateFormat.format(DateTime(2024, 10, 1)),
      11: dateFormat.format(DateTime(2024, 11, 1)),
      12: dateFormat.format(DateTime(2024, 12, 1)),
    };
  }

  Widget _buildAdvancedOptions() {
    return Column(
      children: [
        // Fresh Attacks Only
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _filter.freshAttacksOnly ?? false,
              onChanged: (value) {
                _updateFilter(_filter.copyWith(freshAttacksOnly: value));
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.filtersFreshAttacksOnly ??
                    'Fresh Attacks Only',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                softWrap: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Result Limit
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)?.filtersResultLimit ??
                      'Result Limit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filter.limit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // All results checkbox
            InkWell(
              onTap: () {
                if (_filter.limit == 10000) {
                  // When unchecking, set to default
                  _limitController.text = '1000';
                  _updateFilter(_filter.copyWith(limit: 1000));
                } else {
                  // When checking, set to 10000 (All)
                  _limitController.text = '';
                  _updateFilter(_filter.copyWith(limit: 10000));
                }
              },
              child: Row(
                children: [
                  Checkbox(
                    value: _filter.limit == 10000,
                    onChanged: (value) {
                      if (value == true) {
                        _limitController.text = '';
                        _updateFilter(_filter.copyWith(limit: 10000));
                      } else {
                        _limitController.text = '1000';
                        _updateFilter(_filter.copyWith(limit: 1000));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.generalAll ?? 'All Results',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
            if (_filter.limit != 10000) ...[
              const SizedBox(height: 8),
              // Text input field for direct entry
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _limitController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.filtersResultLimit ?? 'Result Limit',
                        hintText: '1000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final intValue = int.tryParse(value);
                          if (intValue != null && intValue >= 1 && intValue <= 9999) {
                            _updateFilter(_filter.copyWith(limit: intValue));
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Slider(
                      value: _filter.limit.toDouble().clamp(10, 9999),
                      min: 10,
                      max: 9999,
                      divisions: 100,
                      onChanged: (value) {
                        final intValue = value.toInt();
                        _limitController.text = intValue.toString();
                        _updateFilter(_filter.copyWith(limit: intValue));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPresetFilters() {
    final builtInPresets = [
      {
        'label': AppLocalizations.of(context)!.filtersLast30Days,
        'icon': Icons.schedule,
        'preset': 'last30days'
      },
      {
        'label': AppLocalizations.of(context)!.filters3StarOnly,
        'icon': Icons.star,
        'preset': '3star'
      },
      {
        'label': AppLocalizations.of(context)!.cwlTitle,
        'icon': Icons.emoji_events,
        'preset': 'cwl'
      },
      {
        'label': AppLocalizations.of(context)!.warFiltersRandom,
        'icon': Icons.shuffle,
        'preset': 'random'
      },
      {
        'label': AppLocalizations.of(context)!.warFiltersFriendly,
        'icon': Icons.handshake,
        'preset': 'friendly'
      },
      {
        'label': AppLocalizations.of(context)!.filtersFreshAttacks,
        'icon': Icons.new_releases,
        'preset': 'fresh'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Filters Header
        Row(
          children: [
            Icon(
              Icons.flash_on,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)?.filtersQuickFilters ??
                  'Quick Filters',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const Spacer(),
            // Save Current Filter Button
            if (_filter.hasActiveFilters())
              TextButton.icon(
                onPressed: _showSavePresetDialog,
                icon: Icon(Icons.bookmark_add,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                label: Text(AppLocalizations.of(context)!.presetsSave),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Built-in Quick Filters
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              builtInPresets.map((preset) => _buildPresetChip(preset)).toList(),
        ),

        // Saved Presets Section
        if (_savedPresets.isNotEmpty || _isLoadingPresets) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.bookmark,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.presetsSaved,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingPresets)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _savedPresets
                  .map((preset) => _buildSavedPresetChip(preset))
                  .toList(),
            ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPresetChip(Map<String, dynamic> preset) {
    final presetType = preset['preset'] as String;
    bool isActive = false;

    // Check if this preset is currently active
    switch (presetType) {
      case 'last30days':
        // Check if we have a 30-day range ending around today
        if (_filter.startDate != null && _filter.endDate != null) {
          final daysDiff =
              _filter.endDate!.difference(_filter.startDate!).inDays;
          final daysFromToday =
              DateTime.now().difference(_filter.endDate!).inDays.abs();
          // Consider active if it's approximately 30 days range and ends within 2 days of today
          isActive = daysDiff >= 28 && daysDiff <= 32 && daysFromToday <= 2;
        }
        break;
      case '3star':
        isActive = starSelection[3] == true &&
            starSelection[0] == false &&
            starSelection[1] == false &&
            starSelection[2] == false;
        break;
      case 'cwl':
        isActive = warTypeSelection['cwl'] == true &&
            warTypeSelection['all'] == false &&
            warTypeSelection['random'] == false &&
            warTypeSelection['friendly'] == false;
        break;
      case 'random':
        isActive = warTypeSelection['random'] == true &&
            warTypeSelection['all'] == false &&
            warTypeSelection['cwl'] == false &&
            warTypeSelection['friendly'] == false;
        break;
      case 'friendly':
        isActive = warTypeSelection['friendly'] == true &&
            warTypeSelection['all'] == false &&
            warTypeSelection['random'] == false &&
            warTypeSelection['cwl'] == false;
        break;
      case 'fresh':
        isActive = _filter.freshAttacksOnly == true;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isActive) {
          _clearPreset(preset['preset']);
        } else {
          _applyPreset(preset['preset']);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              preset['icon'],
              size: 16,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              preset['label'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPresetChip(FilterPreset preset) {
    // Check if this saved preset matches the current filter state
    final isActive = _isPresetActive(preset);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isActive) {
          _clearSavedPreset(preset);
        } else {
          _applySavedPreset(preset);
        }
      },
      onLongPress: () {
        _showPresetContextMenu(preset);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark,
              size: 16,
              color: isActive
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  preset.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                  maxLines: null,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSuggestionChip(FilterPreset suggestion) {
    final metadata = suggestion.filter.metadata ?? {};
    final description = metadata['description'] as String? ?? '';

    // Check if this performance suggestion is currently active
    final isActive = _isPresetActive(suggestion);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isActive) {
          _clearSavedPreset(suggestion);
        } else {
          _applySavedPreset(suggestion);
        }
      },
      child: Tooltip(
        message: description.isNotEmpty ? description : suggestion.name,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: isActive
                    ? Theme.of(context).colorScheme.onTertiary
                    : Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    suggestion.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? Theme.of(context).colorScheme.onTertiary
                              : Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                    maxLines: null,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show context menu for preset management
  void _showPresetContextMenu(FilterPreset preset) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.presetsApply),
              onTap: () {
                Navigator.pop(context);
                final isActive = _isPresetActive(preset);
                if (isActive) {
                  _clearSavedPreset(preset);
                } else {
                  _applySavedPreset(preset);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.edit,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(AppLocalizations.of(context)!.presetsRename),
              onTap: () {
                Navigator.pop(context);
                _showRenamePresetDialog(preset);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.error),
              title: Text(AppLocalizations.of(context)!.presetsDelete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeletePresetDialog(preset);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to rename a preset
  Future<void> _showRenamePresetDialog(FilterPreset preset) async {
    final nameController = TextEditingController(text: preset.name);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.presetsRenameTitle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.presetsName,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.generalCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty || newName == preset.name) {
                Navigator.pop(context);
                return;
              }

              if (await FilterPresetService.instance
                      .presetNameExists(newName, excludeId: preset.id) &&
                  context.mounted) {
                _showInlineError(AppLocalizations.of(context)!.presetsNameExists);
                return;
              }

              final updatedPreset = preset.copyWith(name: newName);
              final success = await FilterPresetService.instance
                  .updatePreset(updatedPreset);

              if (context.mounted) {
                Navigator.pop(context);
              }

              if (success && context.mounted) {
                _showInlineSuccess(AppLocalizations.of(context)!.presetsRenameSuccess(newName));
                await _loadSavedPresets();
              } else {
                if (context.mounted) {
                  _showInlineError(AppLocalizations.of(context)!.presetsRenameError);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.presetsRename),
          ),
        ],
      ),
    );
  }

  /// Show dialog to confirm preset deletion
  Future<void> _showDeletePresetDialog(FilterPreset preset) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.presetsDeleteTitle),
        content: Text(
            AppLocalizations.of(context)!.presetsDeleteConfirm(preset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.generalCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await FilterPresetService.instance.deletePreset(preset.id);

              if (context.mounted) {
                Navigator.pop(context);
              }

              if (success && context.mounted) {
                _showInlineSuccess(AppLocalizations.of(context)!.presetsDeleteSuccess(preset.name));
                await _loadSavedPresets();
              } else {
                if (context.mounted) {
                  _showInlineError(AppLocalizations.of(context)!.presetsDeleteError);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(AppLocalizations.of(context)!.presetsDelete),
          ),
        ],
      ),
    );
  }

  void _removeFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'season':
          selectedSeason = null;
          selectedYear = null;
          selectedMonth = null;
          break;
        case 'dateRange':
        case 'startDate':
        case 'endDate':
          _updateFilter(_filter.copyWith(startDate: null, endDate: null));
          break;
        case 'attackerTH':
          attackerThSelection.updateAll((key, value) => false);
          break;
        case 'defenderTH':
          defenderThSelection.updateAll((key, value) => false);
          break;
        case 'warType':
          warTypeSelection = {
            'all': true,
            'random': false,
            'cwl': false,
            'friendly': false
          };
          break;
        case 'stars':
          starSelection.updateAll((key, value) => false);
          break;
        case 'destruction':
          _updateFilter(
              _filter.copyWith(minDestruction: null, maxDestruction: null));
          break;
        case 'fresh':
          _updateFilter(_filter.copyWith(freshAttacksOnly: null));
          break;
        case 'sameTH':
          _updateFilter(_filter.copyWith(sameTownHall: false));
          break;
      }
    });
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'last30days':
          _updateFilter(_filter.copyWith(
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
          ));
          break;
        case '3star':
          starSelection = {0: false, 1: false, 2: false, 3: true};
          break;
        case 'cwl':
          warTypeSelection = {
            'all': false,
            'random': false,
            'cwl': true,
            'friendly': false
          };
          break;
        case 'random':
          warTypeSelection = {
            'all': false,
            'random': true,
            'cwl': false,
            'friendly': false
          };
          break;
        case 'friendly':
          warTypeSelection = {
            'all': false,
            'random': false,
            'cwl': false,
            'friendly': true
          };
          break;
        case 'fresh':
          _updateFilter(_filter.copyWith(freshAttacksOnly: true));
          break;
      }
    });
  }

  void _clearPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'last30days':
          _updateFilter(_filter.copyWith(
              startDate: DateTime.now().subtract(const Duration(days: 180)),
              endDate: DateTime.now()));
          break;
        case '3star':
          starSelection = {0: false, 1: false, 2: false, 3: false};
          break;
        case 'cwl':
        case 'random':
        case 'friendly':
          warTypeSelection = {
            'all': true,
            'random': false,
            'cwl': false,
            'friendly': false
          };
          break;
        case 'fresh':
          _updateFilter(_filter.copyWith(freshAttacksOnly: false));
          break;
      }
    });
  }

  Widget _buildCollapsibleSectionCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!isExpanded) ...[
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final sectionFilters =
                                    _getSectionActiveFilters(title);
                                if (sectionFilters.isEmpty) {
                                  return Text(
                                    AppLocalizations.of(context)
                                            ?.filtersNoFiltersActive ??
                                        'No filters active',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  );
                                } else {
                                  return Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: sectionFilters.map((filter) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              filter['text'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSecondaryContainer,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(width: 3),
                                            InkWell(
                                              onTap: () =>
                                                  _removeFilter(filter['type']),
                                              child: Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
            ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSectionActiveFilters(String sectionTitle) {
    List<Map<String, dynamic>> filters = [];

    // Get localized section titles for comparison
    final timeFilters =
        AppLocalizations.of(context)?.filtersTimeFilters ?? 'Time Filters';
    final warSettings =
        AppLocalizations.of(context)?.filtersWarSettings ?? 'War Settings';
    final performance =
        AppLocalizations.of(context)?.filtersPerformance ?? 'Performance';
    final advanced =
        AppLocalizations.of(context)?.filtersAdvanced ?? 'Advanced';

    if (sectionTitle == timeFilters) {
      if (selectedSeason != null) {
        // Format season as readable month/year
        String seasonText = '';
        if (selectedYear != null && selectedMonth != null) {
          final months = _generateMonths();
          final monthName = months[selectedMonth!] ?? selectedMonth.toString();
          seasonText = '$monthName $selectedYear';
        } else {
          seasonText = selectedSeason!;
        }
        filters.add({'type': 'season', 'text': seasonText});
      }
      if (_filter.startDate != null && _filter.endDate != null) {
        final start = _formatDate(_filter.startDate!);
        final end = _formatDate(_filter.endDate!);
        filters.add({'type': 'dateRange', 'text': '$start - $end'});
      } else if (_filter.startDate != null) {
        final start = _formatDate(_filter.startDate!);
        filters.add({
          'type': 'startDate',
          'text':
              '${AppLocalizations.of(context)?.filtersStartDate ?? 'From'} $start'
        });
      } else if (_filter.endDate != null) {
        final end = _formatDate(_filter.endDate!);
        filters.add({
          'type': 'endDate',
          'text':
              '${AppLocalizations.of(context)?.filtersEndDate ?? 'Until'} $end'
        });
      }
    } else if (sectionTitle == warSettings) {
      if (warTypeSelection.values.any((selected) => selected) &&
          !(warTypeSelection['all'] == true)) {
        final selectedTypes = warTypeSelection.entries
            .where((entry) => entry.value && entry.key != 'all')
            .map((entry) => entry.key.toUpperCase())
            .join(', ');
        if (selectedTypes.isNotEmpty) {
          filters.add({
            'type': 'warType',
            'text':
                '$selectedTypes ${AppLocalizations.of(context)?.filtersWarType ?? 'wars'}'
          });
        }
      }
      if (attackerThSelection.values.any((selected) => selected)) {
        final selectedTH = attackerThSelection.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key.toString())
            .join(', ');
        filters.add({
          'type': 'attackerTH',
          'text':
              '${AppLocalizations.of(context)?.filtersAttackerTh ?? 'Attacker TH'}$selectedTH'
        });
      }
      if (defenderThSelection.values.any((selected) => selected)) {
        final selectedTH = defenderThSelection.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key.toString())
            .join(', ');
        filters.add({
          'type': 'defenderTH',
          'text':
              '${AppLocalizations.of(context)?.filtersDefenderTh ?? 'Defender TH'}$selectedTH'
        });
      }
      if (_filter.sameTownHall == true) {
        filters.add({
          'type': 'sameTH',
          'text': AppLocalizations.of(context)?.filtersSameTownHallOnly ??
              'Same TH only'
        });
      }
    } else if (sectionTitle == performance) {
      if (starSelection.values.any((selected) => selected)) {
        final selectedStars = starSelection.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key.toString())
            .join(', ');
        filters.add({
          'type': 'stars',
          'text':
              '$selectedStars ${AppLocalizations.of(context)?.warStarsTitle ?? '⭐'}'
        });
      }
      if ((_filter.minDestruction != null && _filter.minDestruction! > 0) ||
          (_filter.maxDestruction != null && _filter.maxDestruction! < 100)) {
        final min = _filter.minDestruction ?? 0;
        final max = _filter.maxDestruction ?? 100;
        filters.add({
          'type': 'destruction',
          'text':
              '${min.toInt()}-${max.toInt()}% ${AppLocalizations.of(context)?.filtersDestructionPercentage ?? 'destruction'}'
        });
      }
    } else if (sectionTitle == advanced) {
      if (_filter.freshAttacksOnly == true) {
        filters.add({
          'type': 'fresh',
          'text': AppLocalizations.of(context)?.filtersFreshAttacksOnly ??
              'Fresh attacks only'
        });
      }
      if (_minMapPositionController.text.isNotEmpty ||
          _maxMapPositionController.text.isNotEmpty) {
        final min = _minMapPositionController.text.isNotEmpty
            ? _minMapPositionController.text
            : '1';
        final max = _maxMapPositionController.text.isNotEmpty
            ? _maxMapPositionController.text
            : '50';
        filters.add({
          'type': 'mapPosition',
          'text':
              '${AppLocalizations.of(context)?.warPositionMap ?? 'Position'} $min-$max'
        });
      }
    }

    return filters;
  }

  /// Check if a saved preset matches the current filter state
  bool _isPresetActive(FilterPreset preset) {
    // Build a filter from current UI state and compare with saved filter
    final currentFilter = _buildCurrentFilter();
    final savedFilter = preset.filter;

    // Compare the essential properties that make filters equivalent
    return _filtersAreEquivalent(currentFilter, savedFilter);
  }

  /// Build a filter object from the current UI state
  WarStatsFilter _buildCurrentFilter() {
    // Get selected war types
    final selectedWarTypes = warTypeSelection.entries
        .where((entry) => entry.value && entry.key != 'all')
        .map((entry) => entry.key)
        .toList();

    // Get selected stars
    final selectedStars = starSelection.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Get selected TH levels
    final selectedAttackerTH = attackerThSelection.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    final selectedDefenderTH = defenderThSelection.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Get map positions
    final minPos = _minMapPositionController.text.isNotEmpty
        ? int.tryParse(_minMapPositionController.text)
        : null;
    final maxPos = _maxMapPositionController.text.isNotEmpty
        ? int.tryParse(_maxMapPositionController.text)
        : null;

    return WarStatsFilter(
      season: selectedSeason,
      startDate: _filter.startDate,
      endDate: _filter.endDate,
      warTypes: warTypeSelection['all'] == true
          ? null
          : (selectedWarTypes.isEmpty ? null : selectedWarTypes),
      allowedStars: selectedStars.isEmpty ? null : selectedStars,
      ownTownHalls: selectedAttackerTH.isEmpty ? null : selectedAttackerTH,
      enemyTownHalls: selectedDefenderTH.isEmpty ? null : selectedDefenderTH,
      minMapPosition: minPos,
      maxMapPosition: maxPos,
      freshAttacksOnly: _filter.freshAttacksOnly,
      sameTownHall: _filter.sameTownHall,
      minDestruction: _filter.minDestruction,
      maxDestruction: _filter.maxDestruction,
      limit: _filter.limit,
    );
  }

  /// Check if two filters are functionally equivalent
  bool _filtersAreEquivalent(WarStatsFilter current, WarStatsFilter saved) {
    // Normalize war types (null/empty list both mean "all")
    final currentWarTypes = current.warTypes?.toSet() ?? <String>{};
    final savedWarTypes = saved.warTypes?.toSet() ?? <String>{};

    // Handle "all wars" case - both null/empty means all
    final currentIsAll = currentWarTypes.isEmpty;
    final savedIsAll = savedWarTypes.isEmpty;

    if (currentIsAll != savedIsAll) {
      return false;
    }
    // Use manual set comparison instead of == operator
    if (!currentIsAll && !_setsAreEqual(currentWarTypes, savedWarTypes)) {
      return false;
    }

    // Compare other list properties using manual set comparison
    final currentStars = current.allowedStars?.toSet() ?? <int>{};
    final savedStars = saved.allowedStars?.toSet() ?? <int>{};
    if (!_setsAreEqual(currentStars, savedStars)) {
      return false;
    }

    final currentAttackerTH = current.ownTownHalls?.toSet() ?? <int>{};
    final savedAttackerTH = saved.ownTownHalls?.toSet() ?? <int>{};
    if (!_setsAreEqual(currentAttackerTH, savedAttackerTH)) {
      return false;
    }

    final currentDefenderTH = current.enemyTownHalls?.toSet() ?? <int>{};
    final savedDefenderTH = saved.enemyTownHalls?.toSet() ?? <int>{};
    if (!_setsAreEqual(currentDefenderTH, savedDefenderTH)) {
      return false;
    }

    // Compare scalar properties one by one
    if (current.season != saved.season) {
      return false;
    }
    if (current.startDate != saved.startDate) {
      return false;
    }
    if (current.endDate != saved.endDate) {
      return false;
    }
    if (current.minMapPosition != saved.minMapPosition) {
      return false;
    }
    if (current.maxMapPosition != saved.maxMapPosition) {
      return false;
    }
    if (current.freshAttacksOnly != saved.freshAttacksOnly) {
      return false;
    }
    if (current.sameTownHall != saved.sameTownHall) {
      return false;
    }
    if (current.minDestruction != saved.minDestruction) {
      return false;
    }
    if (current.maxDestruction != saved.maxDestruction) {
      return false;
    }
    if (current.limit != saved.limit) {
      return false;
    }

    return true;
  }

  /// Helper method to compare sets manually (workaround for Set equality issues)
  bool _setsAreEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.every((element) => set2.contains(element));
  }

  /// Clear/reset a saved preset by resetting to default values
  void _clearSavedPreset(FilterPreset preset) {
    setState(() {
      // Reset to default filter state
      _filter = WarStatsFilter.defaultFilter();
      _minMapPositionController.clear();
      _maxMapPositionController.clear();

      // Reset TH selections
      for (int i = 1; i <= GameDataService.getMaxTownHallLevel(); i++) {
        attackerThSelection[i] = false;
        defenderThSelection[i] = false;
      }

      // Reset war type selections (default to 'all')
      warTypeSelection = {
        'all': true,
        'random': false,
        'cwl': false,
        'friendly': false,
      };

      // Reset star selections
      for (int i = 0; i <= 3; i++) {
        starSelection[i] = false;
      }

      // Reset season selection
      selectedSeason = null;
      selectedYear = null;
      selectedMonth = null;
    });
  }
}

class StarFilterChip extends StatelessWidget {
  final int stars;
  final bool isSelected;
  final Function(bool) onTap;

  const StarFilterChip({
    super.key,
    required this.stars,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(!isSelected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildStarsIcon(stars),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check,
                size: 12,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog for saving filter presets with inline error display
class _SavePresetDialog extends StatefulWidget {
  final WarStatsFilter filter;

  const _SavePresetDialog({
    required this.filter,
  });

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  final _nameController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _savePreset() async {
    final name = _nameController.text.trim();
    
    _clearError();
    
    if (name.isEmpty) {
      _showError(AppLocalizations.of(context)!.presetsNameRequired);
      return;
    }
    
    if (await FilterPresetService.instance.presetNameExists(name)) {
      if (!context.mounted) return;
      _showError(AppLocalizations.of(context)!.presetsNameExists);
      return;
    }

    final success = await FilterPresetService.instance.savePreset(
      name: name,
      filter: widget.filter,
    );

    if (!context.mounted) return;
    
    if (success) {
      Navigator.pop(context, name); // Return the preset name
    } else {
      _showError(AppLocalizations.of(context)!.presetsSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = FilterPresetService.getPresetNameSuggestions(widget.filter);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.presetsSaveTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.presetsName,
                hintText: AppLocalizations.of(context)!.presetsNameHint,
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _savePreset(),
              onChanged: (_) => _clearError(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.presetsSuggestions,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: suggestions.map((suggestion) {
                      return ActionChip(
                        label: Text(
                          suggestion,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2),
                        ),
                        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                        onPressed: () {
                          _nameController.text = suggestion;
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.generalCancel),
        ),
        ElevatedButton(
          onPressed: _savePreset,
          child: Text(AppLocalizations.of(context)!.presetsSave),
        ),
      ],
    );
  }
}

/// Dialog for renaming filter presets with inline error display
class _RenamePresetDialog extends StatefulWidget {
  final FilterPreset preset;

  const _RenamePresetDialog({
    required this.preset,
  });

  @override
  State<_RenamePresetDialog> createState() => _RenamePresetDialogState();
}

class _RenamePresetDialogState extends State<_RenamePresetDialog> {
  late TextEditingController _nameController;
  String? _inlineMessage;
  bool _isInlineError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showInlineError(String message) {
    setState(() {
      _inlineMessage = message;
      _isInlineError = true;
    });
    // Auto-clear after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
          _isInlineError = false;
        });
      }
    });
  }

  void _clearInlineMessage() {
    setState(() {
      _inlineMessage = null;
      _isInlineError = false;
    });
  }

  Future<void> _renamePreset() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.preset.name) {
      Navigator.pop(context);
      return;
    }

    if (await FilterPresetService.instance.presetNameExists(newName, excludeId: widget.preset.id) &&
        context.mounted) {
      _showInlineError(AppLocalizations.of(context)!.presetsNameExists);
      return;
    }

    final updatedPreset = widget.preset.copyWith(name: newName);
    final success = await FilterPresetService.instance.updatePreset(updatedPreset);

    if (context.mounted) {
      if (success) {
        Navigator.pop(context, newName); // Return the new preset name
      } else {
        _showInlineError(AppLocalizations.of(context)!.presetsRenameError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.presetsRenameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inline message display
          if (_inlineMessage != null) 
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isInlineError 
                    ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isInlineError 
                      ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isInlineError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _isInlineError 
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _inlineMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _isInlineError 
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _clearInlineMessage,
                    icon: Icon(
                      Icons.close,
                      color: _isInlineError 
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.presetsName,
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _renamePreset(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.generalCancel),
        ),
        ElevatedButton(
          onPressed: _renamePreset,
          child: Text(AppLocalizations.of(context)!.presetsRename),
        ),
      ],
    );
  }
}
