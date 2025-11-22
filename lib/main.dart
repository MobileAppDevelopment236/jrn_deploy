import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jrr_immigration_app/providers/auth_provider.dart';
import 'package:jrr_immigration_app/providers/documents_provider.dart';
import 'package:jrr_immigration_app/screens/auth/login_screen.dart';
import 'package:jrr_immigration_app/screens/auth/reset_password_screen.dart';
import 'package:jrr_immigration_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting
  await initializeDateFormatting('en_IN');
  Intl.defaultLocale = 'en_IN';

  // Load environment variables
  await dotenv.load(fileName: ".env");

  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase URL or Anon Key is missing. Please check your .env file');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
        provider.ChangeNotifierProvider(create: (_) => DocumentsProvider()),
      ],
      child: MaterialApp(
        title: 'JRR Go',
        debugShowCheckedModeBanner: false,
        routes: {
          '/reset-password': (context) => const ResetPasswordScreen(),
        },
        theme: ThemeData(
          primaryColor: const Color(0xFF0D97CE),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0D97CE),
            secondary: Color(0xFF0D97CE),
          ),
          scaffoldBackgroundColor: const Color(0xFFC5C9CE),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black87),
            titleTextStyle: GoogleFonts.inter(
              color: const Color(0xFF0D97CE),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          textTheme: GoogleFonts.interTextTheme().apply(
            bodyColor: Colors.grey[800],
            displayColor: const Color(0xFF0D97CE),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D97CE)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D97CE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0D97CE),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  User? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isPasswordResetFlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Get initial session
      final initialSession = _supabase.auth.currentSession;
      
      if (mounted) {
        setState(() {
          _currentUser = initialSession?.user;
        });
      }

      // Handle web callbacks for password reset
      if (kIsWeb) {
        await _handleWebPasswordReset();
      }

      // Setup auth state listener
      _setupAuthListener();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      debugPrint('✅ Auth initialization complete');
      debugPrint('👤 User: ${_currentUser?.email ?? "Not logged in"}');
      
    } catch (error) {
      debugPrint('❌ Auth initialization error: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleWebPasswordReset() async {
    try {
      // Get URL components for analysis
      final Uri currentUri = Uri.base;
      final String currentUrl = currentUri.toString();
      final String fragment = currentUri.fragment;
      final String path = currentUri.path;
      final Map<String, String> queryParams = currentUri.queryParameters;

      debugPrint('🌐 WEB URL ANALYSIS:');
      debugPrint('   FULL URL: $currentUrl');
      debugPrint('   FRAGMENT: $fragment');
      debugPrint('   PATH: $path');
      debugPrint('   QUERY PARAMS: $queryParams');

      bool resetDetected = false;

      // Detection Method 1: Check URL fragment for reset patterns
      if (fragment.contains('reset-password') || fragment.contains('recovery')) {
        debugPrint('🎯 DETECTED: Reset pattern in URL fragment');
        resetDetected = true;
      }

      // Detection Method 2: Check path for reset-password patterns
      if (path.contains('reset-password')) {
        debugPrint('🎯 DETECTED: Reset password in URL path');
        resetDetected = true;
      }

      // Detection Method 3: Check full URL for reset-password patterns
      if (currentUrl.contains('/reset-password')) {
        debugPrint('🎯 DETECTED: Reset password in full URL');
        resetDetected = true;
      }

      // Detection Method 4: Check session storage for reset flag (only on web)
      if (kIsWeb) {
        resetDetected = await _checkSessionStorage() || resetDetected;
      }

      // Activate password reset flow if any detection method succeeded
      if (resetDetected) {
        debugPrint('🚀 PASSWORD RESET FLOW ACTIVATED');
        if (mounted) {
          setState(() {
            _isPasswordResetFlow = true;
          });
        }
      } else {
        debugPrint('✅ No password reset patterns detected');
      }

    } catch (error) {
      debugPrint('❌ URL analysis error: $error');
    }
  }

  // Separate method for web-specific session storage check
  Future<bool> _checkSessionStorage() async {
    if (!kIsWeb) return false;
    
    // Use conditional import for web-only functionality
    try {
      // This will only be executed on web
      final dynamic storage = _getSessionStorage();
      if (storage != null) {
        final String? resetFlag = storage['from_reset_redirect'];
        if (resetFlag == 'true') {
          debugPrint('🎯 DETECTED: Session storage flag found');
          storage.remove('from_reset_redirect');
          return true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Session storage check error: $e');
    }
    return false;
  }

  // Helper method to access session storage without direct web imports
  dynamic _getSessionStorage() {
    if (kIsWeb) {
      // This uses dart:js_interop for safe web access
      // In a real implementation, you might use universal_html or js packages
      // For now, we'll return null to avoid compilation errors
      return null;
    }
    return null;
  }

  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((AuthState data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      debugPrint('🔐 Auth Event: $event');
      debugPrint('   User: ${session?.user.email ?? "No user"}');

      if (mounted) {
        setState(() {
          _currentUser = session?.user;
        });

        // FIXED: Remove null-aware operator from authProvider
        final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
        authProvider.initializeUser(_currentUser);

        // Handle password recovery event
        if (event == AuthChangeEvent.passwordRecovery) {
          debugPrint('🔄 Password recovery event detected');
          setState(() {
            _isPasswordResetFlow = true;
          });
        }

        // Handle successful sign-in
        if (event == AuthChangeEvent.signedIn) {
          debugPrint('✅ User signed in successfully');
        }

        // Handle sign out
        if (event == AuthChangeEvent.signedOut) {
          debugPrint('🚪 User signed out');
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Session check on app resume
    if (state == AppLifecycleState.resumed) {
      _checkCurrentSession();
    }
  }

  Future<void> _checkCurrentSession() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      if (mounted) {
        setState(() {
          _currentUser = currentSession?.user;
        });
      }
      debugPrint('📱 App resumed - Session: ${_currentUser != null ? "Active" : "Inactive"}');
    } catch (e) {
      debugPrint('❌ Session check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFC5C9CE),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D97CE)),
          ),
        ),
      );
    }

    // Handle password reset flow
    if (_isPasswordResetFlow) {
      debugPrint('🔄 Rendering Reset Password Screen');
      return const ResetPasswordScreen();
    }

    // Determine if user is logged in
    final isLoggedIn = _currentUser != null;

    // Initialize auth provider - FIXED NULL-AWARE OPERATOR
    if (mounted) {
      final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeUser(_currentUser);
    }

    debugPrint('🏠 Rendering: ${isLoggedIn ? 'Home Screen' : 'Login Screen'}');

    // Return appropriate screen
    return Scaffold(
      body: SafeArea(
        child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }
}