import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../../../../core/services/version_check_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileSettingsScreen extends StatelessWidget {
  final AuthController authController;

  const ProfileSettingsScreen({
    super.key,
    required this.authController,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: MaatraTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Log Out of MAATRA',
          style: GoogleFonts.plusJakartaSans(
            color: MaatraTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out? You will need your password or Google account to sign in again.',
          style: GoogleFonts.plusJakartaSans(
            color: MaatraTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: MaatraTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaatraTheme.crimsonAlert,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx); // Close dialog
              Navigator.pop(context); // Close profile screen
              await authController.logout();
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser;
    final fullName = user?.fullName.isNotEmpty == true ? user!.fullName : 'MAATRA User';
    final email = user?.email ?? 'Unknown Email';
    final role = user?.role ?? 'USER';
    final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: MaatraTheme.bgDark,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaatraTheme.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.plusJakartaSans(
            color: MaatraTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MaatraTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MaatraTheme.borderMuted, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [MaatraTheme.deepAmethyst, MaatraTheme.primaryAmethyst],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              role,
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.accentLilac,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
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

              // Account Information Section
              Text(
                'ACCOUNT DETAILS',
                style: GoogleFonts.plusJakartaSans(
                  color: MaatraTheme.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: MaatraTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaatraTheme.borderMuted),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      title: 'Role Designation',
                      value: role,
                    ),
                    const Divider(color: MaatraTheme.borderMuted, height: 1),
                    _buildInfoTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Verification Status',
                      value: user?.isVerified == true ? 'Verified' : 'Active Account',
                      valueColor: MaatraTheme.emeraldSafe,
                    ),
                    if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                      const Divider(color: MaatraTheme.borderMuted, height: 1),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        title: 'Phone',
                        value: user.phone!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Application Section
              Text(
                'ABOUT APPLICATION',
                style: GoogleFonts.plusJakartaSans(
                  color: MaatraTheme.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: MaatraTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaatraTheme.borderMuted),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.smart_toy_outlined,
                      title: 'AI Companion',
                      value: 'Anu (ur ai at ur place)',
                    ),
                    const Divider(color: MaatraTheme.borderMuted, height: 1),
                    _buildInfoTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Platform Version',
                      value: 'MAATRA 1.0.0',
                    ),
                    const Divider(color: MaatraTheme.borderMuted, height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sync_rounded, color: MaatraTheme.accentLilac, size: 20),
                      ),
                      title: Text(
                        'Check for Updates',
                        style: GoogleFonts.plusJakartaSans(
                          color: MaatraTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: MaatraTheme.textTertiary, size: 20),
                      onTap: () {
                        VersionCheckService.checkAndPrompt(context, manualCheck: true);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Dedicated Logout Section
              Container(
                decoration: BoxDecoration(
                  color: MaatraTheme.crimsonAlert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaatraTheme.crimsonAlert.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MaatraTheme.crimsonAlert.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: MaatraTheme.crimsonAlert, size: 20),
                  ),
                  title: Text(
                    'Log Out',
                    style: GoogleFonts.plusJakartaSans(
                      color: MaatraTheme.crimsonAlert,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Securely sign out of this device',
                    style: GoogleFonts.plusJakartaSans(
                      color: MaatraTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: MaatraTheme.crimsonAlert, size: 14),
                  onTap: () => _showLogoutDialog(context),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: MaatraTheme.accentLilac, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: MaatraTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: valueColor ?? MaatraTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
