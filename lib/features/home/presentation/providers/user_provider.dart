import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final userProvider = StreamProvider<QuerySnapshot>((ref) {
  final authState = ref.watch(authProvider);

  final currentUid = authState.asData?.value?.uid ?? '';

  print('Current UID in userProvider: $currentUid');
  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isNotEqualTo: currentUid)
      .snapshots();
});