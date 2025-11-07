// main.dart 
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jrr_immigration_app/providers/auth_provider.dart';
import 'package:jrr_immigration_app/providers/documents_provider.dart';
import 'package:jrr_immigration_app/screens/auth/login_screen.dart';
import 'package:jrr_immigration_app/screens/auth/reset_password_screen.dart';
import 'package:jrr_immigration_app/screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // FIX FOR DATE PICKER ISSUE
  // ===========================================================================
  await initializeDateFormatting('en_IN');
  
  // SIMPLE FIX FOR LOCALE ERROR
  Intl.defaultLocale = 'en_IN'; // Indian time format

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

class _AuthGateState extends State<AuthGate> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getInitialSession();
    
    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthState data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;
    
    print('🔐 Auth state changed: $event');
    
    if (mounted) {
      setState(() {
        _currentUser = session?.user;
      });
      
      final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeUser(_currentUser);

      // Handle password recovery - this works when user clicks the email link
      if (event == AuthChangeEvent.passwordRecovery) {
        print('🔄 Password recovery detected, navigating to reset screen');
        _handlePasswordRecovery();
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
      
      print('👤 Initial session loaded: ${_currentUser?.email}');
    } catch (error) {
      print('❌ Error getting initial session: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePasswordRecovery() {
    print('🚀 Navigating to Reset Password Screen');
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
          (route) => false,
        );
      });
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

  final isLoggedIn = _currentUser != null;

  if (mounted) {
    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    authProvider.initializeUser(_currentUser);
  }

  // WRAP THE ENTIRE APP WITH A RESPONSIVE SCAFFOLD
  return Scaffold(
    body: SafeArea(
      child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    ),
  );
}
  
}