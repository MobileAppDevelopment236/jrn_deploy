// auth_service.dart - FIXED VERSION WITH PROPER LOGGING
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get the current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get the current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentSession != null;

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  // Sign in with email and password - STRICT VERIFICATION ENFORCEMENT
Future<User?> signIn({
  required String email,
  required String password,
}) async {
  try {
    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    
    // STRICT CHECK: User must exist AND email must be verified
    if (response.user == null) {
      throw Exception('Invalid login credentials');
    }
    
    // Check if email is verified - THIS IS THE CRITICAL FIX
    if (response.user?.emailConfirmedAt == null) {
      // IMMEDIATELY sign out the unverified user
      await _supabase.auth.signOut();
      
      // Check if user exists but isn't verified
      try {
        // Try to resend verification email
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: email.trim(),
          emailRedirectTo: kIsWeb 
    ? 'https://mobileappdevelopment236.github.io/jrn_deploy/auth-callback' 
    : 'jrr-immigration://auth-callback',
        );
        
        throw Exception('Email not verified. We have sent a new verification link to $email. Please check your email and verify your account before logging in.');
      } catch (resendError) {
        throw Exception('Email not verified. Please check your email for the verification link or use "Resend Verification Email".');
      }
    }
    
    return response.user;
  } on AuthException catch (e) {
    throw Exception('Sign in failed: ${e.message}');
  } catch (error) {
    throw Exception('Sign in failed: ${error.toString()}');
  }
}

  Future<User?> signUp({
  required String email,
  required String password,
  required Map<String, dynamic> metadata,
}) async {
  try {
    if (kDebugMode) {
      debugPrint('🔄 Starting signup for: $email');
    }

    // FIRST: Try to check if we can login with these credentials
    // This will tell us if user already exists and is verified
    try {
      final testResponse = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      // If we get here, user exists AND credentials are correct
      if (testResponse.user?.emailConfirmedAt != null) {
        // User exists and is verified - sign them out and show error
        await _supabase.auth.signOut();
        throw Exception('An account with this email already exists. Please login instead of signing up again.');
      }
    } on AuthException {
      // Expected - user doesn't exist or wrong password, continue with signup
      if (kDebugMode) {
        debugPrint('✅ No existing verified user found - proceeding with signup');
      }
    }

    // Proceed with actual signup
    final AuthResponse response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
      emailRedirectTo: kIsWeb 
    ? 'https://mobileappdevelopment236.github.io/jrn_deploy/auth-callback' 
    : 'jrr-immigration://auth-callback',
    );
    
    if (kDebugMode) {
      debugPrint('✅ Signup API call completed');
      debugPrint('📧 User: ${response.user?.email}');
      debugPrint('📨 Email confirmed at: ${response.user?.emailConfirmedAt}');
    }
    
    // Check if this is a new unverified user
    if (response.user != null && response.user?.emailConfirmedAt == null) {
      if (kDebugMode) {
        debugPrint('📨 Email verification required for new user');
      }
      
      // Try to send verification email
      try {
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: email.trim(),
          emailRedirectTo: kIsWeb 
    ? 'https://mobileappdevelopment236.github.io/jrn_deploy/auth-callback' 
    : 'jrr-immigration://auth-callback',
        );
        if (kDebugMode) {
          debugPrint('✅ Verification email sent successfully');
        }
      } on AuthException catch (resendError) {
        if (resendError.message.contains('rate limit')) {
          if (kDebugMode) {
            debugPrint('⚠️ Rate limited - email was already sent');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Could not resend verification: $resendError');
          }
        }
      }
    } else if (response.user?.emailConfirmedAt != null) {
      // User already verified - this shouldn't happen with our check above
      if (kDebugMode) {
        debugPrint('⚠️ User already verified - signing out');
      }
      await _supabase.auth.signOut();
      throw Exception('An account with this email already exists and is verified. Please login instead.');
    }
    
    // Always sign out to enforce email verification for new users
    await _supabase.auth.signOut();
    if (kDebugMode) {
      debugPrint('🚫 Signed out to enforce email verification');
    }
    
    return response.user;
    
  } on AuthException catch (e) {
    if (kDebugMode) {
      debugPrint('❌ AuthException: ${e.message}');
    }
    
    // Enhanced user existence detection
    if (e.message.toLowerCase().contains('already registered') || 
        e.message.toLowerCase().contains('user_exists') ||
        e.message.toLowerCase().contains('already in use')) {
      
      throw Exception('An account with this email already exists. Please check your email for the verification link or use "Forgot Password" if you can\'t access your account.');
    }
    
    throw Exception('Sign up failed: ${e.message}');
    
  } catch (error) {
    if (kDebugMode) {
      debugPrint('❌ General error: $error');
    }
    
    // Re-throw our custom exceptions
    if (error.toString().contains('already exists')) {
      rethrow;
    }
    
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

  // Reset password - USE PASSWORD RECOVERY METHOD (FIXED)
Future<bool> resetPassword(String email) async {
  try {
    
    String redirectUrl;
    
    if (kIsWeb) {
      // TEMPORARY: Use your GitHub Pages URL for testing
      redirectUrl = 'https://mobileappdevelopment236.github.io/jrn_deploy/reset-password';
    } else {
      // For mobile - use the deep link
      redirectUrl = 'jrr-immigration://reset-password';
    }
    // FIX: Use resetPasswordForEmail for proper password reset flow
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
    return true;
  } on AuthException catch (e) {
    throw Exception('Failed to send reset email: ${e.message}');
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
      if (kDebugMode) {
        debugPrint('Profile creation warning: $error');
      }
    }
  }
  
  // Check if user already exists and is verified
Future<bool> checkUserExistsAndVerified(String email) async {
  try {
    // Try to sign in without password to check if user exists
    await _supabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false, // Don't create new user
    );
    // If no error, user exists - but we don't know if verified
    
    // For web, we need a different approach since we can't check verification status directly
    // This is a limitation - we'll rely on the login check instead
    return false;
  } on AuthException catch (e) {
    if (e.message.contains('Email not confirmed')) {
      return true; // User exists but not verified
    }
    if (e.message.contains('Invalid login credentials') ||
        e.message.contains('User not found')) {
      return false; // User doesn't exist
    }
    return false; // Default to false for other errors
  } catch (e) {
    return false;
  }
}
  // Resend email confirmation - UPDATED
  Future<bool> resendEmailConfirmation(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: kIsWeb 
    ? 'https://mobileappdevelopment236.github.io/jrn_deploy/auth-callback' 
    : 'jrr-immigration://auth-callback',
      );
      return true;
    } catch (e) {
      throw Exception('Failed to resend verification email: ${e.toString()}');
    }
  }

  // Stream for auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Stream for user changes
  Stream<User?> get userChanges => _supabase.auth.onAuthStateChange.map(
        (event) => event.session?.user,
      );
}