import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pitpulse_mobile/features/patients/presentation/controllers/patient_controller.dart';
import 'package:pitpulse_mobile/features/patients/presentation/screens/patient_profile_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/controllers/pregnancy_controller.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/add_pregnancy_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/pregnancy_detail_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/pregnancy_list_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final AuthController authController;
  final PatientController patientController;
  final PregnancyController? pregnancyController;

  const PatientDashboardScreen({
    super.key,
    required this.authController,
    required this.patientController,
    this.pregnancyController,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final PregnancyController _pregnancyController;
  static const Color primaryTeal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _pregnancyController = widget.pregnancyController ?? PregnancyController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.patientController.loadProfile();
      _pregnancyController.fetchMyPregnancies();
    });
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
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
          animation: Listenable.merge([widget.patientController, _pregnancyController]),
          builder: (context, _) {
            final profile = widget.patientController.profile;
            final isProfileLoading = widget.patientController.status == PatientStateStatus.loading;
            final isPregnancyLoading = _pregnancyController.isLoading;
            final activePregnancy = _pregnancyController.activePregnancy;
            final allPregnancies = _pregnancyController.pregnancies;

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
                                      child: const Text(
                                        'PATIENT / CITIZEN',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                                      ),
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
                                    profile?.healthRecord?.recordNumber ?? (isProfileLoading ? 'Loading...' : 'HR-INITIALIZING'),
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

                  // ==========================================
                  // STAGE 4: Maternal & Pregnancy Health Section
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maternal & Pregnancy Care',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                      ),
                      if (allPregnancies.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PregnancyListScreen(controller: _pregnancyController),
                              ),
                            );
                          },
                          child: Text('All Records (${allPregnancies.length})'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (isPregnancyLoading && allPregnancies.isEmpty)
                    const Card(
                      color: Color(0xFF1E293B),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (activePregnancy != null)
                    // Real Active Pregnancy Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF14B8A6), width: 1.2),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF14B8A6).withValues(alpha: 0.15),
                              const Color(0xFF0F172A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.pregnant_woman, color: Color(0xFF14B8A6), size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pregnancy #${activePregnancy.pregnancyNumber}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF14B8A6)),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Gestational Age', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        activePregnancy.gestationalAgeDisplay,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Trimester', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        activePregnancy.trimesterDisplay,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Estimated Due Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDateShort(activePregnancy.edd),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF14B8A6),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: const Text('View Maternal Record'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PregnancyDetailScreen(
                                          pregnancy: activePregnancy,
                                          controller: _pregnancyController,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Truthful Empty State Card
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: primaryTeal.withValues(alpha: 0.2),
                                  child: const Icon(Icons.pregnant_woman, color: primaryTeal, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No Active Pregnancy Record',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        allPregnancies.isNotEmpty
                                            ? 'You have ${allPregnancies.length} past pregnancy record(s).'
                                            : 'Register your pregnancy to track gestation, EDD, and timeline milestones.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (allPregnancies.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PregnancyListScreen(controller: _pregnancyController),
                                        ),
                                      );
                                    },
                                    child: const Text('View History'),
                                  ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                  label: const Text('Register Pregnancy', style: TextStyle(color: Colors.white)),
                                  onPressed: () async {
                                    final created = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddPregnancyScreen(controller: _pregnancyController),
                                      ),
                                    );
                                    if (created != null) {
                                      _pregnancyController.fetchMyPregnancies();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Health Modules Foundation
                  Text(
                    'Connected Health Network Foundation',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 12),

                  _buildModuleCard(
                    title: 'Personal Health Records',
                    subtitle: 'Demographics, emergency contacts, and baseline identity',
                    icon: Icons.folder_shared_outlined,
                    status: 'Stage 3 Anchor',
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
                    status: 'Stage 5+ Foundation',
                  ),
                  _buildModuleCard(
                    title: 'Doctor Appointments',
                    subtitle: 'Book and manage doctor consultations',
                    icon: Icons.calendar_month_outlined,
                    status: 'Stage 5+ Foundation',
                  ),
                  _buildModuleCard(
                    title: 'Active Prescriptions',
                    subtitle: 'Medication reminders and digital prescriptions',
                    icon: Icons.medication_outlined,
                    status: 'Stage 5+ Foundation',
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
