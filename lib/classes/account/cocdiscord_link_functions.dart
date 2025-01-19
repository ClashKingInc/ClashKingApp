import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

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

Future<bool> addLink(
    String playerTag,
    String discordId,
    String authToken,
    Function updateErrorMessage,
    String playerTagNotExists,
    String accountAlreadyLinked,
    String failedToAddTryAgain) async {
  playerTag = playerTag.replaceAll('#', '').replaceAll('!', '');
  try{
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
    updateErrorMessage('');
    return true;
  } else if (response.statusCode == 400) {
    updateErrorMessage(playerTagNotExists);
  } else if (response.statusCode == 409) {
    updateErrorMessage(accountAlreadyLinked);
  } else {
    updateErrorMessage(failedToAddTryAgain);
  }
  }
  catch(exceptions, stackTrace){
    Sentry.captureException(exceptions, stackTrace: stackTrace);
    Sentry.captureMessage('Failed to add link, playerTag: $playerTag, discordId: $discordId');
  }
  return false;
}

Future<bool> checkApiToken(String apiToken, String playerTag, Function updateErrorMessage, String wrongApiToken) async {
  if (playerTag.startsWith('#')) {
    playerTag = playerTag.replaceAll('#', '!');
  } else if (!playerTag.startsWith('!')) {
    playerTag = '!$playerTag';
  }

  final url =
      Uri.parse('https://proxy.clashk.ing/v1/players/$playerTag/verifytoken');
  final response = await http.post(
    url,
    body: jsonEncode(<String, dynamic>{
      'token': apiToken,
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (data['status'] == 'ok') {
      return true;
    }
  }

  updateErrorMessage(wrongApiToken);
  return false;
}

Future<bool> addLinkWithAPIToken(
    String playerTag,
    String discordId,
    String authToken,
    Function updateErrorMessage,
    String playerTagNotExists,
    String accountAlreadyLinked,
    String failedToAddTryAgain,
    String apiToken,
    String failedToDeleteTryAgain,
    String wrongApiToken) async {
  bool isApiTokenValid = await checkApiToken(apiToken, playerTag, updateErrorMessage, wrongApiToken);

  if (isApiTokenValid) {
    bool deleted = await deleteLink(
        playerTag, authToken, updateErrorMessage, failedToDeleteTryAgain);
    bool added = await addLink(
        playerTag,
        discordId,
        authToken,
        updateErrorMessage,
        playerTagNotExists,
        accountAlreadyLinked,
        failedToAddTryAgain);
    return deleted && added;
  } else {
    updateErrorMessage(wrongApiToken);
    return false;
  }
}

Future<bool> deleteLink(String playerTag, String authToken,
    Function updateErrorMessage, String failedToDeleteTryAgain) async {
  playerTag = playerTag.replaceAll('#', '').replaceAll('!', '');
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
    updateErrorMessage('');
    return true;
  }
  {
    updateErrorMessage(failedToDeleteTryAgain);
  }
  return false;
}

Future<bool> getLinks(String playerTag, String authToken) async {
  playerTag = playerTag.replaceFirst('#', '').replaceFirst("!", "");
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
    String playerTag, String authToken) async {
  playerTag = playerTag.replaceAll('#', '!');
  final response = await http.get(
    Uri.parse('https://proxy.clashk.ing/v1/players/$playerTag'),
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
