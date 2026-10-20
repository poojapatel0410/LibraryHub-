import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/borrow_history.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/book_cover_image.dart';
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
  int _currentTab = 0; // 0: Students & Activity, 1: Pending Fines, 2: Book Inventory, 3: Add Book

  // Add Book Form Controllers
  final _addBookFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _copiesController = TextEditingController(text: '5');
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isAddingBook = false;
  bool _isPickingImage = false;
  String? _pickedImageName;

  // Search filter for students
  String _userSearchQuery = '';
  // Search filter for pending fines section
  String _pendingFinesSearchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _copiesController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _imageUrlController.text = base64String;
          _pickedImageName = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access gallery: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
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
        imageUrl: _imageUrlController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isAddingBook = false;
        _titleController.clear();
        _authorController.clear();
        _descController.clear();
        _imageUrlController.clear();
        _pickedImageName = null;
        _copiesController.text = '5';
        _currentTab = 2; // Switch to Inventory view
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
                    _buildPendingFinesTab(),
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
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<List<BorrowHistory>>(
              stream: _firestoreService.allBorrowHistoryStream(),
              builder: (context, snapshot) {
                final history = snapshot.data ?? [];
                final count = history.where((h) => h.remainingFine > 0).length;
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    backgroundColor: AppTheme.error,
                    child: const Icon(Icons.payments_outlined),
                  );
                }
                return const Icon(Icons.payments_outlined);
              },
            ),
            activeIcon: StreamBuilder<List<BorrowHistory>>(
              stream: _firestoreService.allBorrowHistoryStream(),
              builder: (context, snapshot) {
                final history = snapshot.data ?? [];
                final count = history.where((h) => h.remainingFine > 0).length;
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    backgroundColor: AppTheme.error,
                    child: const Icon(Icons.payments_rounded),
                  );
                }
                return const Icon(Icons.payments_rounded);
              },
            ),
            label: 'Pending Fines',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Add Book',
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

            final totalFinesAssessed = history
                .where((h) => h.hasFine)
                .fold<int>(0, (sum, h) => sum + h.totalFine);
            final totalCashCollected = history
                .fold<int>(0, (sum, h) => sum + h.finePaid);
            final totalFinesPending = history
                .fold<int>(0, (sum, h) => sum + h.remainingFine);
            final unpaidLoansCount =
                history.where((h) => h.remainingFine > 0).length;

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

                  // Cash Fines to Collect Banner (if any pending or collected)
                  if (totalFinesPending > 0 || totalCashCollected > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (totalFinesPending > 0
                                    ? AppTheme.error
                                    : AppTheme.success)
                                .withValues(alpha: 0.18),
                            AppTheme.warning.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (totalFinesPending > 0
                                  ? AppTheme.error
                                  : AppTheme.success)
                              .withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (totalFinesPending > 0
                                      ? AppTheme.error
                                      : AppTheme.success)
                                  .withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              totalFinesPending > 0
                                  ? Icons.payments_rounded
                                  : Icons.check_circle_rounded,
                              color: totalFinesPending > 0
                                  ? AppTheme.error
                                  : AppTheme.success,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Cash Fines Pending: ',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₹$totalFinesPending',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: totalFinesPending > 0
                                            ? AppTheme.error
                                            : AppTheme.success,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total Assessed: ₹$totalFinesAssessed • Cash Collected: ₹$totalCashCollected • $unpaidLoansCount loan(s) pending payment',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (totalFinesPending > 0) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    AppTheme.error.withValues(alpha: 0.15),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 13, color: AppTheme.error),
                              label: Text(
                                'View Section',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.error,
                                ),
                              ),
                              onPressed: () =>
                                  setState(() => _currentTab = 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

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
                      final studentTotalFine = studentLoans
                          .where((h) => h.hasFine)
                          .fold<int>(0, (sum, h) => sum + h.totalFine);
                      final studentFinePaid = studentLoans
                          .fold<int>(0, (sum, h) => sum + h.finePaid);
                      final studentRemainingFine = studentLoans
                          .fold<int>(0, (sum, h) => sum + h.remainingFine);
                      final studentOverdueCount =
                          studentLoans.where((h) => h.isOverdue).length;

                      return _buildStudentCard(
                        user: user,
                        issuedCount: issuedCount,
                        returnedCount: returnedCount,
                        loans: studentLoans,
                        studentTotalFine: studentTotalFine,
                        studentFinePaid: studentFinePaid,
                        studentRemainingFine: studentRemainingFine,
                        studentOverdueCount: studentOverdueCount,
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
    required int studentTotalFine,
    required int studentFinePaid,
    required int studentRemainingFine,
    required int studentOverdueCount,
  }) {
    final displayName = user.name.isNotEmpty
        ? user.name
        : (user.email.isNotEmpty ? user.email.split('@').first : 'Student');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildLoanBadge('Issued: $issuedCount',
                      issuedCount > 0 ? AppTheme.warning : AppTheme.textMuted),
                  _buildLoanBadge('Returned: $returnedCount', AppTheme.success),
                  if (studentRemainingFine > 0)
                    _buildLoanBadge('Due: ₹$studentRemainingFine', AppTheme.error),
                  if (studentFinePaid > 0)
                    _buildLoanBadge('Paid: ₹$studentFinePaid', AppTheme.success),
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
                  if (studentTotalFine > 0) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (studentRemainingFine > 0
                                ? AppTheme.error
                                : AppTheme.success)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: (studentRemainingFine > 0
                                    ? AppTheme.error
                                    : AppTheme.success)
                                .withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            studentRemainingFine > 0
                                ? Icons.payments_rounded
                                : Icons.check_circle_rounded,
                            color: studentRemainingFine > 0
                                ? AppTheme.error
                                : AppTheme.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentRemainingFine > 0
                                      ? 'Cash Fine Due: ₹$studentRemainingFine (Total Fee: ₹$studentTotalFine)'
                                      : 'All Cash Fines Settled: ₹$studentFinePaid Paid ✓',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: studentRemainingFine > 0
                                        ? AppTheme.error
                                        : AppTheme.success,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  studentRemainingFine > 0
                                      ? 'Paid: ₹$studentFinePaid • Remaining balance: ₹$studentRemainingFine. Tap "Manage Cash" below to record payment.'
                                      : 'Student has no pending late fee balance.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      (loan) {
                        final hasFine = loan.hasFine;
                        final totalFine = loan.totalFine;
                        final finePaid = loan.finePaid;
                        final remainingFine = loan.remainingFine;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: remainingFine > 0
                                ? AppTheme.error.withValues(alpha: 0.08)
                                : AppTheme.bgCardLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (remainingFine > 0
                                      ? AppTheme.error
                                      : (hasFine
                                          ? AppTheme.success
                                          : Colors.white10))
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    remainingFine > 0
                                        ? Icons.warning_amber_rounded
                                        : (loan.isActive
                                            ? Icons.book_rounded
                                            : Icons.check_circle_outline),
                                    size: 16,
                                    color: remainingFine > 0
                                        ? AppTheme.error
                                        : (loan.isActive
                                            ? AppTheme.warning
                                            : AppTheme.success),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      loan.bookTitle,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (loan.isActive
                                              ? AppTheme.warning
                                              : AppTheme.success)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      loan.status,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: loan.isActive
                                            ? AppTheme.warning
                                            : AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasFine) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fee: ₹$totalFine • Paid: ₹$finePaid • Due: ₹$remainingFine',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: remainingFine > 0
                                                  ? AppTheme.error
                                                  : AppTheme.success,
                                            ),
                                          ),
                                          Text(
                                            remainingFine > 0
                                                ? 'Late by ${loan.overdueDays} day(s) • ₹3/day'
                                                : 'Fine fully settled in cash',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        backgroundColor: remainingFine > 0
                                            ? AppTheme.primary
                                                .withValues(alpha: 0.2)
                                            : AppTheme.success
                                                .withValues(alpha: 0.15),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
                                      ),
                                      icon: Icon(
                                        remainingFine > 0
                                            ? Icons.payments_rounded
                                            : Icons.check_circle_rounded,
                                        size: 13,
                                        color: remainingFine > 0
                                            ? AppTheme.primary
                                            : AppTheme.success,
                                      ),
                                      label: Text(
                                        remainingFine > 0
                                            ? 'Manage Cash (₹$remainingFine)'
                                            : 'Cash Paid ✓',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: remainingFine > 0
                                              ? AppTheme.primary
                                              : AppTheme.success,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showManageCashDialog(loan, user),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showManageCashDialog(BorrowHistory loan, UserModel user) {
    final amountController =
        TextEditingController(text: loan.remainingFine.toString());
    bool isSetDirectly = false;
    bool alsoReturnBook = loan.isActive;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final int enteredAmount =
                int.tryParse(amountController.text.trim()) ?? 0;
            final int previewTotalPaid = isSetDirectly
                ? enteredAmount
                : (loan.finePaid + enteredAmount);
            final int previewRemaining =
                (loan.totalFine - previewTotalPaid).clamp(0, loan.totalFine);

            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Cash Payment',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Student: ${user.name.isNotEmpty ? user.name : user.email}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loan.bookTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metrics breakdown card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Total Fee',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${loan.totalFine}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${loan.overdueDays}d @ ₹3/d',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 32, color: Colors.white12),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Paid (Cash)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${loan.finePaid}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.success,
                                  ),
                                ),
                                Text(
                                  'Collected',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 32, color: Colors.white12),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Balance Due',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${loan.remainingFine}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: loan.remainingFine > 0
                                        ? AppTheme.error
                                        : AppTheme.success,
                                  ),
                                ),
                                Text(
                                  loan.remainingFine > 0 ? 'Pending' : 'Settled',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: loan.remainingFine > 0
                                        ? AppTheme.error
                                        : AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Quick action presets
                    if (loan.remainingFine > 0) ...[
                      Text(
                        'QUICK CASH PRESETS',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.flash_on_rounded,
                                size: 14, color: Colors.white),
                            label: Text(
                              'Full Balance: ₹${loan.remainingFine}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.3),
                            onPressed: () {
                              setDialogState(() {
                                isSetDirectly = true;
                                amountController.text =
                                    loan.totalFine.toString();
                              });
                            },
                          ),
                          if (loan.remainingFine > 10)
                            ActionChip(
                              label: Text('₹10',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: AppTheme.bgCardLight,
                              onPressed: () {
                                setDialogState(() {
                                  isSetDirectly = false;
                                  amountController.text = '10';
                                });
                              },
                            ),
                          if (loan.remainingFine > 5)
                            ActionChip(
                              label: Text('₹5',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: AppTheme.bgCardLight,
                              onPressed: () {
                                setDialogState(() {
                                  isSetDirectly = false;
                                  amountController.text = '5';
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Mode selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setDialogState(() => isSetDirectly = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: !isSetDirectly
                                    ? AppTheme.primary.withValues(alpha: 0.25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !isSetDirectly
                                      ? AppTheme.primary
                                      : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+ Add Cash Paid',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: !isSetDirectly
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: !isSetDirectly
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setDialogState(() => isSetDirectly = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSetDirectly
                                    ? AppTheme.primary.withValues(alpha: 0.25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSetDirectly
                                      ? AppTheme.primary
                                      : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Set Total Paid',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: isSetDirectly
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isSetDirectly
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Amount input field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: isSetDirectly
                            ? 'Total Cash Paid (₹)'
                            : 'Cash Received Now (₹)',
                        labelStyle: GoogleFonts.outfit(
                            fontSize: 12, color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.currency_rupee_rounded,
                            size: 18, color: AppTheme.primary),
                        filled: true,
                        fillColor: AppTheme.bgCardLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Live calculation feedback
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: (previewRemaining > 0
                                ? AppTheme.warning
                                : AppTheme.success)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (previewRemaining > 0
                                  ? AppTheme.warning
                                  : AppTheme.success)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            previewRemaining > 0
                                ? Icons.info_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: previewRemaining > 0
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              previewRemaining > 0
                                  ? 'Result: ₹$previewTotalPaid paid • Remaining balance of ₹$previewRemaining will still be shown.'
                                  : 'Result: Full ₹${loan.totalFine} paid! Loan will be marked fully settled.',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: previewRemaining > 0
                                    ? AppTheme.warning
                                    : AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Optional: Mark as returned if active
                    if (loan.isActive) ...[
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: alsoReturnBook,
                        onChanged: (val) =>
                            setDialogState(() => alsoReturnBook = val ?? true),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: AppTheme.primary,
                        title: Text(
                          'Also mark book as Returned (+1 copy to library)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'Save Payment',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    final int val =
                        int.tryParse(amountController.text.trim()) ?? 0;
                    if (val < 0) return;

                    final int finalPaid =
                        isSetDirectly ? val : (loan.finePaid + val);

                    try {
                      await _firestoreService.recordFinePayment(
                        transactionId: loan.transactionId,
                        newTotalPaid: finalPaid,
                        freezeFine: loan.totalFine,
                      );

                      if (alsoReturnBook && loan.isActive) {
                        await _firestoreService.returnBook(
                          transactionId: loan.transactionId,
                          bookId: loan.bookId,
                          currentOverdueFine: loan.totalFine,
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (!mounted) return;
                      final remaining =
                          (loan.totalFine - finalPaid).clamp(0, loan.totalFine);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: AppTheme.success, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  remaining > 0
                                      ? 'Cash payment recorded! Total paid: ₹$finalPaid. Balance due: ₹$remaining'
                                      : 'Late fee fully settled (₹$finalPaid paid in cash)!',
                                  style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary),
                                ),
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
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to record cash: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
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
  // TAB 1: Pending Fines (Dedicated Cash Fine Recovery Section)
  // ===========================================================================

  Widget _buildPendingFinesTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.usersStream(),
      builder: (context, userSnapshot) {
        return StreamBuilder<List<BorrowHistory>>(
          stream: _firestoreService.allBorrowHistoryStream(),
          builder: (context, historySnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting ||
                historySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final users = userSnapshot.data ?? [];
            final history = historySnapshot.data ?? [];

            // Group all unsettled fines (remainingFine > 0)
            final pendingLoans =
                history.where((h) => h.remainingFine > 0).toList();

            final totalPendingFines =
                pendingLoans.fold<int>(0, (sum, h) => sum + h.remainingFine);
            final totalCashCollected =
                history.fold<int>(0, (sum, h) => sum + h.finePaid);
            final totalAssessedFines = history
                .where((h) => h.hasFine)
                .fold<int>(0, (sum, h) => sum + h.totalFine);

            final userMap = {for (final u in users) u.uid: u};

            // Group pending loans by student userId
            final Map<String, List<BorrowHistory>> studentPendingLoans = {};
            for (final loan in pendingLoans) {
              studentPendingLoans.putIfAbsent(loan.userId, () => []).add(loan);
            }

            // Filter entries according to search query
            final filteredEntries = studentPendingLoans.entries.where((entry) {
              if (_pendingFinesSearchQuery.isEmpty) return true;
              final q = _pendingFinesSearchQuery.toLowerCase();
              final user = userMap[entry.key];
              final name = user?.name.toLowerCase() ?? '';
              final email = user?.email.toLowerCase() ?? '';
              final contact = user?.contact.toLowerCase() ?? '';
              final bookMatch =
                  entry.value.any((l) => l.bookTitle.toLowerCase().contains(q));
              return name.contains(q) ||
                  email.contains(q) ||
                  contact.contains(q) ||
                  bookMatch;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Top header label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PENDING CASH FINES DIRECTORY',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${studentPendingLoans.length} student(s) owe fines',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Primary Highlight Banner for Pending Cash
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.error.withValues(alpha: 0.22),
                        AppTheme.warning.withValues(alpha: 0.12),
                        AppTheme.bgCard,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: AppTheme.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Outstanding Cash Due',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  '₹$totalPendingFines',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: totalPendingFines > 0
                                        ? AppTheme.error
                                        : AppTheme.success,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rate: ₹3/day',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.warning,
                                  ),
                                ),
                                Text(
                                  'Cash only at desk',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFineStatSnippet(
                            label: 'Students Owed',
                            value: '${studentPendingLoans.length}',
                            color: AppTheme.textPrimary,
                          ),
                          _buildFineStatSnippet(
                            label: 'Unsettled Loans',
                            value: '${pendingLoans.length}',
                            color: AppTheme.error,
                          ),
                          _buildFineStatSnippet(
                            label: 'Total Collected',
                            value: '₹$totalCashCollected',
                            color: AppTheme.success,
                          ),
                          _buildFineStatSnippet(
                            label: 'Total Assessed',
                            value: '₹$totalAssessedFines',
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search fine by student name, contact, book...',
                    hintStyle: GoogleFonts.outfit(
                        color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textMuted, size: 20),
                    suffixIcon: _pendingFinesSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              setState(() => _pendingFinesSearchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _pendingFinesSearchQuery = val);
                  },
                ),

                const SizedBox(height: 16),

                // Students List
                if (studentPendingLoans.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.success,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All Late Fees Settled!',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No students currently have outstanding cash fines. Every borrowed book is returned on time or fully settled.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (filteredEntries.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No students with pending fines match "$_pendingFinesSearchQuery".',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                    ),
                  ),
                ] else ...[
                  ...filteredEntries.map((entry) {
                    final userId = entry.key;
                    final studentLoans = entry.value;
                    final student = userMap[userId] ??
                        UserModel(
                          uid: userId,
                          email: 'Student ($userId)',
                          name: 'Student ($userId)',
                          contact: '',
                        );

                    final studentTotalRemaining = studentLoans.fold<int>(
                        0, (sum, l) => sum + l.remainingFine);
                    final studentTotalPaid =
                        studentLoans.fold<int>(0, (sum, l) => sum + l.finePaid);

                    return _buildPendingFineStudentCard(
                      student: student,
                      loans: studentLoans,
                      totalRemainingFine: studentTotalRemaining,
                      totalPaidFine: studentTotalPaid,
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFineStatSnippet({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingFineStudentCard({
    required UserModel student,
    required List<BorrowHistory> loans,
    required int totalRemainingFine,
    required int totalPaidFine,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.25),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name.isNotEmpty ? student.name : 'Unknown Student',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.email}${student.contact.isNotEmpty ? " • ${student.contact}" : ""}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DUE: ₹$totalRemainingFine',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.error,
                        ),
                      ),
                      if (totalPaidFine > 0)
                        Text(
                          'Paid: ₹$totalPaidFine',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            Text(
              'Overdue Books with Unsettled Fines (${loans.length}):',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Book items
            ...loans.map((loan) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.bookTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loan.isActive
                                    ? 'Book Status: Currently in possession (Active)'
                                    : 'Book Status: Book Returned to library',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: loan.isActive
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${loan.remainingFine} due',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Late by ${loan.overdueDays} day(s) (₹3/day)',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Fee: ₹${loan.totalFine}  •  Paid: ₹${loan.finePaid}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Action button to collect cash
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.point_of_sale_rounded,
                            size: 14, color: Colors.white),
                        label: Text(
                          'Collect Cash (₹${loan.remainingFine})',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => _showManageCashDialog(loan, student),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
                  'No books in inventory. Tap "Add Book" below!',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 70,
              child: BookCoverImage(
                imageUrl: book.imageUrl,
                fit: BoxFit.cover,
                fallback: Container(
                  width: 52,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.primary, size: 20),
                      tooltip: 'Edit Book Details',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditBookDialog(book),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.error, size: 20),
                      tooltip: 'Delete Book',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteBookDialog(book),
                    ),
                  ],
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

  void _showEditBookDialog(Book book) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: book.title);
    final authorController = TextEditingController(text: book.author);
    final copiesController =
        TextEditingController(text: book.availableCopies.toString());
    final descController = TextEditingController(text: book.description);
    final imageUrlController = TextEditingController(text: book.imageUrl);
    bool isSaving = false;
    bool isPicking = false;
    String? pickedName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickGalleryImage() async {
              setDialogState(() => isPicking = true);
              try {
                final picker = ImagePicker();
                final XFile? file = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 600,
                  maxHeight: 800,
                  imageQuality: 75,
                );
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  final base64String =
                      'data:image/jpeg;base64,${base64Encode(bytes)}';
                  setDialogState(() {
                    imageUrlController.text = base64String;
                    pickedName = file.name;
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not access gallery: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } finally {
                setDialogState(() => isPicking = false);
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Book Information',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Modify book details in library catalogue',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Preview & Gallery Picker
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 80,
                                  height: 110,
                                  child: BookCoverImage(
                                    imageUrl: imageUrlController.text.trim(),
                                    fit: BoxFit.cover,
                                    fallback: Container(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.menu_book_rounded,
                                          color: Colors.white, size: 32),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: isPicking ? null : pickGalleryImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.bgCard, width: 2),
                                  ),
                                  child: isPicking
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt_rounded,
                                          color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: isPicking ? null : pickGalleryImage,
                            icon: const Icon(Icons.photo_library_rounded,
                                size: 14, color: AppTheme.primary),
                            label: Text(
                              pickedName != null
                                  ? 'Image Picked ($pickedName)'
                                  : 'Select New Image from Gallery',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        _buildFieldLabel('Book Title *'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: titleController,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary, fontSize: 13),
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            hint: 'Book Title',
                            icon: Icons.title_rounded,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Title cannot be empty'
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        // Author
                        _buildFieldLabel('Author Name *'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: authorController,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary, fontSize: 13),
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            hint: 'Author',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Author cannot be empty'
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        // Available Copies
                        _buildFieldLabel('Available Copies *'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: copiesController,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary, fontSize: 13),
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            hint: 'Copies (e.g. 5)',
                            icon: Icons.copy_rounded,
                          ),
                          validator: (val) {
                            final n = int.tryParse(val ?? '');
                            if (n == null || n < 0) {
                              return 'Must be 0 or greater';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Description
                        _buildFieldLabel('Description'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: descController,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary, fontSize: 13),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            hint: 'Book summary or notes...',
                            icon: Icons.description_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Image URL optional override
                        _buildFieldLabel('Image Web URL (Optional)'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: imageUrlController,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary, fontSize: 12),
                          keyboardType: TextInputType.url,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: _inputDecoration(
                            hint: 'https://...',
                            icon: Icons.link_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Changes',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final updatedCopies =
                                int.parse(copiesController.text.trim());
                            await _firestoreService.updateBook(
                              bookId: book.bookId,
                              title: titleController.text.trim(),
                              author: authorController.text.trim(),
                              description: descController.text.trim(),
                              availableCopies: updatedCopies,
                              imageUrl: imageUrlController.text.trim(),
                            );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          color: AppTheme.success, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Book "${titleController.text.trim()}" updated successfully!',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.bgCardLight,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update book: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteBookDialog(Book book) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: AppTheme.error.withValues(alpha: 0.3), width: 1.2),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: AppTheme.error, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delete Book',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 40,
                            height: 52,
                            child: BookCoverImage(
                              imageUrl: book.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'by ${book.author}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Are you sure you want to permanently delete this book from the library catalogue? This action cannot be undone.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_rounded,
                          color: Colors.white, size: 16),
                  label: Text(
                    isDeleting ? 'Deleting...' : 'Delete Book',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await _firestoreService.deleteBook(book.bookId);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded,
                                          color: AppTheme.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Book "${book.title}" was deleted.',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.bgCardLight,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete book: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: Add New Book Form
  // ===========================================================================

  Widget _buildAddBookTab() {
    final hasEnteredUrl = _imageUrlController.text.trim().isNotEmpty;

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
              'Fill in the book details including image cover, title, author, copies, and description.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // 1. Book Cover Image Selection
            _buildFieldLabel('Book Cover Image'),
            const SizedBox(height: 4),
            Text(
              'Select an image directly from your device gallery or enter a web link.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // Prominent Gallery Picker Button
            InkWell(
              onTap: _isPickingImage ? null : _pickImageFromGallery,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.22),
                      AppTheme.accent.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPickingImage) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Opening Gallery...',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pickedImageName != null
                                ? 'Change Gallery Image'
                                : 'Choose Image from Gallery',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Select directly from your phone/PC photos',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.primary, size: 14),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Live Cover Preview Box
            _buildCoverPreviewBox(),

            const SizedBox(height: 14),

            // Secondary Option: Enter Web Link or Presets
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: AppTheme.textMuted,
                  iconColor: AppTheme.primary,
                title: Text(
                  'Or use Web Image Link / Presets',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                children: [
                  TextFormField(
                    controller: _imageUrlController,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                    keyboardType: TextInputType.url,
                    onChanged: (_) {
                      setState(() {
                        _pickedImageName = null;
                      });
                    },
                    decoration: _inputDecoration(
                      hint: 'https://images.unsplash.com/... or web link',
                      icon: Icons.link_rounded,
                      suffixIcon: hasEnteredUrl
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 18, color: AppTheme.textMuted),
                              onPressed: () {
                                _imageUrlController.clear();
                                _pickedImageName = null;
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip(
                        label: '💻 Tech / Code',
                        url:
                            'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        label: '📖 Literature',
                        url:
                            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        label: '🔬 Science',
                        url:
                            'https://images.unsplash.com/photo-1532012164546-f432f2e3794b?w=600&auto=format&fit=crop&q=80',
                      ),
                      _buildPresetChip(
                        label: '💼 Business',
                        url:
                            'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=600&auto=format&fit=crop&q=80',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

            const SizedBox(height: 16),

            // 2. Book Title
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

            // 3. Author Name
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

            // 4. Available Copies
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

            // 5. Description
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

  Widget _buildPresetChip({required String label, required String url}) {
    final isSelected = _imageUrlController.text.trim() == url;
    return InkWell(
      onTap: () {
        setState(() {
          _imageUrlController.text = url;
          _pickedImageName = null;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.25)
              : AppTheme.bgCard,
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreviewBox() {
    final url = _imageUrlController.text.trim();
    final hasImage = url.isNotEmpty;

    if (!hasImage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No image selected. You can choose from gallery or enter a web link above.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isGalleryImage = _pickedImageName != null || url.startsWith('data:image');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 58,
              height: 76,
              child: BookCoverImage(
                imageUrl: url,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isGalleryImage
                          ? 'Gallery Photo Selected'
                          : 'Live Cover Preview',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _pickedImageName ??
                      (url.startsWith('data:')
                          ? 'Ready to publish with book'
                          : url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.error, size: 20),
            tooltip: 'Remove Image',
            onPressed: () {
              setState(() {
                _imageUrlController.clear();
                _pickedImageName = null;
              });
            },
          ),
        ],
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
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      suffixIcon: suffixIcon,
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
