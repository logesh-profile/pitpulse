import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';

class DoctorDashboardScreen extends StatelessWidget {
  final AuthController authController;

  const DoctorDashboardScreen({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Consultation Desk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Doctor Header Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                        child: const Icon(Icons.medical_services, color: Color(0xFF14B8A6), size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Doctor',
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
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF14B8A6)),
                              ),
                              child: const Text(
                                'DOCTOR / CLINICIAN',
                                style: TextStyle(fontSize: 10, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Clinical Modules Foundation',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
              ),
              const SizedBox(height: 12),

              _buildModuleCard(
                context,
                title: 'My Patients Queue',
                subtitle: 'Authorized patient roster and assigned triage',
                icon: Icons.people_outline,
                status: 'Foundation Ready',
              ),
              _buildModuleCard(
                context,
                title: 'Clinical Consultations',
                subtitle: 'Diagnostic notes and consultation history',
                icon: Icons.assignment_outlined,
                status: 'Upcoming in Stage 4+',
              ),
              _buildModuleCard(
                context,
                title: 'Electronic Prescriptions',
                subtitle: 'Formulary-verified digital prescriptions',
                icon: Icons.receipt_long_outlined,
                status: 'Upcoming in Stage 4+',
              ),
              _buildModuleCard(
                context,
                title: 'Appointment Schedules',
                subtitle: 'Teleconsultation and in-clinic appointments',
                icon: Icons.calendar_today_outlined,
                status: 'Upcoming in Stage 4+',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF14B8A6)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
