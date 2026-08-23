import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AuthPasswordRequirements extends StatelessWidget {
  const AuthPasswordRequirements({
    super.key,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecial,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecial;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: CKSpacing.xs),
          child: Text(
            l10n.authPasswordHeader,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _RequirementRow(met: hasMinLength, label: l10n.authPasswordTooShort),
        _RequirementRow(met: hasUppercase, label: l10n.authPasswordUppercase),
        _RequirementRow(met: hasLowercase, label: l10n.authPasswordLowercase),
        _RequirementRow(met: hasNumber, label: l10n.authPasswordNumber),
        _RequirementRow(met: hasSpecial, label: l10n.authPasswordSpecial),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: CKSpacing.xs),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? colorScheme.secondary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: CKSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
