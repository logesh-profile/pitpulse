import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../controllers/patient_controller.dart';
import 'patient_profile_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final AuthController authController;
  final PatientController patientController;

  const PatientDashboardScreen({
    super.key,
    required this.authController,
    required this.patientController,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.patientController.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'View Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientProfileScreen(patientController: widget.patientController),
                ),
              );
            },
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
          animation: widget.patientController,
          builder: (context, _) {
            final profile = widget.patientController.profile;
            final isLoading = widget.patientController.status == PatientStateStatus.loading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Patient Profile Summary Card
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF14B8A6),
                                child: Text(
                                  (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Patient',
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
                                      child: const Text('PATIENT / CITIZEN', style: TextStyle(fontSize: 10, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('HEALTH RECORD ID', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile?.healthRecord?.recordNumber ?? (isLoading ? 'Loading...' : 'HR-INITIALIZING'),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6)),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('View Full Profile'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PatientProfileScreen(patientController: widget.patientController),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Health Modules Foundation
                  Text(
                    'Health Services Foundation',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 12),

                  _buildModuleCard(
                    title: 'Personal Health Records',
                    subtitle: 'Demographics, emergency contacts, and baseline info',
                    icon: Icons.folder_shared_outlined,
                    status: 'Active in Stage 3',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientProfileScreen(patientController: widget.patientController),
                        ),
                      );
                    },
                  ),
                  _buildModuleCard(
                    title: 'Vital Telemetry Tracking',
                    subtitle: 'Blood pressure, pulse, and glucose logs',
                    icon: Icons.favorite_outline,
                    status: 'Upcoming in Stage 4+',
                  ),
                  _buildModuleCard(
                    title: 'Doctor Appointments',
                    subtitle: 'Book and manage doctor consultations',
                    icon: Icons.calendar_month_outlined,
                    status: 'Upcoming in Stage 4+',
                  ),
                  _buildModuleCard(
                    title: 'Active Prescriptions',
                    subtitle: 'Medication reminders and digital prescriptions',
                    icon: Icons.medication_outlined,
                    status: 'Upcoming in Stage 4+',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
    VoidCallback? onTap,
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
        onTap: onTap,
      ),
    );
  }
}
