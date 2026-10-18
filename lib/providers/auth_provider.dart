import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Exposes authentication state and operations via [ChangeNotifier].
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userDocSubscription;

  AuthProvider(this._authService) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _subscribeToUserDoc(user.uid);
      } else {
        _userDocSubscription?.cancel();
        _userDocSubscription = null;
        _userModel = null;
        notifyListeners();
      }
    });
  }

  void _subscribeToUserDoc(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _authService.userModelStream(uid).listen((model) {
      _userModel = model;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  // -- State ------------------------------------------------------------------

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _authService.currentUser;

  // -- Helpers ----------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // -- Register ---------------------------------------------------------------

  /// Registers a new user. Returns true on success, false on failure.
  Future<bool> register({
    required String email,
    required String password,
    String name = '',
    String contact = '',
    String address = '',
    String education = '',
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _userModel = await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        contact: contact,
        address: address,
        education: education,
      );
      if (_userModel != null) {
        _subscribeToUserDoc(_userModel!.uid);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // -- Sign In ----------------------------------------------------------------

  /// Signs in an existing user. Returns true on success, false on failure.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _authService.signInWithEmail(email: email, password: password);
      if (user != null) {
        _subscribeToUserDoc(user.uid);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // -- Update Profile ---------------------------------------------------------

  /// Updates student profile details (name, contact, address, education).
  Future<bool> updateProfile({
    required String name,
    required String contact,
    required String address,
    required String education,
  }) async {
    final uid = firebaseUser?.uid;
    if (uid == null) {
      _setError('User session expired. Please log in again.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _authService.updateUserProfile(
        uid: uid,
        name: name,
        contact: contact,
        address: address,
        education: education,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // -- Sign Out ---------------------------------------------------------------

  Future<void> signOut() async {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  // -- Fetch User Model -------------------------------------------------------

  Future<void> fetchUserModel() async {
    final uid = firebaseUser?.uid;
    if (uid != null) {
      _userModel = await _authService.fetchUserModelById(uid);
      notifyListeners();
    }
  }
}
