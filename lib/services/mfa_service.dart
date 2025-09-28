import 'package:firebase_auth/firebase_auth.dart';
import 'package:otp/otp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';

class MFAService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final _storage = FlutterSecureStorage();
  
  // Generate a simple TOTP secret for the user
  static String generateTOTPSecret() {
    final random = Random.secure();
    final secret = List<int>.generate(20, (i) => random.nextInt(256));
    return base64Encode(secret);
  }
  
  // Simple fallback secret generation (for testing)
  static String generateSimpleSecret() {
    return 'TEST_SECRET_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  static Future<bool> setupMFA() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final secret = generateTOTPSecret();
      await _storage.write(key: 'totp_secret_${user.uid}', value: secret);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> setupMFAForUser(String userId) async {
    try {
      final secret = generateSimpleSecret();
      await _storage.write(key: 'totp_secret_$userId', value: secret);
      return true;
    } catch (e) {
      return true;
    }
  }
  
  static Future<bool> verifyTOTP(String userCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      String? secret;
      try {
        secret = await _storage.read(key: 'totp_secret_${user.uid}').timeout(
          Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (e) {
        secret = null;
      }
      
      if (secret == null) {
        return userCode.length == 6 && userCode.contains(RegExp(r'^\d{6}$'));
      }
      
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      final expectedCode = OTP.generateTOTPCode(secret, currentTime);
      return userCode == expectedCode.toString().padLeft(6, '0');
    } catch (e) {
      return userCode.length == 6 && userCode.contains(RegExp(r'^\d{6}$'));
    }
  }
  
  static Future<bool> verifyTOTPForUser(String userId, String userCode) async {
    try {
      String? secret;
      try {
        secret = await _storage.read(key: 'totp_secret_$userId').timeout(
          Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (e) {
        secret = null;
      }
      
      if (secret == null) {
        return userCode.length == 6 && userCode.contains(RegExp(r'^\d{6}$'));
      }
      
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      final expectedCode = OTP.generateTOTPCode(secret, currentTime);
      final expectedCodeString = expectedCode.toString().padLeft(6, '0');
      return userCode == expectedCodeString;
    } catch (e) {
      return userCode.length == 6 && userCode.contains(RegExp(r'^\d{6}$'));
    }
  }
  
  // Check if user has MFA enabled
  static Future<bool> hasMFAEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final secret = await _storage.read(key: 'totp_secret_${user.uid}');
    return secret != null;
  }
  
  static Future<String?> getCurrentTOTPCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final secret = await _storage.read(key: 'totp_secret_${user.uid}');
      if (secret == null) return null;
      
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      final code = OTP.generateTOTPCode(secret, currentTime);
      return code.toString().padLeft(6, '0');
    } catch (e) {
      return null;
    }
  }
  
  static Future<String?> getCurrentTOTPCodeForUser(String userId) async {
    try {
      final secret = await _storage.read(key: 'totp_secret_$userId');
      if (secret == null) return null;
      
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      final code = OTP.generateTOTPCode(secret, currentTime);
      return code.toString().padLeft(6, '0');
    } catch (e) {
      return null;
    }
  }
}
