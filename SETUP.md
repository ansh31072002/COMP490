# Quick Setup Guide - College Project

## For Demo/Presentation (No Firebase Setup Needed)

The app will run with demo Firebase configuration for presentation purposes.

```bash
flutter pub get
flutter run
```

## For Real Firebase (Optional)

If you want to set up real Firebase for testing:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication (Email/Password)
4. Enable Firestore Database
5. Download `google-services.json` and place in `android/app/`
6. Replace the demo values in `lib/firebase_options.dart` with your real values

## What the App Does

- **Login Screen**: Simple email/password authentication
- **Home Screen**: Shows chat list and user search
- **Chat Screen**: Send/receive messages in real-time

## College Project Features

- Simple Flutter widgets
- Basic Firebase integration
- Real-time messaging
- User authentication
- Clean, functional UI

Perfect for COMP 490 presentation! 🎓
