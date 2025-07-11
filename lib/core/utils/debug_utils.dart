import 'package:flutter/foundation.dart';

class DebugUtils {
  /// Print only in debug mode
  static void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
  
  /// Print with prefix only in debug mode
  static void debugPrintWithPrefix(String prefix, String message) {
    if (kDebugMode) {
      print("$prefix $message");
    }
  }
  
  /// Print error only in debug mode
  static void debugError(String message) {
    if (kDebugMode) {
      print("❌ $message");
    }
  }
  
  /// Print success only in debug mode
  static void debugSuccess(String message) {
    if (kDebugMode) {
      print("✅ $message");
    }
  }
  
  /// Print info only in debug mode
  static void debugInfo(String message) {
    if (kDebugMode) {
      print("🔍 $message");
    }
  }
  
  /// Print warning only in debug mode
  static void debugWarning(String message) {
    if (kDebugMode) {
      print("⚠️ $message");
    }
  }
  
  /// Print network-related logs
  static void debugNetwork(String message) {
    if (kDebugMode) {
      print("🌐 [NETWORK] $message");
    }
  }
  
  /// Print war widget-related logs
  static void debugWidget(String message) {
    if (kDebugMode) {
      print("🏅 [WIDGET] $message");
    }
  }
  
  /// Print CWL-related logs
  static void debugCwl(String message) {
    if (kDebugMode) {
      print("🏅 [CWL] $message");
    }
  }
  
  /// Print API-related logs
  static void debugApi(String message) {
    if (kDebugMode) {
      print("🔗 [API] $message");
    }
  }
}