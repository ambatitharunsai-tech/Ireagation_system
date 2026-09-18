import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../services/auth_service.dart';

/// Manages authentication state for the application.
class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider();

  /// Login with email and password via Supabase Auth.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await AuthService().login(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
      }
    } catch (e) {
      debugPrint('AuthProvider.login error: $e');
      _error = _parseAuthError(e.toString());
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Register a new account via Supabase Auth.
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await AuthService().register(name, email, password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.register error: $e');
      _error = _parseAuthError(e.toString());
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Continue as demo user without authentication.
  void loginAsDemo() {
    _currentUser = AppUser(
      id: SupabaseConfig.demoUserId,
      name: 'Demo Farmer',
      email: 'demo@smartagri.com',
      farmName: 'Green Valley Farm',
      location: 'Karnataka, India',
      farmSize: 12.5,
      soilType: 'Alluvial',
    );
    notifyListeners();
  }

  /// Logout and clear session.
  Future<void> logout() async {
    try {
      await AuthService().logout();
    } catch (_) {
      // Ignore logout errors
    }
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile(AppUser updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService().updateProfile(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseAuthError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Wrong email or password';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email first';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered') ||
        lower.contains('already exists')) {
      return 'An account with this email already exists. Try logging in.';
    }
    if (lower.contains('invalid api key') ||
        lower.contains('apikey') ||
        lower.contains('not authorized') ||
        lower.contains('401')) {
      return 'Server configuration error. Please use Demo Mode for now.';
    }
    if (lower.contains('password should be at least') ||
        lower.contains('password is too short')) {
      return 'Password must be at least 6 characters';
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email')) {
      return 'Please enter a valid email address';
    }
    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('429')) {
      return 'Email rate limit exceeded. Supabase free tier allows limited signups per hour. Please use Demo Mode or wait a while.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('timeout')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lower.contains('signup is disabled') ||
        lower.contains('sign up is disabled')) {
      return 'Registration is currently disabled. Please use Demo Mode.';
    }
    // Log unrecognized errors for debugging
    debugPrint('Unrecognized auth error: $error');
    return 'Registration failed. Please try Demo Mode instead.';
  }
}
