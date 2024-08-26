import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page/login_page.dart';
import 'package:clashkingapp/core/my_home_page.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/core/functions.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:clashkingapp/classes/account/cocdiscord_link_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class StartupWidget extends StatefulWidget {
  @override
  StartupWidgetState createState() => StartupWidgetState();
}

class StartupWidgetState extends State<StartupWidget> {
  final FocusNode _chipFocusNode = FocusNode();
  List<String> _tags = [];
  bool isLoading = false;
  String authToken = '';
  String errorMessage = '';
  String apiErrorMessage = '';
  bool showApiTokenInput = false;
  final TextEditingController playerTagController = TextEditingController();
  final TextEditingController apiTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _chipFocusNode.addListener(() async {
      if (!_chipFocusNode.hasFocus && isLoading != true) {
        // Do nothing on focus loss
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _chipFocusNode.dispose();
    playerTagController.dispose();
    apiTokenController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    final transaction = Sentry.startTransaction(
      'initializeApp',
      'task',
      bindToScope: true,
    );

    try {
      final userType = await getPrefs('user_type');
      if (userType == "guest") {
        final guestSpan = transaction.startChild('initializeGuestUser');
        await appState.initializeGuestUser();
        guestSpan.finish();
        if (mounted) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
        }
      } else if (userType == "discord") {
        if (mounted) {
          final discordSpan = transaction.startChild('initializeDiscordUser');
          await appState.initializeDiscordUser(context);
          discordSpan.finish();
          if (appState.user != null && appState.user!.tags.isNotEmpty) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => MyHomePage()));
          } else {
            authToken = await login();
            _showTagDialog();
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
        }
      }
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
    }
  }

  Future<void> _addAccount() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    String playerTag = playerTagController.text;
    if (playerTag.trim().isNotEmpty) {
      if (!playerTag.startsWith('#')) playerTag = '#$playerTag';

      String status = await checkIfPlayerTagExists(playerTag, authToken);
      if (mounted) {
        if (status == 'notExist') {
          updateErrorMessage(
              AppLocalizations.of(context)!.doesNotExist(playerTag));
        } else if (status == 'alreadyLinked') {
          setState(() => showApiTokenInput = true);
          updateErrorMessage(
              AppLocalizations.of(context)!.isAlreadyLinked(playerTag));
        } else {
          bool success = await addLink(
              playerTag.replaceFirst('#', ''),
              appState.user!.id,
              authToken,
              updateErrorMessage,
              AppLocalizations.of(context)!.playerTagNotExists,
              AppLocalizations.of(context)!.accountAlreadyLinked(""),
              AppLocalizations.of(context)!.failedToAddTryAgain);

          if (success && !_tags.contains(playerTag)) {
            setState(() {
              _tags.add(playerTag.trim());
              playerTagController.clear();
            });
          }
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _submitApiToken() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    String playerTag = playerTagController.text;

    bool success = await addLinkWithAPIToken(
      playerTag,
      appState.user!.id,
      authToken,
      updateApiErrorToken,
      AppLocalizations.of(context)!.playerTagNotExists,
      AppLocalizations.of(context)!.accountAlreadyLinked(""),
      AppLocalizations.of(context)!.failedToAddTryAgain,
      apiTokenController.text,
      AppLocalizations.of(context)!.failedToDeleteTryAgain,
      AppLocalizations.of(context)!.wrongApiToken,
    );

    if (success) {
      setState(() {
        showApiTokenInput = false;
        apiErrorMessage = '';
        _tags.add(playerTag);
        apiTokenController.clear();
        playerTagController.clear();
      });
    } else {
      setState(
          () => apiErrorMessage = AppLocalizations.of(context)!.wrongApiToken);
    }
  }

  void updateErrorMessage(String message) {
    setState(() => errorMessage = message);
  }

  void updateApiErrorToken(String message) {
    setState(() => apiErrorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  void _showTagDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final logoUrl = isDarkMode
            ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png"
            : "https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png";
        final textLogoUrl = isDarkMode
            ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/CK-text-dark-bg.png"
            : "https://assets.clashk.ing/logos/crown-arrow-white-bg/CK-text-white-bg.png";

        return WillPopScope(
          onWillPop: () async {
            // Logic to handle the back button press
            deletePrefs('user_type');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => StartupWidget()),
            );
            return false; // Prevent the dialog from closing automatically
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                scrollable: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Column(children: [
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: CachedNetworkImage(imageUrl: logoUrl),
                  ),
                  SizedBox(
                    width: 150,
                    child: CachedNetworkImage(imageUrl: textLogoUrl),
                  ),
                  SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.welcome,
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center),
                  Text(AppLocalizations.of(context)!.welcomeMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  SizedBox(height: 16),
                ]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      style: Theme.of(context).textTheme.bodySmall,
                      controller: playerTagController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterPlayerTag,
                        labelStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.tertiary,
                              width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.tag,
                            color: Theme.of(context).colorScheme.onSurface),
                        suffixIcon: IconButton(
                          icon: isLoading && !showApiTokenInput
                              ? CircularProgressIndicator()
                              : showApiTokenInput
                                  ? SizedBox.shrink()
                                  : Icon(Icons.add,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                          onPressed: () async {
                            await _addAccount();
                            setState(() {});
                          },
                        ),
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]')),
                      ],
                    ),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            onDeleted: () async {
                              String failedToDeleteTryAgain =
                                  AppLocalizations.of(context)!
                                      .failedToDeleteTryAgain;
                              await deleteLink(tag, authToken,
                                  updateErrorMessage, failedToDeleteTryAgain);
                              setState(() {
                                _tags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    if (errorMessage.isNotEmpty)
                      Column(children: [
                        SizedBox(height: 16),
                        Text(errorMessage,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.error))
                      ]),
                    if (showApiTokenInput)
                      Column(
                        children: [
                          SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.enterApiToken,
                              style: Theme.of(context).textTheme.bodySmall),
                          SizedBox(height: 16),
                          TextField(
                            style: Theme.of(context).textTheme.bodySmall,
                            controller: apiTokenController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.apiToken,
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    width: 1.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    width: 2.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              suffixIcon: IconButton(
                                icon: isLoading && showApiTokenInput
                                    ? CircularProgressIndicator()
                                    : Icon(Icons.add,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                onPressed: () async {
                                  await _submitApiToken();

                                  setState(() {});
                                },
                              ),
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]')),
                            ],
                          ),
                          if (apiErrorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                apiErrorMessage,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                              ),
                            ),
                        ],
                      ),
                    SizedBox(height: 16),
                  ],
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.cancel,
                            style: Theme.of(context).textTheme.bodyMedium),
                        onPressed: () {
                          Navigator.of(context).pop();
                          deletePrefs('user_type');
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => StartupWidget()));
                        },
                      ),
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.ok,
                            style: Theme.of(context).textTheme.bodyMedium),
                        onPressed: () {
                          if (_tags.isNotEmpty) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => StartupWidget()));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
