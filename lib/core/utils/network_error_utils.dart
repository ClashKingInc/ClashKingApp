import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

bool isNetworkError(dynamic error) {
  // Typed checks first (most reliable)
  if (error is SocketException || error is TimeoutException) {
    return true;
  }
  // http.ClientException covers Flutter web network failures (XHR/fetch errors)
  if (error is http.ClientException) {
    return true;
  }

  final errorString = error.toString().toLowerCase();
  return errorString.contains('network') ||
      errorString.contains('connection') ||
      errorString.contains('hostname') ||
      errorString.contains('socket') ||
      errorString.contains('timeout') ||
      errorString.contains('no address') ||
      errorString.contains('xmlhttprequest') ||
      errorString.contains('failed to fetch');
}

bool isMaintenanceError(dynamic error) {
  final errorString = error.toString();
  return errorString.contains('503') || errorString.contains('500');
}
