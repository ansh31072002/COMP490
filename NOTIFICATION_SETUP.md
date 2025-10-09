# Email/SMS Setup Instructions

## For Real Email/SMS Functionality

### Option 1: EmailJS (Free - Recommended for Demo)

1. Go to [EmailJS](https://www.emailjs.com/)
2. Sign up for a free account
3. Create an email service (Gmail, Outlook, etc.)
4. Create an email template
5. Get your r, Template ID, and User ID
6. Update `lib/config/notification_config.dart`:
   ```dart
   static const String EMAILJS_SERVICE_ID = 'your_actual_service_id';
   static const String EMAILJS_TEMPLATE_ID = 'your_actual_template_id';
   static const String EMAILJS_USER_ID = 'your_actual_user_id';
   ```

### Option 2: Twilio SMS (Free Tier)

1. Go to [Twilio](https://www.twilio.com/)
2. Sign up for a free account
3. Get a phone number
4. Get your Account SID and Auth Token
5. Update `lib/config/notification_config.dart`:
   ```dart
   static const String TWILIO_ACCOUNT_SID = 'your_actual_account_sid';
   static const String TWILIO_AUTH_TOKEN = 'your_actual_auth_token';
   static const String TWILIO_PHONE_NUMBER = 'your_actual_phone_number';
   ```

### Option 3: Other Services

You can replace the HTTP requests in `notification_service.dart` with any email/SMS service:
- SendGrid
- AWS SES
- Firebase Cloud Messaging
- Any webhook service

## Current Behavior

- **Without Configuration**: Codes are shown in console/logs as fallback
- **With Configuration**: Real emails/SMS are sent to users
- **MFA Flow**: User enters code they receive via email/SMS

## Testing

1. Set up one of the services above
2. Update the configuration file
3. Run the app
4. Try logging in with MFA enabled
5. Check your email/phone for the verification code
6. Enter the code in the app to complete login

## Security Notes

- Codes expire in 10 minutes
- Each login requires a new code
- No session persistence - MFA required every login after logout
- All messages are AES-256 encrypted
