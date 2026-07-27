import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TranslationScreen extends StatelessWidget {
  const TranslationScreen({super.key});

  static final Uri _crowdinUrl = Uri.parse(
    'https://crowdin.com/project/clashkingapp/invite?h=87a407268713f1cb79724a2e0c00a5d52098842',
  );
  static final Uri _discordUrl = Uri.parse('https://discord.gg/clashking');
  static const String _translatorGifUrl =
      'https://www.icegif.com/wp-content/uploads/2023/06/icegif-202.gif';

  static const List<String> _translators = [
    'AlejandroMoc',
    'athype',
    'bhatzuhaib',
    'ColinSchmale',
    'DeafToDeath',
    'Dinki/Krakakus',
    'dobryakoff',
    'GodOfGods',
    'Joelsuperstar',
    'lucaschuab2015',
    'mango_wz',
    'MixxStar',
    'MechanicaL',
    'MRocha01',
    'Nemo_64',
    'niklas312',
    'niku998',
    'Pottmichel',
    'retrock',
    'SamGo',
    'SudetiZ',
    'Wraxu',
    'zombie23304',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.translationHelpUsTranslate),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
        children: [
          _TranslationHeader(
            gifUrl: _translatorGifUrl,
            title: l10n.translationThankYou,
            body: l10n.translationThankYouContent,
          ),
          const SizedBox(height: 30),
          Text(
            l10n.translationHelpUsTranslate,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l10n.translationHelpTranslateContent,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          _TranslationActionRow(
            icon: Icons.translate_rounded,
            label: l10n.translationHelpTranslateButton,
            onTap: () => launchUrl(_crowdinUrl),
          ),
          _TranslationActionRow(
            icon: Icons.discord,
            label: l10n.faqJoinDiscord,
            onTap: () => launchUrl(_discordUrl),
          ),
          const SizedBox(height: 26),
          _TranslatorList(
            title: l10n.translationCurrentTranslators,
            translators: _translators,
          ),
        ],
      ),
    );
  }
}

class _TranslationHeader extends StatelessWidget {
  const _TranslationHeader({
    required this.gifUrl,
    required this.title,
    required this.body,
  });

  final String gifUrl;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final gif = ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 128,
                height: 128,
                child: MobileWebImage(
                  imageUrl: gifUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.translate_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 34,
                    ),
                  ),
                ),
              ),
            );
            final text = Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            );

            if (constraints.maxWidth < 330) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [gif, const SizedBox(height: 14), text],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                gif,
                const SizedBox(width: 16),
                Expanded(child: text),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TranslationActionRow extends StatelessWidget {
  const _TranslationActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Icon(icon, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslatorList extends StatelessWidget {
  const _TranslatorList({required this.title, required this.translators});

  final String title;
  final List<String> translators;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final translator in translators)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    translator,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
