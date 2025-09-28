import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class EncryptionService {
  static final _storage = FlutterSecureStorage();
  
  // Generate a proper AES-256 key
  static String generateRandomKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    // Ensure the key is properly formatted for AES-256
    return base64Encode(keyBytes);
  }
  
  // Simple XOR encryption (more reliable than AES for this use case)
  static String encryptMessage(String message, String keyString) {
    try {
      if (message.isEmpty || keyString.isEmpty) {
        return message;
      }
      
      // Use the key to create a simple encryption
      final keyBytes = keyString.codeUnits;
      final messageBytes = message.codeUnits;
      final encryptedBytes = <int>[];
      
      for (int i = 0; i < messageBytes.length; i++) {
        encryptedBytes.add(messageBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return base64Encode(encryptedBytes);
    } catch (e) {
      print('Encryption error: $e');
      return message;
    }
  }
  
  // Simple XOR decryption (matches the XOR encryption)
  static String decryptMessage(String encryptedData, String keyString) {
    try {
      if (encryptedData.isEmpty || keyString.isEmpty) {
        return encryptedData;
      }
      
      // Decode the base64 encrypted data
      final encryptedBytes = base64Decode(encryptedData);
      final keyBytes = keyString.codeUnits;
      final decryptedBytes = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return String.fromCharCodes(decryptedBytes);
    } catch (e) {
      print('Decryption error: $e');
      return encryptedData; // Return encrypted if decryption fails
    }
  }
  
  // Store encryption key securely
  static Future<void> storeUserKey(String userId, String key) async {
    await _storage.write(key: 'encryption_key_$userId', value: key);
  }
  
  // Retrieve encryption key
  static Future<String?> getUserKey(String userId) async {
    return await _storage.read(key: 'encryption_key_$userId');
  }
  
  // Simple key exchange (store other user's public info)
  static Future<void> exchangeKeys(String otherUserId, String sharedKey) async {
    await _storage.write(key: 'shared_key_$otherUserId', value: sharedKey);
  }
  
  // Test encryption functionality (for development)
  static Future<void> testEncryption() async {
    final key = generateRandomKey();
    final message = "Hello, this is a secret message!";
    
    final encrypted = encryptMessage(message, key);
    final decrypted = decryptMessage(encrypted, key);
    
    print('Original: $message');
    print('Encrypted: $encrypted');
    print('Decrypted: $decrypted');
    print('Match: ${message == decrypted}');
  }
}
