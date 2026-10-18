/// Represents a user document in the Firestore `users` collection.
class UserModel {
  final String uid;
  final String email;
  final String role; // "student" | "admin"
  final String name;
  final String contact;
  final String address;
  final String education;

  const UserModel({
    required this.uid,
    required this.email,
    this.role = 'student',
    this.name = '',
    this.contact = '',
    this.address = '',
    this.education = '',
  });

  /// Creates a [UserModel] from a Firestore document snapshot map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      name: map['name'] as String? ?? '',
      contact: (map['contact'] ?? map['mobile'] ?? map['phone']) as String? ?? '',
      address: map['address'] as String? ?? '',
      education: map['education'] as String? ?? '',
    );
  }

  /// Converts this [UserModel] to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'contact': contact,
      'address': address,
      'education': education,
    };
  }

  /// Checks if all required student profile fields are filled.
  /// Users cannot borrow books until contact, education, and address are set.
  bool get isProfileComplete =>
      name.trim().isNotEmpty &&
      contact.trim().isNotEmpty &&
      address.trim().isNotEmpty &&
      education.trim().isNotEmpty;

  /// Returns list of missing profile field names for clear user feedback.
  List<String> get missingFields {
    final missing = <String>[];
    if (name.trim().isEmpty) missing.add('Full Name');
    if (contact.trim().isEmpty) missing.add('Contact Number');
    if (education.trim().isEmpty) missing.add('Education / Course');
    if (address.trim().isEmpty) missing.add('Address');
    return missing;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? contact,
    String? address,
    String? education,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      education: education ?? this.education,
    );
  }

  bool get isAdmin => role == 'admin';

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, name: $name, contact: $contact, education: $education)';
}
