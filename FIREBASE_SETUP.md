# Firebase Setup Guide for Secure Chat App

This guide will help you set up Firebase for your Flutter chat application.

## 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Follow the steps to create a new project
4. You can disable Google Analytics for simplicity

## 2. Add Web App to Firebase Project

1. In your Firebase project, click the "Web" icon (</>) to add a web app
2. Register your app with any nickname (e.g., "SecureChatWebApp")
3. Copy the Firebase configuration object - it will look like this:

```javascript
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "your-sender-id",
  appId: "your-app-id"
};
```

## 3. Update Firebase Configuration

1. Open `lib/firebase_options.dart` in your Flutter project
2. Replace the demo values with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-api-key',
  appId: 'your-actual-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

## 4. Enable Firebase Services

### Authentication
1. Go to "Build" > "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider

### Firestore Database
1. Go to "Build" > "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for simplicity
4. Select a location for your database

## 5. Set Firestore Security Rules

1. Go to "Build" > "Firestore Database" > "Rules"
2. Replace the existing rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

3. Click "Publish"

## 6. Test Your App

1. Run `flutter pub get`
2. Run `flutter run`
3. Try registering a new user
4. Try logging in
5. Search for users and start a chat

## Troubleshooting

- **Firebase not initialized**: Make sure you've updated `firebase_options.dart` with your actual config
- **Authentication errors**: Check that Email/Password is enabled in Firebase Console
- **Database errors**: Verify Firestore is enabled and rules are published
- **Build errors**: Run `flutter clean` then `flutter pub get`

## Success!

Your Flutter chat app should now work with Firebase! Users can register, login, search for other users, and send real-time messages.