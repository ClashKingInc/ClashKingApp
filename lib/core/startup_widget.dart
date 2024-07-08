import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page/login_page.dart';
import 'package:clashkingapp/core/my_home_page.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/main_pages/login_page/tag_input_chip.dart';
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
  String _tag = '';
  String authToken = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
    isLoading = false;
    _chipFocusNode.addListener(() async {
      if (!_chipFocusNode.hasFocus && isLoading != true) {
        // Trigger submission when focus is lost
        await _onSubmitted(_tag);
      }
    });
  }

  @override
  void dispose() async {
    // Dispose controllers to avoid memory leaks
    _chipFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    setState(() {
      _tag = value;
    });
  }

  void _onChipTapped(String tag) {}

  Future<void> _onSubmitted(String text) async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    if (text.trim().isNotEmpty) {
      if (!text.startsWith('#')) {
        text = '#$text';
      }
      String status = await checkIfPlayerTagExists(text, authToken);

      if (mounted) {
        if (status == 'notExist') {
          updateErrorMessage(AppLocalizations.of(context)!.doesNotExist(text));
        } else if (status == 'alreadyLinked') {
          updateErrorMessage(
              AppLocalizations.of(context)!.isAlreadyLinked(text));
        } else {
          String playerTagNotExists =
              AppLocalizations.of(context)!.playerTagNotExists;
          String accountAlreadyLinked =
              AppLocalizations.of(context)!.accountAlreadyLinked;
          String failedToAddTryAgain =
              AppLocalizations.of(context)!.failedToAddTryAgain;
          text = text.replaceFirst('#', '');
          final success = await addLink(
              text,
              appState.user!.id,
              authToken,
              updateErrorMessage,
              playerTagNotExists,
              accountAlreadyLinked,
              failedToAddTryAgain);

          setState(() {
            if (!_tags.contains(text) && success == true) {
              _tags = <String>[..._tags, text.trim()];
            }
          });
        }
      }
    } else {
      _chipFocusNode.unfocus();
      setState(() {
        _tags = <String>[];
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  String errorMessage = '';

  void updateErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    final transaction = Sentry.startTransaction(
      'initializeApp',
      'task',
      bindToScope: true,
    );

    try {
      // Start a child span for SharedPreferences
      final prefsSpan = transaction.startChild('SharedPreferences.getInstance');
      prefsSpan.finish(status: SpanStatus.ok());

      final userType = await getPrefs('user_type');

      if (userType == "guest") {
        // Initialize guest user
        final guestSpan = transaction.startChild('initializeGuestUser');
        await appState.initializeGuestUser();
        guestSpan.finish(status: SpanStatus.ok());

        if (mounted) {
          transaction.finish(status: SpanStatus.ok());
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
        }
      } else if (userType == "discord") {
        if (mounted) {
          // Initialize discord user
          final discordSpan = transaction.startChild('initializeDiscordUser');
          await appState.initializeDiscordUser(context);
          discordSpan.finish(status: SpanStatus.ok());

          if (mounted && appState.user!.tags.isNotEmpty) {
            transaction.finish(status: SpanStatus.ok());
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => MyHomePage()));
          } else {
            authToken = await login();
            _showTagDialog();
          }
        } else {
          deletePrefs("user_type");
        }
      } else {
        // Redirect to the login page
        if (mounted) {
          transaction.finish(status: SpanStatus.ok());
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
        }
      }
    } catch (exception, stackTrace) {
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(exception, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the app is initializing
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  void _showTagDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Check if the theme is light or dark

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Set the appropriate image URLs based on the theme
        final logoUrl = isDarkMode
            ? "https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/ClashKing-1.png"
            : "https://clashkingfiles.b-cdn.net/logos/crown-arrow-white-bg/ClashKing-2.png";
        final textLogoUrl = isDarkMode
            ? "https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/CK-text-dark-bg.png"
            : "https://clashkingfiles.b-cdn.net/logos/crown-arrow-white-bg/CK-text-white-bg.png";
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void localOnSubmit(String text) async {
              await _onSubmitted(text);
              setState(() {});
            }

            void localOnChipDeleted(String tag) async {
              String failedToDeleteTryAgain =
                  AppLocalizations.of(context)!.failedToDeleteTryAgain;
              await deleteLink(
                  tag, authToken, updateErrorMessage, failedToDeleteTryAgain);
              setState(() {
                // Use dialog's setState
                _tags.removeWhere((t) => t == tag);
              });
            }

            Widget localChipBuilder(BuildContext context, String tag) {
              return TagInputChip(
                tag: tag,
                onDeleted: (String tag) => localOnChipDeleted(tag),
                onSelected: _onChipTapped,
              );
            }

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
                  ChipsInput<String>(
                    focusNode: _chipFocusNode,
                    values: _tags,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: isLoading
                            ? CircularProgressIndicator()
                            : SizedBox.shrink(),
                        onPressed: () {},
                      ),
                      labelText: AppLocalizations.of(context)!.playerTags,
                      hintText: _tags.isEmpty ? '#2QVPCJJV' : null,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    strutStyle: StrutStyle(fontSize: 15),
                    onChanged: (List<String> data) {
                      setState(() {
                        _tags.addAll(data.where((tag) => !_tags.contains(tag)));
                      });
                    },
                    onSubmitted: localOnSubmit,
                    chipBuilder: localChipBuilder,
                    onTextChanged: _onSearchChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[#a-zA-Z0-9]*')),
                    ],
                  ),
                  if (errorMessage.isNotEmpty)
                    Column(
                        children: [SizedBox(height: 16), Text(errorMessage)]),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    if (_tags.isNotEmpty) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => StartupWidget()));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
