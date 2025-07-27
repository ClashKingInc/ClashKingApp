import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/features/player/models/filter_preset.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';

class FilterPresetService {
  static const String _presetsKey = 'war_stats_filter_presets';
  static FilterPresetService? _instance;
  
  FilterPresetService._internal();
  
  static FilterPresetService get instance {
    _instance ??= FilterPresetService._internal();
    return _instance!;
  }

  /// Save a new filter preset
  Future<bool> savePreset({
    required String name,
    required WarStatsFilter filter,
  }) async {
    try {
      final presets = await getPresets();
      final newPreset = FilterPreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        filter: filter,
        createdAt: DateTime.now(),
      );
      
      presets.add(newPreset);
      return await _savePresets(presets);
    } catch (e) {
      return false;
    }
  }

  /// Get all saved filter presets
  Future<List<FilterPreset>> getPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_presetsKey);
      
      if (presetsJson == null) return [];
      
      final List<dynamic> presetsList = json.decode(presetsJson);
      return presetsList
          .map((json) => FilterPreset.fromJson(json))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
    } catch (e) {
      return [];
    }
  }

  /// Update an existing preset
  Future<bool> updatePreset(FilterPreset preset) async {
    try {
      final presets = await getPresets();
      final index = presets.indexWhere((p) => p.id == preset.id);
      
      if (index == -1) return false;
      
      presets[index] = preset;
      return await _savePresets(presets);
    } catch (e) {
      return false;
    }
  }

  /// Delete a preset
  Future<bool> deletePreset(String presetId) async {
    try {
      final presets = await getPresets();
      presets.removeWhere((preset) => preset.id == presetId);
      return await _savePresets(presets);
    } catch (e) {
      return false;
    }
  }

  /// Check if a preset name already exists
  Future<bool> presetNameExists(String name, {String? excludeId}) async {
    final presets = await getPresets();
    return presets.any((preset) => 
        preset.name.toLowerCase() == name.toLowerCase() && 
        preset.id != excludeId);
  }

  /// Get preset by ID
  Future<FilterPreset?> getPreset(String id) async {
    final presets = await getPresets();
    try {
      return presets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all presets
  Future<bool> clearAllPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_presetsKey);
    } catch (e) {
      return false;
    }
  }

  /// Private method to save presets to SharedPreferences
  Future<bool> _savePresets(List<FilterPreset> presets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = json.encode(presets.map((p) => p.toJson()).toList());
      return await prefs.setString(_presetsKey, presetsJson);
    } catch (e) {
      return false;
    }
  }

  /// Get preset suggestions based on filter characteristics
  static List<String> getPresetNameSuggestions(
    WarStatsFilter filter, {
    Map<String, String> localizations = const {},
  }) {
    List<String> suggestions = [];
    
    // Based on war types
    if (filter.warTypes != null && filter.warTypes!.length == 1) {
      switch (filter.warTypes!.first.toLowerCase()) {
        case 'cwl':
          suggestions.add(localizations['presetSuggestionCwlOnly'] ?? 'CWL Only');
          break;
        case 'random':
          suggestions.add(localizations['presetSuggestionRandomWars'] ?? 'Random Wars');
          break;
        case 'friendly':
          suggestions.add(localizations['presetSuggestionFriendlyWars'] ?? 'Friendly Wars');
          break;
      }
    }
    
    // Based on stars
    if (filter.allowedStars != null) {
      if (filter.allowedStars!.length == 1) {
        final starCount = filter.allowedStars!.first;
        final template = localizations['presetSuggestionStarOnly'] ?? '{count} Star Only';
        suggestions.add(template.replaceAll('{count}', starCount.toString()));
      }
      if (filter.allowedStars!.contains(3) && filter.allowedStars!.length == 1) {
        suggestions.add(localizations['presetSuggestionPerfectAttacks'] ?? 'Perfect Attacks');
      }
      if (!filter.allowedStars!.contains(3)) {
        suggestions.add(localizations['presetSuggestionFailedAttacks'] ?? 'Failed Attacks');
      }
    }
    
    // Based on town hall
    if (filter.ownTownHalls != null && filter.ownTownHalls!.length == 1) {
      final thLevel = filter.ownTownHalls!.first;
      final template = localizations['presetSuggestionThOnly'] ?? 'TH{level} Only';
      suggestions.add(template.replaceAll('{level}', thLevel.toString()));
    }
    
    // Based on fresh attacks
    if (filter.freshAttacksOnly == true) {
      suggestions.add(localizations['filtersFreshAttacks'] ?? 'Fresh Attacks');
    }
    
    // Based on time range
    if (filter.startDate != null && filter.endDate != null) {
      final daysDiff = filter.endDate!.difference(filter.startDate!).inDays;
      if (daysDiff <= 7) {
        suggestions.add(localizations['presetSuggestionLastWeek'] ?? 'Last Week');
      } else if (daysDiff <= 30) {
        suggestions.add(localizations['presetSuggestionLastMonth'] ?? 'Last Month');
      }
    }
    
    // Default suggestions
    if (suggestions.isEmpty) {
      suggestions.addAll([
        localizations['presetSuggestionMyPreset'] ?? 'My Preset',
        localizations['presetSuggestionCustomFilter'] ?? 'Custom Filter',
        localizations['presetSuggestionRecentFilter'] ?? 'Recent Filter',
      ]);
    }
    
    return suggestions;
  }
}