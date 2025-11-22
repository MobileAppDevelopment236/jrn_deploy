// main.dart - CLEAN VERSION
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

  // ===========================================================================
  // FIX FOR DATE PICKER ISSUE
  // ===========================================================================
  await initializeDateFormatting('en_IN');
  
  // SIMPLE FIX FOR LOCALE ERROR
  Intl.defaultLocale = 'en_IN';

  await dotenv.load(fileName: ".env");

  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase URL or Anon Key is missing. Please check your .env file');
  }

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
  bool _isEmailVerificationFlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _handleWebAuthCallbacks();
    await _getInitialSession();
    _setupAuthListener();
  }

  Future<void> _handleWebAuthCallbacks() async {
    if (!kIsWeb) return;

    try {
      final currentUrl = Uri.base.toString();
      debugPrint('🌐 CURRENT URL ANALYSIS:');
      debugPrint('  - Full URL: $currentUrl');
      debugPrint('  - Fragment: ${Uri.base.fragment}');
      debugPrint('  - Contains #reset-password: ${currentUrl.contains('#reset-password')}');
      debugPrint('  - Query params: ${Uri.base.queryParameters}');

      // Check if this is a password reset redirect
      if (currentUrl.contains('#reset-password')) {
        debugPrint('🎯 RESET PASSWORD FLOW DETECTED!');
        
        // Set password reset flow
        if (mounted) {
          setState(() {
            _isPasswordResetFlow = true;
          });
        }
      } else {
        debugPrint('❌ Reset password NOT detected in URL');
      }
      
    } catch (error) {
      debugPrint('❌ Error handling web auth callbacks: $error');
    }
  }

  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthState data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;
    
    if (kDebugMode) {
      debugPrint('🔐 Auth state changed: $event');
      debugPrint('🔑 Session: ${session != null ? "EXISTS" : "NULL"}');
    }
    
    if (mounted) {
      setState(() {
        _currentUser = session?.user;
      });
      
      final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeUser(_currentUser);

      // CRITICAL: Handle password recovery for both web and mobile
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('🎯 PASSWORD RECOVERY EVENT DETECTED - SHOWING RESET SCREEN');
        if (mounted) {
          setState(() {
            _isPasswordResetFlow = true;
          });
        }
      }
      
      // Handle signed in event for email verification
      if (event == AuthChangeEvent.signedIn && _isEmailVerificationFlow) {
        debugPrint('✅ Email verification successful!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isEmailVerificationFlow = false;
        });
      }
    }
  }

  Future<void> _getInitialSession() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      
      if (mounted) {
        setState(() {
          _currentUser = currentSession?.user;
          _isLoading = false;
        });
      }
      
      if (kDebugMode) {
        debugPrint('👤 Initial session loaded: ${_currentUser?.email}');
      }
      
    } catch (error) {
      if (kDebugMode) {
        debugPrint('❌ Error getting initial session: $error');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForActiveSession();
    }
  }

  Future<void> _checkForActiveSession() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      if (mounted) {
        setState(() {
          _currentUser = currentSession?.user;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking active session: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // Handle password reset flow - THIS IS CRITICAL
    if (_isPasswordResetFlow) {
      return const ResetPasswordScreen();
    }

    final isLoggedIn = _currentUser != null;

    if (mounted) {
      final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeUser(_currentUser);
    }

    return Scaffold(
      body: SafeArea(
        child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }
}