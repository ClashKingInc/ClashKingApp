import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';

class WarCalculatorCard extends StatefulWidget {
  const WarCalculatorCard({super.key, required this.currentWarInfo});

  final CurrentWarInfo currentWarInfo;

  @override
  WarCalculatorCardState createState() => WarCalculatorCardState();
}

class WarCalculatorCardState extends State<WarCalculatorCard> {
  bool _isExpanded = false;
  final _teamSizeController = TextEditingController();
  final _percentNeededController = TextEditingController();
  double _result = 0;

  @override
  void initState() {
    super.initState();
    _teamSizeController.text = widget.currentWarInfo.teamSize.toString();
    if (widget.currentWarInfo.clan.destructionPercentage >
        widget.currentWarInfo.opponent.destructionPercentage) {
      _percentNeededController.text =
          (widget.currentWarInfo.clan.destructionPercentage -
                  widget.currentWarInfo.opponent.destructionPercentage +
                  0.01)
              .toStringAsFixed(2);
    } else {
      _percentNeededController.text =
          (widget.currentWarInfo.opponent.destructionPercentage -
                  widget.currentWarInfo.clan.destructionPercentage +
                  0.01)
              .toStringAsFixed(2);
    }
    _result = (double.parse(_percentNeededController.text)) *
        double.parse(_teamSizeController.text);
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
                  Icon(
                    Icons.calculate,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(AppLocalizations.of(context)?.fastCalculator ??
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
                        labelText: AppLocalizations.of(context)?.teamSize ??
                            'Team size',
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        hintText: widget.currentWarInfo.teamSize.toString(),
                        hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16),
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
                        labelText:
                            AppLocalizations.of(context)?.neededOverall ??
                                '% Needed overall',
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        hintText: (100 / widget.currentWarInfo.teamSize)
                            .toStringAsFixed(2),
                        hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16),
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
                    SizedBox(height: 16),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _result =
                                (double.parse(_percentNeededController.text)) *
                                    double.parse(_teamSizeController.text);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        child: Text(
                            AppLocalizations.of(context)?.calculate ??
                                'Calculate',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ),
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.fastCalculatorAnswer(
                                _percentNeededController.text,
                                _result.ceil().toString(),
                                _percentNeededController.text) ??
                            '',
                        textAlign: TextAlign.center,
                      ),
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
