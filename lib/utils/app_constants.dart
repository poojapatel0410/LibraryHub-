/// App-wide constants and string literals.
class AppConstants {
  AppConstants._();

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String borrowHistoryCollection = 'borrow_history';

  // Borrow status values
  static const String statusActive = 'Active';
  static const String statusReturned = 'Returned';

  // Default user role
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';

  // App info
  static const String appName = 'LibraryHub';
  static const String appTagline = 'Your digital reading companion';

  // Error messages
  static const String genericError = 'An unexpected error occurred. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please check your credentials.';
}
