import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel with ChangeNotifier {
  final SupabaseClient _supabaseClient;
  bool _isAuthenticated = false;
  String? _userRole;
  String? _userEmail;
  String? _dentistId;

  AuthViewModel(this._supabaseClient) {
    _checkAuthState();
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _isAuthenticated = true;
        _userEmail = _supabaseClient.auth.currentUser?.email;
        print('User signed in: $_userEmail');
        _fetchUserRoleAndDentistId();
      } else if (event == AuthChangeEvent.signedOut) {
        _isAuthenticated = false;
        _userRole = null;
        _userEmail = null;
        _dentistId = null;
        print('User signed out');
      }
      notifyListeners();
    });
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;
  String? get userEmail => _userEmail;
  String? get dentistId => _dentistId;

  Future<void> _checkAuthState() async {
    final session = _supabaseClient.auth.currentSession;
    if (session != null) {
      _isAuthenticated = true;
      _userEmail = session.user.email;
      print('Session found for user: $_userEmail');
      await _fetchUserRoleAndDentistId();
      notifyListeners();
    }
  }

  Future<void> _fetchUserRoleAndDentistId() async {
    try {
      print('Fetching role for email: $_userEmail');
      final userResponse = await _supabaseClient
          .from('Users')
          .select('role')
          .eq('email', _userEmail!)
          .maybeSingle();
      print('User response: $userResponse');
      _userRole = userResponse?['role'] as String?;

      print('Fetching Dentist ID for email: $_userEmail');
      final dentistResponse = await _supabaseClient
          .from('Dentist')
          .select('id')
          .eq('Email', _userEmail!)
          .maybeSingle();
      print('Dentist response: $dentistResponse');
      _dentistId = dentistResponse?['id']?.toString();
    } catch (e) {
      print('Error fetching role or dentist ID: $e');
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
