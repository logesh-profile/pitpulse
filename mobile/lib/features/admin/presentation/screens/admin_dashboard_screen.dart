import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import 'create_asha_screen.dart';
import 'create_doctor_screen.dart';

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

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.adminController.loadProfessionals();
    });
  }

  void _showActivationCredentialModal(BuildContext context, String name, String email, String role, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.vpn_key, color: Color(0xFF14B8A6)),
            SizedBox(width: 8),
            Text('Account Provisioned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional $role account created in PostgreSQL:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Name: $name'),
            Text('Email: $email'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[900]?.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Temporary Activation Password:', style: TextStyle(fontSize: 12, color: Colors.amber)),
                  const SizedBox(height: 4),
                  SelectableText(
                    tempPassword,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this temporary password securely with the provider. They will be prompted to set a permanent password upon first login.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authController.currentUser;
    final lastProv = widget.adminController.lastProvisioned;

    // Check if a new account was just provisioned
    if (lastProv != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showActivationCredentialModal(
          context,
          lastProv.fullName,
          lastProv.email,
          lastProv.role,
          lastProv.temporaryPassword,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => widget.adminController.loadProfessionals(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => widget.authController.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.adminController,
          builder: (context, _) {
            final isLoading = widget.adminController.status == AdminStateStatus.loading;
            final professionals = widget.adminController.professionals;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Admin Profile Header Card
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.purple[700],
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Administrator',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[900]?.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.purple[500]!),
                                  ),
                                  child: const Text('SYSTEM ADMIN', style: TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('admin_add_doctor_button'),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Add Doctor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('admin_add_asha_button'),
                          icon: const Icon(Icons.group_add),
                          label: const Text('Add ASHA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Healthcare Providers (${professionals.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (professionals.isEmpty && !isLoading)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No professional accounts provisioned yet.\nUse the buttons above to create Doctor or ASHA accounts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),

                  // List of Professionals
                  ...professionals.map((prof) {
                    final isDoctor = prof.role == 'DOCTOR';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDoctor ? const Color(0xFF14B8A6).withValues(alpha: 0.2) : const Color(0xFF0284C7).withValues(alpha: 0.2),
                          child: Icon(
                            isDoctor ? Icons.medical_services : Icons.volunteer_activism,
                            color: isDoctor ? const Color(0xFF14B8A6) : const Color(0xFF0284C7),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(prof.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDoctor ? const Color(0xFF14B8A6) : const Color(0xFF0284C7)).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                prof.role,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDoctor ? const Color(0xFF14B8A6) : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(prof.email, style: const TextStyle(fontSize: 12)),
                            if (prof.phone != null) Text('Phone: ${prof.phone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (prof.mustChangePassword)
                              const Text('Status: Activation Pending (Temporary PW)', style: TextStyle(fontSize: 11, color: Colors.amber)),
                          ],
                        ),
                        trailing: Switch(
                          value: prof.isActive,
                          activeThumbColor: const Color(0xFF14B8A6),
                          onChanged: (val) => widget.adminController.toggleUserStatus(prof.id, val),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
