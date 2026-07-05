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

    final diff =
        (clan?.destructionPercentage ?? 0) -
        (opponent?.destructionPercentage ?? 0);
    final neededPercent = (diff.abs() + 0.01).toStringAsFixed(2);
    _percentNeededController.text = neededPercent;

    _result =
        double.parse(neededPercent) * double.parse(_teamSizeController.text);
  }

  @override
  void dispose() {
    _teamSizeController.dispose();
    _percentNeededController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)?.warCalculatorFast ??
                            'Fast calculator',
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _teamSizeController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.warTeamSize ??
                          'Team size',
                      hintText: widget.warInfo.teamSize?.toString() ?? '15',
                      prefixIcon: const Icon(Icons.groups_rounded),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _percentNeededController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(
                            context,
                          )?.warCalculatorNeededOverall ??
                          '% Needed overall',
                      hintText:
                          AppLocalizations.of(
                            context,
                          )?.warCalculatorHintPercent ??
                          '50.00',
                      prefixIcon: const Icon(Icons.percent_rounded),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _result =
                              parseDouble(_percentNeededController.text) *
                              parseDouble(_teamSizeController.text);
                        });
                      },
                      icon: const Icon(Icons.functions_rounded),
                      label: Text(
                        AppLocalizations.of(context)?.warCalculatorCalculate ??
                            'Calculate',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        AppLocalizations.of(context)?.warCalculatorAnswer(
                              _percentNeededController.text,
                              _result.ceil().toString(),
                            ) ??
                            '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}
