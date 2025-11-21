import 'package:flutter/material.dart';
import 'package:jrr_immigration_app/services/auth_service.dart';
import 'package:jrr_immigration_app/screens/auth/login_screen.dart';

class VerificationPendingScreen extends StatefulWidget {
  final String email;
  
  const VerificationPendingScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  DateTime? _lastEmailSent;

  Future<void> _resendVerification() async {
    if (_isLoading) return;
    
    // Rate limiting: Check if we sent an email recently
    if (_lastEmailSent != null && 
        DateTime.now().difference(_lastEmailSent!).inSeconds < 60) {
      final secondsLeft = 60 - DateTime.now().difference(_lastEmailSent!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait $secondsLeft seconds before sending another email.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.resendEmailConfirmation(widget.email);
      
      if (mounted) {
        setState(() {
          _lastEmailSent = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox and spam folder.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      final errorMessage = error.toString().replaceAll('Exception: ', '');
      
      if (mounted) {
        if (errorMessage.contains('rate limit') || errorMessage.contains('seconds')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait 60 seconds before requesting another email.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _lastEmailSent == null || 
        DateTime.now().difference(_lastEmailSent!).inSeconds >= 60;

    return Scaffold(
      backgroundColor: const Color(0xFFC5C9CE),
      appBar: AppBar(
        title: const Text(
          'Verify Your Email',
          style: TextStyle(color: Color(0xFF0D97CE)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0D97CE)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Email Verification Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D97CE),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We sent a verification link to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D97CE),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'You must verify your email before you can login. '
                    'Please check your inbox (and spam folder) for the verification link. '
                    'Click the link to activate your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D97CE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Go to Login'),
                ),
                const SizedBox(height: 16),
                
                if (canResend) ...[
                  TextButton(
                    onPressed: _isLoading ? null : _resendVerification,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend Verification Email'),
                  ),
                ] else ...[
                  Text(
                    'Resend available in ${60 - DateTime.now().difference(_lastEmailSent!).inSeconds} seconds',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Important:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'You cannot login until you verify your email address.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}