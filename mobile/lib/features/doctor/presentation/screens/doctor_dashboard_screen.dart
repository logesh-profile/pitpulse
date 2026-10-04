import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../controllers/doctor_controller.dart';
import '../../data/models/doctor_models.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final AuthController authController;
  final DoctorController? doctorController;

  const DoctorDashboardScreen({
    super.key,
    required this.authController,
    this.doctorController,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> with SingleTickerProviderStateMixin {
  late final DoctorController _doctorController;
  late final TabController _tabController;

  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color accentCyan = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    _doctorController = widget.doctorController ?? DoctorController();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doctorController.loadDoctorData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAssignAshaDialog(DoctorPatientModel patient) {
    final ashas = _doctorController.availableAshas;
    String? selectedAshaId = ashas.isNotEmpty ? ashas.first.ashaId : null;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Assign ASHA Field Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${patient.fullName}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    if (patient.villageLocality != null)
                      Text('Locality: ${patient.villageLocality}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (ashas.isEmpty) ...[
                      const Text(
                        'No active ASHA workers available.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ] else ...[
                      const Text('Select ASHA Worker *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedAshaId,
                        dropdownColor: const Color(0xFF334155),
                        items: ashas.map((a) {
                          return DropdownMenuItem<String>(
                            value: a.ashaId,
                            child: Text(
                              '${a.fullName} (${a.activePatientsCount} assigned)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedAshaId = val);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Clinical Assignment Notes (Optional)',
                        hintText: 'e.g. High-risk monitoring, weekly BP check...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedAshaId == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogContext);
                          final success = await _doctorController.assignAshaToPatient(
                            patientId: patient.patientId,
                            ashaWorkerId: selectedAshaId!,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          if (success && mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green[800],
                                content: Text('ASHA worker successfully assigned to ${patient.fullName}!'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Assign ASHA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Consultation Desk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _doctorController.loadDoctorData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => widget.authController.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentCyan,
          tabs: const [
            Tab(text: 'Needs ASHA Care', icon: Icon(Icons.person_add_alt_1, size: 20)),
            Tab(text: 'All Patients Queue', icon: Icon(Icons.people_alt, size: 20)),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _doctorController,
          builder: (context, _) {
            if (_doctorController.isLoading && _doctorController.allPatients.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final unassigned = _doctorController.unassignedPatients;
            final all = _doctorController.allPatients;

            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Unassigned Patients
                _buildPatientList(
                  patients: unassigned,
                  emptyMessage: 'No patients currently pending ASHA assignment.',
                  showAssignButton: true,
                ),
                // Tab 2: All Patients
                _buildPatientList(
                  patients: all,
                  emptyMessage: 'No registered patients found in authorized clinical scope.',
                  showAssignButton: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPatientList({
    required List<DoctorPatientModel> patients,
    required String emptyMessage,
    required bool showAssignButton,
  }) {
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _doctorController.loadDoctorData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final p = patients[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryTeal.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: accentCyan),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              p.email,
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            if (p.villageLocality != null)
                              Text(
                                'Village: ${p.villageLocality}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (p.hasActivePregnancy)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.pink[400]!),
                          ),
                          child: Text(
                            'Pregnant • ${p.activePregnancyGaWeeks ?? 0}w',
                            style: TextStyle(color: Colors.pink[200], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.black38),
                  Row(
                    children: [
                      Icon(Icons.assignment_ind, size: 16, color: p.assignedAshaName != null ? Colors.green[400] : Colors.amber[400]),
                      const SizedBox(width: 6),
                      Text(
                        p.assignedAshaName != null
                            ? 'ASHA: ${p.assignedAshaName}'
                            : 'No ASHA Assigned',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.assignedAshaName != null ? Colors.green[300] : Colors.amber[300],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (showAssignButton)
                        ElevatedButton.icon(
                          onPressed: () => _showAssignAshaDialog(p),
                          icon: Icon(p.assignedAshaName != null ? Icons.swap_horiz : Icons.person_add, size: 14),
                          label: Text(p.assignedAshaName != null ? 'Reassign ASHA' : 'Assign ASHA', style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.assignedAshaName != null ? const Color(0xFF334155) : primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
