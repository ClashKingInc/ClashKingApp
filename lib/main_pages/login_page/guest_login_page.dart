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

  // Controllers to manage text input
  final _usernameController = TextEditingController();

  final FocusNode _chipFocusNode = FocusNode();
  List<String> _tags = [];
  List<String> _suggestions = [];
  bool isLoading = false;
  String _tag = '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing user data if available
    _usernameController.text = "ILoveClashKing";
    _tags = []; // Assuming tags are List<String>
    isLoading = false;
    _chipFocusNode.addListener(() {
      if (!_chipFocusNode.hasFocus) {
        // Trigger submission when focus is lost
        _onSubmitted(_tag);
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _usernameController.dispose();
    _chipFocusNode.dispose();
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

  void _selectSuggestion(String tag) {
    setState(() {
      _tags.add(tag);
      _suggestions = <String>[];
    });
  }

  void _onChipTapped(String tag) {}

  void _onChipDeleted(String tag) {
    setState(() {
      _tags.remove(tag);
      _suggestions = <String>[];
    });
  }

  void _onSubmitted(String text) async {
    setState(() {
      isLoading = true;
    });
    if (text.trim().isNotEmpty) {
      if (!text.startsWith('#')) {
        text = '#$text';
      }
      String authToken = await login();
      String status = await checkIfPlayerTagExists(text, authToken);

      if (status == 'notExist' && mounted) {
        updateErrorMessage(AppLocalizations.of(context)!.doesNotExist(text));
      } else if (status == 'alreadyLinked' && mounted) {
        updateErrorMessage(AppLocalizations.of(context)!.isAlreadyLinked(text));
      } else {
        updateErrorMessage('');
      }
      setState(() {
        if (!_tags.contains(text) && status == 'Ok') {
          _tags = <String>[..._tags, text.trim()];
        }
      });
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

  void _onChanged(List<String> data) {
    setState(() {
      _tags.addAll(data);
    });
  }

  String errorMessage = '';

  void updateErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }


  @override
  Widget build(BuildContext context) {
    String globalName = '';
    List<String> tags = [];
    final navigator = Navigator.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop : true,
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
                  child: CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png"),
                ),
                SizedBox(
                  width: 200,
                  child: CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/logos/crown-arrow-white-bg/CK-text-white-bg.png"),
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
                          child: ChipsInput<String>(
                            focusNode: _chipFocusNode,
                            values: _tags,
                            decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: isLoading
                                      ? CircularProgressIndicator()
                                      : SizedBox.shrink(),
                                  onPressed: () {},
                                ),
                                labelText:
                                    AppLocalizations.of(context)!.playerTags,
                                hintText: _tags.isEmpty ? '#2QVPCJJV' : null,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always),
                            strutStyle: StrutStyle(fontSize: 15),
                            onChanged: _onChanged,
                            onSubmitted: _onSubmitted,
                            chipBuilder: _chipBuilder,
                            onTextChanged: _onSearchChanged,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[#a-zA-Z0-9]*'),
                              ),
                            ],
                          ),
                        ),
                        if (_suggestions.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              itemCount: _suggestions.length,
                              itemBuilder: (BuildContext context, int index) {
                                return TagSuggestion(
                                  _suggestions[index],
                                  onTap: _selectSuggestion,
                                );
                              },
                            ),
                          ),
                        if (errorMessage.isNotEmpty) Text(errorMessage),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            minimumSize: Size(240, 48),
                          ),
                          onPressed: () async {
                            try{
                            if (_formKey.currentState!.validate() &&
                                _tags.isNotEmpty) {
                              globalName = _usernameController.text;

                              String authToken = await login();

                              bool allTagsExist = true;
                              bool allTagsNotLinked = true;
                              List<String> nonExistentTags = [];
                              List<String> alreadyLinkedTags = [];
                              String status = '';

                              for (int i = 0; i < _tags.length; i++) {
                                status = await checkIfPlayerTagExists(
                                    _tags[i], authToken);
                                if (status == 'notExist') {
                                  nonExistentTags.add(_tags[i]);
                                  allTagsExist = false;
                                } else if (status == 'alreadyLinked') {
                                  alreadyLinkedTags.add(_tags[i]);
                                  allTagsNotLinked = false;
                                }
                              }
                              if (allTagsExist && allTagsNotLinked) {
                                // Save the tags to the user object (assuming user is DiscordUser object)
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
                                if (!allTagsExist && context.mounted) {
                                  updateErrorMessage(
                                      AppLocalizations.of(context)!
                                          .followingTagsDoNotExist(
                                              nonExistentTags.join(', ')));
                                }
                                if (!allTagsNotLinked && context.mounted) {
                                  updateErrorMessage(
                                      AppLocalizations.of(context)!
                                          .followingTagsAreAlreadyLinked(
                                              alreadyLinkedTags.join(', ')));
                                }
                              }
                            }
                            }
                            catch(exception, stackTrace){
                              Sentry.captureException(exception, stackTrace: stackTrace);
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
