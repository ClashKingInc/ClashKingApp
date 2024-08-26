import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:clashkingapp/core/startup_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:clashkingapp/classes/account/cocdiscord_link_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/login_page/tag_input_chip.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class GuestLoginPage extends StatefulWidget {
  @override
  GuestLoginPageState createState() => GuestLoginPageState();
}

class GuestLoginPageState extends State<GuestLoginPage> {
  final _formKey = GlobalKey<FormState>(); // Form key for managing form state
  final _usernameController = TextEditingController();
  final _tagController = TextEditingController();
  final FocusNode _chipFocusNode = FocusNode();
  List<String> _tags = [];
  bool isLoading = false;
  String _tag = '';
  String errorMessage = '';
  bool showApiTokenInput = false;
  String apiErrorMessage = '';
  final TextEditingController apiTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing user data if available
    _usernameController.text = "ILoveClashKing";
    _tags = []; // Assuming tags are List<String>
    _tagController.text = '';
    isLoading = false;
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _usernameController.dispose();
    _tagController.dispose();
    _chipFocusNode.dispose();
    apiTokenController.dispose(); // Dispose API token controller
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    setState(() {
      _tag = value;
    });
  }

  Widget _chipBuilder(BuildContext context, String tag) {
    return TagInputChip(
      tag: tag,
      onDeleted: _onChipDeleted,
      onSelected: _onChipTapped,
    );
  }

  // Appelée lorsque le bouton pour ajouter un tag est pressé
  void _addTag() async {
    final String text = _tagController.text;
    if (text.trim().isEmpty) return;
    final String apiToken;

    setState(() {
      isLoading = true;
    });

    final String formattedTag = !text.startsWith('#') ? '#$text' : text;
    final String authToken = await login();
    final String status = await checkIfPlayerTagExists(formattedTag, authToken);

    if (!showApiTokenInput) {
      if (status == 'notExist' && mounted) {
        updateErrorMessage(
            AppLocalizations.of(context)!.doesNotExist(formattedTag));
      } else if (status == 'alreadyLinked' && mounted) {
        setState(() {
          showApiTokenInput = true;
          updateErrorMessage(
              AppLocalizations.of(context)!.isAlreadyLinked(formattedTag));
        });
      } else {
        setState(() {
          if (!_tags.contains(formattedTag) && status == 'Ok') {
            _tags.add(formattedTag.trim());
            _tag = ''; // Clear the current tag input after adding
          }
        });
        updateErrorMessage('');
        _tagController.clear();
      }
    } else {
      if (apiTokenController.text.isNotEmpty && mounted) {
        apiToken = apiTokenController.text;

        bool isApiTokenValid = await checkApiToken(apiToken, formattedTag,
            updateApiErrorToken, AppLocalizations.of(context)!.wrongApiToken);

        if (!_tags.contains(formattedTag) && isApiTokenValid) {
          _tags.add(formattedTag.trim());
          _tag = '';
          apiTokenController.clear();
          updateApiErrorToken('');
          updateErrorMessage('');
          _tagController.clear();
          showApiTokenInput = false;
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _onChipTapped(String tag) {}

  void _onChipDeleted(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void updateErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  void updateApiErrorToken(String message) {
    setState(() => apiErrorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    String globalName = '';
    List<String> tags = [];
    final navigator = Navigator.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set the appropriate image URLs based on the theme
    final logoUrl = isDarkMode
        ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png"
        : "https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png";
    final textLogoUrl = isDarkMode
        ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/CK-text-dark-bg.png"
        : "https://assets.clashk.ing/logos/crown-arrow-white-bg/CK-text-white-bg.png";

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) async {
          await deletePrefs('access_token');
          navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => StartupWidget()));
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 32),
              onPressed: () async {
                await deletePrefs('access_token');
                globalNavigatorKey.currentState!.pushReplacement(
                  MaterialPageRoute(builder: (context) => StartupWidget()),
                );
              },
            ),
          ),
          body: SingleChildScrollView(
            // Permet le défilement
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CachedNetworkImage(imageUrl: logoUrl),
                ),
                SizedBox(
                  width: 200,
                  child: CachedNetworkImage(imageUrl: textLogoUrl),
                ),
                SizedBox(height: 32),
                Text(AppLocalizations.of(context)!.createGuestProfile,
                    style: Theme.of(context).textTheme.titleLarge),
                Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: ListBody(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsetsDirectional.only(bottom: 16),
                          child: TextFormField(
                            controller: _usernameController,
                            maxLength:
                                14, // Limits the TextField to 14 characters
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.username,
                              hintText: AppLocalizations.of(context)!.username,
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .pleaseEnterUsername;
                              }
                              return null;
                            },
                            onChanged: (value) => globalName = value,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(bottom: 16),
                          child: TextField(
                            style: Theme.of(context).textTheme.bodySmall,
                            controller: _tagController,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.enterPlayerTag,
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
                                        Theme.of(context).colorScheme.primary,
                                    width: 2.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: Icon(Icons.tag,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              suffixIcon: IconButton(
                                icon: isLoading && !showApiTokenInput
                                    ? CircularProgressIndicator()
                                    : showApiTokenInput
                                        ? SizedBox.shrink()
                                        : Icon(Icons.add,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                onPressed: () {
                                  _addTag();
                                },
                              ),
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]')),
                            ],
                          ),
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
                                  await deleteLink(
                                      tag,
                                      await login(),
                                      updateErrorMessage,
                                      failedToDeleteTryAgain);
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        if (errorMessage.isNotEmpty)
                          Text(errorMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                        if (showApiTokenInput)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              Text(AppLocalizations.of(context)!.enterApiToken,
                                  style: Theme.of(context).textTheme.bodySmall),
                              SizedBox(height: 16),
                              Padding(
                                padding: EdgeInsetsDirectional.symmetric(
                                    vertical: 8),
                                child: TextFormField(
                                  controller: apiTokenController,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.apiToken,
                                    suffixIcon: IconButton(
                                      icon: isLoading
                                          ? CircularProgressIndicator()
                                          : Icon(Icons.add,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                      onPressed: () {
                                        _addTag();
                                      },
                                    ),
                                    hintText:
                                        AppLocalizations.of(context)!.apiToken,
                                  ),
                                ),
                              ),
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
                                      color:
                                          Theme.of(context).colorScheme.error),
                            ),
                          ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            minimumSize: Size(240, 48),
                          ),
                          onPressed: () async {
                            try {
                              if (_formKey.currentState!.validate() &&
                                  _tags.isNotEmpty) {
                                tags = _tags;

                                final prefs =
                                    await SharedPreferences.getInstance();
                                storePrefs("user_type", "guest");
                                storePrefs('username', globalName);
                                prefs.setStringList('tags', tags);

                                // Navigate to the next screen
                                globalNavigatorKey.currentState!
                                    .pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => StartupWidget(),
                                  ),
                                );
                              } else {
                                updateErrorMessage(AppLocalizations.of(context)!
                                    .enterPlayerTagWarning);
                              }
                            } catch (exception, stackTrace) {
                              Sentry.captureException(exception,
                                  stackTrace: stackTrace);
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.login),
                        ),
                      ],
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
}
