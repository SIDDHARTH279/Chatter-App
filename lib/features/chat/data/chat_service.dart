import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {

  // Firestore and Auth instances for reuse across methods
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sends a message to Firestore under the correct chat room
  Future<void> sendMessage(String receiverId, String message) async {

    // Get the current logged in user's uid
    final currentUserId = _auth.currentUser!.uid;

    // Create a unique chat room ID by sorting both uids alphabetically
    // This ensures A->B and B->A always produce the same room ID
    List<String> ids = [receiverId, currentUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Save the message document to Firestore
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp()
    });

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .set({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUserId, receiverId],
    }, SetOptions(merge: true));
  }

  // Returns a real-time stream of messages for a given chat room
  Stream<QuerySnapshot> getMessages(String receiverId) {

    final currentUserId = _auth.currentUser!.uid;

    // Same sorting logic ensures we access the correct chat room
    List<String> ids = [receiverId, currentUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Stream updates automatically whenever new messages are added
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}