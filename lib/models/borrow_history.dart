import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a transaction document in the Firestore `borrow_history` collection.
class BorrowHistory {
  final String transactionId;
  final String userId;
  final String bookId;
  final String bookTitle;
  final DateTime borrowDate;
  final DateTime returnDate;
  final String status; // "Active" | "Returned"

  const BorrowHistory({
    required this.transactionId,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.borrowDate,
    required this.returnDate,
    required this.status,
  });

  /// Creates a [BorrowHistory] from a Firestore document snapshot map.
  factory BorrowHistory.fromMap(Map<String, dynamic> map, String documentId) {
    return BorrowHistory(
      transactionId: documentId,
      userId: map['userId'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      bookTitle: map['bookTitle'] as String? ?? 'Unknown Book',
      borrowDate: (map['borrowDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnDate:
          (map['returnDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'Active',
    );
  }

  /// Converts this [BorrowHistory] to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'returnDate': Timestamp.fromDate(returnDate),
      'status': status,
    };
  }

  /// Returns true if this borrow is currently active (not yet returned).
  bool get isActive => status == 'Active';

  /// Returns true if the return date has passed and book is still active.
  bool get isOverdue => isActive && DateTime.now().isAfter(returnDate);

  @override
  String toString() =>
      'BorrowHistory(transactionId: $transactionId, bookTitle: $bookTitle, status: $status)';
}
