import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page/login_page.dart';
import 'package:clashkingapp/core/my_home_page.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/main_pages/login_page/tag_input_chip.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:clashkingapp/api/cocdiscord_link_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    print('on submitted');
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
              print(_tags);
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

    // Check if a user has been registered yet
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');

    // If yes and the user is a guest, initialize the guest user
    if (userType == "guest") {
      await appState.initializeGuestUser(); // Initialize guest user
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
      }
    }
    // If yes and the user is a discord user, initialize the discord user
    else if (userType == "discord") {
      bool validToken = await isTokenValid(); // Check if the token is valid
      if (validToken && mounted) {
        await appState
            .initializeDiscordUser(context); // Initialize discord user

        if (mounted && appState.user!.tags.isNotEmpty) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
        } else {
          authToken = await login();
          _showTagDialog();
        }
      } else {
        prefs.setString("user_type", "");
      }
    }
    // If no user has been registered yet, redirect to the login page
    else {
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
      }
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void localOnSubmit(String text) async {
              await _onSubmitted(text);
              print('Submitted');
              setState(() {});
            }

            void localOnChipDeleted(String tag) async {
              String failedToDeleteTryAgain =
                  AppLocalizations.of(context)!.failedToDeleteTryAgain;
              bool success = await deleteLink(
                  tag, authToken, updateErrorMessage, failedToDeleteTryAgain);
              print("Delete success: $success");
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
              surfaceTintColor: Colors.transparent,
              title: Column(children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: CachedNetworkImage(
                      imageUrl:
                          "https://clashkingfiles.b-cdn.net/logos/ClashKing-crown-logo.png"),
                ),
                SizedBox(
                  width: 150,
                  child: CachedNetworkImage(
                      imageUrl:
                          "https://clashkingfiles.b-cdn.net/logos/ClashKing-name-logo.png"),
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
              content: SingleChildScrollView(
                child: Column(
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
                          _tags = data;
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
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => StartupWidget()));
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
