// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;

  void initializeUser(User? user) {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setUser(User? user) {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _user = user;
      notifyListeners();
    });
  }

  void clearUser() {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _user = null;
      notifyListeners();
    });
  }

  void setLoading(bool loading) {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _isLoading = loading;
      notifyListeners();
    });
  }
}