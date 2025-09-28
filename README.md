# Secure Chat App - College Project with Firebase

A simple Flutter chat application built for COMP 490 with Firebase backend. This is a functional chat app with real authentication and messaging!

## Features (Simple College Project)

- **Real Authentication**: Firebase email/password login and registration
- **Real-time Chat**: Send and receive messages with Firebase Firestore
- **User Search**: Find other users to start conversations
- **Basic UI**: Simple Material Design interface

## Tech Stack

- Flutter (basic widgets)
- Firebase Auth (email/password authentication)
- Cloud Firestore (real-time database)
- No complex state management - just basic setState

## Setup Instructions

### 1. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Update `lib/firebase_options.dart` with your Firebase config

### 2. Run the App

```bash
flutter pub get
flutter run
```

## Project Structure (Simple)

```
lib/
├── main.dart                     # Simple app entry point
├── firebase_options.dart         # Firebase configuration
├── services/
│   └── auth_service.dart         # Firebase auth wrapper
└── screens/
    ├── login_screen.dart         # Login/register screen
    ├── home_screen.dart          # Chat list
    └── chat_screen.dart          # Individual chat
```

## How It Works (College Level)

1. **Login Screen**: Simple form with email/password fields
2. **Home Screen**: Shows list of chats and search for users
3. **Chat Screen**: Send/receive messages in real-time
4. **Firebase**: Stores users and messages in Firestore

## Code Style (Student Level)

- Simple variable names like `messageController`, `currentUser`
- Basic error handling with print statements
- Simple UI with default Material Design colors
- No complex patterns - just basic Flutter widgets

## Firebase Security Rules (Basic)

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

## Development Notes

- This is a college project - keep it simple!
- Basic error handling with try/catch
- Simple print statements for debugging
- No fancy animations or complex UI
- Focus on functionality over design

## Success Criteria ✅

- [x] Users can login/register with email
- [x] Users can search for other users
- [x] Users can send/receive messages in real-time
- [x] Simple navigation between screens
- [x] Basic but clean UI
- [x] Works on Android and iOS
- [x] Uses Firebase for backend

This is a functional college project that demonstrates basic Flutter and Firebase skills!