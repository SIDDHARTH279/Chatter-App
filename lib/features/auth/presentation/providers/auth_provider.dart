import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// StreamProvider listens to a stream and updates UI automatically
// Here it listens to Firebase authentication state changes
final authProvider = StreamProvider<User?>((ref) {

  // FirebaseAuth.instance.authStateChanges() returns a stream
  // This stream emits:
  // - User object when user is logged in
  // - null when user is logged out
  return FirebaseAuth.instance.authStateChanges();
});
