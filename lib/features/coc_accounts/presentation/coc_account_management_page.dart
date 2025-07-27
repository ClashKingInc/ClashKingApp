import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/app_bar/coc_accounts_app_bar.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/widgets/account_verification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class AddCocAccountPage extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    final CocAccountService cocService = context.read<CocAccountService>();
    if (cocService.cocAccounts.isEmpty) {
      setState(() {
        _isFirstConnection = true;
      });
    } else {
      _syncTempAccountsWithPlayerService();
    }
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
          _errorMessage =
              AppLocalizations.of(context)!.accountsErrorFailedToUpdateOrder;
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
    await cocService.loadApiData(playerService, clanService, warCwlService);

    // Navigate to the home page
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MyHomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final userAccounts = cocService.cocAccounts;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final logoUrl =
        (isDarkMode ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo);
    final textLogoUrl = (isDarkMode
        ? ImageAssets.darkModeTextLogo
        : ImageAssets.lightModeTextLogo);

    return Scaffold(
      appBar: CocAccountsAppBar(),
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(children: [
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: CachedNetworkImage(
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          imageUrl: logoUrl),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 150,
                      child: CachedNetworkImage(
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          imageUrl: textLogoUrl),
                    ),
                    SizedBox(height: 32),
                    if (_isFirstConnection) ...[
                      Text(AppLocalizations.of(context)!.accountsWelcome,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center),
                      Text(AppLocalizations.of(context)!.accountsWelcomeMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                    ] else ...[
                      Text(AppLocalizations.of(context)!.accountsManageTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center),
                      Text(AppLocalizations.of(context)!.authAccountManagement,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                    ],
                  ]),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Column(
                            children: [
                              TextField(
                                controller: _playerTagController,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .accountsPlayerTag,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  suffixIcon: _isAddingLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : IconButton(
                                          icon: Icon(Icons.add_circle,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          tooltip: AppLocalizations.of(context)!
                                              .accountsAdd,
                                          onPressed: _addAccount,
                                        ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9#]')),
                                ],
                              ),
                              if (_errorMessage.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .accountsAddInstruction,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                          Expanded(
                            child: userAccounts.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .accountsNoneFound,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  )
                                : ReorderableListView(
                                    onReorder: (oldIndex, newIndex) {
                                      if (oldIndex < newIndex) {
                                        newIndex--;
                                      }

                                      setState(() {
                                        final item = _tempUserAccounts
                                            .removeAt(oldIndex);
                                        _tempUserAccounts.insert(
                                            newIndex, item);
                                        _isOrderChanged = true;
                                      });
                                    },
                                    children: [
                                      for (int index = 0;
                                          index < _tempUserAccounts.length;
                                          index++)
                                        ListTile(
                                          key: ValueKey(_tempUserAccounts[index]
                                              ["player_tag"]),
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: CachedNetworkImage(
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.error),
                                              imageUrl: ImageAssets.townHall(
                                                  _tempUserAccounts[index]
                                                          ["townHallLevel"] ??
                                                      1),
                                            ),
                                          ),
                                          title: Text(_tempUserAccounts[index]
                                                  ["name"] ??
                                              ""),
                                          subtitle: Text(
                                              _tempUserAccounts[index]
                                                      ["player_tag"] ??
                                                  ""),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Verification status with better UX
                                              if (_tempUserAccounts[index]
                                                      ["isVerified"] ==
                                                  true)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: Colors.green
                                                            .withValues(
                                                                alpha: 0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.verified,
                                                          color: Colors.green,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .accountVerified,
                                                        style: TextStyle(
                                                          color: Colors.green,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                InkWell(
                                                  onTap: () =>
                                                      _showVerificationDialog(
                                                    _tempUserAccounts[index]
                                                        ["player_tag"],
                                                    _tempUserAccounts[index]
                                                            ["name"] ??
                                                        "Unknown Player",
                                                    _tempUserAccounts[index]
                                                            ["townHallLevel"] ??
                                                        1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: Colors.orange
                                                              .withValues(
                                                                  alpha: 0.3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .warning_outlined,
                                                            color:
                                                                Colors.orange,
                                                            size: 16),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .accountVerify,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.orange,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              // Drag handle with better visual design
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.drag_indicator,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  size: 20,
                                                ),
                                              ),
                                              // Delete button with confirmation
                                              IconButton(
                                                icon: _deletingPlayerTag ==
                                                        _tempUserAccounts[index]
                                                            ["player_tag"]
                                                    ? SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      )
                                                    : Icon(Icons.delete,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                onPressed: () => _removeAccount(
                                                    _tempUserAccounts[index]
                                                        ["player_tag"]),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: userAccounts.isEmpty
                      ? null
                      : () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          await _loadAllAccountData();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userAccounts.isEmpty
                        ? Theme.of(context).colorScheme.surface
                        : null,
                    foregroundColor: userAccounts.isEmpty
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4)
                        : null,
                  ),
                  child: Text(AppLocalizations.of(context)!.generalConfirm),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isAddingLoading = false;
    });
  }

  Future<void> _addAccount() async {
    setState(() {
      _isAddingLoading = true;
      _errorMessage = "";
    });

    final playerTag = _playerTagController.text.trim();
    if (playerTag.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.accountsEnterPlayerTag;
        _isAddingLoading = false;
      });
      return;
    }

    final cocService = context.read<CocAccountService>();

    // Check if the player tag is already in the list
    if (cocService.cocAccounts
        .any((account) => account["player_tag"] == playerTag)) {
      _setError(AppLocalizations.of(context)!.accountsErrorAlreadyLinkedToYou);
      return;
    }

    final Map<String, dynamic> response =
        await cocService.addCocAccount(playerTag);

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

    // Get the new account data
    final newAccount = {
      "player_tag": response["account"]["tag"],
      "name": response["account"]["name"],
      "townHallLevel": response["account"]["townHallLevel"] ?? 1,
      "is_verified": response["account"]["is_verified"] ??
          false // Default false for security
    };

    // Add the account to the local list
    setState(() {
      _isAddingLoading = false;
      _errorMessage = "";
      context.read<CocAccountService>().addLocalAccount(newAccount);
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
      _tempUserAccounts
          .removeWhere((account) => account["player_tag"] == playerTag);
      _deletingPlayerTag = null;
    });
  }

  Future<void> _showVerificationDialog(
      String playerTag, String playerName, int playerTownHall) async {
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
              "⚠️ Player not found in PlayerService for tag: $playerTag, using fallback");
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
