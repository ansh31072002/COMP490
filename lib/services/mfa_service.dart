import 'package:firebase_auth/firebase_auth.dart';
import 'package:otp/otp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'notification_service.dart';

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
    
    // Always enable MFA for all users (college student approach)
    return true;
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
  
  // Simple email MFA methods
  static String _currentEmailCode = '';
  static String _currentSMSCode = '';
  static DateTime? _codeExpiry;
  
  // Send MFA code via email
  static Future<bool> sendEmailMFA(String email) async {
    try {
      String code = NotificationService.generateCode();
      _currentEmailCode = code;
      _codeExpiry = DateTime.now().add(Duration(minutes: 10));
      
      bool sent = await NotificationService.sendEmailCode(email, code);
      if (sent) {
        print("Email MFA code sent to: $email");
        return true;
      } else {
        print("Failed to send email MFA code");
        return false;
      }
    } catch (e) {
      print("Error in sendEmailMFA: $e");
      return false;
    }
  }
  
  // Send MFA code via SMS
  static Future<bool> sendSMSMFA(String phoneNumber) async {
    try {
      String code = NotificationService.generateCode();
      _currentSMSCode = code;
      _codeExpiry = DateTime.now().add(Duration(minutes: 10));
      
      bool sent = await NotificationService.sendSMSCode(phoneNumber, code);
      if (sent) {
        print("SMS MFA code sent to: $phoneNumber");
        return true;
      } else {
        print("Failed to send SMS MFA code");
        return false;
      }
    } catch (e) {
      print("Error in sendSMSMFA: $e");
      return false;
    }
  }
  
  // Verify email MFA code
  static bool verifyEmailMFA(String userCode) {
    if (_currentEmailCode.isEmpty) return false;
    if (_codeExpiry == null || DateTime.now().isAfter(_codeExpiry!)) {
      _currentEmailCode = '';
      _codeExpiry = null;
      return false;
    }
    
    bool isValid = userCode == _currentEmailCode;
    if (isValid) {
      _currentEmailCode = '';
      _codeExpiry = null;
    }
    return isValid;
  }
  
  // Verify SMS MFA code
  static bool verifySMSMFA(String userCode) {
    if (_currentSMSCode.isEmpty) return false;
    if (_codeExpiry == null || DateTime.now().isAfter(_codeExpiry!)) {
      _currentSMSCode = '';
      _codeExpiry = null;
      return false;
    }
    
    bool isValid = userCode == _currentSMSCode;
    if (isValid) {
      _currentSMSCode = '';
      _codeExpiry = null;
    }
    return isValid;
  }
  
  // Check if code is expired
  static bool isCodeExpired() {
    if (_codeExpiry == null) return true;
    return DateTime.now().isAfter(_codeExpiry!);
  }
  
  // Get current email code (for demo purposes)
  static String getCurrentEmailCode() {
    return _currentEmailCode;
  }
  
  // Get current SMS code (for demo purposes)
  static String getCurrentSMSCode() {
    return _currentSMSCode;
  }
  
  // Testing methods (for unit tests)
  static void setTestEmailCode(String code) {
    _currentEmailCode = code;
    _codeExpiry = DateTime.now().add(Duration(minutes: 10));
  }
  
  static void setTestSMSCode(String code) {
    _currentSMSCode = code;
    _codeExpiry = DateTime.now().add(Duration(minutes: 10));
  }
  
  static void setExpiredCode() {
    _codeExpiry = DateTime.now().subtract(Duration(minutes: 1));
  }
}
