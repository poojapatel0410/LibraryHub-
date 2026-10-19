import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/book_cover_image.dart';
import '../profile/edit_profile_screen.dart';

/// Detailed view for a single book with borrow functionality.
class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isBorrowing = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Deterministic cover color based on book title
  late Color _coverColorStart;
  late Color _coverColorEnd;

  static const List<List<Color>> _palettes = [
    [Color(0xFF6C63FF), Color(0xFF9D50BB)],
    [Color(0xFFFF6584), Color(0xFFFF9A8B)],
    [Color(0xFF43C6AC), Color(0xFF191654)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFDA4453), Color(0xFF89216B)],
    [Color(0xFF4776E6), Color(0xFF8E54E9)],
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
  ];

  @override
  void initState() {
    super.initState();
    final idx = widget.book.title.hashCode.abs() % _palettes.length;
    _coverColorStart = _palettes[idx][0];
    _coverColorEnd = _palettes[idx][1];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // -- Borrow Flow ------------------------------------------------------------

  Future<void> _handleBorrow() async {
    // Check mandatory profile details (contact, education, address, name)
    final authProvider = context.read<AuthProvider>();
    final userModel = authProvider.userModel;

    if (userModel == null || !userModel.isProfileComplete) {
      _showIncompleteProfileDialog(
        userModel?.missingFields ?? ['Contact Number', 'Education', 'Address'],
      );
      return;
    }

    // Step 1: show date picker for return date
    final returnDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'SELECT RETURN DATE',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.bgCard,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppTheme.bgCard),
          ),
          child: child!,
        );
      },
    );

    // User cancelled the picker
    if (returnDate == null || !mounted) return;

    // Step 2: execute the batched write
    setState(() => _isBorrowing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('User not authenticated.');

      await _firestoreService.borrowBook(
        userId: uid,
        book: widget.book,
        returnDate: returnDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"${widget.book.title}" borrowed successfully!',
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.bgCardLight,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context); // Return to home
    } on StateError catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to borrow book. Please try again.');
    } finally {
      if (mounted) setState(() => _isBorrowing = false);
    }
  }

  void _showIncompleteProfileDialog(List<String> missingFields) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 24),
            const SizedBox(width: 10),
            Text(
              'Profile Incomplete',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You cannot borrow books until you provide your Contact, Education, and Address.',
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Missing details:',
              style: GoogleFonts.outfit(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            ...missingFields.map(
              (field) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      field,
                      style: GoogleFonts.outfit(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              'Complete Profile',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCardLight,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isAvailable = book.availableCopies > 0;
    final authProvider = context.watch<AuthProvider>();
    final isProfileComplete = authProvider.userModel?.isProfileComplete ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cover Banner
                _buildHeroCover(book),

                // Book Details
                Expanded(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Author
                          Text(
                            book.title,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'by ${book.author}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Availability chips
                          _buildAvailabilityRow(book, isAvailable),

                          const SizedBox(height: 28),

                          // Description
                          if (book.description.isNotEmpty) ...[
                            Text(
                              'About this book',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              book.description,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Profile incomplete notice if available
                          if (isAvailable && !isProfileComplete) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.warning.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: AppTheme.warning, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Complete your profile (Contact, Education & Address) to borrow this book.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const EditProfileScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Complete',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Borrow button
                          GradientButton(
                            label: isAvailable ? 'Borrow Book' : 'Unavailable',
                            onPressed: isAvailable && !_isBorrowing
                                ? _handleBorrow
                                : null,
                            isLoading: _isBorrowing,
                            icon: isAvailable
                                ? Icons.book_online_rounded
                                : Icons.block_rounded,
                            gradient: isAvailable
                                ? AppTheme.primaryGradient
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF4A4A6A),
                                      Color(0xFF3A3A5A)
                                    ],
                                  ),
                          ),

                          if (!isAvailable) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'All copies are currently borrowed.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Sub-builders -----------------------------------------------------------

  Widget _buildHeroCover(Book book) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_coverColorStart, _coverColorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // If image is available, display image cover
          if (book.hasImage) ...[
            Positioned.fill(
              child: BookCoverImage(
                imageUrl: book.imageUrl,
                fit: BoxFit.cover,
                fallback: const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Decorative circles (fallback when no image)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Book icon
            Center(
              child: Icon(
                Icons.menu_book_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 80,
              ),
            ),
          ],

          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(Book book, bool isAvailable) {
    return Row(
      children: [
        _StatusChip(
          label: isAvailable ? 'Available' : 'Unavailable',
          color: isAvailable ? AppTheme.success : AppTheme.error,
          icon: isAvailable
              ? Icons.check_circle_outline_rounded
              : Icons.cancel_outlined,
        ),
        const SizedBox(width: 10),
        _StatusChip(
          label: '${book.availableCopies} cop${book.availableCopies == 1 ? "y" : "ies"} left',
          color: AppTheme.info,
          icon: Icons.copy_all_rounded,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
