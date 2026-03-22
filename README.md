# Chatter 💬

A real-time chat application built with Flutter and Firebase. Supports instant messaging between users with a clean, WhatsApp-inspired UI.

---


## Features

- 🔐 **Authentication** — Email/password sign up and login with Firebase Auth
- 💬 **Real-time messaging** — Messages appear instantly using Firestore streams
- 👥 **User discovery** — See all registered users, excluding yourself
- 🔍 **Search** — Filter users by name in real time
- 🟢 **Online status** — Track when users were last seen
- 🔔 **FCM token management** — Device tokens saved to Firestore, ready for push notifications
- 📱 **Auto-scroll** — Chat automatically scrolls to the latest message
- 🎨 **WhatsApp-style UI** — Background image, green/white message bubbles, blue theme

---

## Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter 3.24+ |
| Language | Dart |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| State Management | Riverpod 2.x |
| Push Notifications | Firebase Cloud Messaging |
| Architecture | Feature-First Clean Architecture |

---

## Architecture

The project follows a **Feature-First Clean Architecture** pattern:

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── screens/        # AuthGate, LoginScreen, SignupScreen
│   │       └── providers/      # authProvider (StreamProvider)
│   ├── chat/
│   │   ├── data/               # ChatService (Firestore operations)
│   │   └── presentation/
│   │       ├── screens/        # ChatScreen
│   │       └── providers/      # messagesProvider (StreamProvider.family)
│   └── home/
│       └── presentation/
│           ├── screens/        # HomeScreen
│           └── providers/      # usersProvider (StreamProvider)
└── main.dart
```

---

## Firestore Data Model

### Users Collection
```
users/
  {uid}/
    uid: string
    name: string
    email: string
    bio: string
    profilePicUrl: string
    isOnline: boolean
    lastSeen: timestamp
    createdAt: timestamp
    fcmToken: string
```

### Chats Collection
```
chats/
  {chatRoomId}/                   ← sorted UIDs joined with '_'
    lastMessage: string
    lastMessageTime: timestamp
    participants: [uid1, uid2]
    messages/
      {messageId}/
        senderId: string
        message: string
        timestamp: timestamp
```

---

## How Chat Room IDs Work

Chat rooms are identified by sorting both user UIDs alphabetically and joining them with an underscore. This ensures the same chat room ID is generated regardless of who initiates the conversation.

```dart
List<String> ids = [currentUserId, receiverId];
ids.sort();
String chatRoomId = ids.join('_');
```

---

## Key Implementation Details

### Auth Gate
The app uses a reactive `AuthGate` widget that listens to Firebase Auth state changes. Users are automatically redirected to the correct screen without manual navigation code.

```dart
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

### Real-time Messages
Messages are fetched as a real-time stream ordered by timestamp. The UI rebuilds automatically when new messages arrive.

```dart
final messagesProvider = StreamProvider.family<QuerySnapshot, String>((ref, receiverId) {
  return ChatService().getMessages(receiverId);
});
```

### User Filtering
The users list automatically excludes the currently logged-in user and rebuilds when auth state changes.

```dart
final userProvider = StreamProvider<QuerySnapshot>((ref) {
  final authState = ref.watch(authProvider);
  final currentUid = authState.asData?.value?.uid ?? '';
  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isNotEqualTo: currentUid)
      .snapshots();
});
```

---

## Roadmap

- [ ] Image sharing via Firebase Storage
- [ ] Push notifications via Cloud Functions (requires Blaze plan)
- [ ] Last message preview on Home screen
- [ ] Message timestamps
- [ ] Online/offline status indicator
- [ ] Profile screen with editable bio and photo
- [ ] Firestore security rules for production

---

## What I Learned

- Integrating Firebase Auth, Firestore, and FCM in a Flutter app
- Managing real-time state with Riverpod StreamProvider
- Feature-first clean architecture for scalable Flutter apps
- Debugging Riverpod provider caching issues
- Handling async operations safely with mounted checks
- Building WhatsApp-style chat UI from scratch

---
