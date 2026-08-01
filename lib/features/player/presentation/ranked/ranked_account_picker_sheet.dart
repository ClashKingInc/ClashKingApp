import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RankedAccountPickerSheet extends StatefulWidget {
  const RankedAccountPickerSheet({
    super.key,
    required this.players,
    this.selectedTag,
  });

  final List<Player> players;
  final String? selectedTag;

  @override
  State<RankedAccountPickerSheet> createState() =>
      _RankedAccountPickerSheetState();
}

class _RankedAccountPickerSheetState extends State<RankedAccountPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final query = _query.trim().toLowerCase();
    final players = widget.players
        .where(
          (player) =>
              query.isEmpty ||
              player.name.toLowerCase().contains(query) ||
              player.tag.toLowerCase().contains(query),
        )
        .toList(growable: false);

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
                    loc.rankedLeagueTitle,
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
              hintText: loc.upgradeTrackerChooseAccount,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final selected =
                    _normalizeTag(player.tag) ==
                    _normalizeTag(widget.selectedTag ?? '');
                return ListTile(
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.onSurface,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CKRadius.control),
                  ),
                  leading: SizedBox.square(
                    dimension: 44,
                    child: MobileWebImage(
                      imageUrl: player.townHallPic,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.person_rounded),
                    ),
                  ),
                  title: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${player.tag} · ${loc.gameTownHallShortLevel(player.townHallLevel)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, player.tag),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _normalizeTag(String tag) =>
    tag.replaceAll('#', '').trim().toUpperCase();
