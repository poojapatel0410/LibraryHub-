import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

/// Handles all Firebase Authentication and user document operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -- Stream -----------------------------------------------------------------

  /// Stream of auth state changes. Emits [User?] on every auth event.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase [User], or null if not signed in.
  User? get currentUser => _auth.currentUser;

  // -- Registration -----------------------------------------------------------

  /// Registers a new user with email/password and creates a Firestore user doc.
  ///
  /// Throws [FirebaseAuthException] on auth errors.
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String name = '',
    String contact = '',
    String address = '',
    String education = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? email.trim(),
      role: email.trim().toLowerCase() == 'admin@libraryhub.com'
          ? 'admin'
          : AppConstants.roleStudent,
      name: name.trim(),
      contact: contact.trim(),
      address: address.trim(),
      education: education.trim(),
    );

    // Persist user document to Firestore
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // -- Sign In ----------------------------------------------------------------

  /// Signs in an existing user with email/password.
  /// Handles auto-creation of default admin if not yet registered.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    // Auto-setup for default admin credentials
    if (cleanEmail.toLowerCase() == 'admin@libraryhub.com') {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        // Ensure role is admin
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set({
          'role': 'admin',
          'name': 'Library Administrator',
        }, SetOptions(merge: true));
        return credential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'wrong-password') {
          // If admin doesn't exist, create it with role admin
          try {
            final adminModel = await registerWithEmail(
              email: cleanEmail,
              password: password,
              name: 'Library Administrator',
              contact: '+1 800-LIBRARY',
              education: 'Head Librarian',
              address: 'Central Library Administration Block',
            );
            await _firestore
                .collection(AppConstants.usersCollection)
                .doc(adminModel.uid)
                .update({'role': 'admin'});
            return _auth.currentUser;
          } catch (_) {
            rethrow;
          }
        }
        rethrow;
      }
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    return credential.user;
  }

  // -- Sign Out ---------------------------------------------------------------

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -- User Document ----------------------------------------------------------

  /// Fetches the [UserModel] document for the currently signed-in user.
  Future<UserModel?> fetchCurrentUserModel() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return fetchUserModelById(uid);
  }

  /// Fetches the [UserModel] document by user ID.
  Future<UserModel?> fetchUserModelById(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Real-time stream of the user profile document.
  Stream<UserModel?> userModelStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? UserModel.fromMap(doc.data()!)
            : null);
  }

  /// Updates editable profile fields in Firestore.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String contact,
    required String address,
    required String education,
  }) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'name': name.trim(),
      'contact': contact.trim(),
      'address': address.trim(),
      'education': education.trim(),
    }, SetOptions(merge: true));
  }

  // -- Error Helper -----------------------------------------------------------

  /// Converts a [FirebaseAuthException] code to a user-friendly message.
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
