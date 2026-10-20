import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';

/// Registration screen for new users.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _showTermsError = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final formValid = _formKey.currentState!.validate();
    if (!_agreeToTerms) {
      setState(() => _showTermsError = true);
    }
    if (!formValid || !_agreeToTerms) {
      if (!formValid) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please agree to the Terms & Conditions and Fine Policy to create your account.',
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
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 12),
              Text(
                'Account created successfully!',
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
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
      Navigator.pop(context); // Return to login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authProvider.errorMessage ?? 'Registration failed.',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // -- Back Button ----------------------------------------
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join LibraryHub and start reading',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // -- Form -----------------------------------------------
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required.';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value.trim())) {
                                return 'Please enter a valid email.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required.';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(),
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Terms & Conditions Checkbox Card
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _showTermsError && !_agreeToTerms
                                    ? AppTheme.error
                                    : Colors.white.withValues(alpha: 0.08),
                                width: _showTermsError && !_agreeToTerms ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Checkbox Row
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _agreeToTerms = !_agreeToTerms;
                                      if (_agreeToTerms) _showTermsError = false;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 10, 14, 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            unselectedWidgetColor:
                                                _showTermsError && !_agreeToTerms
                                                    ? AppTheme.error
                                                    : AppTheme.textMuted,
                                          ),
                                          child: Checkbox(
                                            value: _agreeToTerms,
                                            activeColor: AppTheme.primary,
                                            checkColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                _agreeToTerms = val ?? false;
                                                if (_agreeToTerms) {
                                                  _showTermsError = false;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: RichText(
                                              text: TextSpan(
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                  height: 1.4,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'I agree to the ',
                                                  ),
                                                  TextSpan(
                                                    text: 'Terms & Conditions',
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.primary,
                                                      decoration:
                                                          TextDecoration.underline,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' & understand the ',
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        'Overdue Fine Policy (₹3/day)',
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.warning,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: '.',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Key Rules Snippet
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 0, 14, 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgCardLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildRuleSnippetRow(
                                          icon: Icons.currency_rupee_rounded,
                                          iconColor: AppTheme.warning,
                                          title: 'Late Fine Rate',
                                          desc:
                                              '₹3 per book per day past the due date',
                                        ),
                                        const SizedBox(height: 6),
                                        _buildRuleSnippetRow(
                                          icon: Icons.payments_outlined,
                                          iconColor: AppTheme.accent,
                                          title: 'Cash Payment',
                                          desc:
                                              'All overdue fines must be paid in cash at library desk',
                                        ),
                                        const SizedBox(height: 6),
                                        _buildRuleSnippetRow(
                                          icon: Icons.badge_outlined,
                                          iconColor: AppTheme.primary,
                                          title: 'Profile Rule',
                                          desc:
                                              'Contact & address required before borrowing books',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Action link to open full terms modal
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                          Icons.description_outlined,
                                          size: 14,
                                          color: AppTheme.primary),
                                      label: Text(
                                        'Read Full Agreement',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      onPressed: _showTermsDialog,
                                    ),
                                  ),
                                ),

                                // Validation Error Banner
                                if (_showTermsError && !_agreeToTerms)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error
                                          .withValues(alpha: 0.15),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(14),
                                        bottomRight: Radius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded,
                                            size: 15, color: AppTheme.error),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'You must check the box to agree to the terms to create an account.',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Register button
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => GradientButton(
                              label: 'Create Account',
                              onPressed: _handleRegister,
                              isLoading: auth.isLoading,
                              icon: Icons.person_add_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
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
                child: const Icon(Icons.gavel_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'LibraryHub User Agreement & Fine Policy',
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTermClause(
                    number: '1',
                    title: 'Student Membership & Eligibility',
                    content:
                        'All registered student accounts are subject to profile verification. To borrow library books, members must provide valid profile details (Full Name, Contact Number, Education Level, and Residential Address). Incomplete profiles will be restricted from book borrowing until completed.',
                  ),
                  const SizedBox(height: 12),
                  _buildTermClause(
                    number: '2',
                    title: 'Borrowing Periods & Return Deadlines',
                    content:
                        'Books are issued for the specific duration chosen upon borrowing. Borrowers are strictly responsible for returning the borrowed books on or before the agreed return date. The library catalog reflects live availability.',
                  ),
                  const SizedBox(height: 12),
                  _buildTermClause(
                    number: '3',
                    title: 'Late Return Fine Policy (₹3/Day in Cash)',
                    isHighlighted: true,
                    content:
                        'If a book is not returned on or before its designated due date, an overdue fine of ₹3 per book per day will be charged automatically.\n\n• Payment Method: All late return fees must be paid in CASH directly to the librarian at the desk.\n• Outstanding balance: Borrowers with unpaid cash fines will have their dues recorded in the administrator ledger, and further borrowing privileges will be paused until full cash clearance.',
                  ),
                  const SizedBox(height: 12),
                  _buildTermClause(
                    number: '4',
                    title: 'Care of Books & Library Property',
                    content:
                        'Borrowers are expected to keep books in good condition. Underlining, highlighting, tearing pages, or water damage is strictly prohibited. Lost or severely damaged books must be replaced or paid for in full as determined by library administration.',
                  ),
                  const SizedBox(height: 12),
                  _buildTermClause(
                    number: '5',
                    title: 'Account Security & Personal Responsibility',
                    content:
                        'Each member is personally liable for all books borrowed under their login credentials. Never share your password or allow others to borrow using your account.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Close',
                style: GoogleFonts.outfit(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 16),
              label: Text(
                'Accept Terms',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                setState(() {
                  _agreeToTerms = true;
                  _showTermsError = false;
                });
                Navigator.pop(dialogCtx);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRuleSnippetRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                  fontSize: 11, color: AppTheme.textSecondary),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermClause({
    required String number,
    required String title,
    required String content,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.warning.withValues(alpha: 0.1)
            : AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppTheme.warning.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppTheme.warning
                      : AppTheme.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isHighlighted ? Colors.black : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        isHighlighted ? AppTheme.warning : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
