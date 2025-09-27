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
  double _result = 0;

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
    final clan = widget.warInfo.clan;
    final opponent = widget.warInfo.opponent;

    _teamSizeController.text = widget.warInfo.teamSize?.toString() ?? '15';

    final diff = (clan?.destructionPercentage ?? 0) -
        (opponent?.destructionPercentage ?? 0);
    final neededPercent = (diff.abs() + 0.01).toStringAsFixed(2);
    _percentNeededController.text = neededPercent;

    _result =
        double.parse(neededPercent) * double.parse(_teamSizeController.text);
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
                            _result =
                                parseDouble(_percentNeededController.text) *
                                    parseDouble(_teamSizeController.text);
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
                      child: Text(
                        AppLocalizations.of(context)?.warCalculatorAnswer(
                                _percentNeededController.text,
                                _result.ceil().toString()) ??
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