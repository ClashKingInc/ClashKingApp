import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountVerificationDialog extends StatefulWidget {
  final String playerTag;
  final String playerName;
  final int playerTownHall;

  const AccountVerificationDialog({
    super.key,
    required this.playerTag,
    required this.playerName,
    required this.playerTownHall,
  });

  @override
  State<AccountVerificationDialog> createState() =>
      _AccountVerificationDialogState();
}

class _AccountVerificationDialogState extends State<AccountVerificationDialog> {
  final TextEditingController _apiTokenController = TextEditingController();
  bool _isVerifying = false;
  String _errorMessage = "";

  @override
  void dispose() {
    _apiTokenController.dispose();
    super.dispose();
  }

  void _updateErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _verifyAccount() async {
    if (_apiTokenController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.accountsApiToken;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = "";
    });

    final cocService = context.read<CocAccountService>();
    final success = await cocService.verifyAccount(
      widget.playerTag,
      _apiTokenController.text.trim(),
      _updateErrorMessage,
    );

    setState(() {
      _isVerifying = false;
    });

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.accountVerificationSuccess),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.accountVerificationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player info display - simplified
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: MobileWebImage(
                    imageUrl: ImageAssets.townHall(
                        widget.playerTownHall > 0 ? widget.playerTownHall : 1),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.playerName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.playerTag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Simple instruction text
          Text(
            AppLocalizations.of(context)!.accountsEnterApiToken,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 16),
          
          // API Token input field - simplified
          TextField(
            controller: _apiTokenController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.accountsApiToken,
              border: const OutlineInputBorder(),
              errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
            ),
            enabled: !_isVerifying,
          ),
          
          const SizedBox(height: 16),
          
          // Direct link to get API token
          InkWell(
            onTap: () async {
              try {
                final uri = Uri.parse(
                    'https://link.clashofclans.com/?action=OpenMoreSettings');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Could not open Clash of Clans. Please open it manually.'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Could not open Clash of Clans. Please open it manually.'),
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.accountsOpenMoreSettings,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isVerifying ? null : () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context)!.generalCancel),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyAccount,
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.accountVerifyButton),
        ),
      ],
    );
  }
}
