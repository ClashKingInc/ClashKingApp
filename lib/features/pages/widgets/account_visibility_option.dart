import 'package:flutter/material.dart';

class AccountVisibilityOption extends StatelessWidget {
  const AccountVisibilityOption({
    super.key,
    required this.hidden,
    required this.verified,
    required this.updating,
    required this.onPressed,
  });

  final bool hidden;
  final bool verified;
  final bool updating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = verified && !updating;
    final contentColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    return Semantics(
      enabled: enabled,
      toggled: hidden,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Icon(
                  Icons.visibility_off_outlined,
                  size: 20,
                  color: contentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hide account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? null : contentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      verified
                          ? hidden
                                ? 'This account is hidden from public lookups.'
                                : 'This account is visible in public lookups.'
                          : 'Verify this account to change visibility.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: contentColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: hidden,
                  onChanged: enabled ? (_) => onPressed() : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
