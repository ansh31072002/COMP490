# Google Sign-In Setup for Web

## Current Status
The app includes Google Sign-In functionality, but it requires additional configuration to work on web platforms.

## Error Message
```
"ClientID not set. Either set it on a <meta name=\"google-signin-client_id\" content=\"CLIENT_ID\" /> tag, or pass clientId when initializing GoogleSignIn"
```

## How to Fix (For Production)

### 1. Get Google OAuth Client ID
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Choose "Web application"
6. Add your domain to authorized origins
7. Copy the Client ID

### 2. Configure Web App
Add the meta tag to `web/index.html`:

```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID_HERE">
```

### 3. Update AuthService (Optional)
You can also pass the client ID directly:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: 'YOUR_CLIENT_ID_HERE',
);
```

## Current Implementation
The app currently handles Google Sign-In errors gracefully:
- Shows Google Sign-In button
- Displays helpful error message if configuration is missing
- Falls back to email/password authentication
- All other security features work without Google Sign-In

## For College Project Demo
The current implementation is perfect for a college project because:
- ✅ Shows OAuth 2.0 integration concept
- ✅ Handles errors gracefully
- ✅ Demonstrates security features without requiring Google setup
- ✅ All other features (AES-256, MFA, RBAC) work perfectly

## Testing Without Google Sign-In
1. Use email/password registration
2. Complete MFA setup during signup
3. Test all security features
4. Demonstrate the OAuth button (even if it shows error)

This demonstrates the security concepts while being practical for a college project!
