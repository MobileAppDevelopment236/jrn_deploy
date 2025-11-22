// main.dart - CORRECTED VERSION
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
    final currentUrl = Uri.base.toString();
    final fragment = Uri.base.fragment;
    final queryParams = Uri.base.queryParameters;

    debugPrint('🌐 WEB URL ANALYSIS - ENHANCED:');
    debugPrint('   FULL URL: $currentUrl');
    debugPrint('   FRAGMENT: $fragment');
    debugPrint('   QUERY PARAMS: $queryParams');

    // COMPREHENSIVE DETECTION
    bool isResetDetected = false;

    // 1. Check if we're on the reset-password path
    if (Uri.base.path.contains('reset-password')) {
      debugPrint('🎯 DETECTED: reset-password in path');
      isResetDetected = true;
    }

    // 2. Check for hash/fragment patterns
    if (fragment.contains('reset-password') || fragment.contains('recovery')) {
      debugPrint('🎯 DETECTED: reset pattern in fragment');
      isResetDetected = true;
    }

    // 3. Check for exact hash match
    if (fragment == 'reset-password') {
      debugPrint('🎯 DETECTED: exact reset-password fragment');
      isResetDetected = true;
    }

    if (isResetDetected) {
      debugPrint('🚀 PASSWORD RESET FLOW ACTIVATED!');
      if (mounted) {
        setState(() {
          _isPasswordResetFlow = true;
        });
      }
    } else {
      debugPrint('❌ NO RESET PATTERNS FOUND');
    }
    
  } catch (error) {
    debugPrint('❌ Web reset handler error: $error');
  }
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