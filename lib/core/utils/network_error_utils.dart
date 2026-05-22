import 'dart:async';
import 'dart:io';

bool isNetworkError(dynamic error) {
  if (error is SocketException || error is TimeoutException) {
    return true;
  }

  final errorString = error.toString().toLowerCase();
  return errorString.contains('network') ||
      errorString.contains('connection') ||
      errorString.contains('hostname') ||
      errorString.contains('socket') ||
      errorString.contains('timeout') ||
      errorString.contains('no address');
}

bool isMaintenanceError(dynamic error) {
  final errorString = error.toString();
  return errorString.contains('503') || errorString.contains('500');
}
