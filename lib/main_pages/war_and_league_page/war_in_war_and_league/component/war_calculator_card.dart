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
                  Icon(Icons.calculate),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(AppLocalizations.of(context)?.fastCalculator ?? 'Fast calculator'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _isExpanded,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _teamSizeController,
                      decoration: InputDecoration(
                        labelText: 'Team size',
                        hintText: widget.teamSize.toString(),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _percentNeededController,
                      decoration: InputDecoration(
                        labelText: '% Needed overall',
                        hintText: (100 / widget.teamSize).toStringAsFixed(2),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: 150,
                      height: 50, 
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _result = (double.parse(_percentNeededController.text)) * double.parse(_teamSizeController.text);
                          });
                        },
                        child: Text('Calculate'),
                      ),
                    ),
                    Text('To score overall ${_percentNeededController.text}%, you need to achieve at least ${_result.ceil()}%'),
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
