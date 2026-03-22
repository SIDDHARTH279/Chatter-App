import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_service.dart';

final messagesProvider = StreamProvider.family<QuerySnapshot, String>((ref, receiverId) {
  return ChatService().getMessages(receiverId);
});