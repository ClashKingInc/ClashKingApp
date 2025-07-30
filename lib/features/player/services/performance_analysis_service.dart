import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:clashkingapp/features/player/models/filter_preset.dart';

/// Service for analyzing war performance and suggesting filter presets
/// to help identify performance issues and improvement opportunities
class PerformanceAnalysisService {
  static const double _lowSuccessRateThreshold = 0.6; // 60%
  static const int _minSampleSize = 5; // Minimum wars needed for analysis
  
  /// Analyze war statistics and generate suggested filter presets
  /// Returns a list of preset suggestions that highlight performance issues
  static List<FilterPreset> analyzePerformance(PlayerWarStats warStats, {
    dynamic localizations,
  }) {
    final suggestions = <FilterPreset>[];
    final stats = warStats.getStatsForTypes([]);
    
    if (stats.warsCounts < _minSampleSize) {
      return suggestions; // Not enough data for meaningful analysis
    }
    
    // 1. Low success rate detection
    if (stats.averageStars < 2.0) {
      suggestions.add(_createPreset(
        'failed-attacks',
        localizations?.performanceAnalysisFailedAttacks ?? 'Failed Attacks (0-1 Stars)',
        localizations?.performanceAnalysisFailedAttacksDesc ?? 'Shows attacks that failed to get 2+ stars',
        WarStatsFilter(
          allowedStars: [0, 1],
        ),
      ));
    }
    
    // 2. Perfect attack opportunities
    final threeStarCount = stats.starsCount['3'] ?? 0;
    final perfectRate = stats.totalAttacks > 0 ? threeStarCount / stats.totalAttacks : 0.0;
    if (perfectRate < _lowSuccessRateThreshold) {
      suggestions.add(_createPreset(
        'missed-perfects',
        localizations?.performanceAnalysisMissedPerfects ?? 'Missed Perfect Attacks',
        localizations?.performanceAnalysisMissedPerfectsDesc ?? 'Shows attacks that got 2 stars - potential perfect opportunities',
        WarStatsFilter(
          allowedStars: [2],
        ),
      ));
    }
    
    // 3. Town Hall performance issues
    final thStats = stats.byEnemyTownhall;
    for (final entry in thStats.entries) {
      final thKey = entry.key;
      final thData = entry.value;
      
      // Parse TH level from key (format: "attacker_defender")
      final parts = thKey.split('_');
      if (parts.length >= 2) {
        final enemyTh = int.tryParse(parts[1]);
        if (enemyTh != null && thData.count >= 3 && thData.averageStars < 1.5) {
          suggestions.add(_createPreset(
            'th$enemyTh-struggles',
            localizations?.performanceAnalysisThAttackIssues(enemyTh) ?? 'TH$enemyTh Attack Issues',
            localizations?.performanceAnalysisThAttackIssuesDesc(enemyTh) ?? 'Shows poor performance against TH$enemyTh',
            WarStatsFilter(
              enemyTownHalls: [enemyTh],
            ),
          ));
        }
      }
    }
    
    // 4. Defense vulnerabilities
    final defStats = stats.byEnemyTownhallDef;
    for (final entry in defStats.entries) {
      final thKey = entry.key;
      final defData = entry.value;
      
      // Parse TH level from key (format: "attacker_defender")
      final parts = thKey.split('_');
      if (parts.length >= 2) {
        final attackerTh = int.tryParse(parts[0]);
        if (attackerTh != null && defData.count >= 3 && defData.averageStars > 2.0) {
          suggestions.add(_createPreset(
            'th$attackerTh-defense-weak',
            localizations?.performanceAnalysisThDefenseIssues(attackerTh) ?? 'TH$attackerTh Defense Issues',
            localizations?.performanceAnalysisThDefenseIssuesDesc(attackerTh) ?? 'Shows where you\'re vulnerable to TH$attackerTh attacks',
            WarStatsFilter(
              enemyTownHalls: [attackerTh],
            ),
          ));
        }
      }
    }
    
    // 5. War type specific issues
    final cwlStats = warStats.getStatsForTypes(['cwl']);
    final randomStats = warStats.getStatsForTypes(['random']);
    
    if (cwlStats.warsCounts >= 3 && randomStats.warsCounts >= 3) {
      final cwlSuccess = cwlStats.averageStars;
      final randomSuccess = randomStats.averageStars;
      
      // CWL performance issues
      if (cwlSuccess < randomSuccess - 0.5) {
        suggestions.add(_createPreset(
          'cwl-issues',
          localizations?.performanceAnalysisCwlIssues ?? 'CWL Performance Issues',
          localizations?.performanceAnalysisCwlIssuesDesc ?? 'Shows CWL attacks - lower success than regular wars',
          WarStatsFilter(
            warTypes: ['cwl'],
          ),
        ));
      }
      
      // Random war issues
      if (randomSuccess < cwlSuccess - 0.5) {
        suggestions.add(_createPreset(
          'random-war-issues',
          localizations?.performanceAnalysisRandomWarIssues ?? 'Random War Issues',
          localizations?.performanceAnalysisRandomWarIssuesDesc ?? 'Shows random war attacks - lower success than CWL',
          WarStatsFilter(
            warTypes: ['random'],
          ),
        ));
      }
    }
    
    // 6. Fresh attack performance
    suggestions.add(_createPreset(
      'fresh-only',
      localizations?.performanceAnalysisFreshOnly ?? 'Fresh Attack Analysis',
      localizations?.performanceAnalysisFreshOnlyDesc ?? 'Analyzes performance on fresh bases only',
      WarStatsFilter(
        freshAttacksOnly: true,
      ),
    ));
    
    // 7. Recent performance trends (last 30 days)
    final recentDate = DateTime.now().subtract(const Duration(days: 30));
    suggestions.add(_createPreset(
      'recent-performance',
      localizations?.performanceAnalysisRecentPerformance ?? 'Recent Performance (30 Days)',
      localizations?.performanceAnalysisRecentPerformanceDesc ?? 'Shows recent performance to identify current trends',
      WarStatsFilter(
        startDate: recentDate,
      ),
    ));
    
    // 8. High-stakes wars (position 1-5)
    suggestions.add(_createPreset(
      'high-stakes',
      localizations?.performanceAnalysisHighStakes ?? 'High-Stakes Attacks',
      localizations?.performanceAnalysisHighStakesDesc ?? 'Shows attacks from top 5 war positions',
      WarStatsFilter(
        maxMapPosition: 5,
      ),
    ));
    
    // 9. Cleanup crew performance (position 6+)
    suggestions.add(_createPreset(
      'cleanup-crew',
      localizations?.performanceAnalysisCleanupCrew ?? 'Cleanup Attacks',
      localizations?.performanceAnalysisCleanupCrewDesc ?? 'Shows attacks from lower war positions',
      WarStatsFilter(
        minMapPosition: 6,
      ),
    ));
    
    return suggestions.take(6).toList(); // Limit to top 6 suggestions
  }
  
  /// Create a filter preset with analytics metadata
  static FilterPreset _createPreset(
    String id,
    String name,
    String description,
    WarStatsFilter filter,
  ) {
    return FilterPreset(
      id: 'analysis_$id',
      name: name,
      filter: filter.copyWith(
        // Add metadata for analytics tracking
        metadata: {
          'type': 'performance_analysis',
          'description': description,
          'generated_at': DateTime.now().toIso8601String(),
        },
      ),
      createdAt: DateTime.now(),
    );
  }
  
  /// Get performance summary for display
  static Map<String, dynamic> getPerformanceSummary(PlayerWarStats warStats) {
    final stats = warStats.getStatsForTypes([]);
    
    return {
      'overall_rating': _calculateOverallRating(stats),
      'strength_areas': _getStrengthAreas(stats),
      'improvement_areas': _getImprovementAreas(stats),
      'key_metrics': {
        'average_stars': stats.averageStars,
        'three_star_rate': _calculateThreeStarRate(stats),
        'total_wars': stats.warsCounts,
        'destruction_average': stats.averageDestruction,
      },
    };
  }
  
  static double _calculateThreeStarRate(PlayerWarTypeStats stats) {
    final threeStarCount = stats.starsCount['3'] ?? 0;
    return stats.totalAttacks > 0 ? threeStarCount / stats.totalAttacks : 0.0;
  }
  
  static String _calculateOverallRating(PlayerWarTypeStats stats) {
    final threeStarRate = _calculateThreeStarRate(stats);
    if (stats.averageStars >= 2.5 && threeStarRate >= 0.7) {
      return 'performanceRatingExcellent';
    } else if (stats.averageStars >= 2.0 && threeStarRate >= 0.5) {
      return 'performanceRatingGood';
    } else if (stats.averageStars >= 1.5) {
      return 'performanceRatingAverage';
    } else {
      return 'performanceRatingNeedsImprovement';
    }
  }
  
  static List<String> _getStrengthAreas(PlayerWarTypeStats stats) {
    final strengths = <String>[];
    final threeStarRate = _calculateThreeStarRate(stats);
    
    if (threeStarRate >= 0.8) {
      strengths.add('performanceStrengthHighThreeStarRate');
    }
    if (stats.averageDestruction >= 85.0) {
      strengths.add('performanceStrengthHighDestruction');
    }
    if (stats.averageStars >= 2.5) {
      strengths.add('performanceStrengthConsistentPerformance');
    }
    
    return strengths;
  }
  
  static List<String> _getImprovementAreas(PlayerWarTypeStats stats) {
    final improvements = <String>[];
    final threeStarRate = _calculateThreeStarRate(stats);
    
    if (threeStarRate < 0.5) {
      improvements.add('performanceImprovementThreeStarConsistency');
    }
    if (stats.averageStars < 2.0) {
      improvements.add('performanceImprovementOverallStarPerformance');
    }
    if (stats.averageDestruction < 70.0) {
      improvements.add('performanceImprovementDestructionPercentage');
    }
    
    return improvements;
  }
}