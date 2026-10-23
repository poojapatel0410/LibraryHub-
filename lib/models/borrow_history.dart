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
  final int finePaid; // Cash amount in INR (₹) collected from the user so far
  final DateTime? actualReturnDate; // Physical return timestamp
  final int? frozenFine; // Snapshot of overdue fine at return time or when assessed
  final DateTime? lastPaymentDate; // Timestamp of the last cash fine payment

  const BorrowHistory({
    required this.transactionId,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.borrowDate,
    required this.returnDate,
    required this.status,
    this.finePaid = 0,
    this.actualReturnDate,
    this.frozenFine,
    this.lastPaymentDate,
  });

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate().toLocal();
    if (val is DateTime) return val.toLocal();
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    }
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  /// Returns the actual return date, or falls back to returnDate if already marked Returned.
  DateTime? get effectiveReturnDate =>
      actualReturnDate ?? (!isActive ? returnDate : null);

  /// Creates a [BorrowHistory] from a Firestore document snapshot map.
  factory BorrowHistory.fromMap(Map<String, dynamic> map, String documentId) {
    return BorrowHistory(
      transactionId: documentId,
      userId: map['userId'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      bookTitle: map['bookTitle'] as String? ?? 'Unknown Book',
      borrowDate: _parseDateTime(map['borrowDate']) ?? DateTime.now(),
      returnDate: _parseDateTime(map['returnDate']) ?? DateTime.now(),
      status: map['status'] as String? ?? 'Active',
      finePaid: (map['finePaid'] as num?)?.toInt() ?? 0,
      actualReturnDate: _parseDateTime(map['actualReturnDate']),
      frozenFine: (map['frozenFine'] as num?)?.toInt(),
      lastPaymentDate: _parseDateTime(map['lastPaymentDate']),
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
      'finePaid': finePaid,
      if (actualReturnDate != null)
        'actualReturnDate': Timestamp.fromDate(actualReturnDate!),
      if (frozenFine != null) 'frozenFine': frozenFine,
      if (lastPaymentDate != null)
        'lastPaymentDate': Timestamp.fromDate(lastPaymentDate!),
    };
  }

  /// Returns true if this borrow is currently active (not yet returned).
  bool get isActive => status == 'Active';

  /// Returns true if this loan has exceeded its due date.
  bool get isOverdue {
    if (isActive) {
      return DateTime.now().isAfter(returnDate);
    } else if (actualReturnDate != null) {
      return actualReturnDate!.isAfter(returnDate);
    } else {
      return (frozenFine != null && frozenFine! > 0) || finePaid > 0;
    }
  }

  /// Overdue fine rate (₹3 per book per day).
  static const int dailyFineRate = 3;

  /// Number of whole days overdue (minimum 1 day if return date has passed).
  int get overdueDays {
    if (!isOverdue) return 0;
    if (frozenFine != null && frozenFine! > 0) {
      return (frozenFine! / dailyFineRate).ceil();
    }
    final referenceDate =
        isActive ? DateTime.now() : (actualReturnDate ?? returnDate);
    final diff = referenceDate.difference(returnDate);
    final days = diff.inDays;
    return days > 0 ? days : 1;
  }

  /// Total calculated/assessed overdue fine amount in INR (₹).
  int get totalFine {
    if (frozenFine != null && frozenFine! > 0) {
      return frozenFine!;
    }
    return overdueDays * dailyFineRate;
  }

  /// Backward-compatible alias for totalFine.
  int get overdueFine => totalFine;

  /// Remaining unpaid cash fine balance in INR (₹).
  /// E.g. If fee is ₹12 and user paid ₹10, remainingFine is ₹2.
  int get remainingFine {
    final balance = totalFine - finePaid;
    return balance > 0 ? balance : 0;
  }

  /// True if a fine has been incurred/assessed on this book.
  bool get hasFine => totalFine > 0;

  /// True if the user has paid part of the fine but still has an outstanding balance.
  bool get isPartiallyPaid => finePaid > 0 && remainingFine > 0;

  /// True if the fine is completely settled.
  bool get isFineFullyPaid => totalFine > 0 && remainingFine == 0;

  @override
  String toString() =>
      'BorrowHistory(transactionId: $transactionId, bookTitle: $bookTitle, status: $status, totalFine: ₹$totalFine, paid: ₹$finePaid, remaining: ₹$remainingFine)';
}
