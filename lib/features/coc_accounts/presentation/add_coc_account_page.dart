import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/app_bar/coc_accounts_app_bar.dart';
import 'package:clashkingapp/common/widgets/error_page.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/profile_info_service.dart';
import 'package:clashkingapp/features/home/presentation/my_home_page.dart';
import 'package:clashkingapp/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddCocAccountPage extends StatefulWidget {
  @override
  _AddCocAccountPageState createState() => _AddCocAccountPageState();
}

class _AddCocAccountPageState extends State<AddCocAccountPage> {
  final TextEditingController _playerTagController = TextEditingController();
  final TextEditingController _apiTokenController = TextEditingController();
  bool _showApiTokenInput = false;
  bool _isLoading = false;
  String _errorMessage = "";
  List<Map<String, dynamic>> _tempUserAccounts = [];
  bool _isOrderChanged = false;

  void _loadAllAccountData() async {
    final profileService = context.read<ProfileService>();
    final cocService = context.read<CocAccountService>();
    List<String> playerTags = [];

    // Save the new order
    if (_isOrderChanged) {
      playerTags = _tempUserAccounts
          .map((account) => account["tag"].toString())
          .toList();
      await cocService.updateAccountOrder(playerTags);
      _isOrderChanged = false;
    } else {
      playerTags = context
          .read<CocAccountService>()
          .cocAccounts
          .map((account) => account["tag"].toString())
          .toList();
    }

    if (playerTags.isEmpty) return;

    // Load all account stats
    await profileService.loadPlayerAndClanData(cocService);

    // Navigate to the home page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MyHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final userAccounts = cocService.cocAccounts;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final logoUrl = ApiService.assetUrl +
        (isDarkMode
            ? "/logos/crown-arrow-dark-bg/ClashKing-1.png"
            : "/logos/crown-arrow-white-bg/ClashKing-2.png");
    final textLogoUrl = ApiService.assetUrl +
        (isDarkMode
            ? "/logos/crown-arrow-dark-bg/CK-text-dark-bg.png"
            : "/logos/crown-arrow-white-bg/CK-text-white-bg.png");

    if (_tempUserAccounts.length != userAccounts.length) {
      _tempUserAccounts = List.from(userAccounts);
    }

    return Scaffold(
      appBar: CocAccountsAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // Permet de prendre tout l'espace disponible
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Column(children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CachedNetworkImage(imageUrl: logoUrl),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: CachedNetworkImage(imageUrl: textLogoUrl),
                      ),
                      SizedBox(height: 32),
                      Text(AppLocalizations.of(context)!.welcome,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center),
                      Text(AppLocalizations.of(context)!.welcomeMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                    ]),
                    SizedBox(height: 32),
                    TextField(
                      controller: _playerTagController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.playerTag,
                        border: OutlineInputBorder(),
                        suffixIcon: _isLoading
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
                      Text(AppLocalizations.of(context)!.enterApiToken,
                          style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 8),
                      TextField(
                        controller: _apiTokenController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.apiToken,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.linkedAccounts,
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: userAccounts.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .noAccountLinkedToYourProfileFound,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ReorderableListView(
                              onReorder: (oldIndex, newIndex) {
                                if (oldIndex < newIndex)
                                  newIndex--; // Adjust the index

                                setState(() {
                                  final item =
                                      _tempUserAccounts.removeAt(oldIndex);
                                  _tempUserAccounts.insert(newIndex, item);
                                  _isOrderChanged = true;
                                });
                              },
                              children: [
                                for (int index = 0;
                                    index < _tempUserAccounts.length;
                                    index++)
                                  ListTile(
                                    key: ValueKey(
                                        _tempUserAccounts[index]["tag"]),
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            "${ApiService.assetUrl}/home-base/town-hall-pics/town-hall-${_tempUserAccounts[index]["townHallLevel"]}.png",
                                      ),
                                    ),
                                    title:
                                        Text(_tempUserAccounts[index]["name"]),
                                    subtitle:
                                        Text(_tempUserAccounts[index]["tag"]),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.drag_handle),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          onPressed: () => _removeAccount(
                                              _tempUserAccounts[index]["tag"]),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        userAccounts.isNotEmpty ? _loadAllAccountData : null,
                    child: Text(
                      AppLocalizations.of(context)!.loadAccountData,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setError(String message, {bool showApiToken = false}) {
    setState(() {
      _errorMessage = message;
      _showApiTokenInput = showApiToken;
      _isLoading = false;
    });
  }

  Future<void> _addAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final playerTag = _playerTagController.text.trim();
    if (playerTag.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.enterPlayerTag;
        _isLoading = false;
      });
      return;
    }

    final cocService = context.read<CocAccountService>();

    // Check if the player tag is already in the list
    if (cocService.cocAccounts.any((account) => account["tag"] == playerTag)) {
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
      "tag": response["account"]["tag"],
      "name": response["account"]["name"],
      "townHallLevel": response["account"]["townHallLevel"]
    };

    // Add the account to the local list
    setState(() {
      _isLoading = false;
      _errorMessage = "";
      context.read<CocAccountService>().addLocalAccount(newAccount);
    });

    _playerTagController.clear();
  }

  Future<void> _submitApiToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final playerTag = _playerTagController.text.trim();
    final apiToken = _apiTokenController.text.trim();

    if (playerTag.isEmpty || apiToken.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.fillAllFields;
        _isLoading = false;
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
      "tag": response["account"]["tag"],
      "name": response["account"]["name"],
      "townHallLevel": response["account"]["townHallLevel"]
    };

    // Add the account to the local list
    setState(() {
      _isLoading = false;
      _errorMessage = "";
      context.read<CocAccountService>().addLocalAccount(newAccount);
    });

    _playerTagController.clear();
    _apiTokenController.clear();
  }

  Future<void> _removeAccount(String playerTag) async {
    final cocService = context.read<CocAccountService>();
    await cocService.removeCocAccount(playerTag);

    setState(() {
      _tempUserAccounts.removeWhere((account) => account["tag"] == playerTag);
    });
  }
}
