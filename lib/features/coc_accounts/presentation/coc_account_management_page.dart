import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/app_bar/coc_accounts_app_bar.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class AddCocAccountPage extends StatefulWidget {
  @override
  AddCocAccountPageState createState() => AddCocAccountPageState();
}

class AddCocAccountPageState extends State<AddCocAccountPage> {
  final TextEditingController _playerTagController = TextEditingController();
  final TextEditingController _apiTokenController = TextEditingController();
  bool _showApiTokenInput = false;
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
          _errorMessage = AppLocalizations.of(context)!.failedToUpdateOrder;
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
                      Text(AppLocalizations.of(context)!.welcome,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center),
                      Text(AppLocalizations.of(context)!.welcomeMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                    ] else ...[
                      Text(AppLocalizations.of(context)!.manageAccounts,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center),
                      Text(
                          AppLocalizations.of(context)!
                              .manageAccountsDescription,
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
                                  labelText:
                                      AppLocalizations.of(context)!.playerTag,
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
                                          icon: Icon(Icons.add_circle),
                                          onPressed: _showApiTokenInput
                                              ? _submitApiToken
                                              : _addAccount,
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
                              if (_showApiTokenInput) ...[
                                SizedBox(height: 16),
                                Text(
                                    AppLocalizations.of(context)!.enterApiToken,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                SizedBox(height: 8),
                                TextField(
                                  controller: _apiTokenController,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.apiToken,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                              SizedBox(height: 8),
                            ],
                          ),
                          Expanded(
                            child: userAccounts.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .noAccountLinkedToYourProfileFound,
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
                                              Icon(Icons.drag_handle),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (userAccounts.isEmpty) return;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    await _loadAllAccountData();
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _setError(String message, {bool showApiToken = false}) {
    setState(() {
      _errorMessage = message;
      _showApiTokenInput = showApiToken;
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
        _errorMessage = AppLocalizations.of(context)!.enterPlayerTag;
        _isAddingLoading = false;
      });
      return;
    }

    final cocService = context.read<CocAccountService>();

    // Check if the player tag is already in the list
    if (cocService.cocAccounts
        .any((account) => account["player_tag"] == playerTag)) {
      _setError(AppLocalizations.of(context)!.accountAlreadyLinkedToYou);
      return;
    }

    final Map<String, dynamic> response =
        await cocService.addCocAccount(playerTag);

    if (response["code"] != 200 && mounted) {
      final errorCode = response["code"];

      if (errorCode == 409) {
        _setError(AppLocalizations.of(context)!.accountAlreadyLinked(playerTag),
            showApiToken: true);
      } else if (errorCode == 404) {
        _setError(AppLocalizations.of(context)!.playerTagNotExists);
      } else if (errorCode == 500) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ErrorPage(onRetry: _addAccount),
          ),
        );
      } else {
        _setError(AppLocalizations.of(context)!.failedToAddTryAgain);
      }
      return;
    }

    if (response["account"] == null) return;

    // Get the new account data
    final newAccount = {
      "player_tag": response["account"]["tag"],
      "name": response["account"]["name"],
      "townHallLevel": response["account"]["townHallLevel"] ?? 1
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

  Future<void> _submitApiToken() async {
    setState(() {
      _isAddingLoading = true;
      _errorMessage = "";
    });

    final playerTag = _playerTagController.text.trim();
    final apiToken = _apiTokenController.text.trim();

    if (playerTag.isEmpty || apiToken.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.fillAllFields;
        _isAddingLoading = false;
      });
      return;
    }

    final cocService = context.read<CocAccountService>();
    final Map<String, dynamic> response =
        await cocService.addCocAccountWithVerification(playerTag, apiToken);

    if (response["code"] != 200 && mounted) {
      final errorCode = response["code"];

      if (errorCode == 403) {
        _setError(AppLocalizations.of(context)!.wrongApiToken,
            showApiToken: true);
      } else if (errorCode == 404) {
        _setError(AppLocalizations.of(context)!.playerTagNotExists);
      } else if (errorCode == 500) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ErrorPage(onRetry: _addAccount),
          ),
        );
      } else {
        _setError(AppLocalizations.of(context)!.failedToAddTryAgain);
      }
      return;
    }

    if (response["account"] == null) return;

    // Get the new account data
    final newAccount = {
      "player_tag": response["account"]["tag"],
      "name": response["account"]["name"],
      "townHallLevel": response["account"]["townHallLevel"] ?? 1
    };

    // Add the account to the local list
    setState(() {
      _isAddingLoading = false;
      _errorMessage = "";
      context.read<CocAccountService>().addLocalAccount(newAccount);
      _syncTempAccountsWithPlayerService();
    });

    _playerTagController.clear();
    _apiTokenController.clear();
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

  void _syncTempAccountsWithPlayerService() {
    setState(() {
      _tempUserAccounts =
          context.read<CocAccountService>().cocAccounts.map((account) {
        return {
          "player_tag": account["player_tag"],
          "name": account["name"],
          "townHallLevel": account["townHallLevel"] ?? 1,
        };
      }).toList();
    });
  }
}
