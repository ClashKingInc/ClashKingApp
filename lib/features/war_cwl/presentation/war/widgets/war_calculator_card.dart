import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';

class WarCalculatorCard extends StatefulWidget {
  const WarCalculatorCard({
    super.key,
    required this.warInfo,
    this.initiallyExpanded = false,
  });

  final WarInfo warInfo;
  final bool initiallyExpanded;

  @override
  WarCalculatorCardState createState() => WarCalculatorCardState();
}

class WarCalculatorCardState extends State<WarCalculatorCard> {
  late bool _isExpanded;
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
    _isExpanded = widget.initiallyExpanded;
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
    final loc = AppLocalizations.of(context);

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
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc?.warCalculatorFast ?? 'Fast calculator',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calculate_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final teamSizeInput = _CalculatorInput(
                        controller: _teamSizeController,
                        label: loc?.warTeamSize ?? 'Team size',
                        hint: widget.warInfo.teamSize?.toString() ?? '15',
                        icon: Icons.groups_rounded,
                      );
                      final percentInput = _CalculatorInput(
                        controller: _percentNeededController,
                        label:
                            loc?.warCalculatorNeededOverall ??
                            '% Needed overall',
                        hint: loc?.warCalculatorHintPercent ?? '50.00',
                        icon: Icons.percent_rounded,
                      );

                      if (constraints.maxWidth < 430) {
                        return Column(
                          children: [
                            teamSizeInput,
                            const SizedBox(height: 10),
                            percentInput,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: teamSizeInput),
                          const SizedBox(width: 10),
                          Expanded(child: percentInput),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _result =
                                  parseDouble(_percentNeededController.text) *
                                  parseDouble(_teamSizeController.text);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.72,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            loc?.warCalculatorCalculate ?? 'Calculate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        loc?.warCalculatorAnswer(
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

class _CalculatorInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _CalculatorInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.38,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
