// lib/screens/auth/web_reset_wrapper.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_screen.dart';
import 'login_screen.dart';

class WebResetWrapper extends StatefulWidget {
  const WebResetWrapper({super.key});

  @override
  State<WebResetWrapper> createState() => _WebResetWrapperState();
}

class _WebResetWrapperState extends State<WebResetWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isValidRecovery = false;
  String _statusMessage = 'Checking reset link...';

  @override
  void initState() {
    super.initState();
    _validateResetSession();
  }

  Future<void> _validateResetSession() async {
    try {
      debugPrint('🔄 WebResetWrapper: Starting session validation');
      
      // Check current URL for reset indicators
      final bool hasResetIndicators = _checkUrlForResetIndicators();
      
      if (!hasResetIndicators) {
        debugPrint('❌ WebResetWrapper: No reset indicators found in URL');
        _redirectToLogin('Invalid reset link');
        return;
      }

      // Verify active session exists
      final Session? session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint('❌ WebResetWrapper: No active session found');
        _redirectToLogin('Session expired or invalid');
        return;
      }

      // Additional recovery session verification
      final bool isValidRecovery = await _verifyRecoveryContext(session);
      
      if (mounted) {
        setState(() {
          _isValidRecovery = isValidRecovery;
          _isLoading = false;
          _statusMessage = isValidRecovery 
              ? 'Reset link verified successfully' 
              : 'Invalid recovery session';
        });
      }

      if (!isValidRecovery) {
        _redirectToLogin('Invalid recovery session');
      }

    } catch (error) {
      debugPrint('❌ WebResetWrapper: Error during validation: $error');
      _redirectToLogin('Error verifying reset link');
    }
  }

  bool _checkUrlForResetIndicators() {
    final Uri uri = Uri.base;
    
    // Check fragment for reset patterns
    final bool hasFragmentIndicators = uri.fragment.contains('access_token') ||
                                      uri.fragment.contains('type=recovery') ||
                                      uri.fragment.contains('reset-password');
    
    // Check query parameters for reset patterns
    final bool hasQueryIndicators = uri.queryParameters.containsKey('access_token') ||
                                   uri.queryParameters['type'] == 'recovery' ||
                                   uri.queryParameters.containsKey('token');
    
    // Check path for reset patterns
    final bool hasPathIndicators = uri.path.contains('reset-password') ||
                                  uri.path.contains('password-reset');

    debugPrint('🔍 WebResetWrapper URL Analysis:');
    debugPrint('   - Fragment: ${uri.fragment}');
    debugPrint('   - Query: ${uri.queryParameters}');
    debugPrint('   - Path: ${uri.path}');
    debugPrint('   - Has Fragment Indicators: $hasFragmentIndicators');
    debugPrint('   - Has Query Indicators: $hasQueryIndicators');
    debugPrint('   - Has Path Indicators: $hasPathIndicators');

    return hasFragmentIndicators || hasQueryIndicators || hasPathIndicators;
  }

  Future<bool> _verifyRecoveryContext(Session session) async {
  try {
    final user = session.user;
    
    // Check if this appears to be a password recovery context
    final bool isEmailProvider = user.appMetadata['provider'] == 'email';
    
    // FIXED: Convert timestamp (int) to DateTime
    final DateTime now = DateTime.now();
    final DateTime thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
    
    // Convert Unix timestamp to DateTime and compare
    final bool hasRecentAuth = session.expiresAt != null 
        ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).isAfter(thirtyMinutesAgo)
        : false;

    debugPrint('🔐 WebResetWrapper Session Verification:');
    debugPrint('   - User Email: ${user.email}');
    debugPrint('   - Is Email Provider: $isEmailProvider');
    debugPrint('   - Session Recent: $hasRecentAuth');
    debugPrint('   - Session Expires: ${session.expiresAt}');
    debugPrint('   - Current Time: $now');

    return isEmailProvider && hasRecentAuth;
  } catch (e) {
    debugPrint('❌ WebResetWrapper: Error in recovery context verification: $e');
    return false;
  }
}

  void _redirectToLogin(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = message;
      });

      // Delay redirect to show message briefly
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return _isValidRecovery ? const ResetPasswordScreen() : _buildErrorScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFC5C9CE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D97CE)),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFC5C9CE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[600],
            ),
            const SizedBox(height: 20),
            Text(
              'Reset Link Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D97CE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}