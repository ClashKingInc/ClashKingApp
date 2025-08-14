import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';

class WarCalculatorCard extends StatefulWidget {
  const WarCalculatorCard({super.key, required this.warInfo});

  final WarInfo warInfo;

  @override
  WarCalculatorCardState createState() => WarCalculatorCardState();
}

class WarCalculatorCardState extends State<WarCalculatorCard> {
  bool _isExpanded = false;
  final _teamSizeController = TextEditingController();
  final _percentNeededController = TextEditingController();

  double parseDouble(String value, {double defaultValue = 0.0}) {
    try {
      return double.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  void initState() {
    super.initState();
    
    _teamSizeController.text = widget.warInfo.teamSize?.toString() ?? '15';

    // Calculate what's needed to win the war
    final calculationResult = calculateWhatIsNeededToWin();
    _percentNeededController.text = calculationResult['percentNeeded'].toString();
  }

  Map<String, dynamic> calculateComprehensiveWarAnalysis() {
    final clan = widget.warInfo.clan;
    final opponent = widget.warInfo.opponent;
    final teamSize = widget.warInfo.teamSize ?? 15;

    if (clan == null || opponent == null) {
      return {
        'yourClan': {'starsNeeded': 0, 'destructionNeeded': 0.0, 'winPossible': true},
        'opponent': {'starsNeeded': 0, 'destructionNeeded': 0.0, 'winPossible': true},
        'winProbability': 50.0,
        'status': 'No data available',
        'insights': ['Unable to analyze - missing war data']
      };
    }

    final clanStars = clan.stars;
    final opponentStars = opponent.stars;
    final clanDestruction = clan.destructionPercentage;
    final opponentDestruction = opponent.destructionPercentage;
    final clanAttacks = clan.attacks;
    final opponentAttacks = opponent.attacks;
    final maxPossibleStars = teamSize * 3;
    final maxPossibleDestruction = teamSize * 100.0;

    // Calculate remaining potential - detect CWL properly
    final bool isCwlWar = widget.warInfo.attacksPerMember == null || 
                         widget.warInfo.warType?.toLowerCase().contains('cwl') == true;
    final int attacksPerMember = isCwlWar ? 1 : (widget.warInfo.attacksPerMember ?? 2);
    final int totalPossibleAttacks = teamSize * attacksPerMember;
    
    final clanRemainingAttacks = totalPossibleAttacks - clanAttacks;
    final opponentRemainingAttacks = totalPossibleAttacks - opponentAttacks;
    final clanMaxPossibleStars = clanStars + (clanRemainingAttacks * 3);
    final opponentMaxPossibleStars = opponentStars + (opponentRemainingAttacks * 3);
    final clanMaxPossibleDestruction = clanDestruction + (clanRemainingAttacks * 100);
    final opponentMaxPossibleDestruction = opponentDestruction + (opponentRemainingAttacks * 100);

    // Check for perfect wars and impossible scenarios
    bool clanHasPerfectWar = clanStars == maxPossibleStars && clanDestruction >= (maxPossibleDestruction - 1);
    bool opponentHasPerfectWar = opponentStars == maxPossibleStars && opponentDestruction >= (maxPossibleDestruction - 1);

    // Calculate what each clan needs to win
    Map<String, dynamic> clanNeeds = _calculateClanRequirements(
      ourStars: clanStars, theirStars: opponentStars,
      ourDestruction: clanDestruction, theirDestruction: opponentDestruction,
      ourMaxStars: clanMaxPossibleStars, theirMaxStars: opponentMaxPossibleStars,
      ourMaxDestruction: clanMaxPossibleDestruction, theirMaxDestruction: opponentMaxPossibleDestruction,
      remainingAttacks: clanRemainingAttacks
    );

    Map<String, dynamic> opponentNeeds = _calculateClanRequirements(
      ourStars: opponentStars, theirStars: clanStars,
      ourDestruction: opponentDestruction, theirDestruction: clanDestruction,
      ourMaxStars: opponentMaxPossibleStars, theirMaxStars: clanMaxPossibleStars,
      ourMaxDestruction: opponentMaxPossibleDestruction, theirMaxDestruction: clanMaxPossibleDestruction,
      remainingAttacks: opponentRemainingAttacks
    );

    // Calculate win probability based on current situation and remaining potential
    double winProbability = _calculateWinProbability(
      clanStars, opponentStars, clanDestruction, opponentDestruction,
      clanMaxPossibleStars, opponentMaxPossibleStars,
      clanMaxPossibleDestruction, opponentMaxPossibleDestruction,
      clanRemainingAttacks, opponentRemainingAttacks
    );

    // Generate strategic insights
    List<String> insights = _generateStrategicInsights(
      clanStars, opponentStars, clanDestruction, opponentDestruction,
      clanRemainingAttacks, opponentRemainingAttacks, clanNeeds, opponentNeeds
    );

    // Determine current status
    String status = _determineWarStatus(
      clanStars, opponentStars, clanDestruction, opponentDestruction,
      clanHasPerfectWar, opponentHasPerfectWar, winProbability
    );

    return {
      'yourClan': clanNeeds,
      'opponent': opponentNeeds,
      'winProbability': winProbability,
      'status': status,
      'insights': insights,
      'clanRemainingAttacks': clanRemainingAttacks,
      'opponentRemainingAttacks': opponentRemainingAttacks
    };
  }

  Map<String, dynamic> _calculateClanRequirements({
    required int ourStars, required int theirStars,
    required double ourDestruction, required double theirDestruction,
    required int ourMaxStars, required int theirMaxStars,
    required double ourMaxDestruction, required double theirMaxDestruction,
    required int remainingAttacks
  }) {
    int starsNeeded = 0;
    double destructionNeeded = 0.0;
    bool winPossible = true;
    bool drawPossible = false;
    String strategy = '';

    if (ourStars > theirStars) {
      // Leading on stars - calculate destruction buffer needed
      if (theirMaxStars > ourStars) {
        // Opponent can catch up on stars, need destruction buffer
        destructionNeeded = (theirMaxDestruction - ourDestruction + 0.01);
        if (destructionNeeded > (ourMaxDestruction - ourDestruction)) {
          winPossible = false;
          strategy = 'Maintain star lead - opponent cannot catch up';
        } else {
          strategy = 'Maintain star lead with destruction buffer';
        }
      } else {
        strategy = 'Star lead is secure';
      }
    } else if (ourStars < theirStars) {
      // Behind on stars
      starsNeeded = theirStars - ourStars + 1;
      if (starsNeeded > (ourMaxStars - ourStars)) {
        // Can't catch up to win, check if we can tie
        int starsToTie = theirStars - ourStars;
        if (starsToTie <= (ourMaxStars - ourStars)) {
          // Can tie on stars, check if we can win on destruction or just draw
          starsNeeded = starsToTie; // Update to show stars needed to tie
          if (ourMaxDestruction > theirMaxDestruction) {
            destructionNeeded = theirDestruction - ourDestruction + 0.01;
            strategy = 'Tie on stars, win on destruction';
          } else if (ourMaxDestruction == theirMaxDestruction) {
            drawPossible = true;
            strategy = 'Can achieve draw by tying stars and destruction';
          } else {
            winPossible = false;
            strategy = 'Can tie stars but will lose on destruction';
          }
        } else {
          winPossible = false;
          strategy = 'Too far behind on stars';
        }
      } else {
        strategy = 'Need to get more stars to win';
      }
    } else {
      // Tied on stars
      if (ourDestruction > theirDestruction) {
        if (theirMaxDestruction > ourDestruction) {
          destructionNeeded = theirMaxDestruction - ourDestruction + 0.01;
          winPossible = destructionNeeded <= (ourMaxDestruction - ourDestruction);
          strategy = winPossible ? 'Maintain destruction lead' : 'Destruction lead at risk';
        } else {
          strategy = 'Destruction lead is secure';
        }
      } else if (ourDestruction < theirDestruction) {
        destructionNeeded = theirDestruction - ourDestruction + 0.01;
        if (destructionNeeded <= (ourMaxDestruction - ourDestruction)) {
          strategy = 'Catch up on destruction to win';
        } else {
          // Check if we can at least tie
          double destructionToTie = theirDestruction - ourDestruction;
          if (destructionToTie <= (ourMaxDestruction - ourDestruction)) {
            drawPossible = true;
            destructionNeeded = destructionToTie;
            strategy = 'Can tie on destruction for draw';
          } else {
            winPossible = false;
            strategy = 'Cannot catch up on destruction';
          }
        }
      } else {
        // Perfect tie situation - both stars and destruction equal
        drawPossible = true;
        strategy = 'Currently in perfect tie - result is draw';
      }
    }

    return {
      'starsNeeded': starsNeeded,
      'destructionNeeded': destructionNeeded.clamp(0.0, double.infinity),
      'winPossible': winPossible,
      'drawPossible': drawPossible,
      'strategy': strategy,
      'remainingAttacks': remainingAttacks
    };
  }

  double _calculateWinProbability(
    int clanStars, int opponentStars, double clanDestruction, double opponentDestruction,
    int clanMaxStars, int opponentMaxStars, double clanMaxDestruction, double opponentMaxDestruction,
    int clanRemainingAttacks, int opponentRemainingAttacks
  ) {
    // Base probability on current standing
    double probability = 50.0;

    // Adjust for star difference
    if (clanStars > opponentStars) {
      double starAdvantage = (clanStars - opponentStars) / ((clanStars + opponentStars) / 2);
      probability += starAdvantage * 25;
    } else if (opponentStars > clanStars) {
      double starDisadvantage = (opponentStars - clanStars) / ((clanStars + opponentStars) / 2);
      probability -= starDisadvantage * 25;
    }

    // Adjust for destruction difference
    if (clanDestruction > opponentDestruction) {
      double destructionAdvantage = (clanDestruction - opponentDestruction) / ((clanDestruction + opponentDestruction) / 2);
      probability += destructionAdvantage * 15;
    } else if (opponentDestruction > clanDestruction) {
      double destructionDisadvantage = (opponentDestruction - clanDestruction) / ((clanDestruction + opponentDestruction) / 2);
      probability -= destructionDisadvantage * 15;
    }

    // Adjust for remaining potential
    double clanPotential = clanMaxStars + (clanMaxDestruction / 100);
    double opponentPotential = opponentMaxStars + (opponentMaxDestruction / 100);
    
    if (clanPotential > opponentPotential) {
      probability += 10;
    } else if (opponentPotential > clanPotential) {
      probability -= 10;
    }

    return probability.clamp(5.0, 95.0); // Keep between 5-95%
  }

  List<String> _generateStrategicInsights(
    int clanStars, int opponentStars, double clanDestruction, double opponentDestruction,
    int clanRemainingAttacks, int opponentRemainingAttacks,
    Map<String, dynamic> clanNeeds, Map<String, dynamic> opponentNeeds
  ) {
    List<String> insights = [];
    final clanWinPossible = clanNeeds['winPossible'] as bool;
    final clanDrawPossible = clanNeeds['drawPossible'] as bool? ?? false;
    final opponentWinPossible = opponentNeeds['winPossible'] as bool;
    final opponentDrawPossible = opponentNeeds['drawPossible'] as bool? ?? false;

    // Attack efficiency insights
    if (clanRemainingAttacks > 0 && clanWinPossible) {
      double starsPerAttack = clanRemainingAttacks > 0 ? clanNeeds['starsNeeded'] / clanRemainingAttacks : 0;
      if (starsPerAttack > 2.5) {
        insights.add('Need ${starsPerAttack.toStringAsFixed(1)} stars per attack - very challenging!');
      } else if (starsPerAttack > 2.0) {
        insights.add('Need ${starsPerAttack.toStringAsFixed(1)} stars per attack - requires strong performance');
      } else if (starsPerAttack > 0) {
        insights.add('Need ${starsPerAttack.toStringAsFixed(1)} stars per attack - achievable goal');
      }
    }

    // Draw scenario insights
    if (clanStars == opponentStars && (clanDestruction - opponentDestruction).abs() < 1.0) {
      insights.add('🤝 Perfect tie situation - draw is the current outcome');
    } else if (clanStars == opponentStars && (clanDestruction - opponentDestruction).abs() < 5) {
      insights.add('🎯 Very close war - every percentage point matters!');
    }

    // Win/draw possibility analysis
    if (!opponentWinPossible && !opponentDrawPossible) {
      insights.add('🔒 Opponent cannot win or draw - victory is secured!');
    } else if (!opponentWinPossible && opponentDrawPossible) {
      insights.add('⚠️ Opponent can only achieve draw - victory within reach!');
    } else if (!clanWinPossible && clanDrawPossible) {
      insights.add('🤝 Draw is your best possible outcome - fight for it!');
    } else if (!clanWinPossible && !clanDrawPossible) {
      insights.add('💪 Comeback time - every attack counts!');
    }

    // Attack timing insights
    if (opponentRemainingAttacks == 0 && clanRemainingAttacks > 0) {
      if (clanWinPossible) {
        insights.add('⚡ Opponent has finished - time to capitalize and win!');
      } else if (clanDrawPossible) {
        insights.add('⚡ Opponent has finished - can you secure the draw?');
      }
    } else if (clanRemainingAttacks == 0 && opponentRemainingAttacks > 0) {
      insights.add('⏰ You have finished - outcome depends on opponent');
    }

    // Strategic positioning
    if (clanRemainingAttacks > opponentRemainingAttacks && clanWinPossible) {
      insights.add('✨ You have more attacks remaining - good position to win');
    } else if (clanRemainingAttacks == opponentRemainingAttacks && clanStars == opponentStars) {
      insights.add('⚖️ Equal attacks remaining with tied stars - destruction will decide!');
    }

    return insights;
  }

  String _determineWarStatus(
    int clanStars, int opponentStars, double clanDestruction, double opponentDestruction,
    bool clanHasPerfectWar, bool opponentHasPerfectWar, double winProbability
  ) {
    if (clanHasPerfectWar) return 'Perfect War - Victory Guaranteed! 🏆';
    if (opponentHasPerfectWar) return 'Opponent Perfect War - Defeat 💔';
    
    // Check for current draw situation
    if (clanStars == opponentStars && (clanDestruction - opponentDestruction).abs() < 0.5) {
      return 'Perfect Draw - Equal Performance! 🤝';
    }
    
    if (winProbability >= 80) return 'Excellent Position - Likely Victory 🌟';
    if (winProbability >= 65) return 'Good Position - Favored to Win ✅';
    if (winProbability >= 35) return 'Close War - Could Go Either Way ⚔️';
    if (winProbability >= 20) return 'Difficult Position - Uphill Battle ⛰️';
    return 'Very Challenging - Major Comeback Needed 🔥';
  }

  // Keep the old method for backward compatibility, but make it call the new one
  Map<String, dynamic> calculateWhatIsNeededToWin() {
    final analysis = calculateComprehensiveWarAnalysis();
    return {
      'starsNeeded': analysis['yourClan']['starsNeeded'],
      'percentNeeded': analysis['yourClan']['destructionNeeded'] / (widget.warInfo.teamSize ?? 15),
      'destructionNeeded': analysis['yourClan']['destructionNeeded'],
      'winPossible': analysis['yourClan']['winPossible'],
      'message': analysis['status']
    };
  }

  Widget _buildResultDisplay(BuildContext context) {
    final result = calculateWhatIsNeededToWin();
    final starsNeeded = result['starsNeeded'] as int;
    final percentNeeded = result['percentNeeded'] as double;
    final winPossible = result['winPossible'] as bool;

    if (!winPossible) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          "Victory not possible with remaining attacks",
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (starsNeeded == 0 && percentNeeded <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Text(
          "You are already winning!",
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Text(
        AppLocalizations.of(context)?.warCalculatorAnswer(
          percentNeeded.toStringAsFixed(1), 
          result['destructionNeeded'].toStringAsFixed(1)
        ) ?? 'To achieve a destruction rate of ${percentNeeded.toStringAsFixed(1)}%, a total of ${result['destructionNeeded'].toStringAsFixed(1)}% is needed.',
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Card(
        child: Column(
          children: [
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate,
                      color: Theme.of(context).colorScheme.onSurface),
                  Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(
                        AppLocalizations.of(context)?.warCalculatorFast ??
                            'Fast calculator'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _isExpanded,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _teamSizeController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.warTeamSize ??
                            'Team size',
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        hintText: widget.warInfo.teamSize?.toString() ?? '15',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _percentNeededController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                                ?.warCalculatorNeededOverall ??
                            '% Needed overall',
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        hintText: '50.00',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            // Recalculate with current inputs - this will trigger _buildResultDisplay to refresh
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        child: Text(
                            AppLocalizations.of(context)
                                    ?.warCalculatorCalculate ??
                                'Calculate',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: _buildResultDisplay(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
