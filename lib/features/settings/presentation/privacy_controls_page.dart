import 'dart:async';
import 'dart:convert';

import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

typedef PrivacyExportSaver =
    Future<void> Function({required String fileName, required String data});

class PrivacyControlsPage extends StatefulWidget {
  const PrivacyControlsPage({super.key, this.saveExport = _savePrivacyExport});

  final PrivacyExportSaver saveExport;

  @override
  State<PrivacyControlsPage> createState() => _PrivacyControlsPageState();
}

Future<void> _savePrivacyExport({
  required String fileName,
  required String data,
}) {
  return FlutterFileSaver().writeFileAsString(fileName: fileName, data: data);
}

class _PrivacyControlsPageState extends State<PrivacyControlsPage> {
  static final Uri _privacyPolicyUri = Uri.parse('https://clashk.ing/privacy');
  static final Uri _supportEmailUri = Uri(
    scheme: 'mailto',
    path: 'devs@clashk.ing',
    queryParameters: {
      'subject': 'ClashKing privacy request',
      'body':
          'Hello ClashKing team,\n\nI want to exercise a privacy right for my account. Please help me with:\n\n- Access/export\n- Correction\n- Deletion\n- Consent withdrawal\n- Other:\n\nAccount email or Discord username:\n\nThank you.',
    },
  );

  var _isExporting = false;
  var _isDeleting = false;
  String? _pendingExportFileName;
  String? _pendingExportData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cards = [
      _PrivacyCard(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy policy',
        body:
            'Review what ClashKing collects, why it is used, who processes it, retention rules, and how to contact us.',
        action: FilledButton.tonalIcon(
          onPressed: () => launchUrl(
            _privacyPolicyUri,
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open policy'),
        ),
      ),
      _PrivacyCard(
        icon: Icons.file_download_outlined,
        title: 'Access or export your data',
        body:
            'Download a copy of account data linked to your ClashKing login, including linked Clash of Clans accounts and notification preferences.',
        action: _buildExportAction(),
      ),
      _PrivacyCard(
        icon: Icons.edit_note_outlined,
        title: 'Correct or limit data',
        body:
            'Remove linked Clash of Clans accounts from account settings, disable notifications in notification settings, or contact support for correction and restriction requests.',
        action: FilledButton.tonalIcon(
          onPressed: _contactSupport,
          icon: const Icon(Icons.email_outlined),
          label: const Text('Contact support'),
        ),
      ),
      _PrivacyCard(
        icon: Icons.delete_forever_outlined,
        title: 'Delete your ClashKing account',
        body:
            'This starts deletion of your ClashKing account and associated app data unless ClashKing must keep limited records for security, fraud prevention, or legal obligations.',
        action: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: _isDeleting ? null : _confirmDeletion,
          icon: _isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete account'),
        ),
      ),
      const _PrivacyCard(
        icon: Icons.child_care_outlined,
        title: 'Children and families',
        body:
            'ClashKing is a general-audience companion app and is not directed to children. Do not create an account if you are not old enough to consent in your country without parent or guardian approval.',
        action: null,
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Privacy & data'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktopWeb = kIsWeb && constraints.maxWidth >= 900;
          if (!isDesktopWeb) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
              children: cards,
            );
          }

          final contentWidth = (constraints.maxWidth - 48)
              .clamp(0.0, 1100.0)
              .toDouble();
          final columns = contentWidth >= 780 ? 2 : 1;
          final cardWidth = columns == 2
              ? (contentWidth - 16) / 2
              : contentWidth;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            children: [
              Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final card in cards)
                        SizedBox(width: cardWidth, child: card),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExportAction() {
    final hasPreparedExport =
        _pendingExportFileName != null && _pendingExportData != null;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: _isExporting ? null : _requestExport,
          icon: _isExporting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(hasPreparedExport ? 'Refresh export' : 'Prepare export'),
        ),
        if (hasPreparedExport)
          FilledButton.tonalIcon(
            onPressed: _savePreparedExport,
            icon: const Icon(Icons.save_alt_outlined),
            label: const Text('Save export'),
          ),
      ],
    );
  }

  Future<void> _requestExport() async {
    setState(() => _isExporting = true);
    try {
      final response = await context.read<AuthService>().requestDataExport();
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      if (!mounted) return;
      setState(() {
        _pendingExportFileName = 'clashking-data-$timestamp.json';
        _pendingExportData = const JsonEncoder.withIndent(
          '  ',
        ).convert(response);
      });
      _showSnack('Your data export is ready to save.');
    } catch (_) {
      await _contactSupport();
      _showSnack(
        'The data export could not be created. A privacy email has been prepared instead.',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _savePreparedExport() async {
    final fileName = _pendingExportFileName;
    final data = _pendingExportData;
    if (fileName == null || data == null) {
      _showSnack('Prepare your export before saving it.');
      return;
    }

    try {
      await widget.saveExport(fileName: fileName, data: data);
      _showSnack('Your data export has been saved.');
    } catch (_) {
      await _contactSupport();
      _showSnack(
        'The data export could not be saved. A privacy email has been prepared instead.',
      );
    }
  }

  Future<void> _confirmDeletion() async {
    final authService = context.read<AuthService>();
    final cocAccountService = context.read<CocAccountService>();
    final playerService = context.read<PlayerService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This request is permanent after processing. You may lose linked accounts, notification settings, saved preferences, and authentication methods.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await authService.deleteAccount();
      if (!mounted) return;
      cocAccountService.clearAccountData();
      clearAccountScopedHomeCaches(playerService);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (_) {
      await _contactSupport();
      _showSnack(
        'The deletion endpoint is not available in this build. A privacy email has been prepared instead.',
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _contactSupport() async {
    await launchUrl(_supportEmailUri, mode: LaunchMode.externalApplication);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
