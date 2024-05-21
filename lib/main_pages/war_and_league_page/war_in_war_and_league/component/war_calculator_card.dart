import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WarCalculatorCard extends StatefulWidget {
  const WarCalculatorCard({
    super.key,
    required this.teamSize,
  });

  final int teamSize;

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
    _teamSizeController.text = widget.teamSize.toString();
    _percentNeededController.text = (100 / widget.teamSize).toStringAsFixed(2);
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
                    child: Text(AppLocalizations.of(context)?.fastCalculator ?? 'Fast calculator'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _isExpanded,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _teamSizeController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.teamSize ?? 'Team size',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        hintText: widget.teamSize.toString(),
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _percentNeededController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.neededOverall ?? '% Needed overall',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        hintText: (100 / widget.teamSize).toStringAsFixed(2),
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
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
                            _result = (double.parse(_percentNeededController.text)) * double.parse(_teamSizeController.text);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.calculate ?? 'Calculate', 
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'To score overall ${_percentNeededController.text}%, you need to achieve at least ${_result.ceil()}%',
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
