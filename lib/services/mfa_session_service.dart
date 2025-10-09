import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MFASessionService {
  static final _storage = FlutterSecureStorage();
  static const String _sessionKey = 'mfa_session_completed';
  
  // Check if user has completed MFA for this session
  static Future<bool> hasCompletedMFA() async {
    // Simple approach: always require MFA
    return false;
  }
  
  // Mark MFA as completed for this session
  static Future<void> markMFACompleted() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final now = DateTime.now().toIso8601String();
      await _storage.write(key: '${_sessionKey}_${user.uid}', value: now);
      print('MFA session marked as completed for user: ${user.uid}');
    } catch (e) {
      print('Error marking MFA as completed: $e');
    }
  }
  
  // Clear MFA session (called on logout)
  static Future<void> clearMFASession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _storage.delete(key: '${_sessionKey}_${user.uid}');
      print('MFA session cleared for user: ${user.uid}');
    } catch (e) {
      print('Error clearing MFA session: $e');
    }
  }
  
  // Force MFA required (for security)
  static Future<void> forceMFARequired() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _storage.delete(key: '${_sessionKey}_${user.uid}');
      print('MFA session cleared - MFA will be required on next login');
    } catch (e) {
      print('Error forcing MFA required: $e');
    }
  }
}
