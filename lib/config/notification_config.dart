class NotificationConfig {
  // Email service configuration
  static const String EMAILJS_SERVICE_ID = 'service_8x9lgec';
  static const String EMAILJS_TEMPLATE_ID = 'template_v5p25si';
  static const String EMAILJS_USER_ID = 'wDYYxjMLX1OwyDA6w';
  
  // SMS service configuration (Twilio)
  static const String TWILIO_ACCOUNT_SID = 'your_account_sid';
  static const String TWILIO_AUTH_TOKEN = 'your_auth_token';
  static const String TWILIO_PHONE_NUMBER = 'your_twilio_phone';
  
  // Alternative: Use a simple webhook service
  static const String WEBHOOK_URL = 'https://your-webhook-url.com/send-notification';
  
  // For demo purposes, you can set these to actual values:
  // 1. Sign up for EmailJS (free): https://www.emailjs.com/
  // 2. Sign up for Twilio (free tier): https://www.twilio.com/
  // 3. Or use any other email/SMS service
  
  static bool get isConfigured {
    return EMAILJS_SERVICE_ID != 'your_service_id' && 
           TWILIO_ACCOUNT_SID != 'your_account_sid';
  }
}
