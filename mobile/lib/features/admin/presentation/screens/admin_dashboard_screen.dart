import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../../data/models/professional_user_model.dart';
import '../../presentation/controllers/admin_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'create_asha_screen.dart';
import 'create_doctor_screen.dart';
import '../../../common/presentation/screens/profile_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AuthController authController;
  final AdminController adminController;

  const AdminDashboardScreen({
    super.key,
    required this.authController,
    required this.adminController,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.adminController.loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showActivationCredentialModal(
      BuildContext context, String name, String email, String role, String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaatraTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MaatraTheme.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: MaatraTheme.accentLilac),
            const SizedBox(width: 10),
            Text(
              'Account Provisioned',
              style: GoogleFonts.plusJakartaSans(
                color: MaatraTheme.textPrimary,
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
              'Professional $role provisioned successfully:',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: MaatraTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Gmail: $email',
              style: GoogleFonts.plusJakartaSans(color: MaatraTheme.accentLilac, fontWeight: FontWeight.w600),
            ),
            if (name.isNotEmpty && name != email) ...[
              const SizedBox(height: 4),
              Text(
                'Identifier: $name',
                style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temporary Access Token / Password:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MaatraTheme.accentLilac,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    token,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The professional will sign in with this Gmail and complete their personal profile (Name, Age, Gender, Phone, Specialization) upon first login.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: MaatraTheme.textTertiary, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaatraTheme.primaryAmethyst,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              widget.adminController.clearLastProvisioned();
              Navigator.pop(ctx);
            },
            child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, String userId, String name, String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaatraTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MaatraTheme.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: MaatraTheme.crimsonAlert),
            const SizedBox(width: 8),
            Text(
              'Delete $role',
              style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the $role account for "$name"? This action is permanent and removes all associated records.',
          style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaatraTheme.crimsonAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await widget.adminController.deleteUser(userId);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? '$role account deleted successfully.' : 'Failed to delete $role.'),
                  backgroundColor: ok ? MaatraTheme.emeraldSafe : MaatraTheme.crimsonAlert,
                ),
              );
            },
            child: Text('Delete Permanently', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.currentUser;
    final lastProv = widget.adminController.lastProvisioned;

    if (lastProv != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showActivationCredentialModal(
          context,
          lastProv.fullName,
          lastProv.email,
          lastProv.role,
          lastProv.activationToken.isNotEmpty ? lastProv.activationToken : lastProv.temporaryPassword,
        );
      });
    }

    return Scaffold(
      backgroundColor: MaatraTheme.bgDark,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgDark,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/maatra_logo.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.all_inclusive_rounded,
                  size: 22,
                  color: MaatraTheme.accentLilac,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MAATRA Admin Console',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: MaatraTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: MaatraTheme.textSecondary),
            tooltip: 'Refresh All',
            onPressed: () => widget.adminController.loadAll(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: MaatraTheme.textSecondary),
            tooltip: 'Profile & Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSettingsScreen(authController: widget.authController),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: MaatraTheme.borderDark)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: MaatraTheme.primaryAmethyst,
              indicatorWeight: 3,
              labelColor: MaatraTheme.accentLilac,
              unselectedLabelColor: MaatraTheme.textTertiary,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.medical_services_rounded, size: 18),
                  text: 'Doctors (${widget.adminController.doctors.length})',
                ),
                Tab(
                  icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                  text: 'ASHAs (${widget.adminController.ashas.length})',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.adminController,
          builder: (context, _) {
            final isLoading = widget.adminController.status == AdminStateStatus.loading;

            return Column(
              children: [
                // Admin Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: MaatraTheme.surfaceDark,
                    border: Border(bottom: BorderSide(color: MaatraTheme.borderDark)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 18,
                          color: MaatraTheme.accentLilac,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.email ?? 'admin123@gmail.com',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: MaatraTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Master Provider Administrator • Zero Hardcoded Accounts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: MaatraTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: MaatraTheme.accentLilac),
                        ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDoctorsTab(context, isLoading),
                      _buildAshasTab(context, isLoading),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDoctorsTab(BuildContext context, bool isLoading) {
    final doctors = widget.adminController.doctors;

    return RefreshIndicator(
      color: MaatraTheme.primaryAmethyst,
      backgroundColor: MaatraTheme.surfaceDark,
      onRefresh: () => widget.adminController.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Doctor Accounts (${doctors.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MaatraTheme.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_doctor_button'),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text('Provision Doctor', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaatraTheme.primaryAmethyst,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateDoctorScreen(adminController: widget.adminController),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (doctors.isEmpty && !isLoading)
            _buildEmptyState('No doctor accounts created yet. Tap "Provision Doctor" to create a genuine Gmail account.'),

          ...doctors.map((doc) => _buildDoctorCard(context, doc)),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, ProfessionalUserModel doc) {
    final spec = doc.details?['specialization'] ?? 'General Medicine';
    final facility = doc.details?['facility_name'] ?? 'Primary Health Center';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MaatraTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaatraTheme.borderDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_rounded, color: MaatraTheme.accentLilac, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.fullName.isNotEmpty ? doc.fullName : 'Doctor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MaatraTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: MaatraTheme.accentLilac,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (doc.phone != null && doc.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Phone: ${doc.phone}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: MaatraTheme.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: MaatraTheme.crimsonAlert, size: 20),
                tooltip: 'Delete Doctor Account',
                onPressed: () => _confirmDeleteUser(context, doc.id, doc.fullName, 'Doctor'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge('Specialization: $spec', MaatraTheme.primaryAmethyst),
              _buildBadge('Facility: $facility', MaatraTheme.borderDark),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: MaatraTheme.borderDark, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doc.mustChangePassword
                    ? 'Pending First Login'
                    : (doc.isActive ? 'Active Provider' : 'Deactivated'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: doc.mustChangePassword
                      ? MaatraTheme.amberWarning
                      : (doc.isActive ? MaatraTheme.emeraldSafe : MaatraTheme.crimsonAlert),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Active:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: MaatraTheme.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: doc.isActive,
                    activeThumbColor: MaatraTheme.primaryAmethyst,
                    onChanged: (val) => widget.adminController.toggleUserStatus(doc.id, val),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAshasTab(BuildContext context, bool isLoading) {
    final ashas = widget.adminController.ashas;

    return RefreshIndicator(
      color: MaatraTheme.primaryAmethyst,
      backgroundColor: MaatraTheme.surfaceDark,
      onRefresh: () => widget.adminController.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASHA Healthcare Workers (${ashas.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MaatraTheme.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_asha_button'),
                icon: const Icon(Icons.group_add_rounded, size: 16),
                label: Text('Provision ASHA', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaatraTheme.deepAmethyst,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateAshaScreen(adminController: widget.adminController),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (ashas.isEmpty && !isLoading)
            _buildEmptyState('No ASHA worker accounts created yet. Tap "Provision ASHA" to register a healthcare worker.'),

          ...ashas.map((asha) => _buildAshaCard(context, asha)),
        ],
      ),
    );
  }

  Widget _buildAshaCard(BuildContext context, ProfessionalUserModel asha) {
    final code = asha.details?['worker_id_code'] ?? 'N/A';
    final area = asha.details?['assigned_area'] ?? 'Community Sector';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MaatraTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaatraTheme.borderDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MaatraTheme.deepAmethyst.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: MaatraTheme.accentLightAmethyst, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asha.fullName.isNotEmpty ? asha.fullName : 'ASHA Worker',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MaatraTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asha.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: MaatraTheme.accentLightAmethyst,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (asha.phone != null && asha.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Phone: ${asha.phone}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: MaatraTheme.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: MaatraTheme.crimsonAlert, size: 20),
                tooltip: 'Delete ASHA Account',
                onPressed: () => _confirmDeleteUser(context, asha.id, asha.fullName, 'ASHA Worker'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge('Worker Code: $code', MaatraTheme.deepAmethyst),
              _buildBadge('Assigned Area: $area', MaatraTheme.borderDark),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: MaatraTheme.borderDark, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                asha.mustChangePassword
                    ? 'Pending First Login'
                    : (asha.isActive ? 'Active Field Worker' : 'Deactivated'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: asha.mustChangePassword
                      ? MaatraTheme.amberWarning
                      : (asha.isActive ? MaatraTheme.emeraldSafe : MaatraTheme.crimsonAlert),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Active:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: MaatraTheme.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: asha.isActive,
                    activeThumbColor: MaatraTheme.primaryAmethyst,
                    onChanged: (val) => widget.adminController.toggleUserStatus(asha.id, val),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: MaatraTheme.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: MaatraTheme.textTertiary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
