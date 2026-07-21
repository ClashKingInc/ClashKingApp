import 'dart:math' as math;

import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'side_page_components.dart';

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key});

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && _selectedTab != _tabController.index) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SidePageScaffold(
      title: loc.calculatorsTitle,
      subtitle: loc.calculatorsSubtitle,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: NativeLiquidGlassSegmentedControl<int>(
            values: const [0, 1],
            labels: [loc.calculatorZapQuake, loc.calculatorFireball],
            selected: _selectedTab,
            height: 44,
            onChanged: (index) {
              setState(() => _selectedTab = index);
              _tabController.animateTo(index);
            },
          ),
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: const [_ZapQuakeCalculator(), _FireballQuakeCalculator()],
      ),
    );
  }
}

class _ZapQuakeCalculator extends StatefulWidget {
  const _ZapQuakeCalculator();

  @override
  State<_ZapQuakeCalculator> createState() => _ZapQuakeCalculatorState();
}

class _ZapQuakeCalculatorState extends State<_ZapQuakeCalculator> {
  int _buildingHp = 4200;
  int _lightningLevel = 11;
  int _quakeLevel = 5;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lightning = _lightningDamage[_lightningLevel] ?? 600;
    final quake = (_buildingHp * ((_quakePercent[_quakeLevel] ?? 29) / 100))
        .floor();
    final afterQuake = math.max(0, _buildingHp - quake);
    final zaps = (afterQuake / lightning).ceil();
    final noQuakeZaps = (_buildingHp / lightning).ceil();

    return _CalculatorResponsiveLayout(
      lead: [
        _CalculatorResult(
          title: loc.sideZapQuakeTitle(zaps),
          subtitle: loc.sideZapQuakeSubtitle(
            formatSidePageInt(quake),
            formatSidePageInt(lightning),
          ),
        ),
        const SizedBox(height: 12),
        SidePageMetricPanel(
          label: loc.sideWithoutEarthquake,
          value: loc.sideLightningCount(noQuakeZaps),
        ),
      ],
      controls: [
        const SizedBox(height: 16),
        _CompactStepper(
          label: loc.sideBuildingHp,
          value: _buildingHp,
          step: 100,
          min: 100,
          onChanged: (value) => setState(() => _buildingHp = value),
        ),
        _LevelSelector(
          label: loc.sideLightningLevel,
          value: _lightningLevel,
          min: 1,
          max: 12,
          onChanged: (value) => setState(() => _lightningLevel = value),
        ),
        _LevelSelector(
          label: loc.sideEarthquakeLevel,
          value: _quakeLevel,
          min: 1,
          max: 5,
          onChanged: (value) => setState(() => _quakeLevel = value),
        ),
      ],
    );
  }
}

class _FireballQuakeCalculator extends StatefulWidget {
  const _FireballQuakeCalculator();

  @override
  State<_FireballQuakeCalculator> createState() =>
      _FireballQuakeCalculatorState();
}

class _FireballQuakeCalculatorState extends State<_FireballQuakeCalculator> {
  int _buildingHp = 5200;
  int _fireballLevel = 18;
  int _quakeLevel = 5;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final fireball = _fireballDamage(_fireballLevel);
    final afterFireball = math.max(0, _buildingHp - fireball);
    final quakeDamage =
        (_buildingHp * ((_quakePercent[_quakeLevel] ?? 29) / 100)).floor();
    final remaining = math.max(0, afterFireball - quakeDamage);
    final quakesNeeded = remaining == 0
        ? 1
        : math.min(4, (remaining / math.max(1, quakeDamage)).ceil() + 1);

    return _CalculatorResponsiveLayout(
      lead: [
        _CalculatorResult(
          title: remaining == 0
              ? loc.sideFireballQuakeTitle
              : loc.sideAddSupportDamage,
          subtitle: loc.sideFireballQuakeSubtitle(
            formatSidePageInt(fireball),
            formatSidePageInt(math.max(0, remaining)),
          ),
        ),
        const SizedBox(height: 12),
        SidePageMetricPanel(
          label: loc.sideQuakePressure,
          value: loc.sideQuakeSpellCount(quakesNeeded),
        ),
      ],
      controls: [
        const SizedBox(height: 16),
        _CompactStepper(
          label: loc.sideBuildingHp,
          value: _buildingHp,
          step: 100,
          min: 100,
          onChanged: (value) => setState(() => _buildingHp = value),
        ),
        _LevelSelector(
          label: loc.sideFireballLevel,
          value: _fireballLevel,
          min: 1,
          max: 27,
          onChanged: (value) => setState(() => _fireballLevel = value),
        ),
        _LevelSelector(
          label: loc.sideEarthquakeLevel,
          value: _quakeLevel,
          min: 1,
          max: 5,
          onChanged: (value) => setState(() => _quakeLevel = value),
        ),
      ],
    );
  }
}

class _CalculatorResponsiveLayout extends StatelessWidget {
  const _CalculatorResponsiveLayout({
    required this.lead,
    required this.controls,
  });

  final List<Widget> lead;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    if (!isSidePageDesktop(context)) {
      return ListView(
        padding: sidePagePadding,
        children: [...lead, ...controls],
      );
    }

    return ListView(
      padding: sidePagePadding,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 760;
            if (!useColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...lead, ...controls],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: lead,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: controls,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CalculatorResult extends StatelessWidget {
  const _CalculatorResult({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
  });

  final String label;
  final int value;
  final int step;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: AppLocalizations.of(context)!.sideDecrease,
            onPressed: value <= min
                ? null
                : () => onChanged(math.max(min, value - step)),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 72,
            child: Text(
              formatSidePageInt(value),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.sideIncrease,
            onPressed: () => onChanged(value + step),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DropdownButton<int>(
            value: value,
            items: [
              for (var level = min; level <= max; level++)
                DropdownMenuItem(
                  value: level,
                  child: Text(AppLocalizations.of(context)!.sideLevel(level)),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

const _lightningDamage = {
  1: 150,
  2: 180,
  3: 210,
  4: 240,
  5: 270,
  6: 320,
  7: 400,
  8: 480,
  9: 560,
  10: 600,
  11: 640,
  12: 680,
};

const _quakePercent = {1: 14, 2: 17, 3: 21, 4: 25, 5: 29};

int _fireballDamage(int level) {
  return 900 + ((level - 1) * 65);
}
