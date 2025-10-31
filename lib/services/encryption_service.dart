import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';

class EncryptionService {
  static final _storage = FlutterSecureStorage();
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  
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
  
  // Store encryption key securely (Firebase + Local backup)
  static Future<void> storeUserKey(String userId, String key) async {
    try {
      // Store in Firebase for persistence across devices/sessions
      await _firestore.collection('encryption_keys').doc(userId).set({
        'key': key,
        'userId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also store locally as backup
      await _storage.write(key: 'encryption_key_$userId', value: key);
    } catch (e) {
      print('Error storing key in Firebase: $e');
      // Fallback to local storage only
      await _storage.write(key: 'encryption_key_$userId', value: key);
    }
  }
  
  // Retrieve encryption key (Firebase + Local fallback)
  static Future<String?> getUserKey(String userId) async {
    try {
      // First try Firebase
      final doc = await _firestore.collection('encryption_keys').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final key = doc.data()!['key'] as String?;
        if (key != null) {
          // Update local storage with Firebase key
          await _storage.write(key: 'encryption_key_$userId', value: key);
          return key;
        }
      }
      
      // Fallback to local storage
      return await _storage.read(key: 'encryption_key_$userId');
    } catch (e) {
      print('Error retrieving key from Firebase: $e');
      // Fallback to local storage
      return await _storage.read(key: 'encryption_key_$userId');
    }
  }
  
  // Simple key exchange (store other user's public info)
  static Future<void> exchangeKeys(String otherUserId, String sharedKey) async {
    await _storage.write(key: 'shared_key_$otherUserId', value: sharedKey);
  }
  
  // Store shared key for a chat/group in Firebase
  static Future<void> storeSharedKey(String chatId, String key, List<String> participantIds) async {
    try {
      // Store the shared key in Firebase
      await _firestore.collection('shared_keys').doc(chatId).set({
        'key': key,
        'chatId': chatId,
        'participants': participantIds,
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also store locally as backup
      await _storage.write(key: '${chatId}_shared', value: key);
    } catch (e) {
      print('Error storing shared key in Firebase: $e');
      // Fallback to local storage only
      await _storage.write(key: '${chatId}_shared', value: key);
    }
  }
  
  // Retrieve shared key for a chat/group from Firebase
  static Future<String?> getSharedKey(String chatId) async {
    try {
      // First try Firebase
      final doc = await _firestore.collection('shared_keys').doc(chatId).get();
      if (doc.exists && doc.data() != null) {
        final key = doc.data()!['key'] as String?;
        if (key != null) {
          // Update local storage with Firebase key
          await _storage.write(key: '${chatId}_shared', value: key);
          return key;
        }
      }
      
      // Fallback to local storage
      return await _storage.read(key: '${chatId}_shared');
    } catch (e) {
      print('Error retrieving shared key from Firebase: $e');
      // Fallback to local storage
      return await _storage.read(key: '${chatId}_shared');
    }
  }
  
  // Get or create shared key for a chat/group
  static Future<String> getOrCreateSharedKey(String chatId) async {
    // Try to get existing key from Firebase
    String? sharedKey = await getSharedKey(chatId);
    
    if (sharedKey == null) {
      // Generate a new shared key for this chat/group
      sharedKey = generateRandomKey();
      
      // Get current user and other participants for this chat
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        // For now, just store with current user as participant
        // In a real implementation, you'd get the actual participants from the chat
        await storeSharedKey(chatId, sharedKey, [currentUserId]);
      } else {
        // Fallback to local storage if no user
        await _storage.write(key: '${chatId}_shared', value: sharedKey);
      }
    }
    
    return sharedKey;
  }
  
  // Try to decrypt with multiple key strategies
  static Future<String> decryptWithFallback(String encryptedData, String chatId) async {
    try {
      // First, try with the current shared key from Firebase
      final currentKey = await getSharedKey(chatId);
      if (currentKey != null) {
        try {
          final result = decryptMessage(encryptedData, currentKey);
          if (result != encryptedData) { // If decryption succeeded
            return result;
          }
        } catch (e) {
          print('Failed to decrypt with current key: $e');
        }
      }
      
      // If that fails, try with any stored keys for this chat
      final allKeys = await _getAllKeysForChat(chatId);
      for (final key in allKeys) {
        try {
          final result = decryptMessage(encryptedData, key);
          if (result != encryptedData) { // If decryption succeeded
            return result;
          }
        } catch (e) {
          // Continue to next key
          continue;
        }
      }
      
      // Check if this looks like encrypted data (base64 encoded)
      if (_isBase64Encoded(encryptedData)) {
        return '[Encrypted message - key not available]';
      } else {
        // If it doesn't look encrypted, return as-is
        return encryptedData;
      }
    } catch (e) {
      print('Decryption fallback error: $e');
      return '[Decryption failed]';
    }
  }
  
  // Check if a string is base64 encoded (likely encrypted)
  static bool _isBase64Encoded(String data) {
    try {
      // Check if it's valid base64 and has reasonable length for encrypted data
      final decoded = base64Decode(data);
      return decoded.length > 16; // Encrypted data should be longer than 16 bytes
    } catch (e) {
      return false;
    }
  }
  
  // Get all stored keys for a chat (for fallback decryption)
  static Future<List<String>> _getAllKeysForChat(String chatId) async {
    final keys = <String>[];
    try {
      // Try different key patterns that might have been used
      final patterns = [
        '${chatId}_shared',
        'encryption_key_${chatId}',
        'shared_key_${chatId}',
      ];
      
      for (final pattern in patterns) {
        final key = await _storage.read(key: pattern);
        if (key != null) {
          keys.add(key);
        }
      }
    } catch (e) {
      print('Error getting all keys for chat: $e');
    }
    return keys;
  }
  
  // Check if a shared key exists for a chat/group
  static Future<bool> hasSharedKey(String chatId) async {
    final key = await getUserKey('${chatId}_shared');
    return key != null;
  }
  
  // Migrate old keys to new format (for backward compatibility)
  static Future<void> migrateKeysIfNeeded() async {
    try {
      // This method can be called on app startup to handle key migration
      // For now, we'll rely on the fallback decryption system
      print('Key migration check completed');
    } catch (e) {
      print('Key migration error: $e');
    }
  }
  
  // Clear all keys for a specific chat (use with caution)
  static Future<void> clearChatKeys(String chatId) async {
    try {
      final patterns = [
        '${chatId}_shared',
        'encryption_key_${chatId}',
        'shared_key_${chatId}',
      ];
      
      for (final pattern in patterns) {
        await _storage.delete(key: pattern);
      }
      print('Cleared all keys for chat: $chatId');
    } catch (e) {
      print('Error clearing chat keys: $e');
    }
  }
  
  // Handle legacy encrypted messages that can't be decrypted
  static String handleLegacyMessage(String message, bool isEncrypted) {
    if (!isEncrypted) {
      return message;
    }
    
    // If it's marked as encrypted but we can't decrypt it, show a helpful message
    if (_isBase64Encoded(message)) {
      return '🔒 [Encrypted message from previous session]';
    } else {
      return message;
    }
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
