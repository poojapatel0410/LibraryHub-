import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/borrow_history.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

/// Handles all Firestore read/write operations for books, borrow history, and users.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // -- Books ------------------------------------------------------------------

  /// Returns a real-time stream of all [Book] documents, ordered by title.
  Stream<List<Book>> booksStream() {
    return _db
        .collection(AppConstants.booksCollection)
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetches a single [Book] by its document ID.
  Future<Book?> fetchBook(String bookId) async {
    final doc = await _db
        .collection(AppConstants.booksCollection)
        .doc(bookId)
        .get();
    if (!doc.exists) return null;
    return Book.fromMap(doc.data()!, doc.id);
  }

  /// Adds a new book to the library catalogue (Admin feature).
  Future<void> addBook({
    required String title,
    required String author,
    required String description,
    required int availableCopies,
    String imageUrl = '',
  }) async {
    final bookId = _uuid.v4();
    final book = Book(
      bookId: bookId,
      title: title.trim(),
      author: author.trim(),
      description: description.trim(),
      availableCopies: availableCopies,
      imageUrl: imageUrl.trim(),
    );
    await _db
        .collection(AppConstants.booksCollection)
        .doc(bookId)
        .set(book.toMap());
  }

  /// Updates available copy count for a book.
  Future<void> updateBookCopies(String bookId, int newCopies) async {
    await _db.collection(AppConstants.booksCollection).doc(bookId).update({
      'availableCopies': newCopies,
    });
  }

  /// Deletes a book from the library catalogue.
  Future<void> deleteBook(String bookId) async {
    await _db.collection(AppConstants.booksCollection).doc(bookId).delete();
  }

  // -- Borrow History ---------------------------------------------------------

  /// Returns a real-time stream of [BorrowHistory] for a specific user,
  /// ordered by borrow date descending.
  Stream<List<BorrowHistory>> borrowHistoryStream(String userId) {
    return _db
        .collection(AppConstants.borrowHistoryCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => BorrowHistory.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      return items;
    });
  }

  /// Returns a real-time stream of all [BorrowHistory] records across all students (Admin feature).
  Stream<List<BorrowHistory>> allBorrowHistoryStream() {
    return _db
        .collection(AppConstants.borrowHistoryCollection)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => BorrowHistory.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      return items;
    });
  }

  // -- Users / Students -------------------------------------------------------

  /// Returns a real-time stream of all registered student accounts (Admin feature).
  Stream<List<UserModel>> usersStream() {
    return _db
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // -- Borrow Transaction -----------------------------------------------------

  /// Executes an atomic batched write to borrow a book:
  ///   1. Creates a new document in `borrow_history`.
  ///   2. Decrements `availableCopies` in the `books` document by 1.
  ///
  /// Throws a [StateError] if the book has no available copies.
  /// Throws [FirebaseException] on write failure.
  Future<void> borrowBook({
    required String userId,
    required Book book,
    required DateTime returnDate,
  }) async {
    // Guard: verify copies are available before writing
    if (book.availableCopies <= 0) {
      throw StateError('No available copies for "${book.title}".');
    }

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    final WriteBatch batch = _db.batch();

    // 1. Create borrow_history document
    final historyRef = _db
        .collection(AppConstants.borrowHistoryCollection)
        .doc(transactionId);

    final history = BorrowHistory(
      transactionId: transactionId,
      userId: userId,
      bookId: book.bookId,
      bookTitle: book.title,
      borrowDate: now,
      returnDate: returnDate,
      status: AppConstants.statusActive,
    );

    batch.set(historyRef, history.toMap());

    // 2. Decrement availableCopies in books document
    final bookRef =
        _db.collection(AppConstants.booksCollection).doc(book.bookId);

    batch.update(bookRef, {
      'availableCopies': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // -- Return Book ------------------------------------------------------------

  /// Marks a borrow transaction as "Returned" and increments `availableCopies`.
  /// Also preserves [actualReturnDate] and optionally captures [currentOverdueFine] snapshot.
  Future<void> returnBook({
    required String transactionId,
    required String bookId,
    int? currentOverdueFine,
  }) async {
    final WriteBatch batch = _db.batch();
    final now = DateTime.now();

    // Update borrow_history status
    final historyRef = _db
        .collection(AppConstants.borrowHistoryCollection)
        .doc(transactionId);

    final Map<String, dynamic> historyUpdates = {
      'status': AppConstants.statusReturned,
      'actualReturnDate': Timestamp.fromDate(now),
    };

    if (currentOverdueFine != null && currentOverdueFine > 0) {
      historyUpdates['frozenFine'] = currentOverdueFine;
    }

    batch.update(historyRef, historyUpdates);

    // Increment availableCopies
    final bookRef =
        _db.collection(AppConstants.booksCollection).doc(bookId);
    batch.update(bookRef, {
      'availableCopies': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // -- Fine Payment Management ------------------------------------------------

  /// Records a cash fine payment collected by the admin for a borrow transaction.
  /// If [newTotalPaid] is specified, explicitly sets the total paid cash.
  /// If [amountReceived] is specified, increments existing `finePaid` atomically.
  /// If [freezeFine] is provided, locks the assessed fine snapshot.
  Future<void> recordFinePayment({
    required String transactionId,
    int? amountReceived,
    int? newTotalPaid,
    int? freezeFine,
  }) async {
    final docRef = _db
        .collection(AppConstants.borrowHistoryCollection)
        .doc(transactionId);

    final Map<String, dynamic> updates = {
      'lastPaymentDate': Timestamp.now(),
    };

    if (newTotalPaid != null) {
      updates['finePaid'] = newTotalPaid;
    } else if (amountReceived != null) {
      updates['finePaid'] = FieldValue.increment(amountReceived);
    }

    if (freezeFine != null && freezeFine > 0) {
      updates['frozenFine'] = freezeFine;
    }

    await docRef.update(updates);
  }
}
