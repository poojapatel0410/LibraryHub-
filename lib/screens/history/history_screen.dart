import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/borrow_history.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/error_view.dart';

/// Screen showing a user''s complete borrow history from Firestore.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Header ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Books',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your borrowing activity',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // -- List -----------------------------------------------------
            Expanded(
              child: uid == null
                  ? const EmptyView(
                      title: 'Not Signed In',
                      subtitle: 'Please log in to see your borrow history.',
                      icon: Icons.login_rounded,
                    )
                  : StreamBuilder<List<BorrowHistory>>(
                      stream: _firestoreService.borrowHistoryStream(uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary),
                          );
                        }

                        if (snapshot.hasError) {
                          return ErrorView(
                            message:
                                'Failed to load history: ${snapshot.error}',
                          );
                        }

                        final history = snapshot.data ?? [];

                        if (history.isEmpty) {
                          return const EmptyView(
                            title: 'No Borrows Yet',
                            subtitle:
                                'Books you borrow will appear here. Start reading!',
                            icon: Icons.bookmark_border_rounded,
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            return _BorrowHistoryCard(
                              history: history[index],
                              dateFormat: _dateFormat,
                              firestoreService: _firestoreService,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- History Card ---------------------------------------------------------------

class _BorrowHistoryCard extends StatelessWidget {
  final BorrowHistory history;
  final DateFormat dateFormat;
  final FirestoreService firestoreService;

  const _BorrowHistoryCard({
    required this.history,
    required this.dateFormat,
    required this.firestoreService,
  });

  Future<void> _handleReturn(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Return Book',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to return "${history.bookTitle}"? This will return 1 copy to the library catalogue.',
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Return Now',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await firestoreService.returnBook(
        transactionId: history.transactionId,
        bookId: history.bookId,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"${history.bookTitle}" returned successfully! Catalogue updated.',
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
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
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to return book. Please try again.',
            style: GoogleFonts.outfit(color: AppTheme.error),
          ),
          backgroundColor: AppTheme.bgCardLight,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = history.isActive;
    final isOverdue = history.isOverdue;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isOverdue) {
      statusColor = AppTheme.warning;
      statusLabel = 'Overdue';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isActive) {
      statusColor = AppTheme.success;
      statusLabel = 'Active';
      statusIcon = Icons.check_circle_outline_rounded;
    } else {
      statusColor = AppTheme.textMuted;
      statusLabel = 'Returned';
      statusIcon = Icons.assignment_return_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Cover icon -----------------------------------------------
            Container(
              width: 52,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _coverColors(history.bookTitle),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // -- Details --------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.bookTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Borrowed',
                    value: dateFormat.format(history.borrowDate),
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Due',
                    value: dateFormat.format(history.returnDate),
                    valueColor: isOverdue ? AppTheme.warning : null,
                  ),
                  const SizedBox(height: 10),
                  // Status badge and Return Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.assignment_return_outlined,
                              size: 14,
                              color: AppTheme.accent,
                            ),
                            label: Text(
                              'Return',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.accent,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () => _handleReturn(context),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  List<Color> _coverColors(String title) {
    const palettes = [
      [Color(0xFF6C63FF), Color(0xFF9D50BB)],
      [Color(0xFFFF6584), Color(0xFFFF9A8B)],
      [Color(0xFF43C6AC), Color(0xFF191654)],
      [Color(0xFFF7971E), Color(0xFFFFD200)],
      [Color(0xFF11998E), Color(0xFF38EF7D)],
      [Color(0xFFDA4453), Color(0xFF89216B)],
      [Color(0xFF4776E6), Color(0xFF8E54E9)],
      [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    ];
    final idx = title.hashCode.abs() % palettes.length;
    return palettes[idx];
  }
}
