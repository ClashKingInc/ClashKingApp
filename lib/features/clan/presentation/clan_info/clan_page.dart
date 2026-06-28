import 'package:clashkingapp/common/widgets/navigation/scrollable_tab.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_activity_tab.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_composition_tab.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_top_performers_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClanInfoScreen extends StatefulWidget {
  final Clan clanInfo;

  const ClanInfoScreen({super.key, required this.clanInfo});

  @override
  State<ClanInfoScreen> createState() => _ClanInfoScreenState();
}

class _ClanInfoScreenState extends State<ClanInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClanService>().fetchClanRanking(widget.clanInfo.tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ranking = context
        .watch<ClanService>()
        .getClanRanking(widget.clanInfo.tag);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: ClanInfoHeaderCard(clanInfo: widget.clanInfo, ranking: ranking),
            ),
            const SizedBox(height: 8),
            ScrollableTab(
              scrollable: true,
              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              tabs: const [
                Tab(text: 'Members'),
                Tab(text: 'Composition'),
                Tab(text: 'Top Players'),
                Tab(text: 'Activity'),
              ],
              children: [
                ClanMembers(clanInfo: widget.clanInfo),
                ClanCompositionTab(clanTag: widget.clanInfo.tag),
                ClanTopPerformersTab(clanInfo: widget.clanInfo),
                ClanActivityTab(clanInfo: widget.clanInfo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
