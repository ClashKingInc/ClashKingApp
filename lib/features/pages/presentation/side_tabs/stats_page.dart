part of '../side_tabs_pages.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final ApiService _apiService = ApiService.shared;
  _OfficialRankingType _type = _OfficialRankingType.playerTrophies;
  _LocationOption _location = _locations.first;
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
      throw Exception('Failed to load official stats (${response.statusCode})');
    }
    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => _RankingEntry.fromJson(item, _type))
        .toList();
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return _SidePageScaffold(
      title: 'Stats',
      subtitle: 'Leaderboard stats from official Clash API surfaces.',
      child: ListView(
        padding: _pagePadding,
        children: [
          _HorizontalSelector<_OfficialRankingType>(
            values: _OfficialRankingType.values,
            selected: _type,
            labelBuilder: (type) => type.label,
            onSelected: (value) {
              setState(() => _type = value);
              _reload();
            },
          ),
          const SizedBox(height: 10),
          _HorizontalSelector<_LocationOption>(
            values: _locations,
            selected: _location,
            labelBuilder: (location) => location.name,
            onSelected: (value) {
              setState(() => _location = value);
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
                  message: 'Could not load leaderboard stats.',
                  detail: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final entries = snapshot.data ?? [];
              final topScore = entries.isEmpty ? 0 : entries.first.score;
              final average = entries.isEmpty
                  ? 0
                  : entries
                            .map((entry) => entry.score)
                            .reduce((a, b) => a + b) /
                        entries.length;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPanel(
                          label: 'Top score',
                          value: _formatInt(topScore),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricPanel(
                          label: 'Top 200 avg',
                          value: _formatInt(average.round()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...entries.take(25).map((entry) => _RankingRow(entry: entry)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
