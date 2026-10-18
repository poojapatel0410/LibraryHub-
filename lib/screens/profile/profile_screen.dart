import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import 'edit_profile_screen.dart';

/// Screen displaying student profile details and status.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userModel = authProvider.userModel;
    final email = authProvider.firebaseUser?.email ?? 'student@libraryhub.com';
    final name = userModel?.name.isNotEmpty == true
        ? userModel!.name
        : (email.split('@').first);
    final isComplete = userModel?.isProfileComplete ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // -- App Bar ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Student Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // -- Profile Content --------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      // Avatar & Name Card
                      _buildHeaderCard(name, email, isComplete),

                      const SizedBox(height: 16),

                      // Profile status banner
                      _buildStatusBanner(context, isComplete, userModel?.missingFields ?? []),

                      const SizedBox(height: 20),

                      // Profile Details Section
                      _buildSectionTitle('ACCOUNT DETAILS'),
                      const SizedBox(height: 10),

                      _buildInfoTile(
                        icon: Icons.person_rounded,
                        label: 'Full Name',
                        value: userModel?.name.isNotEmpty == true
                            ? userModel!.name
                            : 'Not set yet',
                        isSet: userModel?.name.isNotEmpty == true,
                      ),
                      const SizedBox(height: 10),

                      _buildInfoTile(
                        icon: Icons.mail_rounded,
                        label: 'Email Address',
                        value: email,
                        isSet: true,
                      ),
                      const SizedBox(height: 10),

                      _buildInfoTile(
                        icon: Icons.phone_android_rounded,
                        label: 'Contact / Mobile',
                        value: userModel?.contact.isNotEmpty == true
                            ? userModel!.contact
                            : 'Required to borrow books',
                        isSet: userModel?.contact.isNotEmpty == true,
                        isRequired: true,
                      ),
                      const SizedBox(height: 10),

                      _buildInfoTile(
                        icon: Icons.school_rounded,
                        label: 'Education / Degree',
                        value: userModel?.education.isNotEmpty == true
                            ? userModel!.education
                            : 'Required to borrow books',
                        isSet: userModel?.education.isNotEmpty == true,
                        isRequired: true,
                      ),
                      const SizedBox(height: 10),

                      _buildInfoTile(
                        icon: Icons.location_on_rounded,
                        label: 'Residential Address',
                        value: userModel?.address.isNotEmpty == true
                            ? userModel!.address
                            : 'Required to borrow books',
                        isSet: userModel?.address.isNotEmpty == true,
                        isRequired: true,
                      ),

                      const SizedBox(height: 28),

                      // Edit Profile Button
                      GradientButton(
                        label: 'Edit Profile',
                        icon: Icons.edit_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // Sign Out
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(
                            color: AppTheme.error.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.error, size: 18),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.outfit(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await authProvider.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String name, String email, bool isComplete) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.primaryShadow,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isComplete ? 'Borrowing Eligible' : 'Incomplete Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isComplete ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
      BuildContext context, bool isComplete, List<String> missingFields) {
    if (isComplete) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.success, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Profile Verified. You are eligible to borrow books from the catalogue.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.warning, size: 22),
              const SizedBox(width: 10),
              Text(
                'Profile Incomplete',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You cannot borrow books until you provide your Contact, Education, and Address.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          if (missingFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missingFields.map((field) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Missing: $field',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isSet,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRequired && !isSet
              ? AppTheme.warning.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSet
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isSet ? AppTheme.primary : AppTheme.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isSet ? AppTheme.textPrimary : AppTheme.textMuted,
                    fontWeight: isSet ? FontWeight.w500 : FontWeight.w400,
                    fontStyle: isSet ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (isRequired && !isSet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Required',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
