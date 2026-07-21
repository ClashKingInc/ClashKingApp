import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'rankings_page.dart';
import 'side_page_components.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final ApiService _apiService = ApiService();
  OfficialRankingType _type = OfficialRankingType.playerTrophies;
  LocationOption _location = rankingLocations.first;
  late Future<List<RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RankingEntry>> _load() async {
    final response = await _apiService.proxyGet(
      '/locations/${_location.apiPath}/rankings/${_type.path}?limit=200',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load official stats (${response.statusCode})');
    }
    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => RankingEntry.fromJson(item, _type))
        .toList();
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SidePageScaffold(
      title: loc.sideStatsTitle,
      subtitle: loc.sideStatsSubtitle,
      child: ListView(
        padding: sidePagePadding,
        children: [
          SidePageHorizontalSelector<OfficialRankingType>(
            values: OfficialRankingType.values,
            selected: _type,
            labelBuilder: (type) => type.labelOf(loc),
            onSelected: (value) {
              setState(() => _type = value);
              _reload();
            },
          ),
          const SizedBox(height: 10),
          SidePageHorizontalSelector<LocationOption>(
            values: rankingLocations,
            selected: _location,
            labelBuilder: (location) => location.name,
            onSelected: (value) {
              setState(() => _location = value);
              _reload();
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<RankingEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SidePageLoadingRows();
              }
              if (snapshot.hasError) {
                return SidePageErrorPanel(
                  message: loc.sideStatsLoadError,
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
                        child: SidePageMetricPanel(
                          label: loc.sideTopScore,
                          value: formatSidePageInt(topScore),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SidePageMetricPanel(
                          label: loc.sideTop200Avg,
                          value: formatSidePageInt(average.round()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...entries.take(25).map((entry) => RankingRow(entry: entry)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
