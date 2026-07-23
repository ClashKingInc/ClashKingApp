import 'package:clashkingapp/common/theme/app_tokens.dart';
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
    final success = await cocService.addAccountWithToken(
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
          content: Text(
            AppLocalizations.of(context)!.accountVerificationSuccess,
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(
        AppLocalizations.of(context)!.accountVerificationTitle,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player info display
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: AppOpacity.fillMuted),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: MobileWebImage(
                        imageUrl: ImageAssets.townHall(
                          widget.playerTownHall > 0 ? widget.playerTownHall : 1,
                        ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.playerTag,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // API Token instructions
              Text(
                AppLocalizations.of(context)!.accountsEnterApiToken,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.accountsApiTokenLocation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),

              // API Token input field
              TextField(
                controller: _apiTokenController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.accountsApiToken,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                ),
                enabled: !_isVerifying,
              ),

              const SizedBox(height: 12),

              // Direct link to get API token
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final uri = Uri.parse(
                        'https://link.clashofclans.com/?action=OpenMoreSettings',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.accountsCouldNotOpenClash,
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.accountsCouldNotOpenClash,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    AppLocalizations.of(context)!.accountsOpenMoreSettings,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying
              ? null
              : () => Navigator.of(context).pop(false),
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
              : Text(AppLocalizations.of(context)!.accountVerify),
        ),
      ],
    );
  }
}
