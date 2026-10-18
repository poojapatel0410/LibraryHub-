import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/borrow_history.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../home/home_screen.dart';

/// Admin Dashboard allowing library administrators to:
/// - Track registered students & their issued/returned books.
/// - Add new books to the catalogue with title, author, description, copies.
/// - View overall library statistics in real-time.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentTab = 0; // 0: Students & Activity, 1: Book Inventory, 2: Add Book

  // Add Book Form Controllers
  final _addBookFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _copiesController = TextEditingController(text: '5');
  final _descController = TextEditingController();
  bool _isAddingBook = false;

  // Search filter for students
  String _userSearchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _copiesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleAddBook() async {
    if (!_addBookFormKey.currentState!.validate()) return;

    setState(() => _isAddingBook = true);

    try {
      final copies = int.tryParse(_copiesController.text.trim()) ?? 1;

      await _firestoreService.addBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descController.text.trim(),
        availableCopies: copies,
      );

      if (!mounted) return;
      setState(() {
        _isAddingBook = false;
        _titleController.clear();
        _authorController.clear();
        _descController.clear();
        _copiesController.text = '5';
        _currentTab = 1; // Switch to Inventory view
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('New book published to catalogue successfully!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.bgCardLight,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAddingBook = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add book: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildStudentsAndActivityTab(),
                    _buildInventoryTab(),
                    _buildAddBookTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Portal',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'LibraryHub Management',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Student View button
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded,
                size: 16, color: AppTheme.primary),
            label: Text(
              'Student View',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.error, size: 20),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.textMuted.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt_rounded),
            label: 'Students & Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Book Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Add New Book',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: Students & Activity Tracking
  // ===========================================================================

  Widget _buildStudentsAndActivityTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.usersStream(),
      builder: (context, userSnapshot) {
        return StreamBuilder<List<BorrowHistory>>(
          stream: _firestoreService.allBorrowHistoryStream(),
          builder: (context, historySnapshot) {
            final users = userSnapshot.data ?? [];
            final history = historySnapshot.data ?? [];

            // Calculate overall metrics
            final totalStudents = users.length;
            final activeLoans = history.where((h) => h.isActive).length;
            final returnedLoans = history.where((h) => !h.isActive).length;

            final filteredUsers = users.where((u) {
              if (_userSearchQuery.isEmpty) return true;
              final q = _userSearchQuery.toLowerCase();
              return u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q) ||
                  u.contact.toLowerCase().contains(q);
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Students',
                          value: '$totalStudents',
                          icon: Icons.groups_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Active Borrows',
                          value: '$activeLoans',
                          icon: Icons.book_online_rounded,
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Returned',
                          value: '$returnedLoans',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search Users Field
                  TextField(
                    onChanged: (val) => setState(() => _userSearchQuery = val),
                    style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search student by name, email, or contact...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textMuted, size: 20),
                      filled: true,
                      fillColor: AppTheme.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STUDENT ACTIVITY TRACKING',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${filteredUsers.length} students',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (userSnapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    )
                  else if (filteredUsers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'No students found matching "$_userSearchQuery"',
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    ...filteredUsers.map((user) {
                      // Get this student's loans
                      final studentLoans =
                          history.where((h) => h.userId == user.uid).toList();
                      final issuedCount =
                          studentLoans.where((h) => h.isActive).length;
                      final returnedCount =
                          studentLoans.where((h) => !h.isActive).length;

                      return _buildStudentCard(
                        user: user,
                        issuedCount: issuedCount,
                        returnedCount: returnedCount,
                        loans: studentLoans,
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required UserModel user,
    required int issuedCount,
    required int returnedCount,
    required List<BorrowHistory> loans,
  }) {
    final displayName = user.name.isNotEmpty
        ? user.name
        : (user.email.isNotEmpty ? user.email.split('@').first : 'Student');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            foregroundColor: AppTheme.primary,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            displayName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildLoanBadge('Issued: $issuedCount',
                      issuedCount > 0 ? AppTheme.warning : AppTheme.textMuted),
                  const SizedBox(width: 8),
                  _buildLoanBadge('Returned: $returnedCount', AppTheme.success),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 6),
                  _buildUserDetailRow(
                      Icons.phone_android_rounded, 'Contact', user.contact),
                  _buildUserDetailRow(
                      Icons.school_rounded, 'Education', user.education),
                  _buildUserDetailRow(
                      Icons.location_on_rounded, 'Address', user.address),
                  const SizedBox(height: 12),
                  Text(
                    'Borrow Records (${loans.length}):',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (loans.isEmpty)
                    Text(
                      'No books borrowed yet.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...loans.map(
                      (loan) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCardLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              loan.isActive
                                  ? Icons.book_rounded
                                  : Icons.check_circle_outline,
                              size: 14,
                              color: loan.isActive
                                  ? AppTheme.warning
                                  : AppTheme.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loan.bookTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              loan.status,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: loan.isActive
                                  ? AppTheme.warning
                                  : AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(IconData icon, String label, String value) {
    final val = value.isNotEmpty ? value : 'Not provided';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              val,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: value.isNotEmpty
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: Book Inventory
  // ===========================================================================

  Widget _buildInventoryTab() {
    return StreamBuilder<List<Book>>(
      stream: _firestoreService.booksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final books = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT CATALOGUE INVENTORY',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${books.length} titles',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (books.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'No books in inventory. Tap "Add New Book" below!',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                ),
              )
            else
              ...books.map((book) => _buildInventoryBookCard(book)),
          ],
        );
      },
    );
  }

  Widget _buildInventoryBookCard(Book book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 62,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${book.author}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                ),
                if (book.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    book.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: book.availableCopies > 0
                            ? AppTheme.success.withValues(alpha: 0.15)
                            : AppTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${book.availableCopies} available',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: book.availableCopies > 0
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Adjust copies
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.textMuted, size: 20),
                      onPressed: book.availableCopies > 0
                          ? () {
                              _firestoreService.updateBookCopies(
                                  book.bookId, book.availableCopies - 1);
                            }
                          : null,
                    ),
                    Text(
                      '${book.availableCopies}',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppTheme.primary, size: 20),
                      onPressed: () {
                        _firestoreService.updateBookCopies(
                            book.bookId, book.availableCopies + 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: Add New Book Form
  // ===========================================================================

  Widget _buildAddBookTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Form(
        key: _addBookFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADD BOOK TO CATALOGUE',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fill in the book details. Once published, students can immediately discover and borrow it.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Book Title
            _buildFieldLabel('Book Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'e.g., Clean Code, Data Structures',
                icon: Icons.title_rounded,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter book title';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Author Name
            _buildFieldLabel('Author Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _authorController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'e.g., Robert C. Martin, George Orwell',
                icon: Icons.person_outline_rounded,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter author name';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Available Copies
            _buildFieldLabel('Number of Available Copies *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _copiesController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'e.g., 5',
                icon: Icons.copy_rounded,
              ),
              validator: (val) {
                final n = int.tryParse(val ?? '');
                if (n == null || n < 1) {
                  return 'Must have at least 1 copy available';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Description
            _buildFieldLabel('Book Description / Summary'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                hint: 'Enter a short summary or description of the book...',
                icon: Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            GradientButton(
              label: 'Publish Book to Catalogue',
              icon: Icons.publish_rounded,
              isLoading: _isAddingBook,
              onPressed: _isAddingBook ? null : _handleAddBook,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      filled: true,
      fillColor: AppTheme.bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}
