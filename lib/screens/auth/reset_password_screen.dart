// reset_password_screen.dart - CORRECTED VERSION
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jrr_immigration_app/services/auth_service.dart';
import 'package:jrr_immigration_app/screens/auth/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetSuccess = false;

  @override
  void initState() {
    super.initState();
    _verifyResetSession();
  }

  Future<void> _verifyResetSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Reset session verified for: ${session.user.email}');
      } else {
        debugPrint('ℹ️ No active session - proceeding with reset flow');
      }
    } catch (error) {
      debugPrint('❌ Session verification error: $error');
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _authService.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetSuccess = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      }
      
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: ${error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5C9CE),
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Color(0xFF0D97CE)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0D97CE)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _resetSuccess ? _buildSuccessUI() : _buildResetForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF0D97CE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Set New Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D97CE),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your new password below',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            obscureText: _obscureNewPassword,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value != _newPasswordController.text) return 'Passwords do not match';
              return _validatePassword(value);
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D97CE), // FIXED COLOR
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),

          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            ),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
        const SizedBox(height: 20),
        const Text(
          'Password Reset Successful!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your password has been reset successfully. You can now login with your new password.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D97CE), // FIXED COLOR
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}