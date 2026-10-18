import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/error_view.dart';
import '../admin/admin_dashboard_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'book_detail_screen.dart';

/// Main home screen displaying the searchable book catalogue.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  String _searchQuery = '';
  int _selectedIndex = 0;

  late AnimationController _appBarAnimController;

  @override
  void initState() {
    super.initState();
    _appBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _appBarAnimController.dispose();
    super.dispose();
  }

  /// Filters a list of books by the current [_searchQuery].
  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    final query = _searchQuery.toLowerCase();
    return books.where((book) {
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userModel = authProvider.userModel;
    final email = authProvider.firebaseUser?.email ?? 'Reader';
    final displayName = userModel?.name.isNotEmpty == true
        ? userModel!.name
        : email.split('@').first;
    final isProfileComplete = userModel?.isProfileComplete ?? false;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildCatalogueTab(displayName, isProfileComplete),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // -- Catalogue Tab ---------------------------------------------------------

  Widget _buildCatalogueTab(String displayName, bool isProfileComplete) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(displayName),
            _buildProfileAlertBanner(isProfileComplete),
            _buildSearchBar(),
            Expanded(child: _buildBookGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String displayName) {
    return FadeTransition(
      opacity: _appBarAnimController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $displayName',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discover Books',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Profile Menu
            _buildProfileMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAlertBanner(bool isComplete) {
    if (isComplete) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete your profile (Contact, Education & Address) to borrow books.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Edit',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else if (value == 'logout') {
          await context.read<AuthProvider>().signOut();
        }
      },
      offset: const Offset(0, 50),
      color: AppTheme.bgCardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.primaryShadow,
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      itemBuilder: (_) {
        final isAdmin =
            context.read<AuthProvider>().userModel?.isAdmin ?? false;
        return [
          if (isAdmin) ...[
            PopupMenuItem<String>(
              value: 'admin',
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Admin Portal',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
          ],
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'My Profile',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout_rounded,
                    color: AppTheme.error, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: GoogleFonts.outfit(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by title or author...',
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBookGrid() {
    return StreamBuilder<List<Book>>(
      stream: _firestoreService.booksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return ErrorView(
            message: 'Failed to load books: ${snapshot.error}',
          );
        }

        final allBooks = snapshot.data ?? [];
        final filteredBooks = _filterBooks(allBooks);

        if (allBooks.isEmpty) {
          return const EmptyView(
            title: 'No Books Yet',
            subtitle: 'The library catalogue is empty. Check back later!',
            icon: Icons.library_books_outlined,
          );
        }

        if (filteredBooks.isEmpty) {
          return EmptyView(
            title: 'No Results Found',
            subtitle: 'No books match "$_searchQuery". Try a different search.',
            icon: Icons.search_off_rounded,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Text(
                '${filteredBooks.length} book${filteredBooks.length == 1 ? '' : 's'} found',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int columns = 2;
                  if (width > 1200) {
                    columns = 5;
                  } else if (width > 900) {
                    columns = 4;
                  } else if (width > 600) {
                    columns = 3;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return BookCard(
                        book: book,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailScreen(book: book),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // -- Bottom Navigation -----------------------------------------------------

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.textMuted.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'My Books',
          ),
        ],
      ),
    );
  }
}
