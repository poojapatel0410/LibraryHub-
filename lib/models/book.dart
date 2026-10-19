/// Represents a book document in the Firestore `books` collection.
class Book {
  final String bookId;
  final String title;
  final String author;
  final String description;
  final int availableCopies;
  final String imageUrl;

  const Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.description,
    required this.availableCopies,
    this.imageUrl = '',
  });

  /// True if book has a valid web image URL.
  bool get hasImage =>
      imageUrl.trim().isNotEmpty &&
      (imageUrl.trim().startsWith('http://') ||
          imageUrl.trim().startsWith('https://'));

  /// Creates a [Book] from a Firestore document snapshot map with flexible
  /// key matching to handle common typos like 'auther', 'Author', etc.
  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      bookId: documentId,
      title: _extractTitle(map),
      author: _extractAuthor(map),
      description: _extractDescription(map),
      availableCopies: _extractCopies(map),
      imageUrl: _extractImageUrl(map),
    );
  }

  static String _extractAuthor(Map<String, dynamic> map) {
    // 1. Direct priority check (including common typo 'auther')
    for (final key in [
      'author',
      'auther',
      'Author',
      'Auther',
      'writer',
      'Writer',
      'author_name',
      'authorName',
      'book_author',
      'by',
    ]) {
      if (map.containsKey(key) &&
          map[key] != null &&
          map[key].toString().trim().isNotEmpty) {
        return map[key].toString().trim();
      }
    }

    // 2. Case-insensitive fuzzy search
    for (final entry in map.entries) {
      final normalizedKey =
          entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (normalizedKey == 'author' ||
          normalizedKey == 'auther' ||
          normalizedKey == 'writer') {
        if (entry.value != null &&
            entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
    }

    return 'Unknown Author';
  }

  static String _extractTitle(Map<String, dynamic> map) {
    for (final key in [
      'title',
      'Title',
      'name',
      'Name',
      'bookTitle',
      'book_title'
    ]) {
      if (map.containsKey(key) &&
          map[key] != null &&
          map[key].toString().trim().isNotEmpty) {
        return map[key].toString().trim();
      }
    }
    for (final entry in map.entries) {
      final normalizedKey =
          entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (normalizedKey == 'title' || normalizedKey == 'booktitle') {
        if (entry.value != null &&
            entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
    }
    return 'Unknown Title';
  }

  static String _extractDescription(Map<String, dynamic> map) {
    for (final key in [
      'description',
      'Description',
      'desc',
      'Desc',
      'about',
      'summary'
    ]) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key].toString().trim();
      }
    }
    for (final entry in map.entries) {
      final normalizedKey =
          entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (normalizedKey == 'description' || normalizedKey == 'desc') {
        if (entry.value != null) {
          return entry.value.toString().trim();
        }
      }
    }
    return '';
  }

  static int _extractCopies(Map<String, dynamic> map) {
    for (final key in [
      'availableCopies',
      'available_copies',
      'AvailableCopies',
      'copies',
      'Copies',
      'available',
      'stock',
      'totalCopies',
      'total_copies',
    ]) {
      if (map.containsKey(key) && map[key] != null) {
        final val = map[key];
        if (val is num) return val.toInt();
        if (val is String) {
          final parsed = int.tryParse(val.trim());
          if (parsed != null) return parsed;
        }
      }
    }
    return 0;
  }

  static String _extractImageUrl(Map<String, dynamic> map) {
    for (final key in [
      'imageUrl',
      'image_url',
      'image',
      'Image',
      'coverImage',
      'cover_image',
      'cover',
      'thumbnail',
      'book_image',
      'photo',
    ]) {
      if (map.containsKey(key) &&
          map[key] != null &&
          map[key].toString().trim().isNotEmpty) {
        return map[key].toString().trim();
      }
    }
    for (final entry in map.entries) {
      final normalizedKey =
          entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (normalizedKey == 'imageurl' ||
          normalizedKey == 'coverimage' ||
          normalizedKey == 'bookimage' ||
          normalizedKey == 'thumbnail') {
        if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
    }
    return '';
  }

  /// Converts this [Book] to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'description': description,
      'availableCopies': availableCopies,
      'imageUrl': imageUrl,
    };
  }

  /// Returns a copy of this [Book] with the given fields updated.
  Book copyWith({
    String? bookId,
    String? title,
    String? author,
    String? description,
    int? availableCopies,
    String? imageUrl,
  }) {
    return Book(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      availableCopies: availableCopies ?? this.availableCopies,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() =>
      'Book(bookId: $bookId, title: $title, author: $author, availableCopies: $availableCopies, imageUrl: $imageUrl)';
}
