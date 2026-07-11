part of '../side_tabs_pages.dart';

class BasesArmiesPage extends StatelessWidget {
  const BasesArmiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SidePageScaffold(
      title: 'Bases & Armies',
      subtitle: 'Discord-saved layouts and army links.',
      child: ListView(
        padding: _pagePadding,
        children: const [
          _TeasePanel(
            icon: Icons.grid_view_rounded,
            title: 'Bot sync target',
            body:
                'The bot already saves bases and armies to the Discord profile. '
                'This page is ready for that synced payload.',
          ),
          SizedBox(height: 18),
          _SectionHeader(title: 'Saved bases'),
          _SavedLinkPlaceholder(
            title: 'War base slots',
            body: 'Town hall, base type, link, and last updated.',
          ),
          _SavedLinkPlaceholder(
            title: 'Legend base slots',
            body: 'Quick copy plus account association.',
          ),
          SizedBox(height: 18),
          _SectionHeader(title: 'Saved armies'),
          _SavedLinkPlaceholder(
            title: 'Army links',
            body: 'Composition, spells, siege, notes, and share link.',
          ),
        ],
      ),
    );
  }
}
