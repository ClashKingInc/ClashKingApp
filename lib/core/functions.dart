import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:collection/collection.dart';

Future<bool> isTokenValid() async {
  String? expirationDateString = await getPrefs('expiration_date');
  print(expirationDateString);

  if (expirationDateString != null) {
    DateTime expirationDate = DateTime.parse(expirationDateString);
    return DateTime.now().isBefore(expirationDate);
  }

  return false;
}

final storage = FlutterSecureStorage();

Future<void> storePrefs(String name, String token) async {
  try {
    print("Starting to store prefs for: $name");

    // Load the keys from the .env file
    final encryptionKey = Key.fromBase64(
        dotenv.env['ENCRYPTION_KEY']!); // 32 bytes key for AES-256
    final hmacKey = base64.decode(dotenv.env['HMAC_KEY']!); // Key for HMAC

    if (encryptionKey.bytes.length != 32) {
      throw Exception(
          'Invalid encryption key length: ${encryptionKey.bytes.length}');
    }

    if (hmacKey.length != 32) {
      throw Exception('Invalid HMAC key length: ${hmacKey.length}');
    }

    // Encrypt the token
    final iv = IV.fromLength(16); // Initialization vector
    final encrypter = Encrypter(AES(encryptionKey, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(token, iv: iv);

    // Combine IV and encrypted data for HMAC
    final combinedData = iv.bytes + encrypted.bytes;

    // Compute HMAC for integrity
    final hmac = Hmac(sha256, hmacKey);
    final hmacDigest = hmac.convert(combinedData).bytes;

    // Combine IV, encrypted data, and HMAC for storage
    final combined = base64.encode(combinedData + hmacDigest);

    print("Combined data for $name: $combined");

    // Store the combined data
    await storage.write(key: name, value: combined);

    print("Successfully stored prefs for: $name");
  } catch (e) {
    print("Error storing prefs for $name: $e");
  }
}

Future<String?> getPrefs(String name) async {
  try {
    print("Retrieving prefs for: $name");

    // Retrieve the combined data
    final combined = await storage.read(key: name);
    if (combined == null) {
      print("No data found for key: $name");
      return null;
    }

    print("Combined data for $name: $combined");

    final data = base64.decode(combined);
    print("Decoded data length: ${data.length}");

    // Extract IV, encrypted data, and HMAC
    final iv = IV(data.sublist(0, 16));
    final encryptedData = data.sublist(16, data.length - 32);
    final hmacDigest = data.sublist(data.length - 32);

    print("IV: ${iv.bytes}");
    print("Encrypted data length: ${encryptedData.length}");
    print("Stored HMAC digest: $hmacDigest");

    // Combine IV and encrypted data for HMAC
    final combinedData = iv.bytes + encryptedData;

    // Verify HMAC
    final hmacKey = base64.decode(dotenv.env['HMAC_KEY']!); // Key for HMAC
    final hmac = Hmac(sha256, hmacKey);
    final newHmacDigest =
        hmac.convert(combinedData).bytes; // Use IV + encryptedData

    print("Computed HMAC digest: $newHmacDigest");

    if (!ListEquality().equals(hmacDigest, newHmacDigest)) {
      throw Exception('HMAC verification failed');
    }

    // Decrypt the access token
    final encryptionKey = Key.fromBase64(
        dotenv.env['ENCRYPTION_KEY']!); // 32 bytes key for AES-256
    final encrypter = Encrypter(AES(encryptionKey, mode: AESMode.cbc));
    final encrypted = Encrypted(encryptedData);

    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    print("Decrypted data: $decrypted");

    return decrypted;
  } catch (e) {
    print("Error retrieving prefs for $name: $e");
    return null;
  }
}

Future<void> clearPrefs() async {
  await storage.deleteAll();
}
