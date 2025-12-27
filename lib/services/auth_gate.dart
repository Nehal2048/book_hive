/*
AUTH Gate - This will continously listen for auth state changes

and redirect user to login page if not logged in
*/

import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/pages/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      //Listen to the auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,
      //Show appropriate page based on auth state
      builder: (context, snapshot) {
        //Loading

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        //Check Valid Session
        final session = snapshot.data?.session;

        if (session == null) {
          return const SignInPage();
        } else {
          return const MainNavigation();
        }
      },
    );
  }
}
