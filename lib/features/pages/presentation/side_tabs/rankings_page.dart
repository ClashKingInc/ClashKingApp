part of '../side_tabs_pages.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  final ApiService _apiService = ApiService.shared;
  _OfficialRankingType _type = _OfficialRankingType.playerTrophies;
  _LocationOption _location = _locations.first;
  int _townHall = 0;
  late Future<List<_RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_RankingEntry>> _load() async {
    final response = await _apiService.proxyGet(
      '/locations/${_location.id}/rankings/${_type.path}?limit=200',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load rankings (${response.statusCode})');
    }

    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) return [];
    final entries = items
        .whereType<Map<String, dynamic>>()
        .map((item) => _RankingEntry.fromJson(item, _type))
        .toList();
    if (!_type.supportsTownHallFilter || _townHall == 0) {
      return entries;
    }
    return entries.where((entry) => entry.townHallLevel == _townHall).toList();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return _SidePageScaffold(
      title: 'Rankings',
      subtitle: 'Official leaderboards plus ClashKing endpoints.',
      child: ListView(
        padding: _pagePadding,
        children: [
          _RankingTitle(type: _type),
          const SizedBox(height: 14),
          _RankingControlRow(
            location: _location,
            townHall: _townHall,
            townHallEnabled: _type.supportsTownHallFilter,
            onLocationChanged: (value) {
              setState(() => _location = value);
              _reload();
            },
            onTownHallChanged: (value) {
              setState(() => _townHall = value);
              _reload();
            },
          ),
          const SizedBox(height: 16),
          _HorizontalSelector<_OfficialRankingType>(
            values: _OfficialRankingType.values,
            selected: _type,
            labelBuilder: (type) => type.label,
            onSelected: (value) {
              setState(() {
                _type = value;
                if (!value.supportsTownHallFilter) {
                  _townHall = 0;
                }
              });
              _reload();
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<_RankingEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingRows();
              }
              if (snapshot.hasError) {
                return _ErrorPanel(
                  message: 'Could not load official rankings.',
                  detail: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return const _EmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'No rankings returned',
                  body: 'Try another leaderboard or location.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeaderboardMeta(
                    count: entries.length,
                    type: _type,
                    location: _location,
                    townHall: _townHall,
                    onRefresh: _reload,
                  ),
                  const SizedBox(height: 14),
                  ...entries
                      .take(200)
                      .map((entry) => _RankingRow(entry: entry)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'ClashKing mockups'),
          const _EndpointMockupSummary(),
          const SizedBox(height: 8),
          ..._clashKingLeaderboardOptions.map(
            (option) => _EndpointPreview(option: option),
          ),
        ],
      ),
    );
  }
}
