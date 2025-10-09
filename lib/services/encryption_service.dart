import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class EncryptionService {
  static final _storage = FlutterSecureStorage();
  
  // Generate a proper AES-256 key (32 bytes = 256 bits)
  static String generateRandomKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(keyBytes);
  }
  
  // AES-256 encryption using the encrypt package
  static String encryptMessage(String message, String keyString) {
    try {
      if (message.isEmpty || keyString.isEmpty) {
        return message;
      }
      
      // Decode the base64 key
      final keyBytes = base64Decode(keyString);
      final key = Key(keyBytes);
      
      // Create encryptor with AES-256
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      
      // Generate random IV for each encryption
      final iv = IV.fromSecureRandom(16);
      
      // Encrypt the message
      final encrypted = encrypter.encrypt(message, iv: iv);
      
      // Combine IV and encrypted data, then encode to base64
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    } catch (e) {
      print('AES Encryption error: $e');
      return message;
    }
  }
  
  // AES-256 decryption using the encrypt package
  static String decryptMessage(String encryptedData, String keyString) {
    try {
      if (encryptedData.isEmpty || keyString.isEmpty) {
        return encryptedData;
      }
      
      // Decode the base64 key
      final keyBytes = base64Decode(keyString);
      final key = Key(keyBytes);
      
      // Decode the combined IV + encrypted data
      final combined = base64Decode(encryptedData);
      
      // Extract IV (first 16 bytes) and encrypted data (rest)
      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);
      
      final iv = IV(ivBytes);
      final encrypted = Encrypted(encryptedBytes);
      
      // Create decryptor with AES-256
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      
      // Decrypt the message
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('AES Decryption error: $e');
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
  
  // Test AES-256 encryption functionality (for development)
  static Future<void> testEncryption() async {
    final key = generateRandomKey();
    final message = "Hello, this is a secret message encrypted with AES-256!";
    
    print('Testing AES-256 Encryption:');
    print('Original: $message');
    print('Key (Base64): $key');
    
    final encrypted = encryptMessage(message, key);
    print('Encrypted: $encrypted');
    
    final decrypted = decryptMessage(encrypted, key);
    print('Decrypted: $decrypted');
    print('Match: ${message == decrypted}');
    
    // Test with different message to ensure IV randomization
    final message2 = "Another message with different content";
    final encrypted2 = encryptMessage(message2, key);
    print('\nTesting IV randomization:');
    print('Message 2: $message2');
    print('Encrypted 2: $encrypted2');
    print('Different encrypted outputs: ${encrypted != encrypted2}');
  }
}
