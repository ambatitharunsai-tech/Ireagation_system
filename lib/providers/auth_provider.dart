import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await AuthService().getCurrentUser();
      _currentUser = user;
    } catch (e) {
      debugPrint('Session restore failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      _error = 'Invalid email or password';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

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
      _error =
          'Registration failed. Check your connection or use another email.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

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

  Future<void> logout() async {
    try {
      await AuthService().logout();
    } catch (_) {}
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
      debugPrint(_error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
