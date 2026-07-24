import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/app_bar/coc_accounts_app_bar.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/widgets/account_verification_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/utils/deep_link_handler.dart';

class AddCocAccountPage extends StatefulWidget {
  const AddCocAccountPage({super.key, this.refreshOnExit = true});

  final bool refreshOnExit;

  @override
  AddCocAccountPageState createState() => AddCocAccountPageState();
}

class AddCocAccountPageState extends State<AddCocAccountPage> {
  final TextEditingController _playerTagController = TextEditingController();
  bool _isAddingLoading = false;
  String _errorMessage = "";
  List<Map<String, dynamic>> _tempUserAccounts = [];
  bool _isOrderChanged = false;
  String? _deletingPlayerTag;
  bool _isFirstConnection = false;
  bool _hasResolvedInitialConnectionState = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.tryHandlePendingDeepLink(context);
    });
    // Always sync. Skipping it when there were no verified accounts left
    // _tempUserAccounts empty, so already-linked-but-unverified accounts
    // silently vanished from the list below.
    _syncTempAccountsWithPlayerService();
  }

  Future<void> _loadAllAccountData() async {
    final playerService = context.read<PlayerService>();
    final clanService = context.read<ClanService>();
    final warCwlService = context.read<WarCwlService>();
    final cocService = context.read<CocAccountService>();
    List<String> playerTags = [];

    // Save the new order
    if (_isOrderChanged) {
      playerTags = _tempUserAccounts
          .map((account) => account["player_tag"].toString())
          .toList();
      try {
        await cocService.updateAccountOrder(playerTags);
      } catch (error) {
        setState(() {
          _errorMessage = AppLocalizations.of(
            context,
          )!.accountsErrorFailedToUpdateOrder;
        });
      }
      _isOrderChanged = false;
    } else {
      playerTags = context
          .read<CocAccountService>()
          .cocAccounts
          .map((account) => account["player_tag"].toString())
          .toList();
    }

    if (playerTags.isEmpty) return;

    // Load all account stats
    try {
      await cocService.loadApiData(playerService, clanService, warCwlService);
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.generalRefreshFailed(
            error.toString().replaceAll('Exception: ', ''),
          );
        });
      }
      return;
    }

    if (!cocService.hasVerifiedAccounts) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _errorMessage = AppLocalizations.of(
            context,
          )!.homeVerifiedAccountRequiredBody;
          _isFirstConnection = true;
        });
      }
      return;
    }

    // Navigate to the home page only after a verified link exists.
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final userAccounts = cocService.cocAccounts;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    final logoUrl = (isDarkMode
        ? ImageAssets.darkModeLogo
        : ImageAssets.lightModeLogo);
    final textLogoUrl = (isDarkMode
        ? ImageAssets.darkModeTextLogo
        : ImageAssets.lightModeTextLogo);

    return PopScope(
      // During first-connection this page may be the root route — allow
      // immediate pop so the system back gesture / back arrow always works.
      canPop: _isFirstConnection || !widget.refreshOnExit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          unawaited(_persistAccountOrder(cocService));
          return;
        }
        if (!widget.refreshOnExit) {
          unawaited(_persistAccountOrder(cocService));
          return;
        }
        // Only reached when !_isFirstConnection (canPop was false):
        // show a loader while refreshing account data before popping.
        if (context.mounted) {
          showDialog(
            context: context,
            useRootNavigator: false,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          await _loadAllAccountData();
        }
      },
      child: Scaffold(
        appBar: isDesktopWeb ? null : CocAccountsAppBar(),
        resizeToAvoidBottomInset: false,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _AccountManagementIntro(
                          logoUrl: logoUrl,
                          textLogoUrl: textLogoUrl,
                          isFirstConnection: _isFirstConnection,
                        ),
                      ),
                      SliverPinnedHeader(
                        child: _AddAccountStickyPanel(
                          isAddingLoading: _isAddingLoading,
                          errorMessage: _errorMessage,
                          playerTagController: _playerTagController,
                          onAddAccount: _addAccount,
                        ),
                      ),
                      userAccounts.isEmpty
                          ? SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height *
                                    (_isFirstConnection ? 0.34 : 0.46),
                                child: _AccountsEmptyPanel(
                                  message: AppLocalizations.of(
                                    context,
                                  )!.accountsNoneFound,
                                ),
                              ),
                            )
                          : SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16,
                                ),
                                child: _AccountsListPanel(
                                  accounts: _tempUserAccounts,
                                  deletingPlayerTag: _deletingPlayerTag,
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      final item = _tempUserAccounts.removeAt(
                                        oldIndex,
                                      );
                                      _tempUserAccounts.insert(newIndex, item);
                                      _isOrderChanged = true;
                                    });
                                  },
                                  onVerify: _showVerificationDialog,
                                  onRemove: _removeAccount,
                                ),
                              ),
                            ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: _isFirstConnection ? 96 : 24),
                      ),
                    ],
                  ),
                ),
                if (_isFirstConnection)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16.0,
                      left: 16,
                      right: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cocService.hasVerifiedAccounts
                            ? () async {
                                showDialog(
                                  context: context,
                                  useRootNavigator: false,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                await _loadAllAccountData();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cocService.hasVerifiedAccounts
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest
                              : Theme.of(context).colorScheme.surface,
                          foregroundColor: cocService.hasVerifiedAccounts
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                          side: cocService.hasVerifiedAccounts
                              ? BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(
                                        alpha: AppOpacity.borderStrong,
                                      ),
                                )
                              : null,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(
                          MaterialLocalizations.of(context).continueButtonLabel,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _persistAccountOrder(CocAccountService cocService) async {
    if (!_isOrderChanged) return;
    final playerTags = _tempUserAccounts
        .map((account) => account["player_tag"].toString())
        .toList();
    try {
      await cocService.updateAccountOrder(playerTags);
      _isOrderChanged = false;
    } catch (error) {
      DebugUtils.debugError("Failed to persist account order: $error");
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isAddingLoading = false;
    });
  }

  Future<void> _addAccount() async {
    if (_isAddingLoading) return;

    setState(() {
      _isAddingLoading = true;
      _errorMessage = "";
    });

    final playerTagInput = _playerTagController.text.trim().toUpperCase();
    final playerTag = playerTagInput.startsWith('#')
        ? playerTagInput
        : '#$playerTagInput';
    if (playerTagInput.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.accountsEnterPlayerTag;
        _isAddingLoading = false;
      });
      return;
    }

    final cocService = context.read<CocAccountService>();

    // Check if the player tag is already in the list
    if (cocService.cocAccounts.any(
      (account) => account["player_tag"] == playerTag,
    )) {
      _setError(AppLocalizations.of(context)!.accountsErrorAlreadyLinkedToYou);
      return;
    }

    final Map<String, dynamic> response = await cocService.addCocAccount(
      playerTag,
    );

    if (response["code"] != 200 && mounted) {
      final errorCode = response["code"];

      if (errorCode == 409) {
        // Extract account information from 409 response
        final accountData = response["account"];
        final playerName = accountData?["name"] ?? "Player";
        final playerTownHall = accountData?["townHallLevel"] ?? 1;

        // Show popup dialog for token verification with actual account data
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AccountVerificationDialog(
            playerTag: playerTag,
            playerName: playerName,
            playerTownHall: playerTownHall,
          ),
        );

        if (!mounted) return;
        if (result == true) {
          // Account was successfully verified and added
          setState(() {
            _isAddingLoading = false;
            _errorMessage = "";
          });
          _playerTagController.clear();
          _syncTempAccountsWithPlayerService();
        } else {
          setState(() {
            _isAddingLoading = false;
          });
        }
        return;
      } else if (errorCode == 404) {
        _setError(AppLocalizations.of(context)!.accountsErrorTagNotExists);
      } else if (errorCode == 500) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ErrorPage(onRetry: () async => _addAccount()),
          ),
        );
      } else {
        _setError(AppLocalizations.of(context)!.accountsErrorFailedToAdd);
      }
      return;
    }

    if (response["account"] == null) return;

    setState(() {
      _isAddingLoading = false;
      _errorMessage = "";
      _syncTempAccountsWithPlayerService();
    });

    _playerTagController.clear();
  }

  Future<void> _removeAccount(String playerTag) async {
    setState(() {
      _deletingPlayerTag = playerTag;
      _errorMessage = "";
    });

    final cocService = context.read<CocAccountService>();
    await cocService.removeCocAccount(playerTag);

    setState(() {
      _tempUserAccounts.removeWhere(
        (account) => account["player_tag"] == playerTag,
      );
      _deletingPlayerTag = null;
    });
  }

  Future<void> _showVerificationDialog(
    String playerTag,
    String playerName,
    int playerTownHall,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AccountVerificationDialog(
        playerTag: playerTag,
        playerName: playerName,
        playerTownHall: playerTownHall,
      ),
    );

    if (result == true) {
      // Refresh the temp accounts to show updated verification status
      _syncTempAccountsWithPlayerService();
    }
  }

  void _syncTempAccountsWithPlayerService() {
    final playerService = context.read<PlayerService>();
    final cocService = context.read<CocAccountService>();
    setState(() {
      if (!_hasResolvedInitialConnectionState) {
        _isFirstConnection = !cocService.hasVerifiedAccounts;
        _hasResolvedInitialConnectionState = true;
      }
      _tempUserAccounts = cocService.cocAccounts.map((account) {
        String playerTag = account["player_tag"];

        // Try to find the player data from PlayerService
        try {
          final player = playerService.profiles.firstWhere(
            (p) => p.tag == playerTag,
          );
          return {
            "player_tag": playerTag,
            "name": player.name,
            "townHallLevel": player.townHallLevel,
            "isVerified": cocService.getAccountVerificationStatus(playerTag),
          };
        } catch (e) {
          // Fallback to account data if player not found in PlayerService
          DebugUtils.debugWarning(
            "⚠️ Player not found in PlayerService for tag: $playerTag, using fallback",
          );
          return {
            "player_tag": playerTag,
            "name": account["name"] ?? "Unknown Player",
            "townHallLevel": account["townHallLevel"] ?? 1,
            "isVerified": cocService.getAccountVerificationStatus(playerTag),
          };
        }
      }).toList();
    });
  }
}

class _AccountManagementIntro extends StatelessWidget {
  const _AccountManagementIntro({
    required this.logoUrl,
    required this.textLogoUrl,
    required this.isFirstConnection,
  });

  final String logoUrl;
  final String textLogoUrl;
  final bool isFirstConnection;

  @override
  Widget build(BuildContext context) {
    if (!isFirstConnection) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.accountsManageTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.authAccountManagement,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: MobileWebImage(
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageUrl: logoUrl,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            child: MobileWebImage(
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageUrl: textLogoUrl,
            ),
          ),
          const SizedBox(height: 32),
          if (isFirstConnection) ...[
            Text(
              AppLocalizations.of(context)!.accountsWelcome,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              AppLocalizations.of(context)!.accountsWelcomeMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddAccountStickyPanel extends StatelessWidget {
  const _AddAccountStickyPanel({
    required this.isAddingLoading,
    required this.errorMessage,
    required this.playerTagController,
    required this.onAddAccount,
  });

  final bool isAddingLoading;
  final String errorMessage;
  final TextEditingController playerTagController;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: playerTagController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!isAddingLoading) {
                  onAddAccount();
                }
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor:
                    Theme.of(context).cardTheme.color ?? colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                labelText: AppLocalizations.of(context)!.accountsPlayerTag,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: AppOpacity.borderStrong,
                    ),
                  ),
                ),
                suffixIcon: isAddingLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.add_circle,
                          color: colorScheme.primary,
                        ),
                        tooltip: AppLocalizations.of(context)!.accountsAdd,
                        onPressed: onAddAccount,
                      ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9#]')),
              ],
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.accountsAddInstruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsEmptyPanel extends StatelessWidget {
  const _AccountsEmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: AppOpacity.border,
            ),
          ),
        ),
        child: Center(child: _AccountsEmptyState(message: message)),
      ),
    );
  }
}

class _AccountsListPanel extends StatelessWidget {
  const _AccountsListPanel({
    required this.accounts,
    required this.deletingPlayerTag,
    required this.onReorder,
    required this.onVerify,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> accounts;
  final String? deletingPlayerTag;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String playerTag, String playerName, int playerTownHall)
  onVerify;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorderItem: onReorder,
      children: [
        for (int index = 0; index < accounts.length; index++)
          _AccountRow(
            key: ValueKey(accounts[index]["player_tag"]),
            name: accounts[index]["name"] ?? "",
            playerTag: accounts[index]["player_tag"] ?? "",
            townHallLevel: accounts[index]["townHallLevel"] ?? 1,
            isVerified: accounts[index]["isVerified"] == true,
            isDeleting: deletingPlayerTag == accounts[index]["player_tag"],
            onVerify: () => onVerify(
              accounts[index]["player_tag"],
              accounts[index]["name"] ?? "Unknown Player",
              accounts[index]["townHallLevel"] ?? 1,
            ),
            onRemove: () => onRemove(accounts[index]["player_tag"]),
          ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    super.key,
    required this.name,
    required this.playerTag,
    required this.townHallLevel,
    required this.isVerified,
    required this.isDeleting,
    required this.onVerify,
    required this.onRemove,
  });

  final String name;
  final String playerTag;
  final int townHallLevel;
  final bool isVerified;
  final bool isDeleting;
  final VoidCallback onVerify;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: AppOpacity.border,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: MobileWebImage(
                imageUrl: ImageAssets.townHall(townHallLevel),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.shield_outlined),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    playerTag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _VerificationChip(isVerified: isVerified, onTap: onVerify),
            const SizedBox(width: 4),
            Icon(
              Icons.drag_indicator,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.tooltipRemoveAccount,
              icon: isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_outline, color: colorScheme.primary),
              onPressed: isDeleting ? null : onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.isVerified, required this.onTap});

  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? StatColors.win : StatColors.capitalProjected;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.warning_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified
                ? AppLocalizations.of(context)!.accountVerified
                : AppLocalizations.of(context)!.accountVerify,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (isVerified) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: chip,
    );
  }
}

class _AccountsEmptyState extends StatelessWidget {
  const _AccountsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: AppOpacity.fillMuted,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
