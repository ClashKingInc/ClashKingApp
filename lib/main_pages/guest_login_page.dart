import 'dart:async';

import 'package:clashkingapp/core/my_app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:clashkingapp/core/startup_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:clashkingapp/api/cocdiscord_link_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GuestLoginPage extends StatefulWidget {
  final MyAppState appState;

  GuestLoginPage({required this.appState});

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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing user data if available
    _usernameController.text = "ILoveClashKing";
    _tags = []; // Assuming tags are List<String>
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    final List<String> results = await _suggestionCallback(value);
    setState(() {
      _suggestions =
          results.where((String tag) => !_tags.contains(tag)).toList();
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
    if (text.trim().isNotEmpty) {
      if (!text.startsWith('#')) {
        text = '#$text';
      }
      String authToken = await login();
      String status = await checkIfPlayerTagExists(text, authToken, context);
      if (status == 'notExist') {
        updateErrorMessage('$text ${AppLocalizations.of(context)!.doesNotExist}');
      } else if (status == 'alreadyLinked') {
        updateErrorMessage('$text ${AppLocalizations.of(context)!.isAlreadyLinked}');
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

  FutureOr<List<String>> _suggestionCallback(String text) {
    // Replace with actual suggestion logic if needed
    return [];
  }

  @override
  Widget build(BuildContext context) {
    String globalName = '';
    List<String> tags = [];

    return WillPopScope(
      onWillPop: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        if (mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => StartupWidget()));
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 32),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.remove('access_token');
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
                        "https://clashkingfiles.b-cdn.net/logos/ClashKing-crown-logo.png"),
              ),
              SizedBox(
                width: 200,
                child: CachedNetworkImage(
                    imageUrl:
                        "https://clashkingfiles.b-cdn.net/logos/ClashKing-name-logo.png"),
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
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.username,
                            hintText: AppLocalizations.of(context)!.username,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.pleaseEnterUsername;
                            }
                            return null;
                          },
                          onChanged: (value) => globalName = value,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(bottom: 16),
                        child: ChipsInput<String>(
                          values: _tags,
                          decoration: _tags.isEmpty ? InputDecoration(
                            labelText: AppLocalizations.of(context)!.playerTags,
                            hintText: '#2QVPCJJV',
                          ) : InputDecoration(
                            labelText: AppLocalizations.of(context)!.playerTags,
                            floatingLabelBehavior: FloatingLabelBehavior.always
                          ),
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
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            globalName = _usernameController.text;

                            String authToken = await login();

                            bool allTagsExist = true;
                            bool allTagsNotLinked = true;
                            List<String> nonExistentTags = [];
                            List<String> alreadyLinkedTags = [];
                            String status = '';

                            for (int i = 0; i < _tags.length; i++) {
                              status = await checkIfPlayerTagExists(
                                  _tags[i], authToken, context);
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

                              final prefs = await SharedPreferences.getInstance();
                              prefs.setString("user_type", "guest");
                              prefs.setString('username', globalName);
                              prefs.setStringList('tags', tags);

                              // Navigate to the next screen
                              globalNavigatorKey.currentState!.pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => StartupWidget(),
                                ),
                              );
                            } else {
                              if (!allTagsExist) {
                                updateErrorMessage(
                                    '${AppLocalizations.of(context)!.followingTagsDoNotExist} ${nonExistentTags.join(', ')}');
                              }
                              if (!allTagsNotLinked) {
                                updateErrorMessage(
                                    '${AppLocalizations.of(context)!.followingTagsAreAlreadyLinked} ${alreadyLinkedTags.join(', ')}');
                              }
                            }
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
    );
  }
}

class TagSuggestion extends StatelessWidget {
  const TagSuggestion(this.tag, {super.key, this.onTap});

  final String tag;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ObjectKey(tag),
      title: Text(tag),
      onTap: () => onTap?.call(tag),
    );
  }
}

class TagInputChip extends StatelessWidget {
  const TagInputChip({
    super.key,
    required this.tag,
    required this.onDeleted,
    required this.onSelected,
  });

  final String tag;
  final ValueChanged<String> onDeleted;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 3),
      child: InputChip(
        key: ObjectKey(tag),
        label: Text(tag),
        onDeleted: () => onDeleted(tag),
        onSelected: (bool value) => onSelected(tag),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(2),
      ),
    );
  }
}

class ChipsInput<T> extends StatefulWidget {
  const ChipsInput({
    super.key,
    required this.values,
    this.decoration = const InputDecoration(),
    this.style,
    this.strutStyle,
    required this.chipBuilder,
    required this.onChanged,
    this.onChipTapped,
    this.onSubmitted,
    this.onTextChanged,
    this.inputFormatters,
  });

  final List<T> values;
  final InputDecoration decoration;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final List<TextInputFormatter>? inputFormatters;

  final ValueChanged<List<T>> onChanged;
  final ValueChanged<T>? onChipTapped;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onTextChanged;

  final Widget Function(BuildContext context, T data) chipBuilder;

  @override
  ChipsInputState<T> createState() => ChipsInputState<T>();
}

class ChipsInputState<T> extends State<ChipsInput<T>> {
  @visibleForTesting
  late final ChipsInputEditingController<T> controller;

  String _previousText = '';
  TextSelection? _previousSelection;

  @override
  void initState() {
    super.initState();

    controller = ChipsInputEditingController<T>(
      <T>[...widget.values],
      widget.chipBuilder,
    );
    controller.addListener(_textListener);
  }

  @override
  void dispose() {
    controller.removeListener(_textListener);
    controller.dispose();

    super.dispose();
  }

  void _textListener() {
    final String currentText = controller.text;

    if (_previousSelection != null) {
      final int currentNumber = countReplacements(currentText);
      final int previousNumber = countReplacements(_previousText);

      final int cursorEnd = _previousSelection!.extentOffset;
      final int cursorStart = _previousSelection!.baseOffset;

      final List<T> values = <T>[...widget.values];

      // If the current number and the previous number of replacements are different, then
      // the user has deleted the InputChip using the keyboard. In this case, we trigger
      // the onChanged callback. We need to be sure also that the current number of
      // replacements is different from the input chip to avoid double-deletion.
      if (currentNumber < previousNumber && currentNumber != values.length) {
        if (cursorStart == cursorEnd) {
          values.removeRange(cursorStart - 1, cursorEnd);
        } else {
          if (cursorStart > cursorEnd) {
            values.removeRange(cursorEnd, cursorStart);
          } else {
            values.removeRange(cursorStart, cursorEnd);
          }
        }
        widget.onChanged(values);
      }
    }

    _previousText = currentText;
    _previousSelection = controller.selection;
  }

  static int countReplacements(String text) {
    return text.codeUnits
        .where(
            (int u) => u == ChipsInputEditingController.kObjectReplacementChar)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    controller.updateValues(<T>[...widget.values]);

    return TextField(
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      style: widget.style,
      strutStyle: widget.strutStyle,
      inputFormatters: widget.inputFormatters,
      controller: controller,
      onChanged: (String value) =>
          widget.onTextChanged?.call(controller.textWithoutReplacements),
      onSubmitted: (String value) =>
          widget.onSubmitted?.call(controller.textWithoutReplacements),
      decoration: widget.decoration,
    );
  }
}

class ChipsInputEditingController<T> extends TextEditingController {
  ChipsInputEditingController(this.values, this.chipBuilder)
      : super(
          text: String.fromCharCode(kObjectReplacementChar) * values.length,
        );

  // This constant character acts as a placeholder in the TextField text value.
  // There will be one character for each of the InputChip displayed.
  static const int kObjectReplacementChar = 0xFFFE;

  List<T> values;

  final Widget Function(BuildContext context, T data) chipBuilder;

  /// Called whenever chip is either added or removed
  /// from the outside the context of the text field.
  void updateValues(List<T> values) {
    if (values.length != this.values.length) {
      final String char = String.fromCharCode(kObjectReplacementChar);
      final int length = values.length;
      value = TextEditingValue(
        text: char * length,
        selection: TextSelection.collapsed(offset: length),
      );
      this.values = values;
    }
  }

  String get textWithoutReplacements {
    final String char = String.fromCharCode(kObjectReplacementChar);
    return text.replaceAll(RegExp(char), '');
  }

  String get textWithReplacements => text;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final Iterable<WidgetSpan> chipWidgets =
        values.map((T v) => WidgetSpan(child: chipBuilder(context, v)));

    return TextSpan(
      style: style,
      children: <InlineSpan>[
        ...chipWidgets,
        if (textWithoutReplacements.isNotEmpty)
          TextSpan(text: textWithoutReplacements)
      ],
    );
  }
}
