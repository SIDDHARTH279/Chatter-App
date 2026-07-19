import 'package:chat_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:chat_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/screens/home_screen.dart';

class AuthGate extends ConsumerWidget {

  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
        data: (user) {
          if(user != null) {
            return const HomeScreen();
          } else {
            return LoginScreen();
          }
        },
        error: (e, st) {
          return Scaffold(
              body: Center(
                  child: Text(e.toString())
              )
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
            ),
          ),
        ),
    );
  }
}

