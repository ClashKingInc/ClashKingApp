import 'dart:io';
import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:intl/intl.dart';

/// Service for exporting player war statistics using the ClashKing API
class PlayerWarExportService {
  /// Export player war statistics to Excel format via API
  static Future<File> exportWarStats({
    required String playerTag,
    WarStatsFilter? filter,
    String? playerName,
  }) async {
    // Build API URL for new export endpoint
    final baseUrl = ApiService.apiUrlV2;
    final uri = Uri.parse('$baseUrl/exports/war/player-stats');
    
    // Build request body as PlayerWarhitsFilter
    final requestBody = <String, dynamic>{
      'player_tags': [playerTag],
    };
    
    // Add filter parameters if present
    if (filter != null && filter.hasActiveFilters()) {
      if (filter.season != null) {
        requestBody['season'] = filter.season!;
      }
      if (filter.startDate != null) {
        requestBody['timestamp_start'] = filter.startDate!.millisecondsSinceEpoch ~/ 1000;
      }
      if (filter.endDate != null) {
        requestBody['timestamp_end'] = filter.endDate!.millisecondsSinceEpoch ~/ 1000;
      }
      if (filter.warTypes != null && filter.warTypes!.isNotEmpty && !filter.warTypes!.contains('all')) {
        requestBody['type'] = filter.warTypes!;
      }
      if (filter.ownTownHalls != null && filter.ownTownHalls!.isNotEmpty) {
        requestBody['own_th'] = filter.ownTownHalls!;
      }
      if (filter.enemyTownHalls != null && filter.enemyTownHalls!.isNotEmpty) {
        requestBody['enemy_th'] = filter.enemyTownHalls!;
      }
      if (filter.allowedStars != null && filter.allowedStars!.isNotEmpty) {
        requestBody['stars'] = filter.allowedStars!;
      }
      if (filter.minDestruction != null) {
        requestBody['min_destruction'] = filter.minDestruction!;
      }
      if (filter.maxDestruction != null) {
        requestBody['max_destruction'] = filter.maxDestruction!;
      }
      if (filter.minMapPosition != null) {
        requestBody['map_position_min'] = filter.minMapPosition!;
      }
      if (filter.maxMapPosition != null) {
        requestBody['map_position_max'] = filter.maxMapPosition!;
      }
      if (filter.freshAttacksOnly == true) {
        requestBody['fresh_only'] = true;
      }
    }
    
    // Make POST API request with JSON body
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to export war stats: ${response.statusCode} ${response.reasonPhrase}');
    }
    
    // Check if response is actually an Excel file
    final contentType = response.headers['content-type'] ?? '';
    
    if (!contentType.contains('spreadsheet') && !contentType.contains('excel') && !contentType.contains('application/octet-stream')) {
      throw Exception('Expected Excel file but got: $contentType');
    }
    
    // Save file to device
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName(playerName);
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(response.bodyBytes);
    
    return file;
  }
  
  /// Generate a timestamped filename for the export
  static String _generateFileName(String? playerName) {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final playerPart = playerName != null ? '_${playerName.replaceAll(RegExp(r'[^\w\s-]'), '')}' : '';
    return 'war_stats${playerPart}_$timestamp.xlsx';
  }
  
  /// Get export summary for user display
  static Map<String, String> getExportInfo({
    WarStatsFilter? filter,
    required String playerTag,
  }) {
    final info = <String, String>{
      'player': playerTag,
      'format': 'Excel (.xlsx)',
      'includes': 'Overall stats, detailed attacks, TH analysis',
    };
    
    if (filter != null && filter.hasActiveFilters()) {
      info['filters'] = filter.getFilterSummary();
    } else {
      info['filters'] = 'All data';
    }
    
    return info;
  }
}