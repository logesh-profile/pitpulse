import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../../../patients/data/models/patient_profile_model.dart';
import '../../data/models/professional_user_model.dart';
import '../controllers/admin_controller.dart';
import 'create_asha_screen.dart';
import 'create_doctor_screen.dart';
import 'create_patient_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.mark_email_read, color: Color(0xFF14B8A6)),
            SizedBox(width: 8),
            Text('Account Provisioned', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional $role account provisioned:',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Name: $name', style: const TextStyle(color: Colors.white70)),
            Text('Email: $email', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF14B8A6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Activation Token:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF14B8A6))),
                  const SizedBox(height: 4),
                  SelectableText(
                    token,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'An activation email has been dispatched. The provider will set their permanent password upon first activation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.adminController.clearLastProvisioned();
              Navigator.pop(ctx);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, String userId, String name, String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the $role account for "$name" (ID: ${userId.substring(0, 8)}...)? This action is permanent and removes all associated records.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await widget.adminController.deleteUser(userId);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Account deleted successfully.' : 'Failed to delete account.'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      appBar: AppBar(
        title: const Text('Account Lifecycle Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All',
            onPressed: () => widget.adminController.loadAll(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => widget.authController.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF14B8A6),
          labelColor: const Color(0xFF14B8A6),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: const Icon(Icons.medical_services, size: 20),
              text: 'Doctors (${widget.adminController.doctors.length})',
            ),
            Tab(
              icon: const Icon(Icons.volunteer_activism, size: 20),
              text: 'ASHAs (${widget.adminController.ashas.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_alt, size: 20),
              text: 'Patients (${widget.adminController.patients.length})',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.adminController,
          builder: (context, _) {
            final isLoading = widget.adminController.status == AdminStateStatus.loading;

            return Column(
              children: [
                // Top Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${user?.fullName ?? 'Admin'} (Account Administrator)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Doctors Tab
                      _buildDoctorsTab(context, theme, isLoading),

                      // 2. ASHAs Tab
                      _buildAshasTab(context, theme, isLoading),

                      // 3. Patients Tab
                      _buildPatientsTab(context, theme, isLoading),
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

  Widget _buildDoctorsTab(BuildContext context, ThemeData theme, bool isLoading) {
    final doctors = widget.adminController.doctors;

    return RefreshIndicator(
      onRefresh: () => widget.adminController.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered Doctors (${doctors.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_doctor_button'),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(height: 12),

          if (doctors.isEmpty && !isLoading)
            _buildEmptyState('No doctor accounts created yet. Tap "Add Doctor" to provision a doctor.'),

          ...doctors.map((doc) => _buildDoctorCard(context, doc)),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, ProfessionalUserModel doc) {
    final license = doc.details?['medical_license_number'] ?? 'N/A';
    final spec = doc.details?['specialization'] ?? 'General Medicine';
    final facility = doc.details?['facility_name'] ?? 'Primary Health Center';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                  child: const Icon(Icons.medical_services, color: Color(0xFF14B8A6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(doc.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (doc.phone != null)
                        Text('Phone: ${doc.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Doctor Account',
                  onPressed: () => _confirmDeleteUser(context, doc.id, doc.fullName, 'Doctor'),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155), height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge('ID: ${doc.id.substring(0, 8)}...', Colors.purple),
                _buildBadge('Spec: $spec', const Color(0xFF14B8A6)),
                _buildBadge('License: $license', Colors.blueGrey),
                _buildBadge('Facility: $facility', Colors.cyan),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doc.mustChangePassword ? 'Pending Activation' : (doc.isActive ? 'Active' : 'Deactivated'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: doc.mustChangePassword ? Colors.amber : (doc.isActive ? Colors.greenAccent : Colors.redAccent),
                  ),
                ),
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Switch(
                      value: doc.isActive,
                      activeThumbColor: const Color(0xFF14B8A6),
                      onChanged: (val) => widget.adminController.toggleUserStatus(doc.id, val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAshasTab(BuildContext context, ThemeData theme, bool isLoading) {
    final ashas = widget.adminController.ashas;

    return RefreshIndicator(
      onRefresh: () => widget.adminController.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered ASHA Workers (${ashas.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_asha_button'),
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Add ASHA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(height: 12),

          if (ashas.isEmpty && !isLoading)
            _buildEmptyState('No ASHA worker accounts created yet. Tap "Add ASHA" to provision a worker.'),

          ...ashas.map((asha) => _buildAshaCard(context, asha)),
        ],
      ),
    );
  }

  Widget _buildAshaCard(BuildContext context, ProfessionalUserModel asha) {
    final code = asha.details?['worker_id_code'] ?? 'N/A';
    final area = asha.details?['assigned_area'] ?? 'General Sector';
    final phc = asha.details?['primary_health_center'] ?? 'PHC Center';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  child: const Icon(Icons.volunteer_activism, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asha.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(asha.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (asha.phone != null)
                        Text('Phone: ${asha.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete ASHA Account',
                  onPressed: () => _confirmDeleteUser(context, asha.id, asha.fullName, 'ASHA Worker'),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155), height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge('Code: $code', const Color(0xFF0284C7)),
                _buildBadge('User ID: ${asha.id.substring(0, 8)}...', Colors.purple),
                _buildBadge('Area: $area', Colors.indigo),
                _buildBadge('Center: $phc', Colors.blueGrey),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  asha.mustChangePassword ? 'Pending Activation' : (asha.isActive ? 'Active' : 'Deactivated'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: asha.mustChangePassword ? Colors.amber : (asha.isActive ? Colors.greenAccent : Colors.redAccent),
                  ),
                ),
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Switch(
                      value: asha.isActive,
                      activeThumbColor: const Color(0xFF0284C7),
                      onChanged: (val) => widget.adminController.toggleUserStatus(asha.id, val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsTab(BuildContext context, ThemeData theme, bool isLoading) {
    final patients = widget.adminController.patients;

    return RefreshIndicator(
      onRefresh: () => widget.adminController.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered Patients (${patients.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_patient_button'),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePatientScreen(adminController: widget.adminController),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (patients.isEmpty && !isLoading)
            _buildEmptyState('No patient accounts registered yet. Tap "Add Patient" to create a patient profile.'),

          ...patients.map((pat) => _buildPatientCard(context, pat)),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientProfileModel pat) {
    final hrNum = pat.healthRecord?.recordNumber ?? 'HR-PENDING';
    final village = pat.villageLocality ?? 'Locality Not Specified';
    final bg = pat.bloodGroup ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pat.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(pat.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (pat.phone != null)
                        Text('Phone: ${pat.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Patient Account',
                  onPressed: () => _confirmDeleteUser(context, pat.userId, pat.fullName, 'Patient'),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155), height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge('Record: $hrNum', const Color(0xFF10B981)),
                _buildBadge('User ID: ${pat.userId.isNotEmpty ? pat.userId.substring(0, 8) : pat.id.substring(0, 8)}...', Colors.purple),
                _buildBadge('Blood: $bg', Colors.redAccent),
                _buildBadge('Locality: $village', Colors.teal),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Registered Patient',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                ),
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Switch(
                      value: true,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) => widget.adminController.toggleUserStatus(pat.userId, val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
}

