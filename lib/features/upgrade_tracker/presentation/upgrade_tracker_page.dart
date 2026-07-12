import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/collapsible_item_section.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_repository.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_widget_sync_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _trackerContentGutter = 28.0;

class UpgradeTrackerPage extends StatefulWidget {
  const UpgradeTrackerPage({super.key});

  @override
  State<UpgradeTrackerPage> createState() => _UpgradeTrackerPageState();
}

class _UpgradeTrackerPageState extends State<UpgradeTrackerPage> {
  final _repository = UpgradeTrackerRepository();
  final _widgetSync = const UpgradeWidgetSyncService();
  final _planLanes = ValueNotifier<List<UpgradePlanLane>>(const []);
  final _clock = ValueNotifier<DateTime>(DateTime.now());
  late final PageController _pageController;

  UpgradeTrackerSnapshot? _snapshot;
  Object? _error;
  String? _selectedTag;
  bool _loading = true;
  bool _initialized = false;
  int _section = 0;
  int _goldPassPercent = 0;
  UpgradePlanPreferences _planPreferences = const UpgradePlanPreferences();
  final _capturedAtByTag = <String, DateTime>{};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _section);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final snapshot = _snapshot;
      if (mounted &&
          snapshot != null &&
          (snapshot.items.any(
                (item) =>
                    snapshot.remainingActiveSeconds(item) > 0 ||
                    snapshot.remainingHelperSeconds(item) > 0 ||
                    snapshot.remainingCooldownSeconds(item) > 0,
              ) ||
              _activeBoostLabels(snapshot).isNotEmpty)) {
        _clock.value = DateTime.now();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final linkedTags = context.read<CocAccountService>().accounts;
    final initial = linkedTags.firstOrNull;
    unawaited(_loadSnapshotMetadata());
    if (initial == null) {
      setState(() => _loading = false);
    } else {
      _selectedTag = initial;
      _load(initial);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _planLanes.dispose();
    _clock.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadSnapshotMetadata() async {
    final accounts = await _repository.savedSnapshotAccounts();
    if (!mounted) return;
    setState(() {
      for (final account in accounts) {
        final capturedAt = DateTime.tryParse(account['capturedAt'] ?? '');
        if (capturedAt != null) {
          _capturedAtByTag[UpgradeTrackerRepository.normalizeTag(
                account['tag'] ?? '',
              )] =
              capturedAt;
        }
      }
    });
  }

  Future<void> _load(String tag) async {
    setState(() {
      _selectedTag = tag;
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _repository.load(tag);
      final draft = snapshot == null
          ? null
          : await _repository.loadPlanPreferences(snapshot.tag);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        if (snapshot != null) {
          _capturedAtByTag[UpgradeTrackerRepository.normalizeTag(
                snapshot.tag,
              )] =
              snapshot.capturedAt;
        }
        final detectedGoldPass = snapshot == null
            ? 0
            : [
                snapshot.boosts.builderCostReductionPercent,
                snapshot.boosts.builderTimeReductionPercent,
                snapshot.boosts.labCostReductionPercent,
                snapshot.boosts.labTimeReductionPercent,
              ].reduce((a, b) => a > b ? a : b);
        final savedGoldPass = draft?['gold_pass_percent'];
        final parsedGoldPass = savedGoldPass is num
            ? savedGoldPass.toInt()
            : int.tryParse(savedGoldPass?.toString() ?? '');
        _goldPassPercent = (parsedGoldPass ?? detectedGoldPass).clamp(0, 100);
        _planPreferences = UpgradePlanPreferences.fromJson(
          draft?['heuristics'] is Map
              ? Map<String, dynamic>.from(draft!['heuristics'] as Map)
              : null,
        );
      });
      _scheduleWidgetSync();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _snapshot = null;
        _loading = false;
      });
    }
  }

  Future<void> _importSnapshot() async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    try {
      final rawJson = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.upgradeTrackerImportTitle,
                          style: CKTypography.of(
                            sheetContext,
                            CKTextRole.screenTitle,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          sheetContext,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    l10n.upgradeTrackerImportDescription,
                    style: CKTypography.of(sheetContext, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(
                            sheetContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration:
                          InputDecoration(
                            labelText: l10n.upgradeTrackerAccountJson,
                            alignLabelWithHint: true,
                            hintText: '{"tag":"#...","buildings":[...]}',
                          ).copyWith(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(
                                  sheetContext,
                                ).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurface,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            sheetContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          controller.text = data?.text ?? '';
                        },
                        icon: const Icon(Icons.content_paste_rounded),
                        label: Text(l10n.upgradeTrackerPasteClipboard),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          sheetContext,
                        ).colorScheme.onSurface,
                        foregroundColor: Theme.of(
                          sheetContext,
                        ).colorScheme.surface,
                      ),
                      onPressed: () =>
                          Navigator.pop(sheetContext, controller.text.trim()),
                      child: Text(l10n.upgradeTrackerImportAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (rawJson == null || rawJson.isEmpty) return;
      await _importSnapshotBytes(utf8.encode(rawJson));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.upgradeTrackerImportFailed('$error'))),
      );
    } finally {
      // Modal route teardown finishes just after its result resolves. Keep the
      // controller alive through that animation so EditableText can detach.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      controller.dispose();
    }
  }

  Future<void> _pasteSnapshotFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    await _importSnapshotBytes(utf8.encode(data?.text?.trim() ?? ''));
  }

  Future<void> _importSnapshotBytes(List<int> bytes) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final linkedAccounts = _linkedAccountOptions();
      final linkedNames = {
        for (final account in linkedAccounts)
          UpgradeTrackerRepository.normalizeTag(account.tag): account.name,
      };
      final snapshot = await _repository.importSnapshotBytes(
        bytes,
        linkedNamesByTag: linkedNames,
        allowedTags: linkedNames.keys.toSet(),
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _selectedTag = snapshot.tag;
        _capturedAtByTag[UpgradeTrackerRepository.normalizeTag(snapshot.tag)] =
            snapshot.capturedAt;
        _loading = false;
        _error = null;
        _section = 0;
        _goldPassPercent = [
          snapshot.boosts.builderCostReductionPercent,
          snapshot.boosts.builderTimeReductionPercent,
          snapshot.boosts.labCostReductionPercent,
          snapshot.boosts.labTimeReductionPercent,
        ].reduce((a, b) => a > b ? a : b);
      });
      _planLanes.value = const [];
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _scheduleWidgetSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.upgradeTrackerImportSuccess(snapshot.name)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.upgradeTrackerImportFailed('$error'))),
      );
    }
  }

  void _scheduleWidgetSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        SchedulerBinding.instance.scheduleTask(_syncWidget, Priority.idle),
      );
    });
  }

  Future<void> _openClashMoreSettings() async {
    final uri = Uri.parse(
      'https://link.clashofclans.com/?action=OpenMoreSettings',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.accountsCouldNotOpenClash,
          ),
        ),
      );
    }
  }

  Future<void> _syncWidget() async {
    if (!mounted) return;
    final linkedAccounts = _linkedAccountOptions();
    final linkedTags = linkedAccounts.map((account) => account.tag);
    final snapshots = await _repository.loadSavedSnapshots(linkedTags);
    await _widgetSync.sync(
      snapshots,
      linkedAccounts: linkedAccounts
          .map(
            (account) => <String, Object?>{
              'tag': account.tag,
              'name': account.name,
              'townHallLevel': account.townHallLevel,
              'builderHallLevel': account.builderHallLevel,
            },
          )
          .toList(growable: false),
    );
  }

  List<_TrackerAccountOption> _linkedAccountOptions() {
    final linked = context.read<CocAccountService>().cocAccounts;
    final profiles = context.read<PlayerService>().profiles;
    final profilesByTag = {
      for (final player in profiles)
        UpgradeTrackerRepository.normalizeTag(player.tag): player,
    };
    return linked
        .map((raw) {
          final tag =
              raw['player_tag']?.toString() ?? raw['tag']?.toString() ?? '';
          final normalizedTag = UpgradeTrackerRepository.normalizeTag(tag);
          final profile = profilesByTag[normalizedTag];
          int readInt(Object? value) => switch (value) {
            final num number => number.toInt(),
            final String text => int.tryParse(text) ?? 0,
            _ => 0,
          };
          final townHall =
              profile?.townHallLevel ??
              (readInt(raw['townHallLevel']) > 0
                  ? readInt(raw['townHallLevel'])
                  : readInt(raw['town_hall_level']));
          final builderHall = readInt(raw['builderHallLevel']) > 0
              ? readInt(raw['builderHallLevel'])
              : readInt(raw['builder_hall_level']);
          final name = profile?.name.trim().isNotEmpty == true
              ? profile!.name
              : (raw['name']?.toString().trim().isNotEmpty == true
                    ? raw['name'].toString()
                    : 'Linked account');
          return _TrackerAccountOption(
            tag: tag,
            name: name,
            subtitle: [
              if (townHall > 0) 'TH$townHall',
              if (builderHall > 0) 'BH$builderHall',
            ].join(' · '),
            townHallLevel: townHall,
            builderHallLevel: builderHall,
            capturedAt: _capturedAtByTag[normalizedTag],
          );
        })
        .where((account) => account.tag.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    context.select<CocAccountService, int>(
      (service) => Object.hashAll(
        service.cocAccounts.map(
          (account) => Object.hash(
            account['player_tag'],
            account['tag'],
            account['name'],
            account['townHallLevel'],
            account['builderHallLevel'],
          ),
        ),
      ),
    );
    context.select<PlayerService, int>(
      (service) => Object.hashAll(
        service.profiles.map(
          (player) =>
              Object.hash(player.tag, player.name, player.townHallLevel),
        ),
      ),
    );
    final l10n = AppLocalizations.of(context)!;
    final linkedAccounts = _linkedAccountOptions();
    final accounts = linkedAccounts;
    final uniqueAccounts = <String, _TrackerAccountOption>{
      for (final account in accounts)
        UpgradeTrackerRepository.normalizeTag(account.tag): account,
    }.values.toList(growable: false);

    final selectedAccount = uniqueAccounts
        .where(
          (account) =>
              UpgradeTrackerRepository.normalizeTag(account.tag) ==
              UpgradeTrackerRepository.normalizeTag(_selectedTag ?? ''),
        )
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        titleSpacing: 4,
        title: Semantics(
          button: true,
          label: l10n.upgradeTrackerSwitchAccount(
            selectedAccount?.name ?? l10n.upgradeTrackerChooseAccount,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => _showAccountPicker(uniqueAccounts),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((selectedAccount?.townHallLevel ?? 0) > 0) ...[
                    MobileWebImage(
                      imageUrl: ImageAssets.townHall(
                        selectedAccount!.townHallLevel,
                      ),
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: ValueListenableBuilder<DateTime>(
                      valueListenable: _clock,
                      builder: (context, now, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAccount?.name ??
                                l10n.upgradeTrackerChooseAccount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CKTypography.of(
                              context,
                              CKTextRole.rowTitle,
                            ),
                          ),
                          if (selectedAccount?.capturedAt
                              case final capturedAt?)
                            Text(
                              _snapshotAgeLabel(context, capturedAt, now: now),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  CKTypography.of(
                                    context,
                                    CKTextRole.compactLabel,
                                  ).copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.expand_more_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (_snapshot != null)
            IconButton(
              tooltip: l10n.upgradeTrackerShare,
              onPressed: () => _showShareHub(_snapshot!),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          IconButton(
            tooltip: l10n.upgradeTrackerPasteJson,
            onPressed: _importSnapshot,
            icon: const Icon(Icons.content_paste_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: LiquidGlassSegmentedControl<int>(
              values: const [0, 1, 2],
              labels: [
                l10n.upgradeTrackerPlan,
                l10n.upgradeTrackerUpgrades,
                l10n.upgradeTrackerCollection,
              ],
              selected: _section,
              color: Theme.of(context).colorScheme.onSurface,
              height: CKControlDensity.compact.minimumHeight,
              onChanged: _selectSection,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  void _selectSection(int value) {
    if (value == _section) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _section = value);
    if (!_pageController.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(value);
    } else {
      _pageController.animateToPage(
        value,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int value) {
    if (value == _section) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _section = value);
  }

  Future<void> _showAccountPicker(List<_TrackerAccountOption> accounts) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AccountPickerSheet(
        accounts: accounts,
        selectedTag: _selectedTag,
        onImport: () {
          Navigator.pop(context);
          _importSnapshot();
        },
      ),
    );
    if (result != null) await _load(result);
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _TrackerEmptyState(
        icon: Icons.error_outline_rounded,
        title: l10n.upgradeTrackerSnapshotUnreadable,
        body: _error.toString(),
        actionLabel: _selectedTag == null ? null : l10n.upgradeTrackerTryAgain,
        onAction: _selectedTag == null ? null : () => _load(_selectedTag!),
      );
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return _TrackerEmptyState(
        icon: Icons.content_paste_rounded,
        stickerUrl: ImageAssets.builderWave,
        title: l10n.upgradeTrackerNoDataTitle,
        body: _selectedTag == null
            ? l10n.upgradeTrackerNoLinkedAccount
            : l10n.upgradeTrackerNoDataBody,
        detail: _selectedTag == null ? null : l10n.upgradeTrackerNoDataLocation,
        actionLabel: _selectedTag == null
            ? null
            : l10n.upgradeTrackerPasteClipboard,
        onAction: _selectedTag == null ? null : _pasteSnapshotFromClipboard,
        secondaryActionLabel: _selectedTag == null
            ? null
            : l10n.upgradeTrackerOpenMoreSettings,
        onSecondaryAction: _selectedTag == null ? null : _openClashMoreSettings,
      );
    }
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        _PlanTab(
          snapshot: snapshot,
          goldPassPercent: _goldPassPercent,
          preferences: _planPreferences,
          clock: _clock,
          onLanesChanged: (lanes) => _planLanes.value = lanes,
          controls: _buildPlanActions(snapshot),
        ),
        _UpgradesTab(
          snapshot: snapshot,
          clock: _clock,
          goldPassPercent: _goldPassPercent,
          preferences: _planPreferences,
        ),
        _CollectionTab(snapshot: snapshot),
      ],
    );
  }

  Widget _buildPlanActions(UpgradeTrackerSnapshot snapshot) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<int>(
                tooltip: 'Gold Pass reduction',
                initialValue: _goldPassPercent,
                onSelected: (value) {
                  setState(() => _goldPassPercent = value);
                  unawaited(_savePlanDraft());
                },
                itemBuilder: (context) => [0, 10, 15, 20]
                    .map(
                      (value) => PopupMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            _AspectSafeImage(
                              imageUrl: ImageAssets.goldPass,
                              width: 25,
                              height: 25,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              value == 0 ? 'No Gold Pass' : '$value% Gold Pass',
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
                child: _PlanToolButton(
                  imageUrl: ImageAssets.goldPass,
                  label: _goldPassPercent == 0
                      ? 'No Gold Pass'
                      : 'Gold Pass $_goldPassPercent%',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PlanToolButton(
                icon: Icons.tune_rounded,
                label: 'Priorities',
                onTap: () => _showPlanPreferences(
                  context,
                  snapshot,
                  _planPreferences,
                  (value) {
                    setState(() => _planPreferences = value);
                    unawaited(_savePlanDraft());
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PlanToolButton(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                onTap: () => _showPlanCalendar(
                  context,
                  snapshot,
                  goldPassPercent: _goldPassPercent,
                  preferences: _planPreferences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<List<UpgradePlanLane>>(
                valueListenable: _planLanes,
                builder: (context, lanes, _) => _PlanToolButton(
                  icon: Icons.view_list_rounded,
                  label: 'Entire plan',
                  onTap: lanes.isEmpty
                      ? null
                      : () => _showFullPlan(context, lanes),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _savePlanDraft() async {
    final tag = _selectedTag;
    if (tag == null) return;
    await _repository.savePlanPreferences(
      tag,
      goldPassPercent: _goldPassPercent,
      strategy: UpgradePlanStrategy.balanced.name,
      preferences: _planPreferences,
    );
  }

  Future<void> _showCollectionShare(UpgradeTrackerSnapshot snapshot) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareCollectionSheet(snapshot: snapshot),
    );
  }

  Future<void> _showShareHub(UpgradeTrackerSnapshot snapshot) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share tracker',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Home Village progress'),
              onTap: () => Navigator.pop(context, 'home'),
            ),
            ListTile(
              leading: const Icon(Icons.cottage_rounded),
              title: const Text('Builder Base progress'),
              onTap: () => Navigator.pop(context, 'builder'),
            ),
            ListTile(
              leading: const Icon(Icons.collections_rounded),
              title: const Text('Collection'),
              onTap: () => Navigator.pop(context, 'collection'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'home':
        await _showSharePreview(snapshot, UpgradeVillage.home);
      case 'builder':
        await _showSharePreview(snapshot, UpgradeVillage.builderBase);
      case 'collection':
        await _showCollectionShare(snapshot);
    }
  }

  Future<void> _showSharePreview(
    UpgradeTrackerSnapshot snapshot,
    UpgradeVillage village,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ShareProgressSheet(snapshot: snapshot, village: village),
    );
  }
}

// Kept temporarily as a visual reference while the merged Progress surface is
// validated; it is not reachable from navigation.
// ignore: unused_element
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.snapshot,
    required this.village,
    required this.onVillageChanged,
    required this.onShare,
    required this.onOpenCategory,
  });

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeVillage village;
  final ValueChanged<UpgradeVillage> onVillageChanged;
  final VoidCallback onShare;
  final ValueChanged<UpgradeCategory> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final summary = snapshot.overallSummary(village: village);
    final categories = UpgradeCategory.values
        .map((category) => snapshot.summaryFor(category, village: village))
        .where((entry) => entry.target > 0)
        .toList(growable: false);
    final active = snapshot
        .itemsFor(village: village)
        .where((item) => (item.activeSeconds ?? 0) > 0)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        _VillageControl(value: village, onChanged: onVillageChanged),
        const SizedBox(height: 12),
        _ProgressHero(snapshot: snapshot, village: village, summary: summary),
        const SizedBox(height: 12),
        if (snapshot.events.isNotEmpty || snapshot.boosts.hasTemporaryBoost)
          _ModifierNotice(snapshot: snapshot),
        if (snapshot.events.isNotEmpty || snapshot.boosts.hasTemporaryBoost)
          const SizedBox(height: 14),
        if (active.isNotEmpty) ...[
          _SectionHeading(
            title: 'In progress',
            trailing: '${active.length} active',
          ),
          const SizedBox(height: 6),
          ...active.map(
            (item) => _ActiveUpgradeRow(snapshot: snapshot, item: item),
          ),
          const SizedBox(height: 10),
        ],
        const _SectionHeading(title: 'Completion'),
        const SizedBox(height: 6),
        ...categories.map(
          (category) => _CategoryProgressRow(
            summary: category,
            imageUrl: _categoryImage(snapshot, category.category, village),
            onTap: () => onOpenCategory(category.category),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Share progress'),
        ),
      ],
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.snapshot,
    required this.village,
    required this.summary,
    this.finish,
    this.clock,
  });

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeVillage village;
  final UpgradeCategorySummary summary;
  final DateTime? finish;
  final ValueListenable<DateTime>? clock;

  @override
  Widget build(BuildContext context) => clock == null
      ? _buildContent(context, DateTime.now())
      : ValueListenableBuilder<DateTime>(
          valueListenable: clock!,
          builder: (context, now, _) => _buildContent(context, now),
        );

  Widget _buildContent(BuildContext context, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    final hall = village == UpgradeVillage.home
        ? snapshot.townHallLevel
        : snapshot.builderHallLevel;
    final image = village == UpgradeVillage.home
        ? ImageAssets.townHall(hall)
        : ImageAssets.builderHall(hall);
    final active = snapshot.items
        .where((item) => snapshot.remainingActiveSeconds(item, now: now) > 0)
        .toList(growable: false);
    final helpers = snapshot.items
        .where(
          (item) =>
              item.category == UpgradeCategory.builders &&
              _isHelperStatusItem(item),
        )
        .toList(growable: false);
    final boosts = _activeBoostLabels(snapshot, now: now);
    return CKSectionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AspectSafeImage(imageUrl: image, width: 72, height: 72),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(summary.completion * 100).toStringAsFixed(1)}%',
                      style: CKTypography.of(context, CKTextRole.heroMetric),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      summary.levelsRemaining == 0
                          ? 'Everything tracked is complete'
                          : '${summary.levelsRemaining} levels left${finish == null ? '' : ' · ${_dateLabel(finish!)}'}',
                      style: CKTypography.of(
                        context,
                        CKTextRole.metadata,
                      ).copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (boosts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: boosts
                  .map(
                    (label) =>
                        _BoostStatusPill(label: label, snapshot: snapshot),
                  )
                  .toList(growable: false),
            ),
          ],
          if (active.isNotEmpty) ...[
            const Divider(height: 20),
            _SectionHeading(
              title: 'In progress',
              trailing: '${active.length} active',
            ),
            ...active
                .take(6)
                .map(
                  (item) => _ActiveUpgradeRow(
                    snapshot: snapshot,
                    item: item,
                    now: now,
                  ),
                ),
          ],
          if (helpers.isNotEmpty) ...[
            const Divider(height: 20),
            const _SectionHeading(title: 'Helpers'),
            ...helpers.map(
              (helper) => _HelperStatusRow(
                snapshot: snapshot,
                helper: helper,
                now: now,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

bool _isHelperStatusItem(UpgradeTrackerItem item) {
  final name = item.name.toLowerCase();
  return name.contains('apprentice') ||
      name.contains('assistant') ||
      name.contains('alchemist');
}

class _HelperStatusRow extends StatelessWidget {
  const _HelperStatusRow({
    required this.snapshot,
    required this.helper,
    this.now,
  });

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeTrackerItem helper;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final assigned = snapshot.items.where((item) {
      final helperName = snapshot.helperNameFor(item);
      return helperName == helper.name &&
          snapshot.remainingHelperSeconds(item, now: now) > 0;
    }).firstOrNull;
    final cooldown = snapshot.remainingCooldownSeconds(helper, now: now);
    final status = assigned != null
        ? 'Helping ${assigned.name} · ${_duration(snapshot.remainingHelperSeconds(assigned, now: now))}'
        : cooldown > 0
        ? 'Ready in ${_duration(cooldown)}'
        : 'Ready';
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          _AspectSafeImage(imageUrl: helper.imageUrl, width: 38, height: 32),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${helper.name} · Level ${helper.currentLevel}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostStatusPill extends StatelessWidget {
  const _BoostStatusPill({required this.label, required this.snapshot});

  final String label;
  final UpgradeTrackerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = _boostImageUrl(label, snapshot);
    final parts = label.split(' · ');
    final title = parts.first;
    final detail = parts.length > 1 ? parts.skip(1).join(' · ') : null;
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AspectSafeImage(imageUrl: imageUrl, width: 22, height: 22),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (detail != null)
                Text(
                  detail,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _boostImageUrl(String label, UpgradeTrackerSnapshot snapshot) {
  final normalized = label.toLowerCase();
  if (normalized.startsWith('builder potion')) {
    return ImageAssets.builderPotion;
  }
  if (normalized.startsWith('research potion')) {
    return ImageAssets.researchPotion;
  }
  if (normalized.startsWith('pet potion')) return ImageAssets.petPotion;
  if (normalized.startsWith('clock tower')) {
    return ImageAssets.clockTowerPotion;
  }
  if (normalized.contains('perk')) return ImageAssets.iconGoldPass;
  return ImageAssets.townHall(snapshot.townHallLevel);
}

class _ModifierNotice extends StatelessWidget {
  const _ModifierNotice({required this.snapshot});

  final UpgradeTrackerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = _activeBoostLabels(snapshot);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              children: labels
                  .map(
                    (label) =>
                        _BoostStatusPill(label: label, snapshot: snapshot),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.summary,
    required this.imageUrl,
    required this.onTap,
  });

  final UpgradeCategorySummary summary;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 36,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: MobileWebImage(
                  imageUrl: imageUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _categoryLabel(summary.category),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${(summary.completion * 100).toStringAsFixed(summary.completion == 1 ? 0 : 1)}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: summary.completion,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.onSurface.withValues(alpha: 0.82),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ActiveUpgradeRow extends StatelessWidget {
  const _ActiveUpgradeRow({
    required this.snapshot,
    required this.item,
    this.now,
  });

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeTrackerItem item;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _AspectSafeImage(imageUrl: item.imageUrl, width: 48, height: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Level ${item.currentLevel} → ${item.currentLevel + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (snapshot.helperNameFor(item) case final helper?)
                  Text(
                    '$helper helping · ${_duration(snapshot.remainingHelperSeconds(item, now: now))}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          _Pill(
            text: _duration(snapshot.remainingActiveSeconds(item, now: now)),
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }
}

class _TrackerCollapsibleCard extends StatelessWidget {
  const _TrackerCollapsibleCard({
    required this.title,
    required this.imageUrl,
    required this.completion,
    required this.countLabel,
    required this.expanded,
    required this.onToggle,
    required this.onSummaryTap,
    required this.child,
    this.showContent = true,
  });

  final String title;
  final String imageUrl;
  final double completion;
  final String countLabel;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onSummaryTap;
  final Widget child;
  final bool showContent;

  @override
  Widget build(BuildContext context) {
    return CollapsibleItemSection(
      title: title,
      subtitle: countLabel,
      leading: _AspectSafeImage(imageUrl: imageUrl, width: 34, height: 30),
      trailing: SectionProgressBadge(progress: completion, onTap: onSummaryTap),
      expanded: expanded,
      onToggle: onToggle,
      margin: const EdgeInsets.only(bottom: 10),
      showContent: showContent,
      surfaceWhenExpanded: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: CKSpacing.sm,
        vertical: CKSpacing.xs,
      ),
      expandedSpacing: CKSpacing.sm,
      animateContent: false,
      child: child,
    );
  }
}

class _UpgradesTab extends StatefulWidget {
  const _UpgradesTab({
    required this.snapshot,
    required this.clock,
    required this.goldPassPercent,
    required this.preferences,
  });

  final UpgradeTrackerSnapshot snapshot;
  final ValueListenable<DateTime> clock;
  final int goldPassPercent;
  final UpgradePlanPreferences preferences;

  @override
  State<_UpgradesTab> createState() => _UpgradesTabState();
}

class _UpgradesTabState extends State<_UpgradesTab> {
  final _expandedVillages = <UpgradeVillage>{UpgradeVillage.home};
  final _expandedGroups = <String>{'home-buildings'};
  final _searchController = TextEditingController();
  String _query = '';
  late Map<UpgradeVillage, _UpgradeVillageViewData> _viewData;

  @override
  void initState() {
    super.initState();
    _rebuildViewData();
  }

  @override
  void didUpdateWidget(covariant _UpgradesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.snapshot, widget.snapshot)) {
      _rebuildViewData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    if (value == _query) return;
    setState(() {
      _query = value;
      _rebuildViewData();
    });
  }

  void _rebuildViewData() {
    final normalized = _query.trim().toLowerCase();
    _viewData = {
      for (final village in UpgradeVillage.values)
        village: _UpgradeVillageViewData.build(
          widget.snapshot,
          village,
          normalized,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _trackerContentGutter,
          8,
          _trackerContentGutter,
          10,
        ),
        sliver: SliverToBoxAdapter(
          child: AppSearchField(
            controller: _searchController,
            query: _query,
            hintText: l10n.upgradeTrackerSearchUpgrades,
            onChanged: _setQuery,
          ),
        ),
      ),
    ];

    for (final village in UpgradeVillage.values) {
      final data = _viewData[village]!;
      if (data.visibleItems.isEmpty) continue;
      final expanded = _expandedVillages.contains(village);
      final title = village == UpgradeVillage.home
          ? l10n.upgradeTrackerHomeVillage
          : l10n.upgradeTrackerBuilderBase;
      final image = village == UpgradeVillage.home
          ? ImageAssets.townHall(widget.snapshot.townHallLevel)
          : ImageAssets.builderHall(widget.snapshot.builderHallLevel);
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: CollapsibleItemSection(
              title: title,
              leading: _AspectSafeImage(imageUrl: image, width: 38, height: 34),
              subtitle: l10n.upgradeTrackerLevelsLeft(
                data.summary.levelsRemaining,
              ),
              trailing: SectionProgressBadge(
                progress: data.summary.completion,
                onTap: () => _showUpgradeSectionSummary(
                  context,
                  title,
                  data.summary,
                  snapshot: widget.snapshot,
                  village: village,
                  goldPassPercent: widget.goldPassPercent,
                  preferences: widget.preferences,
                ),
              ),
              expanded: expanded,
              onToggle: () => setState(() {
                expanded
                    ? _expandedVillages.remove(village)
                    : _expandedVillages.add(village);
              }),
              margin: const EdgeInsets.only(bottom: 10),
              showContent: false,
              surfaceWhenExpanded: false,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      if (!expanded) continue;

      for (final group in data.groups) {
        final items = data.itemsByGroup[group]!;
        final summary = data.summaryByGroup[group]!;
        final key = '${village.name}-${group.name}';
        final groupExpanded = _expandedGroups.contains(key);
        final groupTitle = _upgradeGroupLabelForVillage(group, village);
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _trackerContentGutter,
              0,
              _trackerContentGutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _TrackerCollapsibleCard(
                title: groupTitle,
                countLabel:
                    '${l10n.upgradeTrackerLevelsLeft(summary.levelsRemaining)} · ${l10n.upgradeTrackerItemCount(items.length)}',
                imageUrl: _groupImage(widget.snapshot, group, village),
                completion: summary.completion,
                expanded: groupExpanded,
                onToggle: () => setState(() {
                  groupExpanded
                      ? _expandedGroups.remove(key)
                      : _expandedGroups.add(key);
                }),
                onSummaryTap: () =>
                    _showUpgradeSectionSummary(context, groupTitle, summary),
                showContent: false,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        final groupSlivers = <Widget>[];
        if (groupExpanded && group == _UpgradeGroup.laboratory) {
          for (final category in <(String, List<UpgradeTrackerItem>)>[
            (
              'Troops',
              items
                  .where(
                    (item) =>
                        item.category == UpgradeCategory.troops ||
                        item.category == UpgradeCategory.darkTroops,
                  )
                  .toList(growable: false),
            ),
            (
              'Spells',
              items
                  .where((item) => item.category == UpgradeCategory.spells)
                  .toList(growable: false),
            ),
            (
              'Siege Machines',
              items
                  .where((item) => item.category == UpgradeCategory.sieges)
                  .toList(growable: false),
            ),
          ]) {
            if (category.$2.isEmpty) continue;
            groupSlivers.add(
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _trackerContentGutter,
                  4,
                  _trackerContentGutter,
                  6,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    category.$1,
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                ),
              ),
            );
            groupSlivers.add(_upgradeGridSliver(category.$2));
          }
        } else if (groupExpanded && group == _UpgradeGroup.equipment) {
          for (final heroGroup in _equipmentHeroGroups(items)) {
            groupSlivers.add(
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _trackerContentGutter,
                  4,
                  _trackerContentGutter,
                  6,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _AspectSafeImage(
                        imageUrl: ImageAssets.getHeroImage(heroGroup.$1),
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(width: CKSpacing.xs),
                      Text(
                        heroGroup.$1,
                        style: CKTypography.of(context, CKTextRole.rowTitle),
                      ),
                    ],
                  ),
                ),
              ),
            );
            groupSlivers.add(_upgradeGridSliver(heroGroup.$2));
          }
        } else if (groupExpanded) {
          groupSlivers.add(_upgradeGridSliver(items));
        }
        slivers.add(
          SliverAnimatedPaintExtent(
            duration: CKMotion.durationOf(context, CKMotion.standard),
            curve: CKMotion.standardCurve,
            child: groupExpanded
                ? SliverMainAxisGroup(slivers: groupSlivers)
                : SliverToBoxAdapter(child: const SizedBox.shrink()),
          ),
        );
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 28)));
    return CustomScrollView(slivers: slivers);
  }

  Widget _upgradeGridSliver(List<UpgradeTrackerItem> items) => SliverPadding(
    padding: EdgeInsets.fromLTRB(
      _trackerContentGutter,
      0,
      _trackerContentGutter,
      12,
    ),
    sliver: SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 5 : 8,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _UpgradeIconTile(
        snapshot: widget.snapshot,
        item: items[index],
        clock: widget.clock,
      ),
    ),
  );
}

class _UpgradeVillageViewData {
  const _UpgradeVillageViewData({
    required this.visibleItems,
    required this.summary,
    required this.groups,
    required this.itemsByGroup,
    required this.summaryByGroup,
  });

  final List<UpgradeTrackerItem> visibleItems;
  final UpgradeCategorySummary summary;
  final List<_UpgradeGroup> groups;
  final Map<_UpgradeGroup, List<UpgradeTrackerItem>> itemsByGroup;
  final Map<_UpgradeGroup, UpgradeCategorySummary> summaryByGroup;

  factory _UpgradeVillageViewData.build(
    UpgradeTrackerSnapshot snapshot,
    UpgradeVillage village,
    String normalizedQuery,
  ) {
    final displayItems = snapshot.itemsFor(village: village);
    final completionItems = displayItems
        .where((item) => item.category != UpgradeCategory.builders)
        .toList(growable: false);
    final visible = displayItems
        .where(
          (item) =>
              normalizedQuery.isEmpty ||
              item.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
    final groups = _availableUpgradeGroups(snapshot, village)
        .where(
          (group) => visible.any(
            (item) => _itemBelongsToUpgradeGroup(item, group, village),
          ),
        )
        .toList(growable: false);
    final itemsByGroup = <_UpgradeGroup, List<UpgradeTrackerItem>>{};
    final summaryByGroup = <_UpgradeGroup, UpgradeCategorySummary>{};
    for (final group in groups) {
      final items =
          visible
              .where((item) => _itemBelongsToUpgradeGroup(item, group, village))
              .toList()
            ..sort((a, b) {
              final id = a.id.compareTo(b.id);
              if (id != 0) return id;
              final name = a.name.compareTo(b.name);
              return name != 0
                  ? name
                  : a.currentLevel.compareTo(b.currentLevel);
            });
      itemsByGroup[group] = items;
      summaryByGroup[group] = snapshot.summaryForItems(
        displayItems.where(
          (item) => _itemBelongsToUpgradeGroup(item, group, village),
        ),
      );
    }
    return _UpgradeVillageViewData(
      visibleItems: visible,
      summary: snapshot.summaryForItems(completionItems),
      groups: groups,
      itemsByGroup: itemsByGroup,
      summaryByGroup: summaryByGroup,
    );
  }
}

/*
class _UpgradeGroupSection extends StatelessWidget {
  const _UpgradeGroupSection({
    required this.snapshot,
    required this.group,
    required this.village,
    required this.items,
    required this.summary,
    required this.expanded,
    required this.onToggle,
  });

  final UpgradeTrackerSnapshot snapshot;
  final _UpgradeGroup group;
  final UpgradeVillage village;
  final List<UpgradeTrackerItem> items;
  final UpgradeCategorySummary summary;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CollapsibleItemSection(
      title: _upgradeGroupLabel(group),
      subtitle:
          '${summary.levelsRemaining} levels left · ${items.length} items',
      leading: _AspectSafeImage(
        imageUrl: _groupImage(snapshot, group, village),
        width: 34,
        height: 30,
      ),
      trailing: SectionProgressBadge(
        progress: summary.completion,
        onTap: () => _showUpgradeSectionSummary(
          context,
          _upgradeGroupLabel(group),
          summary,
        ),
      ),
      expanded: expanded,
      onToggle: onToggle,
      margin: const EdgeInsets.only(top: 8),
      child: group == _UpgradeGroup.laboratory
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UpgradeCategoryGrid(
                  snapshot: snapshot,
                  label: 'Troops',
                  items: items
                      .where(
                        (item) =>
                            item.category == UpgradeCategory.troops ||
                            item.category == UpgradeCategory.darkTroops,
                      )
                      .toList(growable: false),
                ),
                _UpgradeCategoryGrid(
                  snapshot: snapshot,
                  label: 'Spells',
                  items: items
                      .where((item) => item.category == UpgradeCategory.spells)
                      .toList(growable: false),
                ),
                _UpgradeCategoryGrid(
                  snapshot: snapshot,
                  label: 'Siege Machines',
                  items: items
                      .where((item) => item.category == UpgradeCategory.sieges)
                      .toList(growable: false),
                ),
              ],
            )
          : CompactItemGrid(
              itemCount: items.length,
              itemBuilder: (context, index, size) => _UpgradeIconTile(
                snapshot: snapshot,
                item: items[index],
                size: size,
              ),
            ),
    );
  }
}

class _UpgradeCategoryGrid extends StatelessWidget {
  const _UpgradeCategoryGrid({
    required this.snapshot,
    required this.label,
    required this.items,
  });

  final UpgradeTrackerSnapshot snapshot;
  final String label;
  final List<UpgradeTrackerItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          CompactItemGrid(
            itemCount: items.length,
            itemBuilder: (context, index, size) => _UpgradeIconTile(
              snapshot: snapshot,
              item: items[index],
              size: size,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeIconTile extends StatelessWidget {
*/
class _UpgradeIconTile extends StatelessWidget {
  const _UpgradeIconTile({
    required this.snapshot,
    required this.item,
    this.clock,
  });

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeTrackerItem item;
  final ValueListenable<DateTime>? clock;

  @override
  Widget build(BuildContext context) => clock == null
      ? _buildContent(context, DateTime.now())
      : ValueListenableBuilder<DateTime>(
          valueListenable: clock!,
          builder: (context, now, _) => _buildContent(context, now),
        );

  Widget _buildContent(BuildContext context, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    final active = snapshot.remainingActiveSeconds(item, now: now) > 0;
    final border = active ? scheme.primary : scheme.outlineVariant;
    return Semantics(
      button: true,
      label:
          '${item.name}, level ${item.currentLevel} of ${item.targetLevel}${item.count > 1 ? ', ${item.count} buildings' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showUpgradeDetails(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(CKRadius.tile),
            border: Border.all(color: border, width: active ? 2 : 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: MobileWebImage(
                    imageUrl: item.imageUrl,
                    fallbackImageUrls: _upgradeImageFallbacks(item),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 23),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: item.isComplete
                        ? CKUpgradeColors.completion
                        : Colors.black.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.currentLevel}',
                    style: CKTypography.of(context, CKTextRole.compactLabel)
                        .copyWith(
                          color: item.isComplete ? Colors.black : Colors.white,
                          height: 1,
                        ),
                  ),
                ),
              ),
              if (item.count > 1)
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '×${item.count}',
                      style: CKTypography.of(
                        context,
                        CKTextRole.compactLabel,
                      ).copyWith(color: Colors.white, height: 1),
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

// Kept as the detailed list-row treatment used by planner surfaces.
// ignore: unused_element
class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.snapshot, required this.item});

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeTrackerItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = item.steps.firstOrNull;
    final remainingActive = snapshot.remainingActiveSeconds(item);
    return InkWell(
      onTap: item.isComplete ? null : () => showUpgradeDetails(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _AspectSafeImage(imageUrl: item.imageUrl, width: 58, height: 48),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (item.count > 1)
                        Text(
                          '×${item.count}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.isComplete
                        ? 'Level ${item.currentLevel} · Complete'
                        : 'Level ${item.currentLevel} → ${item.targetLevel} · ${item.levelsRemaining} left',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: item.isComplete
                          ? StatColors.win
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (remainingActive > 0) ...[
                    const SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Pill(
                          text: '${_duration(remainingActive)} left',
                          icon: Icons.schedule_rounded,
                        ),
                        if (snapshot.helperNameFor(item) case final helper?)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$helper helping · ${_duration(snapshot.remainingHelperSeconds(item))}',
                              softWrap: true,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ] else if (next != null) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        ...next.costs.map(
                          (cost) => _ResourcePill(cost: cost, compact: true),
                        ),
                        if (next.seconds > 0)
                          _Pill(
                            text: _duration(next.seconds),
                            icon: Icons.schedule_rounded,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (!item.isComplete)
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PlanToolButton extends StatelessWidget {
  const _PlanToolButton({
    required this.label,
    this.icon,
    this.imageUrl,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null || imageUrl != null,
      child: Material(
        color: onTap == null && imageUrl == null
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.18)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageUrl != null)
                    _AspectSafeImage(imageUrl: imageUrl!, width: 25, height: 25)
                  else
                    Icon(icon, size: 19, color: scheme.onSurface),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTab extends StatefulWidget {
  const _PlanTab({
    required this.snapshot,
    required this.goldPassPercent,
    required this.preferences,
    required this.onLanesChanged,
    required this.controls,
    required this.clock,
  });

  final UpgradeTrackerSnapshot snapshot;
  final int goldPassPercent;
  final UpgradePlanPreferences preferences;
  final ValueChanged<List<UpgradePlanLane>> onLanesChanged;
  final Widget controls;
  final ValueListenable<DateTime> clock;

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  late DateTime _startsAt;
  late List<UpgradePlanLane> _allLanes;
  late DateTime? _finish;
  late String _preferenceSignature;

  @override
  void initState() {
    super.initState();
    _computePlan();
    _notifyLanes();
  }

  @override
  void didUpdateWidget(covariant _PlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = jsonEncode(widget.preferences.toJson());
    if (!identical(oldWidget.snapshot, widget.snapshot) ||
        oldWidget.snapshot.capturedAt != widget.snapshot.capturedAt ||
        oldWidget.goldPassPercent != widget.goldPassPercent ||
        nextSignature != _preferenceSignature) {
      _computePlan();
      _notifyLanes();
    }
  }

  void _notifyLanes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLanesChanged(_allLanes);
    });
  }

  void _computePlan() {
    _startsAt = DateTime.now();
    _preferenceSignature = jsonEncode(widget.preferences.toJson());
    List<UpgradePlanLane> build(UpgradeVillage village, UpgradeQueue queue) =>
        _buildPlannerLanes(
          widget.snapshot,
          queue: queue,
          strategy: UpgradePlanStrategy.balanced,
          village: village,
          startsAt: _startsAt,
          goldPassPercent: widget.goldPassPercent,
          preferences: _preferencesForQueue(
            widget.snapshot,
            widget.preferences,
            village,
            queue,
          ),
        );

    final walls = _buildWallPlan(
      widget.snapshot,
      widget.preferences,
      goldPassPercent: widget.goldPassPercent,
      startsAt: _startsAt,
    );
    _allLanes = [
      ...build(UpgradeVillage.home, UpgradeQueue.builders),
      ...build(UpgradeVillage.home, UpgradeQueue.laboratory),
      ...build(UpgradeVillage.home, UpgradeQueue.pets),
      ...build(UpgradeVillage.builderBase, UpgradeQueue.builders),
      ...build(UpgradeVillage.builderBase, UpgradeQueue.laboratory),
      if (walls.isNotEmpty) UpgradePlanLane(index: 0, upgrades: walls),
    ];
    _finish = _allLanes
        .map((lane) => lane.finishesAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, date) {
          return latest == null || date.isAfter(latest) ? date : latest;
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 30),
      children: [
        _ProgressHero(
          snapshot: widget.snapshot,
          village: UpgradeVillage.home,
          summary: widget.snapshot.overallSummary(village: UpgradeVillage.home),
          finish: _finish,
          clock: widget.clock,
        ),
        const SizedBox(height: 12),
        widget.controls,
        const SizedBox(height: 12),
        _LootOutlookCard(lanes: _allLanes, startsAt: _startsAt),
      ],
    );
  }
}

enum _PlanCalendarGroup {
  homeBuilders,
  homeLaboratory,
  pets,
  builderBaseBuilders,
  builderBaseLaboratory,
}

extension on _PlanCalendarGroup {
  String get label => switch (this) {
    _PlanCalendarGroup.homeBuilders => 'Builders',
    _PlanCalendarGroup.homeLaboratory => 'Laboratory',
    _PlanCalendarGroup.pets => 'Pets',
    _PlanCalendarGroup.builderBaseBuilders => 'Builder Base Builders',
    _PlanCalendarGroup.builderBaseLaboratory => 'Builder Base Laboratory',
  };

  UpgradeVillage get village => switch (this) {
    _PlanCalendarGroup.homeBuilders ||
    _PlanCalendarGroup.homeLaboratory ||
    _PlanCalendarGroup.pets => UpgradeVillage.home,
    _PlanCalendarGroup.builderBaseBuilders ||
    _PlanCalendarGroup.builderBaseLaboratory => UpgradeVillage.builderBase,
  };

  UpgradeQueue get queue => switch (this) {
    _PlanCalendarGroup.homeBuilders ||
    _PlanCalendarGroup.builderBaseBuilders => UpgradeQueue.builders,
    _PlanCalendarGroup.homeLaboratory ||
    _PlanCalendarGroup.builderBaseLaboratory => UpgradeQueue.laboratory,
    _PlanCalendarGroup.pets => UpgradeQueue.pets,
  };

  Color get accent => switch (this) {
    _PlanCalendarGroup.homeBuilders => const Color(0xFF4D9DE0),
    _PlanCalendarGroup.homeLaboratory => const Color(0xFF9B6DE3),
    _PlanCalendarGroup.pets => const Color(0xFFE56B9F),
    _PlanCalendarGroup.builderBaseBuilders => const Color(0xFFE7953D),
    _PlanCalendarGroup.builderBaseLaboratory => const Color(0xFF43B3AE),
  };
}

String _planCalendarGroupImage(
  UpgradeTrackerSnapshot snapshot,
  _PlanCalendarGroup group,
) {
  int levelFor(String name, UpgradeVillage village) => snapshot
      .itemsFor(village: village)
      .where((item) => item.name == name)
      .map((item) => item.currentLevel)
      .fold<int>(1, math.max);

  return switch (group) {
    _PlanCalendarGroup.homeBuilders => ImageAssets.getHomeVillageBuildingImage(
      "Builder's Hut",
      levelFor("Builder's Hut", UpgradeVillage.home),
    ),
    _PlanCalendarGroup.homeLaboratory =>
      ImageAssets.getHomeVillageBuildingImage(
        'Laboratory',
        levelFor('Laboratory', UpgradeVillage.home),
      ),
    _PlanCalendarGroup.pets => ImageAssets.getHomeVillageBuildingImage(
      'Pet House',
      levelFor('Pet House', UpgradeVillage.home),
    ),
    _PlanCalendarGroup.builderBaseBuilders =>
      ImageAssets.getBuilderBaseBuildingImage(
        'Builder Hall',
        snapshot.builderHallLevel,
      ),
    _PlanCalendarGroup.builderBaseLaboratory =>
      ImageAssets.getBuilderBaseBuildingImage(
        'Star Laboratory',
        levelFor('Star Laboratory', UpgradeVillage.builderBase),
      ),
  };
}

class _PlanTimelineGroup {
  const _PlanTimelineGroup({required this.type, required this.lanes});

  final _PlanCalendarGroup type;
  final List<UpgradePlanLane> lanes;
}

List<_PlanTimelineGroup> _buildPlanCalendarGroups(
  UpgradeTrackerSnapshot snapshot, {
  required int goldPassPercent,
  required UpgradePlanPreferences preferences,
  required DateTime startsAt,
}) {
  List<UpgradePlanLane> build(_PlanCalendarGroup group) => _buildPlannerLanes(
    snapshot,
    queue: group.queue,
    strategy: UpgradePlanStrategy.balanced,
    village: group.village,
    startsAt: startsAt,
    goldPassPercent: goldPassPercent,
    preferences: _preferencesForQueue(
      snapshot,
      preferences,
      group.village,
      group.queue,
    ),
  );

  return _PlanCalendarGroup.values
      .map((group) => _PlanTimelineGroup(type: group, lanes: build(group)))
      .toList(growable: false);
}

Future<void> _showPlanCalendar(
  BuildContext context,
  UpgradeTrackerSnapshot snapshot, {
  required int goldPassPercent,
  required UpgradePlanPreferences preferences,
}) async {
  final startsAt = DateTime.now();
  final groups = _buildPlanCalendarGroups(
    snapshot,
    goldPassPercent: goldPassPercent,
    preferences: preferences,
    startsAt: startsAt,
  );
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.98,
      child: _PlanTimeline(
        snapshot: snapshot,
        startsAt: startsAt,
        groups: groups,
      ),
    ),
  );
}

class _PlanTimeline extends StatelessWidget {
  const _PlanTimeline({
    required this.snapshot,
    required this.startsAt,
    required this.groups,
  });

  final UpgradeTrackerSnapshot snapshot;
  final DateTime startsAt;
  final List<_PlanTimelineGroup> groups;

  static const _horizonDays = 30;
  static const _labelWidth = 64.0;
  static const _dayWidth = 72.0;
  static const _laneHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(startsAt.year, startsAt.month, startsAt.day);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendar',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '30-day horizon · swipe sideways to explore',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final timelineViewport = math.max(
                    0.0,
                    constraints.maxWidth - 32 - _labelWidth,
                  );
                  final contentWidth =
                      _labelWidth +
                      math.max(timelineViewport, _horizonDays * _dayWidth);
                  return SingleChildScrollView(
                    key: ValueKey(
                      'plan-calendar-vertical-${startsAt.microsecondsSinceEpoch}',
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    primary: false,
                    child: SingleChildScrollView(
                      key: ValueKey(
                        'plan-calendar-horizontal-${startsAt.microsecondsSinceEpoch}',
                      ),
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      physics: const ClampingScrollPhysics(),
                      dragStartBehavior: DragStartBehavior.down,
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PlanTimelineHeader(
                              firstDay: firstDay,
                              days: _horizonDays,
                              labelWidth: _labelWidth,
                              dayWidth: _dayWidth,
                            ),
                            const SizedBox(height: 8),
                            ...groups.map(
                              (group) => _PlanTimelineSection(
                                snapshot: snapshot,
                                group: group,
                                firstDay: startsAt,
                                days: _horizonDays,
                                labelWidth: _labelWidth,
                                dayWidth: _dayWidth,
                                laneHeight: _laneHeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTimelineHeader extends StatelessWidget {
  const _PlanTimelineHeader({
    required this.firstDay,
    required this.days,
    required this.labelWidth,
    required this.dayWidth,
  });

  final DateTime firstDay;
  final int days;
  final double labelWidth;
  final double dayWidth;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: labelWidth),
      ...List.generate(
        days,
        (index) => SizedBox(
          width: dayWidth,
          child: Text(
            DateFormat(
              'EEE\nMMM d',
            ).format(firstDay.add(Duration(days: index))),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ),
    ],
  );
}

class _PlanTimelineSection extends StatefulWidget {
  const _PlanTimelineSection({
    required this.snapshot,
    required this.group,
    required this.firstDay,
    required this.days,
    required this.labelWidth,
    required this.dayWidth,
    required this.laneHeight,
  });

  final UpgradeTrackerSnapshot snapshot;
  final _PlanTimelineGroup group;
  final DateTime firstDay;
  final int days;
  final double labelWidth;
  final double dayWidth;
  final double laneHeight;

  @override
  State<_PlanTimelineSection> createState() => _PlanTimelineSectionState();
}

class _PlanTimelineSectionState extends State<_PlanTimelineSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.group.type.accent;
    final plannedLanes = widget.group.lanes
        .where((lane) => lane.upgrades.isNotEmpty)
        .toList(growable: false);
    final scheduledCount = plannedLanes.expand((lane) => lane.upgrades).length;
    if (plannedLanes.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 2),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                  const SizedBox(width: 3),
                  _AspectSafeImage(
                    imageUrl: _planCalendarGroupImage(
                      widget.snapshot,
                      widget.group.type,
                    ),
                    width: 28,
                    height: 25,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.group.type.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    '$scheduledCount upgrades',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      ...plannedLanes.map(
                        (lane) => _PlanTimelineLane(
                          label: _planLaneLabel(
                            widget.snapshot,
                            widget.group.type,
                            lane,
                          ),
                          upgrades: lane.upgrades,
                          firstDay: widget.firstDay,
                          days: widget.days,
                          labelWidth: widget.labelWidth,
                          dayWidth: widget.dayWidth,
                          laneHeight: widget.laneHeight,
                          accent: accent,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _PlanTimelineLane extends StatelessWidget {
  const _PlanTimelineLane({
    required this.label,
    required this.upgrades,
    required this.firstDay,
    required this.days,
    required this.labelWidth,
    required this.dayWidth,
    required this.laneHeight,
    required this.accent,
  });

  final String label;
  final List<PlannedUpgrade> upgrades;
  final DateTime firstDay;
  final int days;
  final double labelWidth;
  final double dayWidth;
  final double laneHeight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = days * dayWidth;
    return SizedBox(
      height: laneHeight,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: width,
            height: laneHeight,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Row(
                      children: List.generate(
                        days,
                        (index) => Container(
                          width: dayWidth,
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.18)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...upgrades.map(
                    (upgrade) => _PlanTimelineBlock(
                      upgrade: upgrade,
                      firstDay: firstDay,
                      days: days,
                      width: width,
                      dayWidth: dayWidth,
                      accent: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTimelineBlock extends StatelessWidget {
  const _PlanTimelineBlock({
    required this.upgrade,
    required this.firstDay,
    required this.days,
    required this.width,
    required this.dayWidth,
    required this.accent,
  });

  final PlannedUpgrade upgrade;
  final DateTime firstDay;
  final int days;
  final double width;
  final double dayWidth;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final horizonEnd = firstDay.add(Duration(days: days));
    if (!upgrade.endsAt.isAfter(firstDay) ||
        !upgrade.startsAt.isBefore(horizonEnd)) {
      return const SizedBox.shrink();
    }
    final visibleStart = upgrade.startsAt.isBefore(firstDay)
        ? firstDay
        : upgrade.startsAt;
    final visibleEnd = upgrade.endsAt.isAfter(horizonEnd)
        ? horizonEnd
        : upgrade.endsAt;
    final left = visibleStart.difference(firstDay).inMinutes / 1440 * dayWidth;
    final duration = visibleEnd.difference(visibleStart).inMinutes;
    final blockWidth = math.max(
      1.0,
      math.min(width - left, duration / 1440 * dayWidth),
    );
    final iconOnly = blockWidth < 54;
    final showMetadata = blockWidth >= 126;
    final firstCost = upgrade.costs.firstOrNull;
    return Positioned(
      left: left + 0.75,
      top: 3,
      width: math.max(1.0, blockWidth - 1.5).toDouble(),
      height: 56,
      child: Semantics(
        label:
            '${upgrade.item.name}, level ${upgrade.step.targetLevel}, ${_timelineDateTimeLabel(upgrade.startsAt)} to ${_timelineDateTimeLabel(upgrade.endsAt)}',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly ? 2 : 6,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(10),
            border: upgrade.isOngoing
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.92),
                    width: 2,
                  )
                : null,
          ),
          child: blockWidth < 24
              ? const SizedBox.shrink()
              : iconOnly
              ? Center(
                  child: _AspectSafeImage(
                    imageUrl: upgrade.item.imageUrl,
                    width: 24,
                    height: 24,
                  ),
                )
              : Row(
                  children: [
                    _AspectSafeImage(
                      imageUrl: upgrade.item.imageUrl,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${upgrade.isOngoing ? 'Now · ' : ''}${upgrade.item.name} · Lv ${upgrade.step.targetLevel}',
                            maxLines: showMetadata ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.05,
                                ),
                          ),
                          if (showMetadata) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (firstCost != null) ...[
                                  Flexible(
                                    child: _TimelineMiniChip(
                                      imageUrl: _resourceImage(
                                        firstCost.resource,
                                      ),
                                      text: _compact(firstCost.amount),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                _TimelineMiniChip(
                                  icon: Icons.schedule_rounded,
                                  text: _duration(
                                    upgrade.endsAt
                                        .difference(upgrade.startsAt)
                                        .inSeconds,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TimelineMiniChip extends StatelessWidget {
  const _TimelineMiniChip({required this.text, this.imageUrl, this.icon});

  final String text;
  final String? imageUrl;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 72),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageUrl != null) ...[
          _AspectSafeImage(imageUrl: imageUrl!, width: 11, height: 11),
          const SizedBox(width: 2),
        ] else if (icon != null) ...[
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 8.5,
              height: 1,
            ),
          ),
        ),
      ],
    ),
  );
}

String _timelineDateTimeLabel(DateTime value) =>
    DateFormat('MMM d HH:mm').format(value);

class _PlanRuleNote extends StatelessWidget {
  const _PlanRuleNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Numbered tiers run first. Shared rows keep the same tier number, and their mix is normalized from the relative weights, so 50 + 25 becomes 67% / 33%. A target makes a category yield after it reaches that percentage while it stays eligible later.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LootOutlookCard extends StatelessWidget {
  const _LootOutlookCard({required this.lanes, required this.startsAt});

  final List<UpgradePlanLane> lanes;
  final DateTime startsAt;

  @override
  Widget build(BuildContext context) {
    final upgrades = lanes
        .expand((lane) => lane.upgrades)
        .where((upgrade) => !upgrade.isOngoing)
        .toList();
    upgrades.sort((a, b) {
      final starts = a.startsAt.compareTo(b.startsAt);
      return starts != 0 ? starts : a.endsAt.compareTo(b.endsAt);
    });
    List<PlannedUpgrade> within(int days) => upgrades
        .where(
          (upgrade) =>
              upgrade.startsAt.isBefore(startsAt.add(Duration(days: days))),
        )
        .toList(growable: false);
    Map<String, num> costsFor(List<PlannedUpgrade> period) {
      final costs = <String, num>{};
      for (final upgrade in period) {
        for (final cost in upgrade.costs) {
          costs[cost.resource] = (costs[cost.resource] ?? 0) + cost.amount;
        }
      }
      return costs;
    }

    final week = within(7);
    final month = within(30);
    final lootNow = upgrades
        .where(
          (upgrade) =>
              upgrade.item.village == UpgradeVillage.home &&
              upgrade.item.queue == UpgradeQueue.builders &&
              !upgrade.startsAt.isAfter(
                startsAt.add(const Duration(minutes: 1)),
              ),
        )
        .toList(growable: false);
    return CKSectionPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loot outlook',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          _PlanPeriodSummary(
            label: lootNow.isEmpty
                ? 'Loot now · all builders occupied'
                : 'Loot now · ${lootNow.length} idle ${lootNow.length == 1 ? 'builder' : 'builders'}',
            upgrades: lootNow,
            costs: costsFor(lootNow),
            countLabel: lootNow.isEmpty
                ? 'Nothing needed right now'
                : 'to put every free builder to work',
            showCount: false,
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PlanPeriodSummary(
                  label: 'Next 7 days',
                  upgrades: week,
                  costs: costsFor(week),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanPeriodSummary(
                  label: 'Next 30 days',
                  upgrades: month,
                  costs: costsFor(month),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanPeriodSummary extends StatelessWidget {
  const _PlanPeriodSummary({
    required this.label,
    required this.upgrades,
    required this.costs,
    this.countLabel = 'upgrades starting',
    this.showCount = true,
  });

  final String label;
  final List<PlannedUpgrade> upgrades;
  final Map<String, num> costs;
  final String countLabel;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = costs.entries.toList()
      ..sort(
        (a, b) => _resourceWeight(a.key).compareTo(_resourceWeight(b.key)),
      );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (showCount) ...[
            const SizedBox(height: 2),
            Text(
              '${upgrades.length}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              countLabel,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const Divider(height: 16),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: ordered
                .take(4)
                .map(
                  (entry) => _ResourcePill(
                    cost: UpgradeCost(entry.key, entry.value),
                    compact: true,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _PlannedUpgradeGroup {
  const _PlannedUpgradeGroup(this.upgrades);

  final List<PlannedUpgrade> upgrades;

  PlannedUpgrade get first => upgrades.first;
  int get count => upgrades.length;
  bool get isOngoing => upgrades.any((upgrade) => upgrade.isOngoing);

  DateTime get startsAt => upgrades
      .map((upgrade) => upgrade.startsAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get endsAt => upgrades
      .map((upgrade) => upgrade.endsAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  List<UpgradeCost> get costs {
    final totals = <String, num>{};
    for (final upgrade in upgrades) {
      for (final cost in upgrade.costs) {
        totals[cost.resource] = (totals[cost.resource] ?? 0) + cost.amount;
      }
    }
    return totals.entries
        .map((entry) => UpgradeCost(entry.key, entry.value))
        .toList(growable: false);
  }
}

List<_PlannedUpgradeGroup> _groupPlannedUpgrades(
  List<PlannedUpgrade> upgrades,
) {
  final groups = <String, List<PlannedUpgrade>>{};
  for (final upgrade in upgrades) {
    final isWall = upgrade.item.category == UpgradeCategory.walls;
    final date = upgrade.startsAt;
    final key = isWall
        ? 'wall:${upgrade.item.planKey}:${upgrade.step.targetLevel}:${date.year}-${date.month}-${date.day}'
        : 'single:${upgrade.item.planKey}:${upgrade.instance}:${upgrade.step.targetLevel}:${date.microsecondsSinceEpoch}';
    groups.putIfAbsent(key, () => []).add(upgrade);
  }
  return groups.values.map(_PlannedUpgradeGroup.new).toList(growable: false);
}

class _PlannedUpgradeRow extends StatelessWidget {
  const _PlannedUpgradeRow({required this.group});

  final _PlannedUpgradeGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final upgrade = group.first;
    final item = upgrade.item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _AspectSafeImage(
            imageUrl: upgrade.item.imageUrl,
            width: 48,
            height: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name}${group.count > 1 ? ' ×${group.count}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Level ${upgrade.step.targetLevel - 1} → ${upgrade.step.targetLevel} · ${DateFormat.MMMd().format(group.startsAt)}',
                      ),
                      if (group.isOngoing)
                        TextSpan(
                          text: ' · Upgrading now',
                          style: const TextStyle(
                            color: CKUpgradeColors.completion,
                          ),
                        ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (group.costs.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: group.costs
                        .map((cost) => _ResourcePill(cost: cost, compact: true))
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          _Pill(
            text: _duration(group.endsAt.difference(group.startsAt).inSeconds),
          ),
        ],
      ),
    );
  }
}

enum _PlanVillageFilter { all, home, builderBase }

enum _PlanQueueFilter { all, builders, laboratory, pets, walls }

enum _PlanSort { scheduled, nameAscending, durationLong, durationShort }

String _planSortLabel(_PlanSort sort) => switch (sort) {
  _PlanSort.scheduled => 'Scheduled',
  _PlanSort.nameAscending => 'Name A–Z',
  _PlanSort.durationLong => 'Longest first',
  _PlanSort.durationShort => 'Shortest first',
};

String _planVillageFilterLabel(_PlanVillageFilter filter) => switch (filter) {
  _PlanVillageFilter.all => 'All villages',
  _PlanVillageFilter.home => 'Home Village',
  _PlanVillageFilter.builderBase => 'Builder Base',
};

String _planQueueFilterLabel(_PlanQueueFilter filter) => switch (filter) {
  _PlanQueueFilter.all => 'All queues',
  _PlanQueueFilter.builders => 'Builders',
  _PlanQueueFilter.laboratory => 'Laboratory',
  _PlanQueueFilter.pets => 'Pets',
  _PlanQueueFilter.walls => 'Walls',
};

bool _matchesPlanFilters(
  PlannedUpgrade upgrade,
  _PlanVillageFilter village,
  _PlanQueueFilter queue,
) {
  final matchesVillage = switch (village) {
    _PlanVillageFilter.all => true,
    _PlanVillageFilter.home => upgrade.item.village == UpgradeVillage.home,
    _PlanVillageFilter.builderBase =>
      upgrade.item.village == UpgradeVillage.builderBase,
  };
  final matchesQueue = switch (queue) {
    _PlanQueueFilter.all => true,
    _PlanQueueFilter.builders =>
      upgrade.item.queue == UpgradeQueue.builders &&
          upgrade.item.category != UpgradeCategory.walls,
    _PlanQueueFilter.laboratory =>
      upgrade.item.queue == UpgradeQueue.laboratory,
    _PlanQueueFilter.pets => upgrade.item.queue == UpgradeQueue.pets,
    _PlanQueueFilter.walls => upgrade.item.category == UpgradeCategory.walls,
  };
  return matchesVillage && matchesQueue;
}

enum _UpgradeGroup {
  buildings,
  defenses,
  craftedDefenses,
  traps,
  supercharges,
  heroes,
  guardians,
  laboratory,
  equipment,
  pets,
  walls,
  helpers,
}

List<_UpgradeGroup> _availableUpgradeGroups(
  UpgradeTrackerSnapshot snapshot,
  UpgradeVillage village,
) => _UpgradeGroup.values
    .where(
      (group) => snapshot
          .itemsFor(village: village)
          .any((item) => _upgradeGroupFor(item.category) == group),
    )
    .toList(growable: false);

_UpgradeGroup _upgradeGroupFor(UpgradeCategory category) => switch (category) {
  UpgradeCategory.army || UpgradeCategory.resources => _UpgradeGroup.buildings,
  UpgradeCategory.defenses => _UpgradeGroup.defenses,
  UpgradeCategory.craftedDefenses => _UpgradeGroup.craftedDefenses,
  UpgradeCategory.traps => _UpgradeGroup.traps,
  UpgradeCategory.supercharge => _UpgradeGroup.supercharges,
  UpgradeCategory.heroes => _UpgradeGroup.heroes,
  UpgradeCategory.guardians => _UpgradeGroup.guardians,
  UpgradeCategory.troops ||
  UpgradeCategory.darkTroops ||
  UpgradeCategory.spells ||
  UpgradeCategory.sieges => _UpgradeGroup.laboratory,
  UpgradeCategory.equipment => _UpgradeGroup.equipment,
  UpgradeCategory.pets => _UpgradeGroup.pets,
  UpgradeCategory.walls => _UpgradeGroup.walls,
  UpgradeCategory.builders => _UpgradeGroup.helpers,
};

String _upgradeGroupLabel(_UpgradeGroup group) => switch (group) {
  _UpgradeGroup.buildings => 'Buildings',
  _UpgradeGroup.defenses => 'Defenses',
  _UpgradeGroup.craftedDefenses => 'Crafted Defenses',
  _UpgradeGroup.traps => 'Traps',
  _UpgradeGroup.supercharges => 'Supercharges',
  _UpgradeGroup.heroes => 'Heroes',
  _UpgradeGroup.guardians => 'Guardians',
  _UpgradeGroup.laboratory => 'Laboratory',
  _UpgradeGroup.equipment => 'Equipment',
  _UpgradeGroup.pets => 'Pets',
  _UpgradeGroup.walls => 'Walls',
  _UpgradeGroup.helpers => 'Helpers',
};

String _upgradeGroupLabelForVillage(
  _UpgradeGroup group,
  UpgradeVillage village,
) {
  if (group != _UpgradeGroup.helpers) return _upgradeGroupLabel(group);
  return village == UpgradeVillage.home ? 'Helpers' : 'Builders';
}

bool _itemBelongsToUpgradeGroup(
  UpgradeTrackerItem item,
  _UpgradeGroup group,
  UpgradeVillage village,
) {
  if (_upgradeGroupFor(item.category) != group) return false;
  if (group != _UpgradeGroup.helpers) return true;
  return village == UpgradeVillage.home
      ? item.queue == UpgradeQueue.none
      : item.queue == UpgradeQueue.builders;
}

String _groupImage(
  UpgradeTrackerSnapshot snapshot,
  _UpgradeGroup group,
  UpgradeVillage village,
) =>
    snapshot
        .itemsFor(village: village)
        .where((item) => _upgradeGroupFor(item.category) == group)
        .firstOrNull
        ?.imageUrl ??
    ImageAssets.defaultImage;

class _AspectSafeImage extends StatelessWidget {
  const _AspectSafeImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Center(
      child: MobileWebImage(imageUrl: imageUrl, fit: BoxFit.contain),
    ),
  );
}

enum _CollectionFilter { all, owned, missing }

enum _CollectionSort { nameAscending, nameDescending, newest, oldest }

class _CollectionTab extends StatefulWidget {
  const _CollectionTab({required this.snapshot});

  final UpgradeTrackerSnapshot snapshot;

  @override
  State<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<_CollectionTab> {
  final _expanded = <UpgradeCollectionType>{UpgradeCollectionType.skins};
  final _searchController = TextEditingController();
  _CollectionFilter _filter = _CollectionFilter.all;
  _CollectionSort _sort = _CollectionSort.nameAscending;
  UpgradeVillage? _village;
  String _query = '';
  bool _showFilters = false;
  late bool _supportsVillage;
  late Map<UpgradeCollectionType, List<UpgradeCollectionItem>> _itemsByType;
  late List<_CollectionSectionViewData> _sections;

  @override
  void initState() {
    super.initState();
    _indexSnapshot();
    _rebuildSections();
  }

  @override
  void didUpdateWidget(covariant _CollectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.snapshot, widget.snapshot)) {
      _indexSnapshot();
      _rebuildSections();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _indexSnapshot() {
    _itemsByType = {for (final type in UpgradeCollectionType.values) type: []};
    var hasHome = false;
    var hasBuilderBase = false;
    for (final item in widget.snapshot.collections) {
      _itemsByType[item.type]!.add(item);
      hasHome |= item.village == UpgradeVillage.home;
      hasBuilderBase |= item.village == UpgradeVillage.builderBase;
    }
    _supportsVillage = hasHome && hasBuilderBase;
  }

  void _update(VoidCallback change) {
    setState(() {
      change();
      _rebuildSections();
    });
  }

  void _rebuildSections() {
    final normalized = _query.trim().toLowerCase();
    _sections = [];
    for (final type in UpgradeCollectionType.values) {
      final all = _itemsByType[type]!;
      if (all.isEmpty) continue;
      final scoped = all
          .where(
            (item) =>
                _village == null ||
                type == UpgradeCollectionType.capitalHouseParts ||
                item.village == _village,
          )
          .toList(growable: false);
      if (scoped.isEmpty) continue;
      final visible = scoped.where((item) {
        if (_filter == _CollectionFilter.owned && !item.owned) return false;
        if (_filter == _CollectionFilter.missing && item.owned) return false;
        return normalized.isEmpty ||
            item.name.toLowerCase().contains(normalized);
      }).toList();
      visible.sort(
        (a, b) => switch (_sort) {
          _CollectionSort.nameAscending => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
          _CollectionSort.nameDescending => b.name.toLowerCase().compareTo(
            a.name.toLowerCase(),
          ),
          _CollectionSort.newest => b.id.compareTo(a.id),
          _CollectionSort.oldest => a.id.compareTo(b.id),
        },
      );
      _sections.add(
        _CollectionSectionViewData(
          type: type,
          scoped: scoped,
          visible: visible,
          owned: scoped.where((item) => item.owned).length,
          preview:
              scoped.where((item) => item.owned).firstOrNull ?? scoped.first,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _trackerContentGutter,
          8,
          _trackerContentGutter,
          10,
        ),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      query: _query,
                      hintText: l10n.upgradeTrackerSearchCollection,
                      onChanged: (value) => _update(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: CKSpacing.sm),
                  IconButton.filledTonal(
                    tooltip: _showFilters
                        ? l10n.upgradeTrackerHideFilters
                        : l10n.upgradeTrackerShowFilters,
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    icon: Icon(
                      _showFilters
                          ? Icons.filter_list_off_rounded
                          : Icons.filter_list_rounded,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: CKMotion.durationOf(context, CKMotion.standard),
                curve: CKMotion.standardCurve,
                alignment: Alignment.topCenter,
                child: !_showFilters
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: CKSpacing.sm),
                        child: Column(
                          children: [
                            CKSegmentedControl<_CollectionFilter>(
                              values: _CollectionFilter.values,
                              labels: [
                                l10n.upgradeTrackerFilterAll,
                                l10n.upgradeTrackerFilterOwned,
                                l10n.upgradeTrackerFilterMissing,
                              ],
                              selected: _filter,
                              density: CKControlDensity.compact,
                              onChanged: (value) =>
                                  _update(() => _filter = value),
                            ),
                            const SizedBox(height: CKSpacing.sm),
                            Row(
                              children: [
                                if (_supportsVillage)
                                  Expanded(
                                    child: CKSegmentedControl<UpgradeVillage?>(
                                      values: const [
                                        null,
                                        UpgradeVillage.home,
                                        UpgradeVillage.builderBase,
                                      ],
                                      labels: [
                                        l10n.upgradeTrackerFilterAll,
                                        l10n.upgradeTrackerHomeVillage,
                                        l10n.upgradeTrackerBuilderBase,
                                      ],
                                      selected: _village,
                                      density: CKControlDensity.compact,
                                      onChanged: (value) =>
                                          _update(() => _village = value),
                                    ),
                                  ),
                                if (_supportsVillage)
                                  const SizedBox(width: CKSpacing.sm),
                                FilterDropdown(
                                  sortBy: _sort.name,
                                  maxWidth: 118,
                                  sortByOptions: const {
                                    'Name A–Z': 'nameAscending',
                                    'Name Z–A': 'nameDescending',
                                    'Newest': 'newest',
                                    'Oldest': 'oldest',
                                  },
                                  updateSortBy: (value) => _update(
                                    () => _sort = _CollectionSort.values.byName(
                                      value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ];

    for (final section in _sections) {
      final expanded = _expanded.contains(section.type);
      final title = _collectionLabel(section.type);
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: _trackerContentGutter,
          ),
          sliver: SliverToBoxAdapter(
            child: _TrackerCollapsibleCard(
              title: title,
              imageUrl: section.preview.imageUrl,
              completion: section.owned / section.scoped.length,
              countLabel: l10n.upgradeTrackerOwnedCount(
                section.owned,
                section.scoped.length,
              ),
              expanded: expanded,
              onToggle: () => setState(() {
                expanded
                    ? _expanded.remove(section.type)
                    : _expanded.add(section.type);
              }),
              onSummaryTap: () => _showCollectionSectionSummary(
                context,
                title,
                items: section.scoped,
              ),
              showContent: false,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      final sectionSlivers = <Widget>[];
      if (expanded && section.visible.isEmpty) {
        sectionSlivers.add(
          SliverPadding(
            padding: const EdgeInsets.all(CKSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.upgradeTrackerNoMatchingItems,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      } else if (expanded) {
        sectionSlivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _trackerContentGutter,
              4,
              _trackerContentGutter,
              14,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: section.type == UpgradeCollectionType.sceneries
                    ? 2
                    : 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
                childAspectRatio:
                    section.type == UpgradeCollectionType.sceneries
                    ? 1.12
                    : 0.84,
              ),
              itemCount: section.visible.length,
              itemBuilder: (context, index) =>
                  _CollectionTile(item: section.visible[index]),
            ),
          ),
        );
      }
      slivers.add(
        SliverAnimatedPaintExtent(
          duration: CKMotion.durationOf(context, CKMotion.standard),
          curve: CKMotion.standardCurve,
          child: expanded
              ? SliverMainAxisGroup(slivers: sectionSlivers)
              : SliverToBoxAdapter(child: const SizedBox.shrink()),
        ),
      );
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 28)));
    return CustomScrollView(slivers: slivers);
  }
}

class _CollectionSectionViewData {
  const _CollectionSectionViewData({
    required this.type,
    required this.scoped,
    required this.visible,
    required this.owned,
    required this.preview,
  });

  final UpgradeCollectionType type;
  final List<UpgradeCollectionItem> scoped;
  final List<UpgradeCollectionItem> visible;
  final int owned;
  final UpgradeCollectionItem preview;
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.item});

  final UpgradeCollectionItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = MobileWebImage(imageUrl: item.imageUrl, fit: BoxFit.contain);
    final artwork = item.owned
        ? image
        : ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              0.56,
              0,
            ]),
            child: image,
          );
    return CKCollectionTile(
      image: Stack(
        fit: StackFit.expand,
        children: [
          Padding(padding: const EdgeInsets.all(2), child: artwork),
          if (item.count > 1)
            Positioned(right: 2, top: 2, child: _Pill(text: '×${item.count}')),
          if (item.type == UpgradeCollectionType.skins &&
              item.meta?['tier'] != null)
            Positioned(
              right: 4,
              top: 4,
              child: _CollectionTierCorner(
                color: _skinTierColor(item.meta!['tier'].toString()),
              ),
            ),
        ],
      ),
      label: _collectionDisplayName(item),
      owned: item.owned,
      semanticLabel:
          '${_collectionDisplayName(item)}, ${item.owned ? l10n.upgradeTrackerCollected : l10n.upgradeTrackerMissing}',
      onTap: () => _showCollectionPreview(context, item),
    );
  }
}

class _ShareCollectionSheet extends StatefulWidget {
  const _ShareCollectionSheet({required this.snapshot});

  final UpgradeTrackerSnapshot snapshot;

  @override
  State<_ShareCollectionSheet> createState() => _ShareCollectionSheetState();
}

class _ShareCollectionSheetState extends State<_ShareCollectionSheet> {
  final _boundaryKey = GlobalKey();
  int _exportPreview = 2;
  bool _sharing = false;

  Future<void> _share() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    try {
      await _precacheTrackerArtwork(context, widget.snapshot);
      final bytes = await _graphicBytes(boundary);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final tag = widget.snapshot.tag.replaceAll('#', '').toLowerCase();
      final file = File('${dir.path}/clashking-collection-$tag.png');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '${widget.snapshot.name} collection on ClashKing',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareAll() async {
    final originalPreview = _exportPreview;
    setState(() => _sharing = true);
    try {
      await _precacheTrackerArtwork(context, widget.snapshot);
      final files = <XFile>[];
      for (final entry in const [
        (preview: 0, suffix: 'home-progress'),
        (preview: 1, suffix: 'builder-progress'),
        (preview: 2, suffix: 'collection'),
      ]) {
        setState(() => _exportPreview = entry.preview);
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 180));
        await WidgetsBinding.instance.endOfFrame;
        final file = await _graphicFile(
          widget.snapshot,
          _boundaryKey,
          entry.suffix,
        );
        if (file == null) return;
        files.add(file);
      }
      if (!mounted) return;
      setState(() => _exportPreview = originalPreview);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: '${widget.snapshot.name} progress and collection on ClashKing',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exportPreview = originalPreview;
          _sharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShareSheetFrame(
      title: 'Share collection',
      button: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(_sharing ? 'Preparing images…' : 'Share collection'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sharing ? null : _shareAll,
              icon: const Icon(Icons.collections_rounded),
              label: const Text('Share all 3'),
            ),
          ),
        ],
      ),
      child: RepaintBoundary(
        key: _boundaryKey,
        child: switch (_exportPreview) {
          0 => _ProgressGraphic(
            snapshot: widget.snapshot,
            village: UpgradeVillage.home,
          ),
          1 => _ProgressGraphic(
            snapshot: widget.snapshot,
            village: UpgradeVillage.builderBase,
          ),
          _ => _CollectionGraphic(snapshot: widget.snapshot),
        },
      ),
    );
  }
}

class _ShareSheetFrame extends StatelessWidget {
  const _ShareSheetFrame({
    required this.title,
    required this.child,
    required this.button,
  });

  final String title;
  final Widget child;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.62,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Center(child: AspectRatio(aspectRatio: 1, child: child)),
            const SizedBox(height: 14),
            button,
          ],
        ),
      ),
    );
  }
}

Future<void> _precacheTrackerArtwork(
  BuildContext context,
  UpgradeTrackerSnapshot snapshot,
) async {
  final urls = <String>{
    ImageAssets.townHall(snapshot.townHallLevel),
    ImageAssets.builderHall(snapshot.builderHallLevel),
    ImageAssets.homeBaseBackground,
    ImageAssets.builderBaseBackground,
    ...snapshot.items
        .where((item) => snapshot.remainingActiveSeconds(item) > 0)
        .map((item) => item.imageUrl),
    ...snapshot.items
        .expand((item) => item.totalCosts.keys)
        .map(_resourceImage),
  };
  for (final category in UpgradeCategory.values) {
    final item = snapshot.items
        .where((candidate) => candidate.category == category)
        .firstOrNull;
    if (item != null) urls.add(item.imageUrl);
  }
  for (final type in UpgradeCollectionType.values) {
    final items = snapshot.collections.where((item) => item.type == type);
    final item =
        items.where((item) => item.owned).firstOrNull ?? items.firstOrNull;
    if (item != null) urls.add(item.imageUrl);
  }
  await Future.wait(
    urls
        .where((url) => url.startsWith('http'))
        .map(
          (url) => precacheImage(
            CachedNetworkImageProvider(url),
            context,
          ).catchError((_) {}),
        ),
  );
}

class _CollectionGraphic extends StatelessWidget {
  const _CollectionGraphic({required this.snapshot});

  final UpgradeTrackerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final types = UpgradeCollectionType.values.where(
      (type) => snapshot.collections.any((item) => item.type == type),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: const Color(0xFF0D0D0F),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MobileWebImage(
                    imageUrl: ImageAssets.townHall(snapshot.townHallLevel),
                    width: 54,
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Collection',
                          style: TextStyle(
                            color: Color(0xFFBFC2C8),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.18,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: types.map((type) {
                    final items = snapshot.collections
                        .where((item) => item.type == type)
                        .toList();
                    final owned = items.where((item) => item.owned).length;
                    final value = type == UpgradeCollectionType.obstacles
                        ? items.fold<int>(0, (sum, item) => sum + item.count)
                        : owned;
                    final image =
                        items.where((item) => item.owned).firstOrNull ??
                        items.first;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF313137)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox.square(
                              dimension: 28,
                              child: MobileWebImage(
                                imageUrl: image.imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              type == UpgradeCollectionType.obstacles
                                  ? '$value owned'
                                  : '$value/${items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _collectionLabel(type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBFC2C8),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Row(
                children: [
                  Image.asset(
                    'assets/icons/app_icon_dark_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ClashKing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Uint8List?> _graphicBytes(RenderRepaintBoundary boundary) async {
  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes?.buffer.asUint8List();
}

Future<XFile?> _graphicFile(
  UpgradeTrackerSnapshot snapshot,
  GlobalKey boundaryKey,
  String suffix,
) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final bytes = await _graphicBytes(boundary);
  if (bytes == null) return null;
  final dir = await getTemporaryDirectory();
  final tag = snapshot.tag.replaceAll('#', '').toLowerCase();
  final file = File('${dir.path}/clashking-$suffix-$tag.png');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: 'image/png');
}

class _ShareProgressSheet extends StatefulWidget {
  const _ShareProgressSheet({required this.snapshot, required this.village});

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeVillage village;

  @override
  State<_ShareProgressSheet> createState() => _ShareProgressSheetState();
}

class _ShareProgressSheetState extends State<_ShareProgressSheet> {
  final _boundaryKey = GlobalKey();
  late int _exportPreview;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _exportPreview = widget.village == UpgradeVillage.home ? 0 : 1;
  }

  Future<void> _share() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    try {
      await _precacheTrackerArtwork(context, widget.snapshot);
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final tag = widget.snapshot.tag.replaceAll('#', '').toLowerCase();
      final file = File('${dir.path}/clashking-progress-$tag.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '${widget.snapshot.name} on ClashKing',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareAll() async {
    final originalPreview = _exportPreview;
    setState(() => _sharing = true);
    try {
      await _precacheTrackerArtwork(context, widget.snapshot);
      final files = <XFile>[];
      for (final entry in const [
        (preview: 0, suffix: 'home-progress'),
        (preview: 1, suffix: 'builder-progress'),
        (preview: 2, suffix: 'collection'),
      ]) {
        setState(() => _exportPreview = entry.preview);
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 180));
        await WidgetsBinding.instance.endOfFrame;
        final file = await _graphicFile(
          widget.snapshot,
          _boundaryKey,
          entry.suffix,
        );
        if (file == null) return;
        files.add(file);
      }
      if (!mounted) return;
      setState(() => _exportPreview = originalPreview);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: '${widget.snapshot.name} progress and collection on ClashKing',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exportPreview = originalPreview;
          _sharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.62,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share progress',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: switch (_exportPreview) {
                    0 => _ProgressGraphic(
                      snapshot: widget.snapshot,
                      village: UpgradeVillage.home,
                    ),
                    1 => _ProgressGraphic(
                      snapshot: widget.snapshot,
                      village: UpgradeVillage.builderBase,
                    ),
                    _ => _CollectionGraphic(snapshot: widget.snapshot),
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(_sharing ? 'Preparing images…' : 'Share progress'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sharing ? null : _shareAll,
                icon: const Icon(Icons.collections_rounded),
                label: const Text('Share all 3'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressGraphic extends StatelessWidget {
  const _ProgressGraphic({required this.snapshot, required this.village});

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeVillage village;

  @override
  Widget build(BuildContext context) {
    final overall = snapshot.overallSummary(village: village);
    final now = DateTime.now();
    final planLanes = [
      ...snapshot.buildPlan(
        queue: UpgradeQueue.builders,
        strategy: UpgradePlanStrategy.balanced,
        village: village,
        startsAt: now,
      ),
      ...snapshot.buildPlan(
        queue: UpgradeQueue.laboratory,
        strategy: UpgradePlanStrategy.balanced,
        village: village,
        startsAt: now,
      ),
      if (village == UpgradeVillage.home)
        ...snapshot.buildPlan(
          queue: UpgradeQueue.pets,
          strategy: UpgradePlanStrategy.balanced,
          village: village,
          startsAt: now,
        ),
    ];
    final finish = planLanes
        .map((lane) => lane.finishesAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, value) {
          if (latest == null || value.isAfter(latest)) return value;
          return latest;
        });
    final daysLeft = finish == null
        ? 0
        : (finish.difference(now).inHours / 24).ceil();
    final resources = overall.costs.entries.toList()
      ..sort(
        (a, b) => _resourceWeight(a.key).compareTo(_resourceWeight(b.key)),
      );
    bool isOre(MapEntry<String, num> entry) =>
        entry.key.toLowerCase().contains('ore');
    final ores = resources.where(isOre).toList(growable: false);
    final primaryResources = resources.where((entry) => !isOre(entry)).take(2);
    final preferred = village == UpgradeVillage.home
        ? const [
            UpgradeCategory.defenses,
            UpgradeCategory.army,
            UpgradeCategory.troops,
            UpgradeCategory.heroes,
            UpgradeCategory.equipment,
            UpgradeCategory.pets,
            UpgradeCategory.walls,
          ]
        : const [
            UpgradeCategory.defenses,
            UpgradeCategory.traps,
            UpgradeCategory.army,
            UpgradeCategory.resources,
            UpgradeCategory.troops,
            UpgradeCategory.heroes,
            UpgradeCategory.walls,
          ];
    final categories = preferred
        .where(
          (category) =>
              snapshot.summaryFor(category, village: village).target > 0,
        )
        .take(ores.isNotEmpty ? 4 : 5);
    final hall = village == UpgradeVillage.home
        ? snapshot.townHallLevel
        : snapshot.builderHallLevel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileWebImage(
            imageUrl: village == UpgradeVillage.home
                ? ImageAssets.homeBaseBackground
                : ImageAssets.builderBaseBackground,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC050506), Color(0xF2050506)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MobileWebImage(
                      imageUrl: village == UpgradeVillage.home
                          ? ImageAssets.townHall(hall)
                          : ImageAssets.builderHall(hall),
                      width: 58,
                      height: 58,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            snapshot.tag,
                            style: const TextStyle(
                              color: Color(0xFFBFC2C8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${(overall.completion * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Village complete',
                  style: TextStyle(
                    color: Color(0xFFD4D7DD),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      Text(
                        '$daysLeft days left',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ...primaryResources.expand(
                        (entry) => [
                          MobileWebImage(
                            imageUrl: _resourceImage(entry.key),
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _compact(entry.value),
                            style: const TextStyle(
                              color: Color(0xFFD4D7DD),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ores.isNotEmpty)
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: [
                        const Text(
                          'Ore needed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...ores
                            .take(3)
                            .expand(
                              (entry) => [
                                MobileWebImage(
                                  imageUrl: _resourceImage(entry.key),
                                  width: 15,
                                  height: 15,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _compact(entry.value),
                                  style: const TextStyle(
                                    color: Color(0xFFD4D7DD),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 7),
                              ],
                            ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                ...categories.map((category) {
                  final summary = snapshot.summaryFor(
                    category,
                    village: village,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 20,
                          child: MobileWebImage(
                            imageUrl: _categoryImage(
                              snapshot,
                              category,
                              village,
                            ),
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 7),
                        SizedBox(
                          width: 68,
                          child: Text(
                            _categoryLabel(category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: summary.completion,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: const Color(0xFF303238),
                            color: summary.completion == 1
                                ? StatColors.win
                                : const Color(0xFFF1B84B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(summary.completion * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Spacer(),
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/app_icon_dark_logo.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ClashKing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${overall.levelsRemaining} levels left',
                      style: const TextStyle(
                        color: Color(0xFFBFC2C8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VillageControl extends StatelessWidget {
  const _VillageControl({required this.value, required this.onChanged});

  final UpgradeVillage value;
  final ValueChanged<UpgradeVillage> onChanged;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSegmentedControl<UpgradeVillage>(
      values: UpgradeVillage.values,
      labels: const ['Home Village', 'Builder Base'],
      selected: value,
      color: Theme.of(context).colorScheme.onSurface,
      height: 40,
      onChanged: onChanged,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.42)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            side: BorderSide(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.72)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 6, 13, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcePill extends StatelessWidget {
  const _ResourcePill({required this.cost, this.compact = false});

  final UpgradeCost cost;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(
            imageUrl: _resourceImage(cost.resource),
            width: compact ? 14 : 17,
            height: compact ? 14 : 17,
          ),
          const SizedBox(width: 4),
          Text(
            _compact(cost.amount),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TrackerEmptyState extends StatelessWidget {
  const _TrackerEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.detail,
    this.stickerUrl,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? detail;
  final String? stickerUrl;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CKSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CKSectionPanel(
            padding: const EdgeInsets.all(CKSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stickerUrl != null)
                  MobileWebImage(
                    imageUrl: stickerUrl!,
                    width: 118,
                    height: 104,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(icon, size: 48, color: scheme.onSurfaceVariant),
                const SizedBox(height: CKSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CKTypography.of(context, CKTextRole.sectionTitle),
                ),
                const SizedBox(height: CKSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: CKTypography.of(
                    context,
                    CKTextRole.body,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
                if (detail != null) ...[
                  const SizedBox(height: CKSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(CKSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.32,
                      ),
                      borderRadius: BorderRadius.circular(CKRadius.control),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: CKSpacing.sm),
                        Expanded(
                          child: Text(
                            detail!,
                            style: CKTypography.of(
                              context,
                              CKTextRole.metadata,
                            ).copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: CKSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.content_paste_rounded),
                      label: Text(actionLabel!),
                    ),
                  ),
                ],
                if (secondaryActionLabel != null &&
                    onSecondaryAction != null) ...[
                  const SizedBox(height: CKSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: onSecondaryAction,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(secondaryActionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackerAccountOption {
  const _TrackerAccountOption({
    required this.tag,
    required this.name,
    required this.subtitle,
    this.townHallLevel = 0,
    this.builderHallLevel = 0,
    this.capturedAt,
  });

  final String tag;
  final String name;
  final String subtitle;
  final int townHallLevel;
  final int builderHallLevel;
  final DateTime? capturedAt;
}

class _AccountPickerSheet extends StatefulWidget {
  const _AccountPickerSheet({
    required this.accounts,
    required this.selectedTag,
    required this.onImport,
  });

  final List<_TrackerAccountOption> accounts;
  final String? selectedTag;
  final VoidCallback onImport;

  @override
  State<_AccountPickerSheet> createState() => _AccountPickerSheetState();
}

class _AccountPickerSheetState extends State<_AccountPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = _query.trim().toLowerCase();
    final accounts = widget.accounts
        .where(
          (account) =>
              normalized.isEmpty ||
              account.name.toLowerCase().contains(normalized) ||
              account.tag.toLowerCase().contains(normalized),
        )
        .toList();
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.accountsManageTitle,
                    style: CKTypography.of(context, CKTextRole.screenTitle),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppSearchField(
              controller: _searchController,
              query: _query,
              hintText: l10n.upgradeTrackerChooseAccount,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                final selected =
                    UpgradeTrackerRepository.normalizeTag(account.tag) ==
                    UpgradeTrackerRepository.normalizeTag(
                      widget.selectedTag ?? '',
                    );
                final hall = account.townHallLevel > 0
                    ? ImageAssets.townHall(account.townHallLevel)
                    : account.builderHallLevel > 0
                    ? ImageAssets.builderHall(account.builderHallLevel)
                    : null;
                return ListTile(
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.onSurface,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  leading: SizedBox.square(
                    dimension: 44,
                    child: hall == null
                        ? const Icon(Icons.person_rounded)
                        : MobileWebImage(imageUrl: hall, fit: BoxFit.contain),
                  ),
                  title: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      '${account.tag} · ${account.subtitle}',
                      if (account.capturedAt case final capturedAt?)
                        _snapshotAgeLabel(context, capturedAt),
                    ].join('\n'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, account.tag),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                ),
                onPressed: widget.onImport,
                icon: const Icon(Icons.content_paste_rounded),
                label: Text(l10n.upgradeTrackerImportAction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _activeBoostLabels(
  UpgradeTrackerSnapshot snapshot, {
  DateTime? now,
}) {
  final boosts = snapshot.boosts;
  final labels = <String>[];
  void addTimed(String name, int seconds) {
    final remaining = snapshot.remainingCapturedSeconds(seconds, now: now);
    if (remaining > 0) labels.add('$name · ${_duration(remaining)}');
  }

  addTimed('Builder boost', boosts.builderBoostSeconds);
  addTimed('Research boost', boosts.labBoostSeconds);
  addTimed('Clock Tower', boosts.clockTowerBoostSeconds);
  addTimed('Builder Potion', boosts.builderConsumableSeconds);
  addTimed('Research Potion', boosts.labConsumableSeconds);
  addTimed('Pet Potion', boosts.petConsumableSeconds);
  final clockCooldown = snapshot.remainingCapturedSeconds(
    boosts.clockTowerCooldownSeconds,
    now: now,
  );
  if (boosts.clockTowerBoostSeconds <= 0 && clockCooldown > 0) {
    labels.add('Clock Tower · Ready in ${_duration(clockCooldown)}');
  }
  if (boosts.builderCostReductionPercent > 0 ||
      boosts.builderTimeReductionPercent > 0) {
    labels.add(
      'Builder perk · ${boosts.builderCostReductionPercent}% cost / '
      '${boosts.builderTimeReductionPercent}% time',
    );
  }
  if (boosts.labCostReductionPercent > 0 ||
      boosts.labTimeReductionPercent > 0) {
    labels.add(
      'Research perk · ${boosts.labCostReductionPercent}% cost / '
      '${boosts.labTimeReductionPercent}% time',
    );
  }
  final effectiveNow = now ?? DateTime.now();
  for (final event in snapshot.events) {
    if (!effectiveNow.isBefore(event.startsAt) &&
        effectiveNow.isBefore(event.endsAt)) {
      labels.add(event.name);
    }
  }
  return labels;
}

UpgradePlanPreferences _preferencesForQueue(
  UpgradeTrackerSnapshot snapshot,
  UpgradePlanPreferences source,
  UpgradeVillage village,
  UpgradeQueue queue,
) {
  final available = snapshot
      .itemsFor(village: village, queue: queue)
      .map((item) => item.category)
      .toSet();
  final savedOrder = source.orderFor(village);
  final order = [
    ...savedOrder.where(available.contains),
    ...UpgradeCategory.values.where(
      (category) =>
          available.contains(category) && !savedOrder.contains(category),
    ),
  ];
  return _copyPlanPreferences(
    source,
    homeCategoryOrder: village == UpgradeVillage.home
        ? order
        : source.homeCategoryOrder,
    builderBaseCategoryOrder: village == UpgradeVillage.builderBase
        ? order
        : source.builderBaseCategoryOrder,
  );
}

int _plannerLaneCapacity(
  UpgradeTrackerSnapshot snapshot,
  UpgradeQueue queue,
  UpgradeVillage village,
) => switch (queue) {
  UpgradeQueue.builders => snapshot.buildersFor(village).clamp(1, 7).toInt(),
  UpgradeQueue.laboratory || UpgradeQueue.pets || UpgradeQueue.none => 1,
};

String _planLaneLabel(
  UpgradeTrackerSnapshot snapshot,
  _PlanCalendarGroup group,
  UpgradePlanLane lane,
) {
  final capacity = _plannerLaneCapacity(snapshot, group.queue, group.village);
  if (lane.index < capacity) return 'Slot ${lane.index + 1}';
  return switch (group.queue) {
    UpgradeQueue.builders => 'Goblin Builder',
    UpgradeQueue.laboratory => 'Goblin Researcher',
    UpgradeQueue.pets || UpgradeQueue.none => 'Goblin',
  };
}

List<UpgradePlanLane> _buildPlannerLanes(
  UpgradeTrackerSnapshot snapshot, {
  required UpgradeQueue queue,
  required UpgradePlanStrategy strategy,
  required UpgradeVillage village,
  required DateTime startsAt,
  required int goldPassPercent,
  required UpgradePlanPreferences preferences,
  Set<String>? includedItemKeys,
}) {
  final lanes = snapshot.buildPlan(
    queue: queue,
    strategy: strategy,
    village: village,
    startsAt: startsAt,
    goldPassPercent: goldPassPercent,
    preferences: preferences,
    includedItemKeys: includedItemKeys,
  );
  final activeItems =
      snapshot
          .itemsFor(village: village, queue: queue)
          .where(
            (item) =>
                (includedItemKeys == null ||
                    includedItemKeys.contains(item.planKey)) &&
                item.steps.isNotEmpty &&
                snapshot.remainingActiveSeconds(item, now: startsAt) > 0,
          )
          .toList()
        ..sort(
          (a, b) => snapshot
              .remainingActiveSeconds(b, now: startsAt)
              .compareTo(snapshot.remainingActiveSeconds(a, now: startsAt)),
        );

  return List.generate(lanes.length, (index) {
    final activeItem = index < activeItems.length ? activeItems[index] : null;
    final activeStep = activeItem?.steps.firstOrNull;
    final activeUpgrade = activeItem == null || activeStep == null
        ? null
        : PlannedUpgrade(
            item: activeItem,
            instance: 0,
            step: activeStep,
            startsAt: startsAt,
            endsAt: startsAt.add(
              Duration(
                seconds: snapshot.remainingActiveSeconds(
                  activeItem,
                  now: startsAt,
                ),
              ),
            ),
            costs: activeStep.costs,
            isOngoing: true,
          );
    return UpgradePlanLane(
      index: lanes[index].index,
      upgrades: [
        ...[activeUpgrade].whereType<PlannedUpgrade>(),
        ...lanes[index].upgrades,
      ],
      reservedUntil: lanes[index].reservedUntil,
    );
  });
}

DateTime _laterDate(DateTime first, DateTime second) =>
    first.isAfter(second) ? first : second;

List<PlannedUpgrade> _buildWallPlan(
  UpgradeTrackerSnapshot snapshot,
  UpgradePlanPreferences preferences, {
  required int goldPassPercent,
  required DateTime startsAt,
}) {
  if (preferences.wallsPerWeek <= 0) return const [];
  final wallItems = snapshot.itemsFor(
    village: UpgradeVillage.home,
    category: UpgradeCategory.walls,
    remainingOnly: true,
  );
  if (wallItems.isEmpty) return const [];

  final candidates = <({UpgradeTrackerItem item, int instance})>[];
  for (final item in wallItems) {
    for (var instance = 1; instance <= item.count; instance++) {
      candidates.add((item: item, instance: instance));
    }
  }
  candidates.sort((a, b) {
    final name = a.item.name.compareTo(b.item.name);
    return name != 0 ? name : a.instance.compareTo(b.instance);
  });

  final result = <PlannedUpgrade>[];
  var week = 0;
  var completedThisWeek = 0;
  for (final candidate in candidates) {
    var dependencyReadyAt = startsAt;
    for (final step in candidate.item.steps) {
      while (true) {
        final weekStart = startsAt.add(Duration(days: week * 7));
        final scheduledAt = _laterDate(weekStart, dependencyReadyAt);
        final adjusted = snapshot.adjustStep(
          candidate.item,
          step,
          scheduledAt,
          goldPassPercent: goldPassPercent,
        );
        final selectedCosts = _wallCostsForPreferences(
          adjusted.costs,
          preferences,
        );
        final countFull = completedThisWeek >= preferences.wallsPerWeek;
        if (countFull) {
          week += 1;
          completedThisWeek = 0;
          continue;
        }

        final endsAt = scheduledAt.add(Duration(seconds: adjusted.seconds));
        result.add(
          PlannedUpgrade(
            item: candidate.item,
            instance: candidate.instance,
            step: adjusted,
            startsAt: scheduledAt,
            endsAt: endsAt,
            costs: selectedCosts,
          ),
        );
        completedThisWeek += 1;
        dependencyReadyAt = endsAt;
        break;
      }
    }
  }
  return result;
}

List<UpgradeCost> _wallCostsForPreferences(
  List<UpgradeCost> costs,
  UpgradePlanPreferences preferences,
) {
  if (costs.length <= 1) return costs;
  final preferredResource =
      preferences.wallResourcePreference == UpgradeWallResourcePreference.gold
      ? 'gold'
      : 'elixir';
  final preferred = costs
      .where(
        (cost) => preferredResource == 'gold'
            ? cost.resource == 'gold' || cost.resource == 'builder_gold'
            : cost.resource == 'elixir',
      )
      .toList(growable: false);
  if (preferred.isNotEmpty) return [preferred.first];
  return [costs.first];
}

UpgradePlanPreferences _copyPlanPreferences(
  UpgradePlanPreferences source, {
  UpgradePlanGoal? homeGoal,
  UpgradePlanGoal? builderBaseGoal,
  List<UpgradeCategory>? homeCategoryOrder,
  List<UpgradeCategory>? builderBaseCategoryOrder,
  Map<UpgradeCategory, int>? homeCategoryTargets,
  Map<UpgradeCategory, int>? builderBaseCategoryTargets,
  Map<UpgradeCategory, int>? homeCategoryShares,
  Map<UpgradeCategory, int>? builderBaseCategoryShares,
  bool? prioritizeUnbuiltBuilders,
  bool? prioritizeUnbuiltLaboratory,
  bool? prioritizeUnbuiltPets,
  UpgradeWallResourcePreference? wallResourcePreference,
  int? wallsPerWeek,
}) => UpgradePlanPreferences(
  homeGoal: homeGoal ?? source.homeGoal,
  builderBaseGoal: builderBaseGoal ?? source.builderBaseGoal,
  homeCategoryOrder: homeCategoryOrder ?? source.homeCategoryOrder,
  builderBaseCategoryOrder:
      builderBaseCategoryOrder ?? source.builderBaseCategoryOrder,
  homeCategoryTargets: homeCategoryTargets ?? source.homeCategoryTargets,
  builderBaseCategoryTargets:
      builderBaseCategoryTargets ?? source.builderBaseCategoryTargets,
  homeCategoryShares: homeCategoryShares ?? source.homeCategoryShares,
  builderBaseCategoryShares:
      builderBaseCategoryShares ?? source.builderBaseCategoryShares,
  prioritizeUnbuiltBuilders:
      prioritizeUnbuiltBuilders ?? source.prioritizeUnbuiltBuilders,
  prioritizeUnbuiltLaboratory:
      prioritizeUnbuiltLaboratory ?? source.prioritizeUnbuiltLaboratory,
  prioritizeUnbuiltPets: prioritizeUnbuiltPets ?? source.prioritizeUnbuiltPets,
  wallResourcePreference:
      wallResourcePreference ?? source.wallResourcePreference,
  wallsPerWeek: wallsPerWeek ?? source.wallsPerWeek,
);

List<UpgradeCategory> _planQueueOrder(
  UpgradeTrackerSnapshot snapshot,
  UpgradePlanPreferences preferences,
  UpgradeVillage village,
  UpgradeQueue queue,
) {
  final available = snapshot
      .itemsFor(village: village, queue: queue)
      .map((item) => item.category)
      .where((category) => category != UpgradeCategory.builders)
      .toSet();
  final saved = preferences.orderFor(village);
  return [
    ...saved.where(available.contains),
    ...UpgradeCategory.values.where(
      (category) => available.contains(category) && !saved.contains(category),
    ),
  ];
}

List<UpgradeCategory> _replacePlanQueueOrder(
  UpgradeTrackerSnapshot snapshot,
  List<UpgradeCategory> saved,
  UpgradeVillage village,
  UpgradeQueue queue,
  List<UpgradeCategory> queueOrder,
) {
  final queueCategories = snapshot
      .itemsFor(village: village, queue: queue)
      .map((item) => item.category)
      .where((category) => category != UpgradeCategory.builders)
      .toSet();
  return [
    ...saved.where((category) => !queueCategories.contains(category)),
    ...queueOrder,
  ];
}

class _PlanPriorityVillageSection {
  const _PlanPriorityVillageSection({
    required this.title,
    required this.order,
    required this.targets,
    required this.shares,
    required this.keyPrefix,
    required this.onReorder,
    required this.onTargetChanged,
    required this.onShareChanged,
  });

  final String title;
  final List<UpgradeCategory> order;
  final Map<UpgradeCategory, int> targets;
  final Map<UpgradeCategory, int> shares;
  final String keyPrefix;
  final ValueChanged<List<UpgradeCategory>> onReorder;
  final void Function(UpgradeCategory category, int target) onTargetChanged;
  final void Function(UpgradeCategory category, int share) onShareChanged;
}

class _PlanPriorityQueueSection extends StatelessWidget {
  const _PlanPriorityQueueSection({
    required this.title,
    required this.subtitle,
    required this.prioritizeUnbuilt,
    required this.onPrioritizeUnbuiltChanged,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final bool prioritizeUnbuilt;
  final ValueChanged<bool> onPrioritizeUnbuiltChanged;
  final List<_PlanPriorityVillageSection> sections;

  @override
  Widget build(BuildContext context) {
    final visibleSections = sections
        .where((section) => section.order.isNotEmpty)
        .toList(growable: false);
    if (visibleSections.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: title),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        _PlanCompactToggle(
          label: 'Prioritize new items',
          description: 'Place newly unlocked or unbuilt items first',
          value: prioritizeUnbuilt,
          onChanged: onPrioritizeUnbuiltChanged,
        ),
        ...visibleSections.expand(
          (section) => [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 3),
              child: Text(
                section.title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            _PlanPriorityList(
              order: section.order,
              targets: section.targets,
              shares: section.shares,
              keyPrefix: section.keyPrefix,
              onReorder: section.onReorder,
              onTargetChanged: section.onTargetChanged,
              onShareChanged: section.onShareChanged,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

class _PlanCompactToggle extends StatelessWidget {
  const _PlanCompactToggle({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox.square(
          dimension: 44,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlanGoalSelector extends StatelessWidget {
  const _PlanGoalSelector({
    required this.label,
    required this.goal,
    required this.onChanged,
  });

  final String label;
  final UpgradePlanGoal goal;
  final ValueChanged<UpgradePlanGoal> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      FilterDropdown(
        sortBy: goal.name,
        maxWidth: double.infinity,
        sortByOptions: {
          for (final value in UpgradePlanGoal.values)
            _planGoalLabel(value): value.name,
        },
        updateSortBy: (value) =>
            onChanged(UpgradePlanGoal.values.byName(value)),
      ),
    ],
  );
}

Future<void> _showPlanPreferences(
  BuildContext context,
  UpgradeTrackerSnapshot snapshot,
  UpgradePlanPreferences initial,
  ValueChanged<UpgradePlanPreferences> onChanged,
) async {
  var draft = initial;

  final result = await showModalBottomSheet<UpgradePlanPreferences>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => FractionallySizedBox(
        heightFactor: 0.92,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Plan priorities',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Text(
                    'Rank what matters most. Upgrade levels and active work always stay in order.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _PlanRuleNote(),
                  const SizedBox(height: 12),
                  const _SectionHeading(title: 'Planning goals'),
                  const SizedBox(height: 4),
                  _PlanGoalSelector(
                    label: 'Home Village',
                    goal: draft.homeGoal,
                    onChanged: (value) => setSheetState(
                      () =>
                          draft = _copyPlanPreferences(draft, homeGoal: value),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PlanGoalSelector(
                    label: 'Builder Base',
                    goal: draft.builderBaseGoal,
                    onChanged: (value) => setSheetState(
                      () => draft = _copyPlanPreferences(
                        draft,
                        builderBaseGoal: value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlanPriorityQueueSection(
                    title: 'Builders',
                    subtitle: 'Construction and hero upgrades',
                    prioritizeUnbuilt: draft.prioritizeUnbuiltBuilders,
                    onPrioritizeUnbuiltChanged: (value) => setSheetState(
                      () => draft = _copyPlanPreferences(
                        draft,
                        prioritizeUnbuiltBuilders: value,
                      ),
                    ),
                    sections: [
                      _PlanPriorityVillageSection(
                        title: 'Home Village',
                        order: _planQueueOrder(
                          snapshot,
                          draft,
                          UpgradeVillage.home,
                          UpgradeQueue.builders,
                        ),
                        targets: draft.homeCategoryTargets,
                        shares: draft.homeCategoryShares,
                        keyPrefix: 'home-builders',
                        onReorder: (order) => setSheetState(
                          () => draft = _copyPlanPreferences(
                            draft,
                            homeCategoryOrder: _replacePlanQueueOrder(
                              snapshot,
                              draft.homeCategoryOrder,
                              UpgradeVillage.home,
                              UpgradeQueue.builders,
                              order,
                            ),
                          ),
                        ),
                        onTargetChanged: (category, target) =>
                            setSheetState(() {
                              final targets = {...draft.homeCategoryTargets};
                              targets[category] = target;
                              draft = _copyPlanPreferences(
                                draft,
                                homeCategoryTargets: targets,
                              );
                            }),
                        onShareChanged: (category, share) => setSheetState(() {
                          final shares = {...draft.homeCategoryShares};
                          if (share <= 0) {
                            shares.remove(category);
                          } else {
                            shares[category] = share;
                          }
                          draft = _copyPlanPreferences(
                            draft,
                            homeCategoryShares: shares,
                          );
                        }),
                      ),
                      _PlanPriorityVillageSection(
                        title: 'Builder Base',
                        order: _planQueueOrder(
                          snapshot,
                          draft,
                          UpgradeVillage.builderBase,
                          UpgradeQueue.builders,
                        ),
                        targets: draft.builderBaseCategoryTargets,
                        shares: draft.builderBaseCategoryShares,
                        keyPrefix: 'builder-base-builders',
                        onReorder: (order) => setSheetState(
                          () => draft = _copyPlanPreferences(
                            draft,
                            builderBaseCategoryOrder: _replacePlanQueueOrder(
                              snapshot,
                              draft.builderBaseCategoryOrder,
                              UpgradeVillage.builderBase,
                              UpgradeQueue.builders,
                              order,
                            ),
                          ),
                        ),
                        onTargetChanged: (category, target) =>
                            setSheetState(() {
                              final targets = {
                                ...draft.builderBaseCategoryTargets,
                              };
                              targets[category] = target;
                              draft = _copyPlanPreferences(
                                draft,
                                builderBaseCategoryTargets: targets,
                              );
                            }),
                        onShareChanged: (category, share) => setSheetState(() {
                          final shares = {...draft.builderBaseCategoryShares};
                          if (share <= 0) {
                            shares.remove(category);
                          } else {
                            shares[category] = share;
                          }
                          draft = _copyPlanPreferences(
                            draft,
                            builderBaseCategoryShares: shares,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PlanPriorityQueueSection(
                    title: 'Laboratory',
                    subtitle: 'Troops, spells and siege research',
                    prioritizeUnbuilt: draft.prioritizeUnbuiltLaboratory,
                    onPrioritizeUnbuiltChanged: (value) => setSheetState(
                      () => draft = _copyPlanPreferences(
                        draft,
                        prioritizeUnbuiltLaboratory: value,
                      ),
                    ),
                    sections: [
                      _PlanPriorityVillageSection(
                        title: 'Home Village',
                        order: _planQueueOrder(
                          snapshot,
                          draft,
                          UpgradeVillage.home,
                          UpgradeQueue.laboratory,
                        ),
                        targets: draft.homeCategoryTargets,
                        shares: draft.homeCategoryShares,
                        keyPrefix: 'home-laboratory',
                        onReorder: (order) => setSheetState(
                          () => draft = _copyPlanPreferences(
                            draft,
                            homeCategoryOrder: _replacePlanQueueOrder(
                              snapshot,
                              draft.homeCategoryOrder,
                              UpgradeVillage.home,
                              UpgradeQueue.laboratory,
                              order,
                            ),
                          ),
                        ),
                        onTargetChanged: (category, target) =>
                            setSheetState(() {
                              final targets = {...draft.homeCategoryTargets};
                              targets[category] = target;
                              draft = _copyPlanPreferences(
                                draft,
                                homeCategoryTargets: targets,
                              );
                            }),
                        onShareChanged: (category, share) => setSheetState(() {
                          final shares = {...draft.homeCategoryShares};
                          if (share <= 0) {
                            shares.remove(category);
                          } else {
                            shares[category] = share;
                          }
                          draft = _copyPlanPreferences(
                            draft,
                            homeCategoryShares: shares,
                          );
                        }),
                      ),
                      _PlanPriorityVillageSection(
                        title: 'Builder Base',
                        order: _planQueueOrder(
                          snapshot,
                          draft,
                          UpgradeVillage.builderBase,
                          UpgradeQueue.laboratory,
                        ),
                        targets: draft.builderBaseCategoryTargets,
                        shares: draft.builderBaseCategoryShares,
                        keyPrefix: 'builder-base-laboratory',
                        onReorder: (order) => setSheetState(
                          () => draft = _copyPlanPreferences(
                            draft,
                            builderBaseCategoryOrder: _replacePlanQueueOrder(
                              snapshot,
                              draft.builderBaseCategoryOrder,
                              UpgradeVillage.builderBase,
                              UpgradeQueue.laboratory,
                              order,
                            ),
                          ),
                        ),
                        onTargetChanged: (category, target) =>
                            setSheetState(() {
                              final targets = {
                                ...draft.builderBaseCategoryTargets,
                              };
                              targets[category] = target;
                              draft = _copyPlanPreferences(
                                draft,
                                builderBaseCategoryTargets: targets,
                              );
                            }),
                        onShareChanged: (category, share) => setSheetState(() {
                          final shares = {...draft.builderBaseCategoryShares};
                          if (share <= 0) {
                            shares.remove(category);
                          } else {
                            shares[category] = share;
                          }
                          draft = _copyPlanPreferences(
                            draft,
                            builderBaseCategoryShares: shares,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PlanPriorityQueueSection(
                    title: 'Pets',
                    subtitle: 'Pet House upgrades',
                    prioritizeUnbuilt: draft.prioritizeUnbuiltPets,
                    onPrioritizeUnbuiltChanged: (value) => setSheetState(
                      () => draft = _copyPlanPreferences(
                        draft,
                        prioritizeUnbuiltPets: value,
                      ),
                    ),
                    sections: [
                      _PlanPriorityVillageSection(
                        title: 'Home Village',
                        order: _planQueueOrder(
                          snapshot,
                          draft,
                          UpgradeVillage.home,
                          UpgradeQueue.pets,
                        ),
                        targets: draft.homeCategoryTargets,
                        shares: draft.homeCategoryShares,
                        keyPrefix: 'home-pets',
                        onReorder: (order) => setSheetState(
                          () => draft = _copyPlanPreferences(
                            draft,
                            homeCategoryOrder: _replacePlanQueueOrder(
                              snapshot,
                              draft.homeCategoryOrder,
                              UpgradeVillage.home,
                              UpgradeQueue.pets,
                              order,
                            ),
                          ),
                        ),
                        onTargetChanged: (category, target) =>
                            setSheetState(() {
                              final targets = {...draft.homeCategoryTargets};
                              targets[category] = target;
                              draft = _copyPlanPreferences(
                                draft,
                                homeCategoryTargets: targets,
                              );
                            }),
                        onShareChanged: (category, share) => setSheetState(() {
                          final shares = {...draft.homeCategoryShares};
                          if (share <= 0) {
                            shares.remove(category);
                          } else {
                            shares[category] = share;
                          }
                          draft = _copyPlanPreferences(
                            draft,
                            homeCategoryShares: shares,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SectionHeading(title: 'Walls'),
                  const SizedBox(height: 4),
                  _PlanPreferenceSlider(
                    label: 'Walls each week',
                    value: (draft.wallsPerWeek / 20).clamp(0, 1),
                    lowLabel: 'Off',
                    highLabel: '${draft.wallsPerWeek} / week',
                    divisions: 20,
                    onChanged: (value) => setSheetState(
                      () => draft = _copyPlanPreferences(
                        draft,
                        wallsPerWeek: (value * 20).round(),
                      ),
                    ),
                  ),
                  _PlanCompactToggle(
                    label: 'Prefer Gold for walls',
                    description: 'Use Gold before Elixir when spending walls',
                    value:
                        draft.wallResourcePreference ==
                        UpgradeWallResourcePreference.gold,
                    onChanged: (value) => setSheetState(
                      () => draft = _copyPlanPreferences(
                        draft,
                        wallResourcePreference: value
                            ? UpgradeWallResourcePreference.gold
                            : UpgradeWallResourcePreference.elixir,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: const Text('Apply priorities'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (result != null) onChanged(result);
}

// ignore: unused_element
Future<void> _showPlanComparison(
  BuildContext context,
  UpgradeTrackerSnapshot snapshot,
  int goldPassPercent,
  UpgradePlanPreferences current,
) async {
  final presets = <(String, String, UpgradePlanPreferences)>[
    ('Your priorities', 'Current settings', current),
    (
      'Fastest finish',
      'Favor long jobs and clean builder handoffs',
      const UpgradePlanPreferences(
        prioritizeUnbuiltBuilders: true,
        prioritizeUnbuiltLaboratory: true,
        prioritizeUnbuiltPets: true,
      ),
    ),
    (
      'Unlock first',
      'Prioritize newly unlocked and unbuilt items in every queue',
      const UpgradePlanPreferences(
        prioritizeUnbuiltBuilders: true,
        prioritizeUnbuiltLaboratory: true,
        prioritizeUnbuiltPets: true,
      ),
    ),
  ];
  final now = DateTime.now();
  final comparisons = presets.map((preset) {
    final lanes = _allPlanLanes(
      snapshot,
      preset.$3,
      goldPassPercent: goldPassPercent,
      startsAt: now,
    );
    final upgrades = lanes.expand((lane) => lane.upgrades).toList();
    final finish = lanes
        .map((lane) => lane.finishesAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, value) {
          return latest == null || value.isAfter(latest) ? value : latest;
        });
    final costs = upgrades
        .expand((upgrade) => upgrade.costs)
        .fold<num>(0, (sum, cost) => sum + cost.amount);
    return (
      preset: preset,
      finish: finish,
      count: upgrades.length,
      costs: costs,
    );
  }).toList();

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare approaches',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Same account, boosts and Gold Pass. Only the priorities change.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...comparisons.map(
            (comparison) => _PlanComparisonCard(
              title: comparison.preset.$1,
              subtitle: comparison.preset.$2,
              finish: comparison.finish,
              count: comparison.count,
              totalCost: comparison.costs,
              startsAt: now,
            ),
          ),
        ],
      ),
    ),
  );
}

List<UpgradePlanLane> _allPlanLanes(
  UpgradeTrackerSnapshot snapshot,
  UpgradePlanPreferences preferences, {
  required int goldPassPercent,
  required DateTime startsAt,
}) {
  final lanes = <UpgradePlanLane>[
    ..._buildPlannerLanes(
      snapshot,
      queue: UpgradeQueue.builders,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: startsAt,
      goldPassPercent: goldPassPercent,
      preferences: preferences,
    ),
    ..._buildPlannerLanes(
      snapshot,
      queue: UpgradeQueue.laboratory,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: startsAt,
      goldPassPercent: goldPassPercent,
      preferences: preferences,
    ),
    ..._buildPlannerLanes(
      snapshot,
      queue: UpgradeQueue.pets,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: startsAt,
      goldPassPercent: goldPassPercent,
      preferences: preferences,
    ),
    ..._buildPlannerLanes(
      snapshot,
      queue: UpgradeQueue.builders,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.builderBase,
      startsAt: startsAt,
      goldPassPercent: goldPassPercent,
      preferences: preferences,
    ),
    ..._buildPlannerLanes(
      snapshot,
      queue: UpgradeQueue.laboratory,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.builderBase,
      startsAt: startsAt,
      goldPassPercent: goldPassPercent,
      preferences: preferences,
    ),
  ];
  final walls = _buildWallPlan(
    snapshot,
    preferences,
    goldPassPercent: goldPassPercent,
    startsAt: startsAt,
  );
  if (walls.isNotEmpty) lanes.add(UpgradePlanLane(index: 0, upgrades: walls));
  return lanes;
}

Future<void> _showFullPlan(
  BuildContext context,
  List<UpgradePlanLane> lanes,
) async {
  final upgrades = lanes.expand((lane) => lane.upgrades).toList();
  var villageFilter = _PlanVillageFilter.all;
  var queueFilter = _PlanQueueFilter.all;
  var planSort = _PlanSort.scheduled;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final filtered =
            upgrades
                .where(
                  (upgrade) =>
                      _matchesPlanFilters(upgrade, villageFilter, queueFilter),
                )
                .toList()
              ..sort((a, b) {
                final comparison = switch (planSort) {
                  _PlanSort.scheduled => a.startsAt.compareTo(b.startsAt),
                  _PlanSort.nameAscending => a.item.name.compareTo(b.item.name),
                  _PlanSort.durationLong =>
                    b.endsAt
                        .difference(b.startsAt)
                        .compareTo(a.endsAt.difference(a.startsAt)),
                  _PlanSort.durationShort =>
                    a.endsAt
                        .difference(a.startsAt)
                        .compareTo(b.endsAt.difference(b.startsAt)),
                };
                return comparison != 0
                    ? comparison
                    : a.endsAt.compareTo(b.endsAt);
              });
        final groups = _groupPlannedUpgrades(filtered);
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entire plan',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${filtered.length} upgrades in plan',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Village',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _PlanVillageFilter.values
                            .map(
                              (value) => _FilterChip(
                                label: _planVillageFilterLabel(value),
                                selected: villageFilter == value,
                                onTap: () =>
                                    setSheetState(() => villageFilter = value),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Queue',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _PlanQueueFilter.values
                            .map(
                              (value) => _FilterChip(
                                label: _planQueueFilterLabel(value),
                                selected: queueFilter == value,
                                onTap: () =>
                                    setSheetState(() => queueFilter = value),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilterDropdown(
                        sortBy: planSort.name,
                        maxWidth: 160,
                        sortByOptions: {
                          for (final value in _PlanSort.values)
                            _planSortLabel(value): value.name,
                        },
                        updateSortBy: (value) => setSheetState(
                          () => planSort = _PlanSort.values.byName(value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: groups.isEmpty
                    ? const _TrackerEmptyState(
                        icon: Icons.task_alt_rounded,
                        title: 'No matching upgrades',
                        body: 'Try another village or queue.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _PlannedUpgradeRow(group: groups[index]),
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _PlanPriorityList extends StatelessWidget {
  const _PlanPriorityList({
    required this.order,
    required this.targets,
    required this.shares,
    required this.keyPrefix,
    required this.onReorder,
    required this.onTargetChanged,
    required this.onShareChanged,
  });

  final List<UpgradeCategory> order;
  final Map<UpgradeCategory, int> targets;
  final Map<UpgradeCategory, int> shares;
  final String keyPrefix;
  final ValueChanged<List<UpgradeCategory>> onReorder;
  final void Function(UpgradeCategory category, int target) onTargetChanged;
  final void Function(UpgradeCategory category, int share) onShareChanged;

  static int _priorityTierForOrder(
    List<UpgradeCategory> order,
    Map<UpgradeCategory, int> shares,
    UpgradeCategory target,
  ) {
    var tier = 0;
    var previousWasShared = false;
    for (final category in order) {
      final shared = (shares[category] ?? 0) > 0;
      if (tier == 0 || !shared || !previousWasShared) tier += 1;
      if (category == target) return tier;
      previousWasShared = shared;
    }
    return 999;
  }

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    buildDefaultDragHandles: false,
    itemCount: order.length,
    onReorderItem: (oldIndex, newIndex) {
      final updated = [...order];
      final moved = updated.removeAt(oldIndex);
      updated.insert(newIndex, moved);
      onReorder(updated);
    },
    itemBuilder: (context, index) {
      final category = order[index];
      final target = targets[category] ?? 100;
      final share = shares[category] ?? 0;
      final tier = _PlanPriorityList._priorityTierForOrder(
        order,
        shares,
        category,
      );
      final sharedWeightTotal = order
          .where(
            (candidate) =>
                _PlanPriorityList._priorityTierForOrder(
                  order,
                  shares,
                  candidate,
                ) ==
                tier,
          )
          .map((candidate) => shares[candidate] ?? 0)
          .where((value) => value > 0)
          .fold<int>(0, (total, value) => total + value);
      final normalizedShare = share > 0 && sharedWeightTotal > 0
          ? (share * 100 / sharedWeightTotal).round()
          : null;
      return ListTile(
        key: ValueKey('$keyPrefix-${category.name}'),
        dense: true,
        visualDensity: VisualDensity.compact,
        minVerticalPadding: 2,
        horizontalTitleGap: 8,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 13,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: Text(
            '$tier',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          _categoryLabel(category),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${share > 0 ? 'Tier $tier · shared mix $normalizedShare% ($share/$sharedWeightTotal)' : 'Tier $tier · strict'} · '
          '${target >= 100 ? 'runs until maxed' : 'yields after $target%'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<int>(
              tooltip: 'Relative tier weight',
              initialValue: share,
              onSelected: (value) => onShareChanged(category, value),
              itemBuilder: (context) => const [0, 20, 25, 33, 50, 67, 75, 80]
                  .map(
                    (value) => PopupMenuItem(
                      value: value,
                      child: Text(
                        value == 0 ? 'Strict tier' : 'Weight $value%',
                      ),
                    ),
                  )
                  .toList(growable: false),
              child: _Pill(text: share > 0 ? '$share%' : 'Strict'),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<int>(
              tooltip: 'Completion target',
              initialValue: target,
              onSelected: (value) => onTargetChanged(category, value),
              itemBuilder: (context) => const [50, 75, 90, 100]
                  .map(
                    (value) => PopupMenuItem(
                      value: value,
                      child: Text(
                        value == 100 ? 'Until maxed' : 'Until $value%',
                      ),
                    ),
                  )
                  .toList(growable: false),
              child: _Pill(text: target == 100 ? 'Max' : '$target%'),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle_rounded),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _planGoalLabel(UpgradePlanGoal goal) => switch (goal) {
  UpgradePlanGoal.maxCurrentHall => 'Max before advancing',
  UpgradePlanGoal.rushNextHall => 'Reach the next hall quickly',
  UpgradePlanGoal.catchUp => 'Catch up rushed levels',
  UpgradePlanGoal.unlockFirst => 'Unlock new things first',
};

class _PlanPreferenceSlider extends StatelessWidget {
  const _PlanPreferenceSlider({
    required this.label,
    required this.value,
    required this.lowLabel,
    required this.highLabel,
    required this.onChanged,
    this.divisions = 10,
  });

  final String label;
  final double value;
  final String lowLabel;
  final String highLabel;
  final ValueChanged<double> onChanged;
  final int divisions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Slider(value: value, divisions: divisions, onChanged: onChanged),
        Row(
          children: [
            Expanded(
              child: Text(
                lowLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              highLabel,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ignore: unused_element
class _ResourcePreferenceControl extends StatelessWidget {
  const _ResourcePreferenceControl({
    required this.resource,
    required this.value,
    required this.onChanged,
  });

  final String resource;
  final UpgradeResourcePreference value;
  final ValueChanged<UpgradeResourcePreference> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        MobileWebImage(
          imageUrl: _resourceImage(resource),
          width: 25,
          height: 25,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _resourceLabel(resource),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        SegmentedButton<UpgradeResourcePreference>(
          segments: const [
            ButtonSegment(
              value: UpgradeResourcePreference.conserve,
              label: Text('Save'),
            ),
            ButtonSegment(
              value: UpgradeResourcePreference.balanced,
              label: Text('Mix'),
            ),
            ButtonSegment(
              value: UpgradeResourcePreference.spend,
              label: Text('Spend'),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (values) => onChanged(values.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlanComparisonCard extends StatelessWidget {
  const _PlanComparisonCard({
    required this.title,
    required this.subtitle,
    required this.finish,
    required this.count,
    required this.totalCost,
    required this.startsAt,
  });

  final String title;
  final String subtitle;
  final DateTime? finish;
  final int count;
  final num totalCost;
  final DateTime startsAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                finish == null
                    ? 'Complete'
                    : _duration(finish!.difference(startsAt).inSeconds),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                '$count · ${_compact(totalCost)} total',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showUpgradeSectionSummary(
  BuildContext context,
  String title,
  UpgradeCategorySummary summary, {
  UpgradeTrackerSnapshot? snapshot,
  UpgradeVillage? village,
  int goldPassPercent = 0,
  UpgradePlanPreferences preferences = const UpgradePlanPreferences(),
}) {
  if (snapshot != null && village != null) {
    _showVillageUpgradeSummary(
      context,
      title,
      summary,
      snapshot: snapshot,
      village: village,
      goldPassPercent: goldPassPercent,
      preferences: preferences,
    );
    return;
  }
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(summary.completion * 100).toStringAsFixed(1)}% complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryMetricPanel(
              metrics: [
                (
                  label: 'Levels left',
                  value: '${summary.levelsRemaining}',
                  icon: Icons.layers_rounded,
                  imageUrl: null,
                  color: null,
                ),
                if (summary.seconds > 0)
                  (
                    label: 'Time left',
                    value: _duration(summary.seconds),
                    icon: Icons.schedule_rounded,
                    imageUrl: null,
                    color: null,
                  ),
                ...summary.costs.entries.map(
                  (entry) => (
                    label: _resourceLabel(entry.key),
                    value: _compact(entry.value),
                    icon: null,
                    imageUrl: _resourceImage(entry.key),
                    color: null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _showVillageUpgradeSummary(
  BuildContext context,
  String title,
  UpgradeCategorySummary overall, {
  required UpgradeTrackerSnapshot snapshot,
  required UpgradeVillage village,
  required int goldPassPercent,
  required UpgradePlanPreferences preferences,
}) {
  final l10n = AppLocalizations.of(context)!;
  final startsAt = DateTime.now();
  _VillageUpgradeBreakdown? timedSection(
    String label,
    UpgradeQueue queue, {
    String? preferredImageName,
  }) {
    final items = snapshot
        .itemsFor(village: village, queue: queue)
        .where((item) => item.category != UpgradeCategory.builders)
        .toList(growable: false);
    if (items.isEmpty) return null;
    final lanes = _buildPlannerLanes(
      snapshot,
      queue: queue,
      strategy: UpgradePlanStrategy.balanced,
      village: village,
      startsAt: startsAt,
      goldPassPercent: goldPassPercent,
      preferences: _preferencesForQueue(snapshot, preferences, village, queue),
      includedItemKeys: items.map((item) => item.planKey).toSet(),
    );
    final finish = lanes
        .map((lane) => lane.finishesAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, date) {
          return latest == null || date.isAfter(latest) ? date : latest;
        });
    final image = preferredImageName == null
        ? items.first.imageUrl
        : items
                  .where((item) => item.name == preferredImageName)
                  .firstOrNull
                  ?.imageUrl ??
              items.first.imageUrl;
    return _VillageUpgradeBreakdown(
      label: label,
      imageUrl: image,
      summary: snapshot.summaryForItems(items),
      finishesAt: finish,
    );
  }

  _VillageUpgradeBreakdown? untimedSection(
    String label,
    UpgradeCategory category,
  ) {
    final items = snapshot.itemsFor(village: village, category: category);
    if (items.isEmpty) return null;
    return _VillageUpgradeBreakdown(
      label: label,
      imageUrl: items.first.imageUrl,
      summary: snapshot.summaryForItems(items, category: category),
    );
  }

  final sections = <_VillageUpgradeBreakdown?>[
    timedSection(
      l10n.upgradeTrackerBuildersCount(snapshot.buildersFor(village)),
      UpgradeQueue.builders,
      preferredImageName: "Builder's Hut",
    ),
    timedSection(
      l10n.upgradeTrackerLaboratory,
      UpgradeQueue.laboratory,
      preferredImageName: village == UpgradeVillage.home
          ? 'Laboratory'
          : 'Star Laboratory',
    ),
    if (village == UpgradeVillage.home)
      timedSection(
        l10n.upgradeTrackerPets,
        UpgradeQueue.pets,
        preferredImageName: 'Pet House',
      ),
    untimedSection(l10n.upgradeTrackerWalls, UpgradeCategory.walls),
    if (village == UpgradeVillage.home)
      untimedSection(l10n.upgradeTrackerEquipment, UpgradeCategory.equipment),
  ].whereType<_VillageUpgradeBreakdown>().toList(growable: false);

  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: CKTypography.of(
                                  context,
                                  CKTextRole.screenTitle,
                                ),
                              ),
                              const SizedBox(height: CKSpacing.xs),
                              Text(
                                '${(overall.completion * 100).toStringAsFixed(1)}% complete · ${overall.levelsRemaining} levels left',
                                style:
                                    CKTypography.of(
                                      context,
                                      CKTextRole.metadata,
                                    ).copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: CKSpacing.sm),
                    for (var index = 0; index < sections.length; index++) ...[
                      if (index > 0) const SizedBox(height: CKSpacing.sm),
                      _VillageBreakdownCard(
                        data: sections[index],
                        startsAt: startsAt,
                        l10n: l10n,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _VillageUpgradeBreakdown {
  const _VillageUpgradeBreakdown({
    required this.label,
    required this.imageUrl,
    required this.summary,
    this.finishesAt,
  });

  final String label;
  final String imageUrl;
  final UpgradeCategorySummary summary;
  final DateTime? finishesAt;
}

class _VillageBreakdownCard extends StatelessWidget {
  const _VillageBreakdownCard({
    required this.data,
    required this.startsAt,
    required this.l10n,
  });

  final _VillageUpgradeBreakdown data;
  final DateTime startsAt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final costs = data.summary.costs.entries.toList()
      ..sort(
        (a, b) => _resourceWeight(a.key).compareTo(_resourceWeight(b.key)),
      );
    return CKSectionPanel(
      padding: const EdgeInsets.all(CKSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AspectSafeImage(imageUrl: data.imageUrl, width: 46, height: 42),
              const SizedBox(width: CKSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: CKTypography.of(context, CKTextRole.sectionTitle),
                    ),
                    Text(
                      data.finishesAt == null
                          ? l10n.upgradeTrackerLevelsRemaining(
                              data.summary.levelsRemaining,
                            )
                          : l10n.upgradeTrackerCompletesOn(
                              DateFormat.yMMMd(
                                Localizations.localeOf(context).toString(),
                              ).format(data.finishesAt!),
                              _duration(
                                data.finishesAt!.difference(startsAt).inSeconds,
                              ),
                            ),
                      style: CKTypography.of(
                        context,
                        CKTextRole.metadata,
                      ).copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (costs.isNotEmpty) ...[
            const SizedBox(height: CKSpacing.md),
            Wrap(
              spacing: CKSpacing.md,
              runSpacing: CKSpacing.sm,
              children: costs
                  .map(
                    (cost) => CKResourceCost(
                      icon: MobileWebImage(
                        imageUrl: _resourceImage(cost.key),
                        fit: BoxFit.contain,
                      ),
                      amount: _compact(cost.value),
                      label: _resourceLabel(cost.key),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

void _showCollectionSectionSummary(
  BuildContext context,
  String title, {
  required List<UpgradeCollectionItem> items,
}) {
  final owned = items.where((item) => item.owned).toList(growable: false);
  final total = items.length;
  final type = items.firstOrNull?.type;
  final details = switch (type) {
    UpgradeCollectionType.skins => _ownedSkinTierCounts(owned),
    UpgradeCollectionType.decorations => _ownedDecorationSizeCounts(owned),
    _ => const <({String label, int count, Color? color})>[],
  };
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryMetricPanel(
              metrics: [
                (
                  label: 'Owned',
                  value: '${owned.length}',
                  icon: Icons.check_circle_rounded,
                  imageUrl: null,
                  color: null,
                ),
                (
                  label: 'Missing',
                  value: '${total - owned.length}',
                  icon: Icons.circle_outlined,
                  imageUrl: null,
                  color: null,
                ),
                (
                  label: 'Available',
                  value: '$total',
                  icon: Icons.grid_view_rounded,
                  imageUrl: null,
                  color: null,
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                type == UpgradeCollectionType.skins
                    ? 'Owned by tier'
                    : 'Owned by size',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details
                    .map(
                      (detail) => _SummaryMetricTile(
                        label: detail.label,
                        value: '${detail.count}',
                        color: detail.color,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

List<({String label, int count, Color? color})> _ownedSkinTierCounts(
  List<UpgradeCollectionItem> items,
) {
  const order = ['Legendary', 'Gold', 'Basic', 'Default'];
  return order
      .map(
        (tier) => (
          label: tier,
          count: items
              .where((item) => item.meta?['tier']?.toString() == tier)
              .length,
          color: _skinTierColor(tier),
        ),
      )
      .where((entry) => entry.count > 0)
      .toList(growable: false);
}

List<({String label, int count, Color? color})> _ownedDecorationSizeCounts(
  List<UpgradeCollectionItem> items,
) {
  final counts = <String, int>{};
  for (final item in items) {
    final size = _collectionSize(item.meta?['width']);
    if (size.isEmpty) continue;
    counts.update(
      size,
      (count) => count + item.count,
      ifAbsent: () => item.count,
    );
  }
  return counts.entries
      .map((entry) => (label: entry.key, count: entry.value, color: null))
      .toList(growable: false);
}

typedef _SummaryMetricData = ({
  String label,
  String value,
  IconData? icon,
  String? imageUrl,
  Color? color,
});

class _SummaryMetricPanel extends StatelessWidget {
  const _SummaryMetricPanel({required this.metrics});

  final List<_SummaryMetricData> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 6.0;
      final width = (constraints.maxWidth - gap) / 2;
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => _SummaryMetricTile(
                  width: width - 5,
                  embedded: true,
                  label: metric.label,
                  value: metric.value,
                  icon: metric.icon,
                  imageUrl: metric.imageUrl,
                  color: metric.color,
                ),
              )
              .toList(growable: false),
        ),
      );
    },
  );
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.label,
    required this.value,
    this.icon,
    this.imageUrl,
    this.color,
    this.width = 132,
    this.embedded = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? imageUrl;
  final Color? color;
  final double width;
  final bool embedded;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: BoxConstraints(minHeight: embedded ? 48 : 62),
    padding: EdgeInsets.symmetric(
      horizontal: embedded ? 8 : 11,
      vertical: embedded ? 6 : 9,
    ),
    decoration: BoxDecoration(
      color: embedded
          ? Colors.transparent
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
    child: Row(
      children: [
        if (imageUrl != null)
          MobileWebImage(imageUrl: imageUrl!, width: 24, height: 24)
        else
          Icon(icon ?? Icons.circle, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void showUpgradeDetails(BuildContext context, UpgradeTrackerItem item) {
  final meta = item.meta;
  final description = meta == null
      ? null
      : _firstSentences(
          GameDataService.localizedInfoForItem(meta).replaceAll(r'\n', ' '),
          2,
        );
  var selectedLevel = item.currentLevel.clamp(1, item.targetLevel);
  final accent = switch (item.category) {
    UpgradeCategory.heroes ||
    UpgradeCategory.guardians => const Color(0xFFAA57E8),
    UpgradeCategory.troops ||
    UpgradeCategory.darkTroops ||
    UpgradeCategory.spells ||
    UpgradeCategory.sieges => const Color(0xFF7A65D9),
    UpgradeCategory.pets => const Color(0xFFE56B9F),
    _ => const Color(0xFF4D9DE0),
  };
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final selectedStats = findLevelStats(meta, selectedLevel);
        final nextStats = selectedLevel < item.targetLevel
            ? findLevelStats(meta, selectedLevel + 1)
            : null;
        final selectedSteps = _upgradeStepsFromLevel(item, selectedLevel);
        final unlocks = _unlocksAtLevel(item, selectedLevel);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    accent.withValues(alpha: 0.28),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 38),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: accent.withValues(alpha: 0.68),
                                        ),
                                      ),
                                      child: MobileWebImage(
                                        imageUrl: _upgradeImageForLevel(
                                          item,
                                          selectedLevel,
                                        ),
                                        fallbackImageUrls:
                                            _upgradeImageFallbacks(
                                              item,
                                              fromLevel: selectedLevel,
                                            ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.08,
                                                ),
                                          ),
                                          if (item.category ==
                                                  UpgradeCategory.equipment &&
                                              meta?['hero'] != null) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              'For ${meta!['hero']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                          if (description != null &&
                                              description.isNotEmpty) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              description,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 11,
                                                    height: 1.18,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: -2,
                                top: -2,
                                child: SizedBox.square(
                                  dimension: 36,
                                  child: IconButton(
                                    tooltip: 'Close',
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 5,
                              activeTrackColor: accent,
                              inactiveTrackColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              thumbColor: accent,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: selectedLevel.toDouble(),
                              min: 1,
                              max: item.targetLevel.toDouble(),
                              divisions: item.targetLevel > 1
                                  ? item.targetLevel - 1
                                  : null,
                              label: 'Level $selectedLevel',
                              onChanged: item.targetLevel > 1
                                  ? (value) => setModalState(
                                      () => selectedLevel = value.round(),
                                    )
                                  : null,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Level $selectedLevel',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                'Max ${item.targetLevel}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          if (unlocks.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const _SectionHeading(title: 'Unlocks'),
                            const SizedBox(height: 6),
                            _UnlockChips(unlocks: unlocks),
                          ],
                          const SizedBox(height: 12),
                          const _SectionHeading(title: 'Stats'),
                          const SizedBox(height: 3),
                          _TrackerDetailStatRow(
                            icon: Icons.schedule_rounded,
                            label: 'Upgrade time',
                            value: selectedSteps.isEmpty
                                ? 'Max'
                                : _duration(selectedSteps.first.seconds),
                            accent: accent,
                          ),
                          if (selectedSteps.isNotEmpty &&
                              selectedSteps.first.costs.isNotEmpty)
                            _UpgradeCostStatRow(
                              costs: selectedSteps.first.costs,
                              accent: accent,
                            )
                          else
                            _TrackerDetailStatRow(
                              icon: Icons.payments_rounded,
                              label: 'Upgrade cost',
                              value: selectedSteps.isEmpty ? 'Max' : 'None',
                              accent: accent,
                            ),
                          if (selectedStats != null)
                            ..._trackerStatRows(
                              meta,
                              selectedStats,
                              nextStats,
                            ).map(
                              (stat) => _TrackerDetailStatRow(
                                icon: stat.icon,
                                label: stat.label,
                                value: stat.value,
                                accent: accent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _firstSentences(String value, int count) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return normalized;
  final matches = RegExp(r'[^.!?]+[.!?]+|[^.!?]+$').allMatches(normalized);
  return matches.take(count).map((match) => match.group(0)!.trim()).join(' ');
}

String _upgradeImageForLevel(UpgradeTrackerItem item, int level) {
  if (item.category == UpgradeCategory.traps) {
    return item.village == UpgradeVillage.home
        ? ImageAssets.getHomeVillageTrapImage(item.name, level)
        : ImageAssets.getBuilderBaseTrapImage(item.name, level);
  }
  if (const {
    UpgradeCategory.defenses,
    UpgradeCategory.craftedDefenses,
    UpgradeCategory.army,
    UpgradeCategory.resources,
    UpgradeCategory.walls,
    UpgradeCategory.supercharge,
  }.contains(item.category)) {
    return item.village == UpgradeVillage.home
        ? ImageAssets.getHomeVillageBuildingImage(item.name, level)
        : ImageAssets.getBuilderBaseBuildingImage(item.name, level);
  }
  return item.imageUrl;
}

List<String> _upgradeImageFallbacks(UpgradeTrackerItem item, {int? fromLevel}) {
  if (!const {
    UpgradeCategory.defenses,
    UpgradeCategory.craftedDefenses,
    UpgradeCategory.army,
    UpgradeCategory.resources,
    UpgradeCategory.walls,
    UpgradeCategory.supercharge,
  }.contains(item.category)) {
    return const [];
  }
  final current = fromLevel ?? item.currentLevel;
  if (current <= 1) return const [];
  return [
    for (var level = current - 1; level >= 1; level--)
      item.village == UpgradeVillage.home
          ? ImageAssets.getHomeVillageBuildingImage(item.name, level)
          : ImageAssets.getBuilderBaseBuildingImage(item.name, level),
  ];
}

List<(String, List<UpgradeTrackerItem>)> _equipmentHeroGroups(
  List<UpgradeTrackerItem> items,
) {
  const preferredOrder = <String>[
    'Barbarian King',
    'Archer Queen',
    'Grand Warden',
    'Royal Champion',
    'Minion Prince',
  ];
  final grouped = <String, List<UpgradeTrackerItem>>{};
  for (final item in items) {
    final rawHero = item.meta?['hero']?.toString().trim();
    final hero = rawHero == null || rawHero.isEmpty ? 'Other' : rawHero;
    grouped.putIfAbsent(hero, () => []).add(item);
  }
  final labels = grouped.keys.toList()
    ..sort((a, b) {
      final aIndex = preferredOrder.indexOf(a);
      final bIndex = preferredOrder.indexOf(b);
      if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
      if (aIndex >= 0) return -1;
      if (bIndex >= 0) return 1;
      return a.compareTo(b);
    });
  return [for (final label in labels) (label, grouped[label]!)];
}

List<UpgradeStep> _upgradeStepsFromLevel(
  UpgradeTrackerItem item,
  int selectedLevel,
) {
  final steps = <UpgradeStep>[];
  for (var target = selectedLevel + 1; target <= item.targetLevel; target++) {
    final existing = item.steps
        .where((step) => step.targetLevel == target)
        .firstOrNull;
    if (existing != null) {
      steps.add(existing);
      continue;
    }
    final level = findLevelStats(item.meta, target);
    if (level == null) continue;
    final costs = <UpgradeCost>[];
    final rawCost = level['upgrade_cost'] ?? level['build_cost'];
    if (rawCost is Map) {
      for (final entry in rawCost.entries) {
        final amount = entry.value is num
            ? entry.value as num
            : num.tryParse(entry.value.toString());
        if (amount != null && amount > 0) {
          costs.add(UpgradeCost(entry.key.toString(), amount));
        }
      }
    } else if (rawCost is num && rawCost > 0) {
      costs.add(
        UpgradeCost(
          item.meta?['upgrade_resource']?.toString() ?? 'gold',
          rawCost,
        ),
      );
    }
    steps.add(
      UpgradeStep(
        targetLevel: target,
        seconds:
            ((level['upgrade_time'] ?? level['build_time']) as num?)?.round() ??
            0,
        costs: costs,
      ),
    );
  }
  return steps;
}

typedef _UnlockItem = ({String name, String imageUrl, String? subtitle});

List<_UnlockItem> _unlocksAtLevel(UpgradeTrackerItem item, int level) {
  final direct = findLevelStats(item.meta, level)?['unlocks'];
  if (direct is List) {
    return direct
        .whereType<Map>()
        .map((entry) {
          final name = entry['name']?.toString() ?? '';
          final quantity = (entry['quantity'] as num?)?.round() ?? 1;
          return (
            name: name,
            imageUrl: _directUnlockImage(name),
            subtitle: quantity > 1 ? '×$quantity' : null,
          );
        })
        .where((entry) => entry.name.isNotEmpty)
        .toList(growable: false);
  }

  final bundle = GameDataService.bundleData;
  final unlocks = <_UnlockItem>[];
  for (final section in ['troops', 'spells', 'pets']) {
    final values = bundle[section];
    if (values is! List) continue;
    for (final raw in values.whereType<Map>()) {
      final name = raw['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      if (item.name == 'Barracks' && _isSuperTroop(raw)) continue;
      if (raw['production_building'] == item.name &&
          (raw['production_building_level'] as num?)?.round() == level) {
        unlocks.add((
          name: name,
          imageUrl: _unlockImage(section, name),
          subtitle: null,
        ));
      }
      if (item.name == 'Laboratory') {
        final levels = raw['levels'];
        if (levels is! List) continue;
        for (final upgrade in levels.whereType<Map>()) {
          if ((upgrade['required_lab_level'] as num?)?.round() == level) {
            unlocks.add((
              name: name,
              imageUrl: _unlockImage(section, name),
              subtitle: 'Level ${upgrade['level']}',
            ));
          }
        }
      }
    }
  }
  return unlocks;
}

bool _isSuperTroop(Map<dynamic, dynamic> item) {
  bool enabled(Object? value) =>
      value == true || value == 1 || value?.toString().toLowerCase() == 'true';
  return enabled(item['is_super_troop']) ||
      enabled(item['super_troop']) ||
      enabled(item['is_super']) ||
      item['type']?.toString().toLowerCase() == 'super_troop' ||
      item['category']?.toString().toLowerCase() == 'super_troop';
}

String _directUnlockImage(String name) {
  final traps = GameDataService.bundleData['traps'];
  if (traps is List &&
      traps.whereType<Map>().any((item) => item['name'] == name)) {
    return ImageAssets.getHomeVillageTrapImage(name, 1);
  }
  return ImageAssets.getHomeVillageBuildingImage(name, 1);
}

String _unlockImage(String section, String name) => switch (section) {
  'spells' => ImageAssets.getSpellImage(name),
  'pets' => ImageAssets.getPetImage(name),
  _ => ImageAssets.getTroopImage(name),
};

class _UnlockChips extends StatelessWidget {
  const _UnlockChips({required this.unlocks});

  final List<_UnlockItem> unlocks;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: unlocks
        .map(
          (unlock) => Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AspectSafeImage(
                  imageUrl: unlock.imageUrl,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 5),
                Text(
                  unlock.name,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (unlock.subtitle != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      unlock.subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .toList(growable: false),
  );
}

List<({IconData icon, String label, String value})> _trackerStatRows(
  Map<String, dynamic>? meta,
  Map<String, dynamic> level,
  Map<String, dynamic>? nextLevel,
) {
  final rows = <({IconData icon, String label, String value})>[];
  String? tiles(Object? value) {
    final raw = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (raw == null) return null;
    return (raw / 1000)
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void add(
    IconData icon,
    String label,
    Object? value,
    Object? nextValue, {
    String suffix = '',
  }) {
    if (value == null || value.toString().isEmpty || value == 0) return;
    final changed = nextValue != null && nextValue != value;
    final currentNumber = num.tryParse(value.toString().replaceAll(',', ''));
    final nextNumber = num.tryParse(
      nextValue?.toString().replaceAll(',', '') ?? '',
    );
    final percent =
        changed &&
            currentNumber != null &&
            nextNumber != null &&
            currentNumber != 0
        ? ((nextNumber - currentNumber) / currentNumber.abs()) * 100
        : null;
    final percentLabel = percent == null
        ? ''
        : ' (${percent >= 0 ? '+' : ''}${percent.abs() >= 10 ? percent.toStringAsFixed(0) : percent.toStringAsFixed(1)}%)';
    rows.add((
      icon: icon,
      label: label,
      value: changed
          ? '${value.toString()}$suffix → ${nextValue.toString()}$suffix$percentLabel'
          : '${value.toString()}$suffix',
    ));
  }

  final attackSpeed = level['attack_speed'] ?? meta?['attack_speed'];
  final nextAttackSpeed = nextLevel?['attack_speed'] ?? meta?['attack_speed'];
  add(
    Icons.speed_rounded,
    'Attack speed',
    attackSpeed is num ? (attackSpeed / 1000).toStringAsFixed(1) : null,
    nextAttackSpeed is num ? (nextAttackSpeed / 1000).toStringAsFixed(1) : null,
    suffix: 's',
  );
  add(
    Icons.my_location_rounded,
    'Attack range',
    tiles(level['attack_range'] ?? meta?['attack_range']),
    tiles(nextLevel?['attack_range'] ?? meta?['attack_range']),
    suffix: ' tiles',
  );
  add(
    Icons.center_focus_strong_rounded,
    'Minimum range',
    tiles(level['min_range'] ?? meta?['min_range']),
    tiles(nextLevel?['min_range'] ?? meta?['min_range']),
    suffix: ' tiles',
  );
  add(
    Icons.radar_rounded,
    'Effect range',
    tiles(level['effect_range'] ?? meta?['effect_range']),
    tiles(nextLevel?['effect_range'] ?? meta?['effect_range']),
    suffix: ' tiles',
  );
  add(
    Icons.directions_run_rounded,
    'Movement speed',
    meta?['movement_speed'],
    meta?['movement_speed'],
  );
  add(Icons.bolt_rounded, 'DPS', level['dps'], nextLevel?['dps']);
  add(Icons.flash_on_rounded, 'Damage', level['damage'], nextLevel?['damage']);
  add(
    Icons.favorite_rounded,
    'HP',
    level['hitpoints'],
    nextLevel?['hitpoints'],
  );
  add(
    Icons.healing_rounded,
    'Healing',
    level['heal_on_activation'],
    nextLevel?['heal_on_activation'],
  );
  add(
    Icons.straighten_rounded,
    'Building size',
    meta?['width'] == null ? null : '${meta!['width']} × ${meta['width']}',
    meta?['width'] == null ? null : '${meta!['width']} × ${meta['width']}',
  );
  add(
    Icons.adjust_rounded,
    'Trigger radius',
    tiles(meta?['trigger_radius']),
    tiles(meta?['trigger_radius']),
    suffix: ' tiles',
  );
  add(
    Icons.blur_circular_rounded,
    'Damage radius',
    tiles(level['damage_radius'] ?? meta?['damage_radius']),
    tiles(nextLevel?['damage_radius'] ?? meta?['damage_radius']),
    suffix: ' tiles',
  );
  add(
    Icons.change_history_rounded,
    'Cone angle',
    meta?['cone_angle'],
    meta?['cone_angle'],
    suffix: '°',
  );
  final air =
      level['is_air_targeting'] == true ||
      meta?['is_air_targeting'] == true ||
      meta?['air_trigger'] == true;
  final ground =
      level['is_ground_targeting'] == true ||
      meta?['is_ground_targeting'] == true ||
      meta?['ground_trigger'] == true;
  if (air || ground) {
    rows.add((
      icon: Icons.gps_fixed_rounded,
      label: 'Targets',
      value: air && ground
          ? 'Air & ground'
          : air
          ? 'Air'
          : 'Ground',
    ));
  }
  return rows;
}

class _TrackerDetailStatRow extends StatelessWidget {
  const _TrackerDetailStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^(.*) \(([+-][0-9.]+%)\)$').firstMatch(value);
    final primaryValue = match?.group(1) ?? value;
    final change = match?.group(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                primaryValue,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (change != null)
                Text(
                  change,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeCostStatRow extends StatelessWidget {
  const _UpgradeCostStatRow({required this.costs, required this.accent});

  final List<UpgradeCost> costs;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.payments_rounded, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Upgrade cost',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: costs
              .map(
                (cost) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MobileWebImage(
                      imageUrl: _resourceImage(cost.resource),
                      width: 17,
                      height: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _compact(cost.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ],
    ),
  );
}

void _showCollectionPreview(BuildContext context, UpgradeCollectionItem item) {
  final info = _collectionInfo(item);
  final musicUrl = _sceneryMusicUrl(item);
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: AspectRatio(
                  aspectRatio: item.type == UpgradeCollectionType.sceneries
                      ? 16 / 10
                      : 1,
                  child: MobileWebImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _collectionDisplayName(item),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                item.type == UpgradeCollectionType.decorations ||
                        item.type == UpgradeCollectionType.obstacles
                    ? '${item.count} owned'
                    : (item.owned ? 'Owned' : 'Missing'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (musicUrl != null) ...[
                const SizedBox(height: 10),
                _SceneryMusicButton(url: musicUrl),
              ],
              if (info.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...info.map(
                  (row) => _CollectionInfoRow(
                    label: row.label,
                    value: row.value,
                    color: row.color,
                    resourceAmount: row.resourceAmount,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

String? _sceneryMusicUrl(UpgradeCollectionItem item) {
  if (item.type != UpgradeCollectionType.sceneries) return null;
  final music = item.meta?['music']?.toString();
  if (music != null && music.isNotEmpty) {
    return music.startsWith('http') ? music : '${ImageAssets.baseUrl}/$music';
  }
  final thumbnail = item.meta?['thumbnail']?.toString();
  if (thumbnail == null || thumbnail.isEmpty) return null;
  final root = thumbnail.replaceFirst(RegExp(r'/thumbnail\.[a-zA-Z0-9]+$'), '');
  return root == thumbnail ? null : '${ImageAssets.baseUrl}/$root/music.ogg';
}

class _SceneryMusicButton extends StatefulWidget {
  const _SceneryMusicButton({required this.url});

  final String url;

  @override
  State<_SceneryMusicButton> createState() => _SceneryMusicButtonState();
}

class _SceneryMusicButtonState extends State<_SceneryMusicButton> {
  final _soloud = SoLoud.instance;
  AudioSource? _source;
  SoundHandle? _handle;
  bool _checking = true;
  bool _available = false;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAvailability());
  }

  Future<void> _checkAvailability() async {
    try {
      final response = await http.head(Uri.parse(widget.url));
      if (mounted) {
        setState(() {
          _available = response.statusCode >= 200 && response.statusCode < 300;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        final handle = _handle;
        if (handle != null && _soloud.getIsValidVoiceHandle(handle)) {
          _soloud.setPause(handle, true);
        }
        _stopPositionTimer();
        if (mounted) setState(() => _playing = false);
      } else {
        final existing = _handle;
        if (existing != null && _soloud.getIsValidVoiceHandle(existing)) {
          _soloud.setPause(existing, false);
          _startPositionTimer();
          if (mounted) setState(() => _playing = true);
          return;
        }
        if (mounted) setState(() => _loading = true);
        if (!_soloud.isInitialized) await _soloud.init();
        final session = await AudioSession.instance;
        await session.configure(
          const AudioSessionConfiguration(
            androidAudioAttributes: AndroidAudioAttributes(
              usage: AndroidAudioUsage.media,
              contentType: AndroidAudioContentType.music,
            ),
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransientMayDuck,
            androidWillPauseWhenDucked: true,
            avAudioSessionCategory: AVAudioSessionCategory.playback,
            avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
          ),
        );
        await session.setActive(true);
        _source ??= await _soloud.loadUrl(widget.url, mode: LoadMode.disk);
        _handle = _soloud.play(_source!);
        _soloud.setVolume(_handle!, 1);
        _duration = _soloud.getLength(_source!);
        _startPositionTimer();
        if (mounted) {
          setState(() {
            _playing = true;
            _loading = false;
          });
        }
      }
    } catch (_) {
      _stopPositionTimer();
      if (mounted) {
        setState(() {
          _available = false;
          _loading = false;
        });
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
      final handle = _handle;
      if (!mounted || handle == null || !_soloud.isInitialized) return;
      if (!_soloud.getIsValidVoiceHandle(handle)) {
        _stopPositionTimer();
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
        return;
      }
      setState(() => _position = _soloud.getPosition(handle));
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    final handle = _handle;
    if (handle != null && _soloud.isInitialized) {
      unawaited(_soloud.stop(handle));
    }
    final source = _source;
    if (source != null && _soloud.isInitialized) {
      unawaited(_soloud.disposeSource(source));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const SizedBox(
        height: 36,
        width: 36,
        child: Padding(
          padding: EdgeInsets.all(9),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!_available) return const SizedBox.shrink();
    final totalMs = math.max(1, _duration.inMilliseconds);
    final positionMs = _position.inMilliseconds.clamp(0, totalMs);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 44,
          child: IconButton.filledTonal(
            tooltip: _playing ? 'Pause soundtrack' : 'Play soundtrack',
            padding: EdgeInsets.zero,
            onPressed: _loading ? null : _toggle,
            icon: _loading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 25,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: positionMs.toDouble(),
                    min: 0,
                    max: totalMs.toDouble(),
                    onChanged: _handle == null || _loading
                        ? null
                        : (value) {
                            final handle = _handle;
                            if (handle == null) return;
                            final position = Duration(
                              milliseconds: value.round(),
                            );
                            _soloud.seek(handle, position);
                            setState(() => _position = position);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(_audioTime(_position)),
                  const Spacer(),
                  Text(
                    _duration == Duration.zero ? '–:––' : _audioTime(_duration),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _audioTime(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _CollectionTierCorner extends StatelessWidget {
  const _CollectionTierCorner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3),
        ],
      ),
      child: const SizedBox(width: 11, height: 11),
    );
  }
}

Color _skinTierColor(String? tier) => switch (tier?.toLowerCase()) {
  'legendary' => const Color(0xFFB85CFF),
  'gold' => const Color(0xFFFFC845),
  'basic' => const Color(0xFF4D9DE0),
  _ => const Color(0xFF8E929A),
};

List<({String label, String value, Color? color, UpgradeCost? resourceAmount})>
_collectionInfo(UpgradeCollectionItem item) {
  final meta = item.meta;
  if (meta == null) return const [];
  final rows =
      <
        ({
          String label,
          String value,
          Color? color,
          UpgradeCost? resourceAmount,
        })
      >[];
  void add(String label, Object? value, {Color? color}) {
    if (value == null || value.toString().isEmpty) return;
    rows.add((
      label: label,
      value: value.toString(),
      color: color,
      resourceAmount: null,
    ));
  }

  void addResource(String label, Object? amount, Object? resource) {
    final numericAmount = amount is num
        ? amount
        : num.tryParse(amount?.toString() ?? '');
    final resourceName = resource?.toString() ?? '';
    if (numericAmount == null || numericAmount <= 0 || resourceName.isEmpty) {
      return;
    }
    rows.add((
      label: label,
      value: '',
      color: null,
      resourceAmount: UpgradeCost(resourceName, numericAmount),
    ));
  }

  switch (item.type) {
    case UpgradeCollectionType.skins:
      final tier = meta['tier']?.toString();
      add('Tier', tier, color: _skinTierColor(tier));
      add('Hero', meta['character']);
    case UpgradeCollectionType.sceneries:
      add('Village', _collectionVillageName(meta['type']));
      if (meta['music'] != null) add('Music', 'Custom soundtrack');
    case UpgradeCollectionType.decorations:
      add('Village', _collectionVillageName(meta['village']));
      add('Size', _collectionSize(meta['width']));
      add('Maximum', item.maxCount);
      addResource('Build cost', meta['build_cost'], meta['build_resource']);
      if (meta['pass_reward'] == true) add('Source', 'Pass reward');
    case UpgradeCollectionType.obstacles:
      add('Village', _collectionVillageName(meta['village']));
      add('Size', _collectionSize(meta['width']));
      addResource('Clear cost', meta['clear_cost'], meta['clear_resource']);
      addResource('Loot', meta['loot_count'], meta['loot_resource']);
    case UpgradeCollectionType.capitalHouseParts:
      add('Part', meta['slot_type']);
  }
  return rows;
}

String _collectionVillageName(Object? value) => switch (value?.toString()) {
  'builderBase' || 'builder' => 'Builder Base',
  'war' => 'War Base',
  'home' => 'Home Village',
  final value? => value,
  _ => '',
};

String _collectionSize(Object? width) => width == null ? '' : '$width × $width';

class _CollectionInfoRow extends StatelessWidget {
  const _CollectionInfoRow({
    required this.label,
    required this.value,
    this.color,
    this.resourceAmount,
  });

  final String label;
  final String value;
  final Color? color;
  final UpgradeCost? resourceAmount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (resourceAmount != null)
          _ResourcePill(cost: resourceAmount!, compact: true)
        else
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );
}

String _categoryLabel(UpgradeCategory value) => switch (value) {
  UpgradeCategory.defenses => 'Defenses',
  UpgradeCategory.guardians => 'Guardians',
  UpgradeCategory.craftedDefenses => 'Crafted defenses',
  UpgradeCategory.traps => 'Traps',
  UpgradeCategory.army => 'Army',
  UpgradeCategory.resources => 'Resources',
  UpgradeCategory.troops => 'Troops',
  UpgradeCategory.spells => 'Spells',
  UpgradeCategory.darkTroops => 'Dark troops',
  UpgradeCategory.sieges => 'Sieges',
  UpgradeCategory.heroes => 'Heroes',
  UpgradeCategory.equipment => 'Equipment',
  UpgradeCategory.pets => 'Pets',
  UpgradeCategory.walls => 'Walls',
  UpgradeCategory.builders => 'Builders',
  UpgradeCategory.supercharge => 'Supercharge',
};

String _categoryImage(
  UpgradeTrackerSnapshot snapshot,
  UpgradeCategory category,
  UpgradeVillage village,
) {
  final items = snapshot.itemsFor(village: village, category: category);
  return items.firstOrNull?.imageUrl ??
      (village == UpgradeVillage.home
          ? ImageAssets.townHall(snapshot.townHallLevel)
          : ImageAssets.builderHall(snapshot.builderHallLevel));
}

String _collectionLabel(UpgradeCollectionType value) => switch (value) {
  UpgradeCollectionType.skins => 'Skins',
  UpgradeCollectionType.sceneries => 'Sceneries',
  UpgradeCollectionType.decorations => 'Decorations',
  UpgradeCollectionType.obstacles => 'Obstacles',
  UpgradeCollectionType.capitalHouseParts => 'House parts',
};

String _collectionDisplayName(UpgradeCollectionItem item) {
  final name = item.name.replaceAll(r'\q', '"');
  if (item.type != UpgradeCollectionType.sceneries) return name;
  return name.replaceFirst(RegExp(r'\s+Scenery$', caseSensitive: false), '');
}

// ignore: unused_element
String _strategyLabel(UpgradePlanStrategy value) => switch (value) {
  UpgradePlanStrategy.balanced => 'Balanced',
  UpgradePlanStrategy.shortest => 'Shortest first',
  UpgradePlanStrategy.cheapest => 'Cheapest first',
};

String _snapshotAgeLabel(
  BuildContext context,
  DateTime capturedAt, {
  DateTime? now,
}) {
  final l10n = AppLocalizations.of(context)!;
  final age = (now ?? DateTime.now()).difference(capturedAt);
  if (age.isNegative || age.inMinutes < 1) {
    return l10n.upgradeTrackerUpdatedJustNow;
  }
  if (age.inHours < 1) {
    return l10n.upgradeTrackerUpdatedMinutesAgo(age.inMinutes);
  }
  if (age.inHours < 24) {
    return l10n.upgradeTrackerUpdatedHoursAgo(age.inHours);
  }
  final locale = Localizations.localeOf(context).toString();
  return l10n.upgradeTrackerUpdatedOn(
    DateFormat.yMMMd(locale).add_jm().format(capturedAt),
  );
}

String _duration(int seconds) {
  if (seconds <= 0) return 'Now';
  final duration = Duration(seconds: seconds);
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  if (hours > 0) return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  return '${minutes.clamp(1, 59)}m';
}

String _compact(num value) {
  final number = value.toDouble();
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  }
  if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
  if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
  return NumberFormat.decimalPattern().format(number.round());
}

String _dateLabel(DateTime date) {
  final difference = date.difference(DateTime.now());
  if (difference.inDays < 1) return 'Today';
  if (difference.inDays < 60) return 'About ${difference.inDays} days';
  return DateFormat.yMMMd().format(date);
}

int _resourceWeight(String value) {
  if (value == 'gold') return 0;
  if (value == 'elixir') return 1;
  if (value == 'dark_elixir') return 2;
  if (value == 'builder_gold') return 3;
  if (value == 'builder_elixir') return 4;
  if (value == 'shiny_ore') return 5;
  if (value == 'glowy_ore') return 6;
  if (value == 'starry_ore') return 7;
  return 99;
}

String _resourceLabel(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _resourceImage(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return '${ImageAssets.baseUrl}/resources/$normalized.webp';
}
