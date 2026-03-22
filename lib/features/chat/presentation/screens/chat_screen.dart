import 'package:chat_app/features/chat/data/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/messages_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  final String receiverId;
  final String receiverName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {

  final ScrollController _scrollController = ScrollController();
  final messageController = TextEditingController();

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    await ChatService().sendMessage(
      widget.receiverId,
      messageController.text.trim(),
    );
    messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final messages = ref.watch(messagesProvider(widget.receiverId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/chat_bg.jpg'),
              fit: BoxFit.cover
          )
        ),
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                  data: (snapshot) {
                    final docs = snapshot.docs;
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollController,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == currentUid;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFFDCF8C6)  // light green for sent
                                        : Colors.white,             // white for received
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: Text(data['message'], style: const TextStyle(color: Colors.black87)),
                              ),
                            ),
                          );
                        }
                    );
                  },
                  error: (e, st) => Center(child: Text(e.toString())),
                  loading: () =>Center(child: CircularProgressIndicator())
              )
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: messageController, decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),)),
                    IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send, size: 39,color: Colors.blue,),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
