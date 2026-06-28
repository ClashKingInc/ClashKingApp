import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_events.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_stats.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClanActivityTab extends StatefulWidget {
  final Clan clanInfo;

  const ClanActivityTab({super.key, required this.clanInfo});

  @override
  State<ClanActivityTab> createState() => _ClanActivityTabState();
}

class _ClanActivityTabState extends State<ClanActivityTab> {
  bool _showEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Prefer pre-loaded data from the main flow; otherwise fetch on demand.
      final svc = context.read<ClanService>();
      if ((widget.clanInfo.joinLeave?.joinLeaveList.isEmpty ?? true) &&
          svc.getSingleClanJoinLeave(widget.clanInfo.tag) == null) {
        svc.fetchSingleClanJoinLeave(widget.clanInfo.tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final svc = context.watch<ClanService>();

    // Prefer the pre-loaded data from clan.joinLeave (main dashboard flow).
    // Fall back to on-demand fetched data (search / direct open).
    final jl = (widget.clanInfo.joinLeave?.joinLeaveList.isNotEmpty ?? false)
        ? widget.clanInfo.joinLeave
        : svc.getSingleClanJoinLeave(widget.clanInfo.tag);

    if (jl == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(loc.generalStats)),
              ButtonSegment(value: true, label: Text(loc.warEventsTitle)),
            ],
            selected: {_showEvents},
            onSelectionChanged: (s) => setState(() => _showEvents = s.first),
          ),
        ),
        if (_showEvents)
          ClanJoinLeaveEvents(joinLeaveClan: jl)
        else
          ClanJoinLeaveStats(joinLeaveClan: jl),
      ],
    );
  }
}
