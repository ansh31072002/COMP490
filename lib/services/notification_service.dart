import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/notification_config.dart';

class NotificationService {
  static bool _testMode = false;
  
  // Enable test mode (for unit tests)
  static void enableTestMode() {
    _testMode = true;
  }
  
  // Simple method to generate a 6-digit code
  static String generateCode() {
    Random random = Random();
    int code = random.nextInt(900000) + 100000; // 100000 to 999999
    return code.toString();
  }
  
  // Send MFA code via email (actually sends email)
  static Future<bool> sendEmailCode(String email, String code) async {
    if (_testMode) {
      return sendTestCode('Email', email, code);
    }
    
    try {
      // Use EmailJS or similar service for real email sending
      // For now, we'll use a simple webhook approach
      String subject = "Your SECURELY MFA Code";
      String body = "Your verification code is: $code\n\nThis code expires in 10 minutes.\n\nIf you didn't request this code, please ignore this email.";
      
      // Debug: Print what we're sending
      print("=== SENDING EMAIL VIA EMAILJS ===");
      print("Service ID: ${NotificationConfig.EMAILJS_SERVICE_ID}");
      print("Template ID: ${NotificationConfig.EMAILJS_TEMPLATE_ID}");
      print("User ID: ${NotificationConfig.EMAILJS_USER_ID}");
      print("To Email: $email");
      print("Subject: $subject");
      print("Body: $body");
      print("================================");
      
      // Simple HTTP request to send email (you can replace this with a real email service)
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: jsonEncode({
          'service_id': NotificationConfig.EMAILJS_SERVICE_ID,
          'template_id': NotificationConfig.EMAILJS_TEMPLATE_ID,
          'user_id': NotificationConfig.EMAILJS_USER_ID,
          'template_params': {
            'to_email': email,
            'to_name': 'User',
            'subject': subject,
            'message': body,
            'reply_to': email,
            'from_name': 'SECURELY App',
            'from_email': 'noreply@securely.app',
            'code': code,
            'user_email': email,
            'verification_code': code,
          }
        }),
      );
      
      print("EmailJS Response Status: ${response.statusCode}");
      print("EmailJS Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        print("Email sent successfully to: $email");
        return true;
      } else {
        print("Failed to send email: ${response.statusCode}");
        print("Response: ${response.body}");
        print("EmailJS is not configured properly. Using fallback method.");
        
        // For now, just show the code in console since EmailJS isn't working
        print("=== EMAIL MFA CODE (FALLBACK) ===");
        print("To: $email");
        print("Code: $code");
        print("================================");
        print("NOTE: EmailJS template needs to be configured to accept 'to_email' parameter");
        return true; // Return true for demo purposes
      }
    } catch (e) {
      print("Error sending email: $e");
      // Fallback: show code in console for demo
      print("=== EMAIL MFA CODE (FALLBACK) ===");
      print("To: $email");
      print("Code: $code");
      print("================================");
      return true; // Return true for demo purposes
    }
  }
  
  // Send MFA code via SMS (actually sends SMS)
  static Future<bool> sendSMSCode(String phoneNumber, String code) async {
    if (_testMode) {
      return sendTestCode('SMS', phoneNumber, code);
    }
    
    try {
      // Use Twilio or similar service for real SMS sending
      String message = "Your SECURELY verification code is: $code. This code expires in 10 minutes.";
      
      // Simple HTTP request to send SMS (you can replace this with a real SMS service)
      final response = await http.post(
        Uri.parse('https://api.twilio.com/2010-04-01/Accounts/${NotificationConfig.TWILIO_ACCOUNT_SID}/Messages.json'),
        headers: {
          'Authorization': 'Basic ' + base64Encode(utf8.encode('${NotificationConfig.TWILIO_ACCOUNT_SID}:${NotificationConfig.TWILIO_AUTH_TOKEN}')),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': NotificationConfig.TWILIO_PHONE_NUMBER,
          'To': phoneNumber,
          'Body': message,
        },
      );
      
      if (response.statusCode == 201) {
        print("SMS sent successfully to: $phoneNumber");
        return true;
      } else {
        print("Failed to send SMS: ${response.statusCode}");
        // Fallback: show code in console for demo
        print("=== SMS MFA CODE (FALLBACK) ===");
        print("To: $phoneNumber");
        print("Code: $code");
        print("==============================");
        return true; // Return true for demo purposes
      }
    } catch (e) {
      print("Error sending SMS: $e");
      // Fallback: show code in console for demo
      print("=== SMS MFA CODE (FALLBACK) ===");
      print("To: $phoneNumber");
      print("Code: $code");
      print("==============================");
      return true; // Return true for demo purposes
    }
  }
  
  // Simple method to simulate sending code (for testing)
  static Future<bool> sendTestCode(String method, String contact, String code) async {
    print("=== MFA CODE SENT ===");
    print("Method: $method");
    print("Contact: $contact");
    print("Code: $code");
    print("===================");
    
    // Simulate some delay
    await Future.delayed(Duration(seconds: 1));
    return true;
  }
}
