import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';

class AshaDashboardScreen extends StatelessWidget {
  final AuthController authController;

  const AshaDashboardScreen({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASHA Field Care Portal'),
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
              // ASHA Header Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        child: const Icon(Icons.volunteer_activism, color: Color(0xFF0284C7), size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'ASHA Worker',
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
                                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF0284C7)),
                              ),
                              child: const Text(
                                'ASHA HEALTH WORKER',
                                style: TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
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
                'Community Field Care Modules',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
              ),
              const SizedBox(height: 12),

              _buildModuleCard(
                context,
                title: 'Assigned Village Roster',
                subtitle: 'Community households and registered individuals',
                icon: Icons.holiday_village_outlined,
                status: 'Foundation Ready',
              ),
              _buildModuleCard(
                context,
                title: 'Home Visits & Surveys',
                subtitle: 'Routine prenatal and community health visits',
                icon: Icons.home_outlined,
                status: 'Upcoming in Stage 4+',
              ),
              _buildModuleCard(
                context,
                title: 'Vital Telemetry & Screening',
                subtitle: 'Blood pressure, pulse, and glucose screening',
                icon: Icons.monitor_heart_outlined,
                status: 'Upcoming in Stage 4+',
              ),
              _buildModuleCard(
                context,
                title: 'Maternal & Child Immunization',
                subtitle: 'Vaccination schedules and reminders',
                icon: Icons.vaccines_outlined,
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
        leading: Icon(icon, color: const Color(0xFF0284C7)),
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
