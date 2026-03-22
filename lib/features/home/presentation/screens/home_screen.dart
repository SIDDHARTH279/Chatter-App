import 'package:chat_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:chat_app/features/home/presentation/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  bool isSearching = false;
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    saveToken();
  }
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> saveToken() async {
    // Step 1 — request notification permission
    await FirebaseMessaging.instance.requestPermission();

    // Step 2 — get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    // Step 3 — save token to Firestore users/{uid}
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});

  }

  @override
  Widget build(BuildContext context) {

    final user = ref.watch(userProvider);

    return user.when(
        data: (snapshot) {
          final docs = snapshot.docs;
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'].toString().toLowerCase();
            return name.contains(searchQuery);
          }).toList();
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: isSearching
                ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ):const Text('Chatter'),
              actions: [
                isSearching
                  ? IconButton(
                    onPressed: () {
                      setState(() {
                        isSearching = false;
                        searchQuery = '';
                        searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.close))
                : IconButton(
                    onPressed: () {
                      setState(() {
                        isSearching = true;
                      });
                    },
                    icon: const Icon(Icons.search)
                )
                ,IconButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout)
                )
              ],
            ),
            body: ListView.separated(
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                  final name = data['name'];
                  final email = data['email'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1E88E5),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            receiverId: data['uid'],
                            receiverName: data['name'],
                          ),
                        ),
                      );
                    },
                  );
                }
            ),
          );
        },
        error: (e, st) {
          return Scaffold(
            body: Center(child: Text(e.toString()),),
          );
        },
        loading: () => Scaffold(body: Center(child: CircularProgressIndicator()))
    );
  }
}

