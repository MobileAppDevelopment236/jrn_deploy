// auth_service.dart - SIMPLIFIED VERSION
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get the current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get the current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentSession != null;

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      return response.user;
    } on AuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (error) {
      throw Exception('Sign in failed: ${error.toString()}');
    }
  }

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );
      
      return response.user;
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (error) {
      throw Exception('Sign up failed: ${error.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      throw Exception('Sign out failed: ${error.toString()}');
    }
  }

  // Reset password - ULTRA SIMPLE VERSION
  // Reset password - CORRECT VERSION
  // Reset password - USE MAGIC LINK APPROACH
Future<bool> resetPassword(String email) async {
  try {
    // Use signInWithOtp which creates proper verification links
    await _supabase.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: 'https://zbjowyzxujktgwqrjseh.supabase.co/auth/v1/verify',
    );
    return true;
  } catch (e) {
    throw Exception('Failed to send reset email: ${e.toString()}');
  }
}


  // Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception('Password update failed: ${e.message}');
    } catch (error) {
      throw Exception('Password update failed: ${error.toString()}');
    }
  }

  // Get user profile from profiles table
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (error) {
      return null;
    }
  }

  // Create user profile in profiles table
  Future<void> createProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      // Don't throw error - just log it
      print('Profile creation warning: $error');
    }
  }

  // Stream for auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Stream for user changes
  Stream<User?> get userChanges => _supabase.auth.onAuthStateChange.map(
        (event) => event.session?.user,
      );
}