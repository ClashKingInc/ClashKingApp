import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/collapsible_item_section.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
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

const _trackerContentGutter = 16.0;
const _trackerDesktopBreakpoint = 900.0;
const _trackerDesktopMaxWidth = 1180.0;

bool _isTrackerDesktop(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= _trackerDesktopBreakpoint;

class UpgradeTrackerPage extends StatefulWidget {
  const UpgradeTrackerPage({super.key, this.initialTag});

  /// Opens directly on this account instead of the first linked one — used
  /// when navigating in from a specific account's card/row elsewhere in the
  /// app (e.g. a Home dashboard panel).
  final String? initialTag;

  @override
  State<UpgradeTrackerPage> createState() => _UpgradeTrackerPageState();
}

class _UpgradeTrackerPageState extends State<UpgradeTrackerPage> {
  final _repository = UpgradeTrackerRepository.shared;
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
  _TrackerPlanData? _planData;
  final _capturedAtByTag = <String, DateTime>{};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _section);
  }

  void _scheduleClockTick() {
    _ticker?.cancel();
    _ticker = null;
    final snapshot = _snapshot;
    if (!mounted || snapshot == null) return;

    final now = DateTime.now();
    DateTime? nextTick;
    void consider(DateTime candidate) {
      if (!candidate.isAfter(now)) return;
      if (nextTick == null || candidate.isBefore(nextTick!)) {
        nextTick = candidate;
      }
    }

    void considerRemaining(int originalSeconds) {
      final remaining = snapshot.remainingCapturedSeconds(
        originalSeconds,
        now: now,
      );
      if (remaining <= 0) return;
      final deadline = snapshot.capturedAt.add(
        Duration(seconds: originalSeconds),
      );
      consider(deadline);
      final displayUnit = remaining >= Duration.secondsPerDay
          ? Duration.secondsPerHour
          : Duration.secondsPerMinute;
      consider(now.add(Duration(seconds: remaining % displayUnit + 1)));
    }

    final age = now.difference(snapshot.capturedAt);
    if (age.isNegative || age.inMinutes < 1) {
      consider(snapshot.capturedAt.add(const Duration(minutes: 1)));
    } else if (age.inHours < 1) {
      consider(snapshot.capturedAt.add(Duration(minutes: age.inMinutes + 1)));
    } else if (age.inHours < 24) {
      consider(snapshot.capturedAt.add(Duration(hours: age.inHours + 1)));
    }

    for (final item in snapshot.items) {
      considerRemaining(item.activeSeconds ?? 0);
      considerRemaining(item.helperSeconds ?? 0);
      considerRemaining(item.cooldownSeconds ?? 0);
    }
    final boosts = snapshot.boosts;
    considerRemaining(boosts.builderBoostSeconds);
    considerRemaining(boosts.labBoostSeconds);
    considerRemaining(boosts.clockTowerBoostSeconds);
    considerRemaining(boosts.builderConsumableSeconds);
    considerRemaining(boosts.labConsumableSeconds);
    considerRemaining(boosts.petConsumableSeconds);
    considerRemaining(boosts.clockTowerCooldownSeconds);
    for (final event in snapshot.events) {
      if (!now.isBefore(event.startsAt) && now.isBefore(event.endsAt)) {
        consider(event.endsAt);
      }
    }

    final target = nextTick;
    if (target == null) return;
    final delay = target.difference(now) + const Duration(milliseconds: 12);
    _ticker = Timer(delay, () {
      if (!mounted) return;
      _clock.value = DateTime.now();
      _scheduleClockTick();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final cocAccounts = context.read<CocAccountService>();
    final linkedTags = cocAccounts.verifiedAccounts
        .map((account) => account['player_tag']?.toString() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    _repository.configureRemote(
      accountId: context.read<AuthService>().currentUser?.userId,
      verifiedPlayerTags: linkedTags,
    );
    final normalizedRequestedTag = widget.initialTag == null
        ? null
        : UpgradeTrackerRepository.normalizeTag(widget.initialTag!);
    final requested = normalizedRequestedTag == null
        ? null
        : linkedTags.firstWhere(
            (tag) =>
                UpgradeTrackerRepository.normalizeTag(tag) ==
                normalizedRequestedTag,
            orElse: () => '',
          );
    final initial = (requested != null && requested.isNotEmpty)
        ? requested
        : linkedTags.firstOrNull;
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
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _selectedTag = tag;
      _loading = true;
      _error = null;
      _planData = null;
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
      if (snapshot != null) {
        _rebuildPlanLanes(snapshot);
        _scheduleClockTick();
      } else {
        _planLanes.value = const [];
      }
      _scheduleWidgetSync();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _snapshot = null;
        _planData = null;
        _loading = false;
      });
      _planLanes.value = const [];
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
      _rebuildPlanLanes(snapshot);
      _scheduleClockTick();
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
    final linked = context.read<CocAccountService>().verifiedAccounts;
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
    final l10n = AppLocalizations.of(context)!;
    context.select<CocAccountService, int>(
      (service) => Object.hashAll(
        service.cocAccounts.map(
          (account) => Object.hash(
            account['player_tag'],
            account['tag'],
            account['name'],
            account['townHallLevel'],
            account['builderHallLevel'],
            account['is_verified'],
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
    final cocAccounts = context.read<CocAccountService>();
    _repository.configureRemote(
      accountId: context.read<AuthService>().currentUser?.userId,
      verifiedPlayerTags: cocAccounts.verifiedAccounts.map(
        (account) => account['player_tag']?.toString() ?? '',
      ),
    );
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
    final snapshot = _snapshot;
    final isDesktop = _isTrackerDesktop(context);
    if (_loading || _error != null || snapshot == null) {
      return Scaffold(
        appBar: isDesktop
            ? null
            : AppBar(
                title: Text(
                  selectedAccount?.name ?? l10n.upgradeTrackerChooseAccount,
                ),
                actions: [
                  IconButton(
                    tooltip: l10n.upgradeTrackerSwitchAccount(
                      selectedAccount?.name ?? l10n.upgradeTrackerChooseAccount,
                    ),
                    onPressed: () => _showAccountPicker(uniqueAccounts),
                    icon: const Icon(Icons.switch_account_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.upgradeTrackerPasteJson,
                    onPressed: _importSnapshot,
                    icon: const Icon(Icons.content_paste_rounded),
                  ),
                ],
              ),
        body: isDesktop
            ? _buildDesktopEmptyShell(uniqueAccounts, selectedAccount)
            : _buildBody(),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _TrackerInfoHeader(
              snapshot: snapshot,
              selectedTab: _section,
              selectedAccount: selectedAccount,
              clock: _clock,
              lanes: _planLanes,
              onBack: () => Navigator.of(context).pop(),
              onSwitchAccount: () => _showAccountPicker(uniqueAccounts),
              onShare: () => _showShareHub(snapshot),
              onImport: _importSnapshot,
              onInfo: _section > 1
                  ? null
                  : () {
                      final village = _section == 1
                          ? UpgradeVillage.builderBase
                          : UpgradeVillage.home;
                      final title = village == UpgradeVillage.home
                          ? l10n.upgradeTrackerHomeVillage
                          : l10n.upgradeTrackerBuilderBase;
                      _showUpgradeSectionSummary(
                        context,
                        title,
                        snapshot.overallSummary(village: village),
                        snapshot: snapshot,
                        village: village,
                        goldPassPercent: _goldPassPercent,
                        preferences: _planPreferences,
                      );
                    },
              goldPassPercent: _goldPassPercent,
              onGoldPass: () => _showGoldPassPicker(snapshot),
              onPriorities: () => _showPlanPreferences(
                context,
                snapshot,
                _planPreferences,
                (value) {
                  setState(() => _planPreferences = value);
                  _rebuildPlanLanes(snapshot);
                  unawaited(_savePlanDraft());
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: InfoProfileTabs(
              selectedIndex: _section,
              onTabSelected: _selectSection,
              alwaysScrollable: true,
              tabs: [
                InfoProfileTabData(
                  label: l10n.upgradeTrackerHomeVillage,
                  imageUrl: ImageAssets.townHall(snapshot.townHallLevel),
                ),
                InfoProfileTabData(
                  label: l10n.upgradeTrackerBuilderBase,
                  imageUrl: ImageAssets.builderHall(snapshot.builderHallLevel),
                ),
                InfoProfileTabData(
                  label: 'Calendar',
                  icon: Icons.calendar_month_rounded,
                ),
                InfoProfileTabData(
                  label: l10n.upgradeTrackerPlan,
                  icon: Icons.route_rounded,
                ),
                InfoProfileTabData(
                  label: l10n.upgradeTrackerCollection,
                  icon: Icons.collections_rounded,
                ),
              ],
            ),
          ),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildDesktopEmptyShell(
    List<_TrackerAccountOption> accounts,
    _TrackerAccountOption? selectedAccount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final subtitle = selectedAccount == null
        ? l10n.upgradeTrackerChooseAccount
        : [
            selectedAccount.name,
            if (selectedAccount.subtitle.isNotEmpty) selectedAccount.subtitle,
          ].join(' · ');

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _trackerDesktopMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(CKRadius.control),
                      ),
                      child: Icon(
                        Icons.construction_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: CKSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.upgradeTrackerTitle,
                            style: CKTypography.of(
                              context,
                              CKTextRole.screenTitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CKTypography.of(
                              context,
                              CKTextRole.metadata,
                            ).copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showAccountPicker(accounts),
                      icon: const Icon(Icons.switch_account_rounded),
                      label: Text(l10n.upgradeTrackerChooseAccount),
                    ),
                    const SizedBox(width: CKSpacing.sm),
                    FilledButton.icon(
                      onPressed: _importSnapshot,
                      icon: const Icon(Icons.content_paste_rounded),
                      label: Text(l10n.upgradeTrackerPasteJson),
                    ),
                  ],
                ),
                const SizedBox(height: CKSpacing.xl),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
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
    final planData = _planData;
    if (planData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        _UpgradesTab(
          key: const ValueKey('home-upgrades'),
          snapshot: snapshot,
          village: UpgradeVillage.home,
          clock: _clock,
        ),
        _UpgradesTab(
          key: const ValueKey('builder-upgrades'),
          snapshot: snapshot,
          village: UpgradeVillage.builderBase,
          clock: _clock,
        ),
        _PlanCalendarTab(snapshot: snapshot, planData: planData),
        _PlanTab(planData: planData),
        _CollectionTab(snapshot: snapshot),
      ],
    );
  }

  void _rebuildPlanLanes(UpgradeTrackerSnapshot snapshot) {
    final planData = _buildTrackerPlanData(
      snapshot,
      goldPassPercent: _goldPassPercent,
      preferences: _planPreferences,
    );
    _planData = planData;
    _planLanes.value = planData.allLanes;
  }

  Future<void> _showGoldPassPicker(UpgradeTrackerSnapshot snapshot) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in const [0, 10, 15, 20])
              ListTile(
                leading: _AspectSafeImage(
                  imageUrl: ImageAssets.goldPass,
                  width: 28,
                  height: 28,
                ),
                title: Text(value == 0 ? 'No Gold Pass' : '$value% Gold Pass'),
                trailing: value == _goldPassPercent
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected == _goldPassPercent) return;
    setState(() => _goldPassPercent = selected);
    _rebuildPlanLanes(snapshot);
    unawaited(_savePlanDraft());
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

class _TrackerInfoHeader extends StatelessWidget {
  const _TrackerInfoHeader({
    required this.snapshot,
    required this.selectedTab,
    required this.selectedAccount,
    required this.clock,
    required this.lanes,
    required this.onBack,
    required this.onSwitchAccount,
    required this.onShare,
    required this.onImport,
    required this.onInfo,
    required this.goldPassPercent,
    required this.onGoldPass,
    required this.onPriorities,
  });

  final UpgradeTrackerSnapshot snapshot;
  final int selectedTab;
  final _TrackerAccountOption? selectedAccount;
  final ValueListenable<DateTime> clock;
  final ValueListenable<List<UpgradePlanLane>> lanes;
  final VoidCallback onBack;
  final VoidCallback onSwitchAccount;
  final VoidCallback onShare;
  final VoidCallback onImport;
  final VoidCallback? onInfo;
  final int goldPassPercent;
  final VoidCallback onGoldPass;
  final VoidCallback onPriorities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final village = selectedTab == 1
        ? UpgradeVillage.builderBase
        : UpgradeVillage.home;
    final hallImage = village == UpgradeVillage.home
        ? ImageAssets.townHall(snapshot.townHallLevel)
        : ImageAssets.builderHall(snapshot.builderHallLevel);
    final background = village == UpgradeVillage.home
        ? ImageAssets.homeBaseBackground
        : ImageAssets.builderBaseBackground;
    final summary = snapshot.overallSummary(village: village);
    final collectionTotal = snapshot.collections.length;
    final collectionOwned = snapshot.collections
        .where((item) => item.owned)
        .length;
    final active = snapshot
        .itemsFor(village: village)
        .where((item) => snapshot.remainingActiveSeconds(item) > 0)
        .length;
    final isDesktop = _isTrackerDesktop(context);
    final headerHeight =
        MediaQuery.paddingOf(context).top + (isDesktop ? 214.0 : 276.0);
    final sidePadding = isDesktop ? 24.0 : 12.0;

    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(imageUrl: background, height: headerHeight),
        ),
        SizedBox(
          height: headerHeight,
          child: Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Row(
                  children: [
                    HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      iconColor: Colors.white,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onTap: onBack,
                      showBackground: false,
                    ),
                    const Spacer(),
                    HeaderIconButton(
                      imageUrl: ImageAssets.goldPass,
                      tooltip: goldPassPercent == 0
                          ? 'No Gold Pass'
                          : '$goldPassPercent% Gold Pass',
                      onTap: onGoldPass,
                      showBackground: false,
                    ),
                    HeaderIconButton(
                      icon: Icons.tune_rounded,
                      iconColor: Colors.white,
                      tooltip: 'Priorities',
                      onTap: onPriorities,
                      showBackground: false,
                    ),
                    if (onInfo != null)
                      HeaderIconButton(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.white,
                        tooltip: 'Village completion details',
                        onTap: onInfo!,
                        showBackground: false,
                      ),
                    HeaderIconButton(
                      icon: Icons.ios_share_rounded,
                      iconColor: Colors.white,
                      tooltip: AppLocalizations.of(
                        context,
                      )!.upgradeTrackerShare,
                      onTap: onShare,
                      showBackground: false,
                    ),
                    const SizedBox(width: 4),
                    HeaderIconButton(
                      icon: Icons.content_paste_rounded,
                      iconColor: Colors.white,
                      tooltip: AppLocalizations.of(
                        context,
                      )!.upgradeTrackerPasteJson,
                      onTap: onImport,
                      showBackground: false,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: onSwitchAccount,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MobileWebImage(
                        imageUrl: selectedTab == 4
                            ? ImageAssets.townHall(snapshot.townHallLevel)
                            : hallImage,
                        width: isDesktop ? 58 : 70,
                        height: isDesktop ? 58 : 70,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              snapshot.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: isDesktop ? 24 : 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Text(
                        snapshot.tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: clock,
                        builder: (context, now, _) => Text(
                          _snapshotAgeLabel(
                            context,
                            selectedAccount?.capturedAt ?? snapshot.capturedAt,
                            now: now,
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 16,
                  0,
                  isDesktop ? 24 : 16,
                  isDesktop ? 12 : 10,
                ),
                child: ValueListenableBuilder<List<UpgradePlanLane>>(
                  valueListenable: lanes,
                  builder: (context, planLanes, _) {
                    final finish = planLanes
                        .where(
                          (lane) => lane.upgrades.any(
                            (upgrade) => upgrade.item.village == village,
                          ),
                        )
                        .map((lane) => lane.finishesAt)
                        .whereType<DateTime>()
                        .fold<DateTime?>(
                          null,
                          (latest, date) =>
                              latest == null || date.isAfter(latest)
                              ? date
                              : latest,
                        );
                    final values = selectedTab == 4
                        ? <(String, String)>[
                            (
                              l10n.upgradeTrackerCollected,
                              collectionTotal == 0
                                  ? '0%'
                                  : '${(collectionOwned * 100 / collectionTotal).toStringAsFixed(1)}%',
                            ),
                            (
                              l10n.upgradeTrackerHeaderOwned,
                              '$collectionOwned / $collectionTotal',
                            ),
                            (
                              l10n.upgradeTrackerHeaderUpdated,
                              _shortAge(snapshot.capturedAt),
                            ),
                          ]
                        : <(String, String)>[
                            (
                              l10n.upgradeTrackerHeaderComplete,
                              '${(summary.completion * 100).toStringAsFixed(1)}%',
                            ),
                            (
                              l10n.upgradeTrackerHeaderLevelsLeft,
                              '${summary.levelsRemaining}',
                            ),
                            (l10n.upgradeTrackerHeaderActive, '$active'),
                            (
                              l10n.upgradeTrackerHeaderFinishes,
                              finish == null ? '—' : _dateLabel(finish),
                            ),
                          ];
                    return Row(
                      children: [
                        for (var index = 0; index < values.length; index++) ...[
                          if (index > 0) const SizedBox(width: 6),
                          Expanded(
                            flex: values.length == 4 && index == 3 ? 2 : 1,
                            child: Container(
                              height: isDesktop ? 48 : 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.34),
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 12 : 16,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    values[index].$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    values[index].$1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _shortAge(DateTime capturedAt) {
  final duration = DateTime.now().difference(capturedAt);
  if (duration.inDays > 0) return '${duration.inDays}d';
  if (duration.inHours > 0) return '${duration.inHours}h';
  return '${duration.inMinutes.clamp(0, 59)}m';
}

// Kept temporarily as a visual reference while the merged Progress surface is
// validated; it is not reachable from navigation.
// ignore: unused_element
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
    this.surfaceWhenExpanded = false,
    this.margin = const EdgeInsets.only(bottom: 10),
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
  final bool surfaceWhenExpanded;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return CollapsibleItemSection(
      title: title,
      subtitle: countLabel,
      leading: _AspectSafeImage(imageUrl: imageUrl, width: 34, height: 30),
      trailing: SectionProgressBadge(progress: completion, onTap: onSummaryTap),
      expanded: expanded,
      onToggle: onToggle,
      margin: margin,
      showContent: showContent,
      surfaceWhenExpanded: surfaceWhenExpanded,
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
    super.key,
    required this.snapshot,
    required this.village,
    required this.clock,
  });

  final UpgradeTrackerSnapshot snapshot;
  final UpgradeVillage village;
  final ValueListenable<DateTime> clock;

  @override
  State<_UpgradesTab> createState() => _UpgradesTabState();
}

class _UpgradesTabState extends State<_UpgradesTab> {
  final _expandedGroups = <String>{};
  final _searchController = TextEditingController();
  String _query = '';
  String _groupFilter = 'all';
  late _UpgradeVillageIndex _index;
  late _UpgradeVillageViewData _viewData;
  late Set<UpgradeTrackerItem> _activeItems;

  @override
  void initState() {
    super.initState();
    _rebuildIndex();
    _activeItems = _currentActiveItems();
    widget.clock.addListener(_handleClockChange);
  }

  @override
  void didUpdateWidget(covariant _UpgradesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock) {
      oldWidget.clock.removeListener(_handleClockChange);
      widget.clock.addListener(_handleClockChange);
    }
    if (!identical(oldWidget.snapshot, widget.snapshot) ||
        oldWidget.village != widget.village) {
      _rebuildIndex();
      _activeItems = _currentActiveItems();
    }
  }

  @override
  void dispose() {
    widget.clock.removeListener(_handleClockChange);
    _searchController.dispose();
    super.dispose();
  }

  Set<UpgradeTrackerItem> _currentActiveItems() => Set.identity()
    ..addAll(
      widget.snapshot
          .itemsFor(village: widget.village)
          .where((item) => widget.snapshot.remainingActiveSeconds(item) > 0),
    );

  void _handleClockChange() {
    final next = _currentActiveItems();
    if (setEquals(_activeItems, next)) return;
    setState(() => _activeItems = next);
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
    _viewData = _index.viewFor(normalized);
  }

  void _rebuildIndex() {
    _index = _UpgradeVillageIndex.build(widget.snapshot, widget.village);
    _rebuildViewData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final village = widget.village;
    final hasActive = _activeItems.isNotEmpty;
    final isDesktop = _isTrackerDesktop(context);
    final data = _viewData;
    if (isDesktop) {
      return _buildDesktopGrid(l10n, village, hasActive, data);
    }

    final slivers = <Widget>[];
    if (hasActive) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            _trackerContentGutter,
            8,
            _trackerContentGutter,
            4,
          ),
          sliver: SliverToBoxAdapter(
            child: ValueListenableBuilder<DateTime>(
              valueListenable: widget.clock,
              builder: (context, now, _) {
                final active = widget.snapshot
                    .itemsFor(village: village)
                    .where(
                      (item) =>
                          widget.snapshot.remainingActiveSeconds(
                            item,
                            now: now,
                          ) >
                          0,
                    )
                    .toList(growable: false);
                return CKSectionPanel(
                  padding: const EdgeInsets.all(CKSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        title: 'In progress',
                        trailing: '${active.length} active',
                      ),
                      ...active.map(
                        (item) => _ActiveUpgradeRow(
                          snapshot: widget.snapshot,
                          item: item,
                          now: now,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _trackerContentGutter,
          8,
          _trackerContentGutter,
          10,
        ),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchController,
                  query: _query,
                  hintText: l10n.upgradeTrackerSearchUpgrades,
                  onChanged: _setQuery,
                ),
              ),
              const SizedBox(width: CKSpacing.sm),
              FilterDropdown(
                sortBy: _groupFilter,
                maxWidth: 118,
                sortByOptions: const {
                  'All': 'all',
                  'Buildings': 'buildings',
                  'Heroes': 'heroes',
                  'Research': 'research',
                  'Other': 'other',
                },
                updateSortBy: (value) => setState(() => _groupFilter = value),
              ),
            ],
          ),
        ),
      ),
    );

    if (data.visibleItems.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(l10n.upgradeTrackerNoMatchingItems)),
        ),
      );
    } else {
      for (final group in data.groups.where(
        (group) => _matchesUpgradeGroupFilter(group, _groupFilter),
      )) {
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

  Widget _buildDesktopGrid(
    AppLocalizations l10n,
    UpgradeVillage village,
    bool hasActive,
    _UpgradeVillageViewData data,
  ) {
    final visibleGroups = data.groups
        .where((group) => _matchesUpgradeGroupFilter(group, _groupFilter))
        .toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _trackerDesktopMaxWidth,
                ),
                child: Column(
                  children: [
                    if (hasActive) ...[
                      ValueListenableBuilder<DateTime>(
                        valueListenable: widget.clock,
                        builder: (context, now, _) {
                          final active = widget.snapshot
                              .itemsFor(village: village)
                              .where(
                                (item) =>
                                    widget.snapshot.remainingActiveSeconds(
                                      item,
                                      now: now,
                                    ) >
                                    0,
                              )
                              .toList(growable: false);
                          return CKSectionPanel(
                            padding: const EdgeInsets.all(CKSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeading(
                                  title: 'In progress',
                                  trailing: '${active.length} active',
                                ),
                                ...active.map(
                                  (item) => _ActiveUpgradeRow(
                                    snapshot: widget.snapshot,
                                    item: item,
                                    now: now,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            controller: _searchController,
                            query: _query,
                            hintText: l10n.upgradeTrackerSearchUpgrades,
                            onChanged: _setQuery,
                          ),
                        ),
                        const SizedBox(width: CKSpacing.sm),
                        FilterDropdown(
                          sortBy: _groupFilter,
                          maxWidth: 136,
                          sortByOptions: const {
                            'All': 'all',
                            'Buildings': 'buildings',
                            'Heroes': 'heroes',
                            'Research': 'research',
                            'Other': 'other',
                          },
                          updateSortBy: (value) =>
                              setState(() => _groupFilter = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (data.visibleItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 88),
                        child: Text(l10n.upgradeTrackerNoMatchingItems),
                      )
                    else
                      _DesktopUpgradeGroupGrid(
                        children: [
                          for (final group in visibleGroups)
                            _buildDesktopGroupCard(l10n, village, group),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGroupCard(
    AppLocalizations l10n,
    UpgradeVillage village,
    _UpgradeGroup group,
  ) {
    final items = _viewData.itemsByGroup[group]!;
    final summary = _viewData.summaryByGroup[group]!;
    final key = '${village.name}-${group.name}';
    final expanded = _expandedGroups.contains(key);
    final title = _upgradeGroupLabelForVillage(group, village);

    return _TrackerCollapsibleCard(
      title: title,
      countLabel:
          '${l10n.upgradeTrackerLevelsLeft(summary.levelsRemaining)} · ${l10n.upgradeTrackerItemCount(items.length)}',
      imageUrl: _groupImage(widget.snapshot, group, village),
      completion: summary.completion,
      expanded: expanded,
      onToggle: () => setState(() {
        expanded ? _expandedGroups.remove(key) : _expandedGroups.add(key);
      }),
      onSummaryTap: () => _showUpgradeSectionSummary(context, title, summary),
      surfaceWhenExpanded: true,
      margin: EdgeInsets.zero,
      child: _buildDesktopGroupContent(group, items),
    );
  }

  Widget _buildDesktopGroupContent(
    _UpgradeGroup group,
    List<UpgradeTrackerItem> items,
  ) {
    if (group == _UpgradeGroup.laboratory) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ])
            if (category.$2.isNotEmpty) ...[
              _DesktopUpgradeSubheading(label: category.$1),
              _upgradeIconWrap(category.$2),
              const SizedBox(height: 10),
            ],
        ],
      );
    }

    if (group == _UpgradeGroup.equipment) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final heroGroup in _equipmentHeroGroups(items)) ...[
            _DesktopUpgradeSubheading(
              label: heroGroup.$1,
              imageUrl: ImageAssets.getHeroImage(heroGroup.$1),
            ),
            _upgradeIconWrap(heroGroup.$2),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return _upgradeIconWrap(items);
  }

  Widget _upgradeIconWrap(List<UpgradeTrackerItem> items) {
    const tileSize = 54.0;
    const spacing = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox.square(
                dimension: tileSize,
                child: _UpgradeIconTile(
                  snapshot: widget.snapshot,
                  item: item,
                  clock: _activeItems.contains(item) ? widget.clock : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _upgradeGridSliver(List<UpgradeTrackerItem> items) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = _isTrackerDesktop(context);
    if (isDesktop) {
      const tileSize = 54.0;
      const spacing = 8.0;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _trackerContentGutter,
          0,
          _trackerContentGutter,
          12,
        ),
        sliver: SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in items)
                    SizedBox.square(
                      dimension: tileSize,
                      child: _UpgradeIconTile(
                        snapshot: widget.snapshot,
                        item: item,
                        clock: _activeItems.contains(item)
                            ? widget.clock
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final crossAxisCount = width < 600 ? 5 : 8;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        _trackerContentGutter,
        0,
        _trackerContentGutter,
        12,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _UpgradeIconTile(
            snapshot: widget.snapshot,
            item: item,
            clock: _activeItems.contains(item) ? widget.clock : null,
          );
        },
      ),
    );
  }
}

class _DesktopUpgradeGroupGrid extends StatelessWidget {
  const _DesktopUpgradeGroupGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 860 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _DesktopUpgradeSubheading extends StatelessWidget {
  const _DesktopUpgradeSubheading({required this.label, this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl case final imageUrl?) ...[
            _AspectSafeImage(imageUrl: imageUrl, width: 22, height: 22),
            const SizedBox(width: CKSpacing.xs),
          ],
          Text(label, style: CKTypography.of(context, CKTextRole.rowTitle)),
        ],
      ),
    );
  }
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
}

class _UpgradeVillageIndex {
  const _UpgradeVillageIndex({
    required this.displayItems,
    required this.normalizedNames,
    required this.summary,
    required this.groups,
    required this.itemsByGroup,
    required this.summaryByGroup,
  });

  final List<UpgradeTrackerItem> displayItems;
  final Map<UpgradeTrackerItem, String> normalizedNames;
  final UpgradeCategorySummary summary;
  final List<_UpgradeGroup> groups;
  final Map<_UpgradeGroup, List<UpgradeTrackerItem>> itemsByGroup;
  final Map<_UpgradeGroup, UpgradeCategorySummary> summaryByGroup;

  factory _UpgradeVillageIndex.build(
    UpgradeTrackerSnapshot snapshot,
    UpgradeVillage village,
  ) {
    final displayItems = snapshot.itemsFor(village: village);
    final completionItems = displayItems
        .where((item) => item.category != UpgradeCategory.builders)
        .toList(growable: false);
    final groups = _availableUpgradeGroups(snapshot, village);
    final itemsByGroup = <_UpgradeGroup, List<UpgradeTrackerItem>>{};
    final summaryByGroup = <_UpgradeGroup, UpgradeCategorySummary>{};
    for (final group in groups) {
      final items =
          displayItems
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
    return _UpgradeVillageIndex(
      displayItems: displayItems,
      normalizedNames: {
        for (final item in displayItems) item: item.name.toLowerCase(),
      },
      summary: snapshot.summaryForItems(completionItems),
      groups: groups,
      itemsByGroup: itemsByGroup,
      summaryByGroup: summaryByGroup,
    );
  }

  _UpgradeVillageViewData viewFor(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      final visibleGroups = groups
          .where((group) => itemsByGroup[group]!.isNotEmpty)
          .toList(growable: false);
      return _UpgradeVillageViewData(
        visibleItems: displayItems,
        summary: summary,
        groups: visibleGroups,
        itemsByGroup: itemsByGroup,
        summaryByGroup: summaryByGroup,
      );
    }
    final visible = displayItems
        .where((item) => normalizedNames[item]!.contains(normalizedQuery))
        .toList(growable: false);
    final visibleByGroup = <_UpgradeGroup, List<UpgradeTrackerItem>>{};
    final visibleGroups = <_UpgradeGroup>[];
    for (final group in groups) {
      final items = itemsByGroup[group]!
          .where((item) => normalizedNames[item]!.contains(normalizedQuery))
          .toList(growable: false);
      if (items.isEmpty) continue;
      visibleGroups.add(group);
      visibleByGroup[group] = items;
    }
    return _UpgradeVillageViewData(
      visibleItems: visible,
      summary: summary,
      groups: List.unmodifiable(visibleGroups),
      itemsByGroup: visibleByGroup,
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
  Widget build(BuildContext context) {
    final content = Stack(
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
              style: CKTypography.of(context, CKTextRole.compactLabel).copyWith(
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
    );
    final tile = clock == null
        ? _buildFrame(context, DateTime.now(), content)
        : ValueListenableBuilder<DateTime>(
            valueListenable: clock!,
            child: content,
            builder: (context, now, child) =>
                _buildFrame(context, now, child ?? const SizedBox.shrink()),
          );
    return Semantics(
      button: true,
      label:
          '${item.name}, level ${item.currentLevel} of ${item.targetLevel}${item.count > 1 ? ', ${item.count} buildings' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showUpgradeDetails(context, item),
        child: tile,
      ),
    );
  }

  Widget _buildFrame(BuildContext context, DateTime now, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    final active = snapshot.remainingActiveSeconds(item, now: now) > 0;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(CKRadius.tile),
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 2 : 1,
        ),
      ),
      child: child,
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

class _PlanTab extends StatefulWidget {
  const _PlanTab({required this.planData});

  final _TrackerPlanData planData;

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  _PlanVillageFilter _villageFilter = _PlanVillageFilter.all;
  _PlanQueueFilter _queueFilter = _PlanQueueFilter.all;
  _PlanSort _planSort = _PlanSort.scheduled;
  late List<_PlannedUpgradeGroup> _groups;

  @override
  void initState() {
    super.initState();
    _rebuildGroups();
  }

  @override
  void didUpdateWidget(covariant _PlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.planData, widget.planData)) _rebuildGroups();
  }

  void _updateFilters(VoidCallback change) {
    setState(() {
      change();
      _rebuildGroups();
    });
  }

  void _rebuildGroups() {
    final filtered =
        widget.planData.allLanes
            .expand((lane) => lane.upgrades)
            .where(
              (upgrade) =>
                  _matchesPlanFilters(upgrade, _villageFilter, _queueFilter),
            )
            .toList()
          ..sort((a, b) {
            final comparison = switch (_planSort) {
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
            return comparison != 0 ? comparison : a.endsAt.compareTo(b.endsAt);
          });
    _groups = _groupPlannedUpgrades(filtered);
  }

  @override
  Widget build(BuildContext context) {
    if (_isTrackerDesktop(context)) {
      return _buildDesktop(context);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          sliver: SliverToBoxAdapter(
            child: _LootOutlookCard(
              lanes: widget.planData.allLanes,
              startsAt: widget.planData.startsAt,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(child: _buildMobileFilters()),
        ),
        if (_groups.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _TrackerEmptyState(
              icon: Icons.task_alt_rounded,
              title: 'No matching upgrades',
              body: 'Try another village or queue.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.separated(
              itemCount: _groups.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _PlannedUpgradeRow(group: _groups[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _trackerDesktopMaxWidth,
                ),
                child: Column(
                  children: [
                    _LootOutlookCard(
                      lanes: widget.planData.allLanes,
                      startsAt: widget.planData.startsAt,
                    ),
                    const SizedBox(height: CKSpacing.md),
                    _buildDesktopFilters(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_groups.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _TrackerEmptyState(
              icon: Icons.task_alt_rounded,
              title: 'No matching upgrades',
              body: 'Try another village or queue.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _trackerDesktopMaxWidth,
                  ),
                  child: _DesktopUpgradeGroupGrid(
                    children: [
                      for (final group in _groups)
                        _PlannedUpgradeCard(group: group),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _PlanVillageFilter.values
                .map(
                  (value) => _FilterChip(
                    label: _planVillageFilterLabel(value),
                    selected: _villageFilter == value,
                    onTap: () => _updateFilters(() => _villageFilter = value),
                  ),
                )
                .toList(growable: false),
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
                    selected: _queueFilter == value,
                    onTap: () => _updateFilters(() => _queueFilter = value),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerRight, child: _buildSortDropdown()),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return CKSectionPanel(
      padding: const EdgeInsets.all(CKSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: CKSpacing.xs,
                  runSpacing: CKSpacing.xs,
                  children: _PlanVillageFilter.values
                      .map(
                        (value) => _FilterChip(
                          label: _planVillageFilterLabel(value),
                          selected: _villageFilter == value,
                          onTap: () =>
                              _updateFilters(() => _villageFilter = value),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: CKSpacing.sm),
                Wrap(
                  spacing: CKSpacing.xs,
                  runSpacing: CKSpacing.xs,
                  children: _PlanQueueFilter.values
                      .map(
                        (value) => _FilterChip(
                          label: _planQueueFilterLabel(value),
                          selected: _queueFilter == value,
                          onTap: () =>
                              _updateFilters(() => _queueFilter = value),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(width: CKSpacing.md),
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return FilterDropdown(
      sortBy: _planSort.name,
      maxWidth: 160,
      sortByOptions: {
        for (final value in _PlanSort.values) _planSortLabel(value): value.name,
      },
      updateSortBy: (value) =>
          _updateFilters(() => _planSort = _PlanSort.values.byName(value)),
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

class _TrackerPlanData {
  const _TrackerPlanData({
    required this.startsAt,
    required this.allLanes,
    required this.calendarGroups,
  });

  final DateTime startsAt;
  final List<UpgradePlanLane> allLanes;
  final List<_PlanTimelineGroup> calendarGroups;
}

_TrackerPlanData _buildTrackerPlanData(
  UpgradeTrackerSnapshot snapshot, {
  required int goldPassPercent,
  required UpgradePlanPreferences preferences,
}) {
  final startsAt = DateTime.now();
  final calendarGroups = _PlanCalendarGroup.values
      .map((group) {
        final lanes = _buildPlannerLanes(
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
        return _PlanTimelineGroup(type: group, lanes: lanes);
      })
      .toList(growable: false);
  final walls = _buildWallPlan(
    snapshot,
    preferences,
    goldPassPercent: goldPassPercent,
    startsAt: startsAt,
  );
  return _TrackerPlanData(
    startsAt: startsAt,
    allLanes: List.unmodifiable([
      ...calendarGroups.expand((group) => group.lanes),
      if (walls.isNotEmpty) UpgradePlanLane(index: 0, upgrades: walls),
    ]),
    calendarGroups: List.unmodifiable(calendarGroups),
  );
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

class _PlanCalendarTab extends StatelessWidget {
  const _PlanCalendarTab({required this.snapshot, required this.planData});

  final UpgradeTrackerSnapshot snapshot;
  final _TrackerPlanData planData;

  @override
  Widget build(BuildContext context) => _PlanTimeline(
    snapshot: snapshot,
    startsAt: planData.startsAt,
    groups: planData.calendarGroups,
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

  static const _horizonDays = 60;
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
                      'plan-calendar-horizontal-${startsAt.microsecondsSinceEpoch}',
                    ),
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    dragStartBehavior: DragStartBehavior.down,
                    child: SizedBox(
                      width: contentWidth,
                      height: constraints.maxHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ColoredBox(
                            color: scheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: _PlanTimelineHeader(
                                firstDay: firstDay,
                                days: _horizonDays,
                                labelWidth: _labelWidth,
                                dayWidth: _dayWidth,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: CustomScrollView(
                              key: ValueKey(
                                'plan-calendar-vertical-${startsAt.microsecondsSinceEpoch}',
                              ),
                              // Share the NestedScrollView's vertical
                              // controller so pulling down at the top restores
                              // the collapsed scenic header.
                              primary: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    28,
                                  ),
                                  sliver: SliverList.builder(
                                    itemCount: groups.length,
                                    itemBuilder: (context, index) =>
                                        _PlanTimelineSection(
                                          snapshot: snapshot,
                                          group: groups[index],
                                          firstDay: startsAt,
                                          days: _horizonDays,
                                          labelWidth: _labelWidth,
                                          dayWidth: _dayWidth,
                                          laneHeight: _laneHeight,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE\nMMM d');
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    return Row(
      children: [
        SizedBox(width: labelWidth),
        ...List.generate(
          days,
          (index) => SizedBox(
            width: dayWidth,
            child: Text(
              formatter.format(firstDay.add(Duration(days: index))),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ),
      ],
    );
  }
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

class _PlanTimelineSectionState extends State<_PlanTimelineSection>
    with AutomaticKeepAliveClientMixin {
  bool _expanded = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
    final horizonEnd = firstDay.add(Duration(days: days));
    final visibleUpgrades = upgrades
        .where(
          (upgrade) =>
              upgrade.endsAt.isAfter(firstDay) &&
              upgrade.startsAt.isBefore(horizonEnd),
        )
        .toList(growable: false);
    final scheme = Theme.of(context).colorScheme;
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
                    child: CustomPaint(
                      painter: _PlanTimelineGridPainter(
                        days: days,
                        dayWidth: dayWidth,
                        alternateColor: scheme.surface.withValues(alpha: 0.18),
                        lineColor: scheme.outlineVariant.withValues(
                          alpha: 0.28,
                        ),
                      ),
                    ),
                  ),
                  ...visibleUpgrades.map(
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

class _PlanTimelineGridPainter extends CustomPainter {
  const _PlanTimelineGridPainter({
    required this.days,
    required this.dayWidth,
    required this.alternateColor,
    required this.lineColor,
  });

  final int days;
  final double dayWidth;
  final Color alternateColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final alternatePaint = Paint()
      ..color = alternateColor
      ..isAntiAlias = false;
    final linePaint = Paint()
      ..color = lineColor
      ..isAntiAlias = false;
    for (var index = 0; index < days; index++) {
      final left = index * dayWidth;
      if (index.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(left, 0, dayWidth, size.height),
          alternatePaint,
        );
      }
      canvas.drawRect(Rect.fromLTWH(left, 0, 1, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanTimelineGridPainter oldDelegate) =>
      oldDelegate.days != days ||
      oldDelegate.dayWidth != dayWidth ||
      oldDelegate.alternateColor != alternateColor ||
      oldDelegate.lineColor != lineColor;
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

class _PlannedUpgradeCard extends StatelessWidget {
  const _PlannedUpgradeCard({required this.group});

  final _PlannedUpgradeGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final upgrade = group.first;
    final item = upgrade.item;
    final duration = _duration(
      group.endsAt.difference(group.startsAt).inSeconds,
    );

    return InkWell(
      onTap: () => showUpgradeDetails(context, item),
      borderRadius: BorderRadius.circular(CKRadius.card),
      child: Container(
        padding: const EdgeInsets.all(CKSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(CKRadius.card),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            _AspectSafeImage(imageUrl: item.imageUrl, width: 56, height: 48),
            const SizedBox(width: CKSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name}${group.count > 1 ? ' ×${group.count}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CKTypography.of(context, CKTextRole.rowTitle),
                        ),
                      ),
                      const SizedBox(width: CKSpacing.sm),
                      _Pill(text: duration),
                    ],
                  ),
                  const SizedBox(height: CKSpacing.xs),
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
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (group.costs.isNotEmpty) ...[
                    const SizedBox(height: CKSpacing.xs),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: group.costs
                          .map(
                            (cost) => _ResourcePill(cost: cost, compact: true),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

bool _matchesUpgradeGroupFilter(_UpgradeGroup group, String filter) =>
    switch (filter) {
      'buildings' => const {
        _UpgradeGroup.buildings,
        _UpgradeGroup.defenses,
        _UpgradeGroup.craftedDefenses,
        _UpgradeGroup.traps,
        _UpgradeGroup.supercharges,
        _UpgradeGroup.walls,
      }.contains(group),
      'heroes' => const {
        _UpgradeGroup.heroes,
        _UpgradeGroup.guardians,
        _UpgradeGroup.equipment,
        _UpgradeGroup.pets,
      }.contains(group),
      'research' => group == _UpgradeGroup.laboratory,
      'other' => group == _UpgradeGroup.helpers,
      _ => true,
    };

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
  final _expanded = <UpgradeCollectionType>{};
  final _searchController = TextEditingController();
  _CollectionFilter _filter = _CollectionFilter.all;
  _CollectionSort _sort = _CollectionSort.nameAscending;
  UpgradeVillage? _village;
  String _query = '';
  bool _showFilters = false;
  late bool _supportsVillage;
  late Map<UpgradeCollectionType, List<UpgradeCollectionItem>> _itemsByType;
  late Map<UpgradeCollectionItem, String> _normalizedNames;
  late Map<
    UpgradeCollectionType,
    Map<_CollectionSort, List<UpgradeCollectionItem>>
  >
  _sortedItemsByType;
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
    _normalizedNames = {
      for (final item in widget.snapshot.collections)
        item: item.name.toLowerCase(),
    };
    _sortedItemsByType = {
      for (final type in UpgradeCollectionType.values)
        type: {
          for (final sort in _CollectionSort.values)
            sort: List.unmodifiable(
              [..._itemsByType[type]!]
                ..sort((a, b) => _compareCollectionItems(a, b, sort)),
            ),
        },
    };
  }

  int _compareCollectionItems(
    UpgradeCollectionItem a,
    UpgradeCollectionItem b,
    _CollectionSort sort,
  ) => switch (sort) {
    _CollectionSort.nameAscending => _normalizedNames[a]!.compareTo(
      _normalizedNames[b]!,
    ),
    _CollectionSort.nameDescending => _normalizedNames[b]!.compareTo(
      _normalizedNames[a]!,
    ),
    _CollectionSort.newest => b.id.compareTo(a.id),
    _CollectionSort.oldest => a.id.compareTo(b.id),
  };

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
      final visible = _sortedItemsByType[type]![_sort]!.where((item) {
        if (_village != null &&
            type != UpgradeCollectionType.capitalHouseParts &&
            item.village != _village) {
          return false;
        }
        if (_filter == _CollectionFilter.owned && !item.owned) return false;
        if (_filter == _CollectionFilter.missing && item.owned) return false;
        return normalized.isEmpty ||
            _normalizedNames[item]!.contains(normalized);
      }).toList();
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
    if (_isTrackerDesktop(context)) {
      return _buildDesktop(context, l10n);
    }

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

  Widget _buildDesktop(BuildContext context, AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _trackerDesktopMaxWidth,
                ),
                child: _buildFilterPanel(l10n),
              ),
            ),
          ),
        ),
        if (_sections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _TrackerEmptyState(
              icon: Icons.collections_bookmark_rounded,
              title: l10n.upgradeTrackerNoMatchingItems,
              body: l10n.upgradeTrackerSearchCollection,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _trackerDesktopMaxWidth,
                  ),
                  child: _DesktopUpgradeGroupGrid(
                    children: [
                      for (final section in _sections)
                        _buildDesktopSection(context, l10n, section),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterPanel(AppLocalizations l10n) {
    return CKSectionPanel(
      padding: const EdgeInsets.all(CKSpacing.md),
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
                onPressed: () => setState(() => _showFilters = !_showFilters),
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
                          onChanged: (value) => _update(() => _filter = value),
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
                              maxWidth: 140,
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
    );
  }

  Widget _buildDesktopSection(
    BuildContext context,
    AppLocalizations l10n,
    _CollectionSectionViewData section,
  ) {
    final expanded = _expanded.contains(section.type);
    final title = _collectionLabel(section.type);
    return _TrackerCollapsibleCard(
      title: title,
      imageUrl: section.preview.imageUrl,
      completion: section.owned / section.scoped.length,
      countLabel: l10n.upgradeTrackerOwnedCount(
        section.owned,
        section.scoped.length,
      ),
      expanded: expanded,
      onToggle: () => setState(() {
        expanded ? _expanded.remove(section.type) : _expanded.add(section.type);
      }),
      onSummaryTap: () =>
          _showCollectionSectionSummary(context, title, items: section.scoped),
      margin: EdgeInsets.zero,
      surfaceWhenExpanded: true,
      child: _CollectionTileGrid(
        section: section,
        emptyLabel: l10n.upgradeTrackerNoMatchingItems,
      ),
    );
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

class _CollectionTileGrid extends StatelessWidget {
  const _CollectionTileGrid({required this.section, required this.emptyLabel});

  final _CollectionSectionViewData section;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (section.visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(CKSpacing.lg),
        child: Center(child: Text(emptyLabel, textAlign: TextAlign.center)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isScenery = section.type == UpgradeCollectionType.sceneries;
        final columns = isScenery
            ? math.max(2, math.min(4, (constraints.maxWidth / 220).floor()))
            : math.max(3, math.min(6, (constraints.maxWidth / 116).floor()));
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            childAspectRatio: isScenery ? 1.18 : 0.88,
          ),
          itemCount: section.visible.length,
          itemBuilder: (context, index) =>
              _CollectionTile(item: section.visible[index]),
        );
      },
    );
  }
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
        : RepaintBoundary(
            child: ColorFiltered(
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
            ),
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
    final media = stickerUrl != null
        ? MobileWebImage(
            imageUrl: stickerUrl!,
            width: 132,
            height: 116,
            fit: BoxFit.contain,
          )
        : Icon(icon, size: 52, color: scheme.onSurfaceVariant);

    Widget details({required bool centered}) => Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: CKTypography.of(context, CKTextRole.sectionTitle),
        ),
        const SizedBox(height: CKSpacing.sm),
        Text(
          body,
          textAlign: centered ? TextAlign.center : TextAlign.start,
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
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
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
            width: centered ? double.infinity : 260,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.content_paste_rounded),
              label: Text(actionLabel!),
            ),
          ),
        ],
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          const SizedBox(height: CKSpacing.sm),
          SizedBox(
            width: centered ? double.infinity : 260,
            child: TextButton.icon(
              onPressed: onSecondaryAction,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(secondaryActionLabel!),
            ),
          ),
        ],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CKSpacing.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useWideState =
                _isTrackerDesktop(context) && constraints.maxWidth >= 720;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: useWideState ? 760 : 440),
              child: CKSectionPanel(
                padding: const EdgeInsets.all(CKSpacing.xl),
                child: useWideState
                    ? Row(
                        children: [
                          SizedBox(width: 170, child: Center(child: media)),
                          const SizedBox(width: CKSpacing.xl),
                          Expanded(child: details(centered: false)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          media,
                          const SizedBox(height: CKSpacing.lg),
                          details(centered: true),
                        ],
                      ),
              ),
            );
          },
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
      backgroundColor:
          Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CKRadius.panel),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: CKOpacity.border),
        ),
      ),
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
                      if (index > 0) const Divider(height: CKSpacing.lg),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CKSpacing.xs,
        vertical: CKSpacing.sm,
      ),
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
  final minimumLevel = _minimumDetailLevel(item);
  var selectedLevel = item.currentLevel.clamp(minimumLevel, item.targetLevel);
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
        final hasWeightMetrics =
            _supportsWeightMetrics(item.category) &&
            (item.wardenWeight != null || item.healerWeight != null);
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
                              min: minimumLevel.toDouble(),
                              max: item.targetLevel.toDouble(),
                              divisions: item.targetLevel > minimumLevel
                                  ? item.targetLevel - minimumLevel
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
                          if (_showsWardenThreshold(item.category) &&
                              meta?['housing_space'] != null)
                            Builder(
                              builder: (context) => _TrackerDetailStatRow(
                                key: const ValueKey('housing-space'),
                                icon: Icons.home_outlined,
                                label: AppLocalizations.of(
                                  context,
                                )!.gameItemHousingSpace,
                                value: meta!['housing_space'].toString(),
                                accent: accent,
                              ),
                            ),
                          if (hasWeightMetrics)
                            ..._weightMetricRows(item, accent),
                          if (selectedStats != null)
                            ..._trackerStatRows(
                              meta,
                              selectedStats,
                              nextStats,
                              item.category,
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

int _minimumDetailLevel(UpgradeTrackerItem item) {
  final levels = item.meta?['levels'];
  if (levels is! List) return 1;
  final available = levels
      .whereType<Map>()
      .map((level) => level['level'])
      .map((level) => level is num ? level.toInt() : int.tryParse('$level'))
      .whereType<int>()
      .where((level) => level > 0)
      .toList(growable: false);
  if (available.isEmpty) return 1;
  return available.reduce((lowest, level) => level < lowest ? level : lowest);
}

int? wardenFollowThresholdCopies(num weight) =>
    weight > 0 ? (20 / weight).ceil() : null;

bool _supportsWeightMetrics(UpgradeCategory category) => const {
  UpgradeCategory.troops,
  UpgradeCategory.darkTroops,
  UpgradeCategory.heroes,
  UpgradeCategory.pets,
}.contains(category);

bool _showsWardenThreshold(UpgradeCategory category) => const {
  UpgradeCategory.troops,
  UpgradeCategory.darkTroops,
}.contains(category);

String _weightValue(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toString();

List<Widget> _weightMetricRows(UpgradeTrackerItem item, Color accent) => [
  if (item.wardenWeight case final weight?)
    Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return _TrackerDetailStatRow(
          key: const ValueKey('warden-weight'),
          imageUrl: ImageAssets.getHeroImage('Grand Warden'),
          label: l10n.gameItemWardenWeight,
          value: _weightValue(weight),
          tooltip: l10n.gameItemWardenWeightTooltip,
          detail: _showsWardenThreshold(item.category)
              ? weight > 0
                    ? l10n.gameItemWardenThresholdCopies(
                        wardenFollowThresholdCopies(weight)!,
                      )
                    : l10n.gameItemWardenNoThresholdContribution
              : null,
          accent: accent,
        );
      },
    ),
  if (item.healerWeight case final weight?)
    Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return _TrackerDetailStatRow(
          key: const ValueKey('healer-weight'),
          imageUrl: ImageAssets.getTroopImage('Healer'),
          label: l10n.gameItemHealerWeight,
          value: _weightValue(weight),
          tooltip: l10n.gameItemHealerWeightTooltip,
          accent: accent,
        );
      },
    ),
];

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

final Expando<Map<int, List<String>>> _upgradeImageFallbackCache = Expando();

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
  final byLevel = _upgradeImageFallbackCache[item] ??= {};
  return byLevel.putIfAbsent(
    current,
    () => List.unmodifiable([
      for (var level = current - 1; level >= 1; level--)
        item.village == UpgradeVillage.home
            ? ImageAssets.getHomeVillageBuildingImage(item.name, level)
            : ImageAssets.getBuilderBaseBuildingImage(item.name, level),
    ]),
  );
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
  final usesBuildFields = _usesBuildLevelFields(item.meta);
  for (var target = selectedLevel + 1; target <= item.targetLevel; target++) {
    final existing = item.steps
        .where((step) => step.targetLevel == target)
        .firstOrNull;
    if (existing != null) {
      steps.add(existing);
      continue;
    }
    final sourceLevel = usesBuildFields ? target : target - 1;
    final level = findLevelStats(item.meta, sourceLevel);
    if (level == null) continue;
    final costs = <UpgradeCost>[];
    final rawCost = level[usesBuildFields ? 'build_cost' : 'upgrade_cost'];
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
            (level[usesBuildFields ? 'build_time' : 'upgrade_time'] as num?)
                ?.round() ??
            0,
        costs: costs,
      ),
    );
  }
  return steps;
}

bool _usesBuildLevelFields(Map<String, dynamic>? meta) {
  final levels = meta?['levels'];
  if (levels is! List) return false;
  return levels.whereType<Map>().any(
    (level) =>
        level.containsKey('build_cost') || level.containsKey('build_time'),
  );
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
  UpgradeCategory category,
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
    _attackRangeTiles(level['attack_range'] ?? meta?['attack_range'], category),
    _attackRangeTiles(
      nextLevel?['attack_range'] ?? meta?['attack_range'],
      category,
    ),
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

String? _attackRangeTiles(Object? value, UpgradeCategory category) {
  final raw = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (raw == null) return null;
  final divisor =
      const {
        UpgradeCategory.troops,
        UpgradeCategory.darkTroops,
        UpgradeCategory.heroes,
        UpgradeCategory.pets,
        UpgradeCategory.sieges,
      }.contains(category)
      ? 100
      : 1000;
  return (raw / divisor)
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class _TrackerDetailStatRow extends StatelessWidget {
  const _TrackerDetailStatRow({
    super.key,
    this.icon,
    this.imageUrl,
    required this.label,
    required this.value,
    required this.accent,
    this.tooltip,
    this.detail,
  });

  final IconData? icon;
  final String? imageUrl;
  final String label;
  final String value;
  final Color accent;
  final String? tooltip;
  final String? detail;

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
            child: imageUrl != null
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: MobileWebImage(imageUrl: imageUrl!),
                  )
                : Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (tooltip != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: tooltip!,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
              ],
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
