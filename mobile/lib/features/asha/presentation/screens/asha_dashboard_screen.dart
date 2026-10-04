import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../controllers/asha_controller.dart';
import 'asha_patient_detail_screen.dart';

class AshaDashboardScreen extends StatefulWidget {
  final AuthController authController;
  final AshaController? ashaController;

  const AshaDashboardScreen({
    super.key,
    required this.authController,
    this.ashaController,
  });

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  late final AshaController _ashaController;

  @override
  void initState() {
    super.initState();
    _ashaController = widget.ashaController ?? AshaController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ashaController.loadMyAssignedPatients();
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
        title: const Text('ASHA Field Care Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _ashaController.loadMyAssignedPatients(),
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
          animation: _ashaController,
          builder: (context, _) {
            final isLoading = _ashaController.isLoading;
            final patients = _ashaController.assignedPatients;

            return RefreshIndicator(
              onRefresh: () => _ashaController.loadMyAssignedPatients(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                    // Section Title: My Assigned Patients
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Assigned Patients (${patients.length})',
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
                    const SizedBox(height: 10),

                    if (patients.isEmpty && !isLoading)
                      Container(
                        padding: const EdgeInsets.all(28),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'No patients assigned yet.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Patients allocated to you by your health administrator will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ...patients.map((p) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: p.hasActivePregnancy ? const Color(0xFF14B8A6).withValues(alpha: 0.6) : Colors.transparent,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AshaPatientDetailScreen(
                                    ashaController: _ashaController,
                                    patient: p,
                                  ),
                                ),
                              );
                              _ashaController.loadMyAssignedPatients();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.patientName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      if (p.hasActivePregnancy)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF14B8A6)),
                                          ),
                                          child: const Text(
                                            'PREGNANCY ACTIVE',
                                            style: TextStyle(fontSize: 10, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('HEALTH RECORD', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text(
                                            p.healthRecordNumber ?? 'HR-PENDING',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('HOME VISITS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text(
                                            '${p.totalVisits} visit(s)',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('LAST VISIT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text(
                                            p.lastVisitDate != null ? _formatDateShort(p.lastVisitDate!) : 'No visits yet',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: p.lastVisitDate != null ? const Color(0xFF0284C7) : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Stage 5 Modules Overview
                    Text(
                      'Community Field Care Modules',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 12),

                    _buildModuleCard(
                      context,
                      title: 'Field Home Visits',
                      subtitle: 'Prenatal surveys, vital telemetry & care observations',
                      icon: Icons.home_outlined,
                      status: 'Stage 5 Active',
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Maternal Telemetry & Vitals',
                      subtitle: 'Blood pressure, weight & thermal observations',
                      icon: Icons.monitor_heart_outlined,
                      status: 'Stage 5 Active',
                    ),
                    _buildModuleCard(
                      context,
                      title: 'ASHA AI Field Intelligence',
                      subtitle: 'On-device triage assistant, maternal risk scoring & clinical guidance',
                      icon: Icons.auto_awesome,
                      status: 'Coming Soon',
                      badgeColor: Colors.purpleAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ASHA AI Field Intelligence is in development for future field deployment.'),
                            backgroundColor: Color(0xFF1E293B),
                          ),
                        );
                      },
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Maternal & Child Immunization',
                      subtitle: 'Vaccination schedules and reminders',
                      icon: Icons.vaccines_outlined,
                      status: 'Stage 6+ Foundation',
                    ),
                  ],
                ),
              ),
            );
          },
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
    Color? badgeColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: badgeColor ?? const Color(0xFF0284C7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor != null ? badgeColor.withValues(alpha: 0.15) : Colors.black26,
            borderRadius: BorderRadius.circular(4),
            border: badgeColor != null ? Border.all(color: badgeColor) : null,
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: badgeColor ?? (status.contains('Active') ? const Color(0xFF0284C7) : Colors.grey),
              fontWeight: (status.contains('Active') || badgeColor != null) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
