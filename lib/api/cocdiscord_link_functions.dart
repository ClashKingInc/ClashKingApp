import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

Future<String> login() async {
  final url = Uri.parse('https://cocdiscord.link/login');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'username': dotenv.env['DISCORDCOC_LOGIN']!,
      'password': dotenv.env['DISCORDCOC_PASSWORD']!,
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['token'];
  } else {
    throw Exception('Failed to login with status code: ${response.statusCode}');
  }
}

Future<bool> addLink(String playerTag, String discordId, String authToken,
    Function updateErrorMessage, String playerTagNotExists, String accountAlreadyLinked, String failedToAddTryAgain) async {

  final url = Uri.parse('https://cocdiscord.link/links');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application',
      'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode(<String, dynamic>{
      'playerTag': playerTag,
      'discordId': discordId,
    }),
  );

  if (response.statusCode == 200) {
    print("Link added successfully.");
    updateErrorMessage('');
    return true;
  } else if (response.statusCode == 400) {
    updateErrorMessage(playerTagNotExists);
  } else if (response.statusCode == 409) {
    updateErrorMessage(accountAlreadyLinked);
  } else {
    updateErrorMessage(failedToAddTryAgain);
  }
  return false;
}

Future<bool> deleteLink(String playerTag, String authToken,
    Function updateErrorMessage, String failedToDeleteTryAgain) async {
  playerTag = playerTag.replaceAll('#', '');
  final url = Uri.parse('https://cocdiscord.link/links/$playerTag');
  final response = await http.delete(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
  );

  if (response.statusCode == 200) {
    print("Link deleted successfully.");
    updateErrorMessage('');
    return true;
  }
  {
    updateErrorMessage(failedToDeleteTryAgain);
  }
  return false;
}

Future<bool> getLinks(
    String playerTag, String authToken) async {
  playerTag = playerTag.replaceAll('#', '');
  final url = Uri.parse('https://cocdiscord.link/links/$playerTag');
  final response = await http.get(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
  );

  if (response.statusCode == 404) {
    return true;
  }
  return false;
}

Future<String> checkIfPlayerTagExists(
    String playerTag, String authToken, BuildContext context) async {
  playerTag = playerTag.replaceAll('#', '');
  final response = await http.get(
    Uri.parse('https://api.clashking.xyz/v1/clans/$playerTag'),
  );

  if (response.statusCode == 200) {
    if (await getLinks(playerTag, authToken)) {
      return "Ok";
    } else {
      return "alreadyLinked";
    }
  } else {
    return "notExist";
  }
}
