import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  //Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(String email, String password) {
    return supabase.auth.signUp(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() {
    return supabase.auth.signOut();
  }

  // Get user email
  String? getUserEmail() {
    return supabase.auth.currentSession?.user.email;
  }
}
