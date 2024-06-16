import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

class ClanSearchFilters extends StatefulWidget {
  @override
  ClanSearchFiltersState createState() => ClanSearchFiltersState();
}

class ClanSearchFiltersState extends State<ClanSearchFilters> {
  String warfrequency = 'whatever'; // Initial war frequency
  String location = 'any'; // Initial location
  String minimumMembers = '0'; // Initial minimum members
  String maximumMembers = '50'; // Initial maximum members
  String minimumClanPoints = '0'; // Initial minimum clan points
  String minimumClanLevel = '0'; // Initial minimum clan level
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controllerMin = TextEditingController(text: "2");
  final TextEditingController _controllerMax =
      TextEditingController(text: "50");
  final TextEditingController _controllerPoints =
      TextEditingController(text: "1");
  final TextEditingController _controllerLevel =
      TextEditingController(text: "2");
  List _countries = [];
  int? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    final response =
        await http.get(Uri.parse('https://api.clashking.xyz/v1/locations'));
    if (response.statusCode == 200) {
      final List items = json.decode(utf8.decode(response.bodyBytes))['items'];
      final countries = items.where((item) => item["name"] != "").toList();
      setState(() {
        _countries = countries;
        if (_countries.isNotEmpty) {
          _selectedCountry = 0;
        }
      });
    } else {
      throw Exception('Failed to load countries');
    }
  }

  void _incrementMin() {
    int currentValue = int.parse(_controllerMin.text);
    if (currentValue < 50) {
      _controllerMin.text = (currentValue + 1).toString();
    }
  }

  void _decrementMin() {
    int currentValue = int.parse(_controllerMin.text);
    if (currentValue > 2) {
      _controllerMin.text = (currentValue - 1).toString();
    }
  }

  void _incrementMax() {
    int currentValue = int.parse(_controllerMax.text);
    if (currentValue < 50) {
      _controllerMax.text = (currentValue + 1).toString();
    }
  }

  void _decrementMax() {
    int currentValue = int.parse(_controllerMax.text);
    if (currentValue > 0) {
      _controllerMax.text = (currentValue - 1).toString();
    }
  }

  void _incrementPoints() {
    int currentValue = int.parse(_controllerPoints.text);
    if (currentValue == 1) {
      _controllerPoints.text = (currentValue + 999).toString();
    } else if (currentValue < 1000000) {
      _controllerPoints.text = (currentValue + 1000).toString();
    }
  }

  void _decrementPoints() {
    int currentValue = int.parse(_controllerPoints.text);
    if (currentValue > 1) {
      _controllerPoints.text = (currentValue - 1000).toString();
    }
  }

  void _incrementLevel() {
    int currentValue = int.parse(_controllerLevel.text);
    if (currentValue < 1000000) {
      _controllerLevel.text = (currentValue + 1).toString();
    }
  }

  void _decrementLevel() {
    int currentValue = int.parse(_controllerLevel.text);
    if (currentValue > 2) {
      _controllerLevel.text = (currentValue - 1).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> warFrequencyItems = [
      DropdownMenuItem(
          value: 'whatever',
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.notSet)),
      DropdownMenuItem(
          value: 'always',
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.always)),
      DropdownMenuItem(
          value: 'never',
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.never)),
      DropdownMenuItem(
          value: 'oncePerWeek',
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.oncePerWeek)),
      DropdownMenuItem(
          value: 'moreThanOncePerWeek',
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.twicePerWeek)),
      DropdownMenuItem(
          value: 'lessThanOncePerWeek',
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context)!.rarely)),
    ];

    return AlertDialog(
      insetPadding: EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(AppLocalizations.of(context)!.filters,
          textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.warFrequency,
                        style: Theme.of(context).textTheme.bodyMedium),
                    DropdownButton<String>(
                      value: warfrequency,
                      elevation: 16,
                      alignment: Alignment.center,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      underline: Container(),
                      onChanged: (String? newValue) {
                        setState(() {
                          warfrequency = newValue!;
                        });
                      },
                      items: warFrequencyItems,
                    ),
                  ],
                ),
              ),
              Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.location,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCountry?.toString() ?? '0',
                            elevation: 16,
                            alignment: Alignment.center,
                            dropdownColor:
                                Theme.of(context).colorScheme.surface,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                            underline: Container(),
                            items: [
                              DropdownMenuItem<String>(
                                value: '0',
                                alignment: Alignment.center,
                                child: Text(
                                    AppLocalizations.of(context)!.notSet),
                              ),
                              ..._countries.map<DropdownMenuItem<String>>(
                                (item) {
                                  return DropdownMenuItem<String>(
                                    value: item['id'].toString(),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        item["isCountry"] == true
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    "https://clashkingfiles.b-cdn.net/country-flags/${item['countryCode']}.png",
                                                width: 16,
                                                height: 20,
                                                errorWidget: (context, url,
                                                        error) =>
                                                    Icon(Icons.flag,
                                                        size: 16,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface),
                                              )
                                            : Icon(Icons.flag,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                        SizedBox(width: 8.0),
                                        Text(item['name'],
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCountry = newValue == 'none'
                                    ? null
                                    : int.parse(newValue!);
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.members,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Row(
                      children: [
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            padding: EdgeInsets.only(right: 8),
                            icon: Icon(Icons.remove,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _decrementMin,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: _controllerMin,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.minimumMembers,
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return null; // valid if field is empty
                              }
                              int? number = int.tryParse(value);
                              if (number == null || number < 0 || number > 50) {
                                return 'Must be between 0 and 50';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              minimumMembers = value!.isEmpty ? "" : value;
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(Icons.add,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _incrementMin,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.remove,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 16),
                          onPressed: _decrementMax,
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: _controllerMax,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.maximumMembers,
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return null; // valid if field is empty
                              }
                              int? number = int.tryParse(value);
                              if (number == null || number < 0 || number > 50) {
                                return 'Must be between 0 and 50';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              maximumMembers = value!.isEmpty ? "" : value;
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(Icons.add,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _incrementMax,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.minimumClanPoints,
                        style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            padding: EdgeInsets.only(right: 8),
                            icon: Icon(Icons.remove,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _decrementPoints,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: _controllerPoints,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.minimumMembers,
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return null; // valid if field is empty
                              }
                              int? number = int.tryParse(value);
                              if (number == null ||
                                  number < 0 ||
                                  number > 100000) {
                                return 'Must be between 0 and 50';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              minimumClanPoints = value!.isEmpty ? "" : value;
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(Icons.add,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _incrementPoints,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.minimumClanLevel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            padding: EdgeInsets.only(right: 8),
                            icon: Icon(Icons.remove,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _decrementLevel,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: _controllerLevel,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.minimumMembers,
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return null; // valid if field is empty
                              }
                              int? number = int.tryParse(value);
                              if (number == null ||
                                  number < 0 ||
                                  number > 100000) {
                                return 'Must be between 0 and 50';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              minimumClanLevel = value!.isEmpty ? "" : value;
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(Icons.add,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16),
                            onPressed: _incrementLevel,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.apply),
          onPressed: () {
            String query = "";
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              if (warfrequency != "whatever") {
                query += "&warFrequency=$warfrequency";
              }
              if (minimumMembers != "") {
                query += "&minMembers=$minimumMembers";
              }
              if (maximumMembers != "") {
                query += "&maxMembers=$maximumMembers";
              }
              if (minimumClanPoints != "") {
                query += "&minClanPoints=$minimumClanPoints";
              }
              if (minimumClanLevel != "") {
                query += "&minClanLevel=$minimumClanLevel";
              }
              if (_selectedCountry != 0) {
                query += "&locationId=$_selectedCountry";
              }
              Navigator.of(context).pop(query);
            }
          },
        ),
      ],
    );
  }
}
