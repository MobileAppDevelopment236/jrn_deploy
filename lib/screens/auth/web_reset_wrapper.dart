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

  @override
  void initState() {
    super.initState();
    _checkRecoverySession();
  }

  Future<void> _checkRecoverySession() async {
    try {
      // Check if current URL contains access_token (web deep link)
      final uri = Uri.base;
      final hasAccessToken = uri.fragment.contains('access_token') || 
                            uri.queryParameters.containsKey('access_token');
      
      if (hasAccessToken) {
        // Try to get session from URL
        final session = _supabase.auth.currentSession;
        if (session != null) {
          // Check if this is a recovery session
          final isRecovery = await _verifyRecoverySession(session);
          if (isRecovery && mounted) {
            setState(() {
              _isValidRecovery = true;
              _isLoading = false;
            });
            return;
          }
        }
      }

      // If not valid recovery, redirect to login
      if (mounted) {
        setState(() {
          _isValidRecovery = false;
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isValidRecovery = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      }
    }
  }

  Future<bool> _verifyRecoverySession(Session session) async {
    try {
      // Simple check - if user has recovery metadata or this is a fresh session
      final user = session.user;
      return user.appMetadata['provider'] == 'email';
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                'Verifying reset link...',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isValidRecovery ? const ResetPasswordScreen() : const LoginScreen();
  }
}