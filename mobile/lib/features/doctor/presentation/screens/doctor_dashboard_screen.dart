import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pitpulse_mobile/core/theme/maatra_theme.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../../data/models/doctor_models.dart';
import '../controllers/doctor_controller.dart';
import 'doctor_patient_detail_screen.dart';
import '../../../common/presentation/screens/profile_settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _doctorController = widget.doctorController ?? DoctorController();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doctorController.loadDoctorData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAssignAshaModal(DoctorPatientModel patient) {
    final ashas = _doctorController.availableAshas;
    String? selectedAshaId = ashas.isNotEmpty ? ashas.first.ashaId : null;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaatraTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: MaatraTheme.accentLilac, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Connect Patient to ASHA',
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: MaatraTheme.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Patient Summary Pill
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MaatraTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MaatraTheme.borderMuted),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gmail: ${patient.email}',
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.accentLilac,
                            fontSize: 13,
                          ),
                        ),
                        if (patient.villageLocality != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Area: ${patient.villageLocality}',
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (ashas.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MaatraTheme.amberWarning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MaatraTheme.amberWarning.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'No ASHA healthcare workers are available in the system yet. Ask Administrator to create ASHA accounts.',
                        style: GoogleFonts.plusJakartaSans(
                          color: MaatraTheme.amberWarning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'SELECT ASHA WORKER',
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.accentLilac,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: MaatraTheme.inputDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: MaatraTheme.borderMuted),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAshaId,
                          dropdownColor: MaatraTheme.surfaceDark,
                          isExpanded: true,
                          items: ashas.map((a) {
                            return DropdownMenuItem<String>(
                              value: a.ashaId,
                              child: Text(
                                '${a.fullName} • ${a.email} (${a.activePatientsCount} patients)',
                                style: GoogleFonts.plusJakartaSans(
                                  color: MaatraTheme.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setSheetState(() => selectedAshaId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Doctor Clinical Assignment Notes (Optional)',
                        hintText: 'e.g. Schedule weekly BP monitoring & dietary checks...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [MaatraTheme.deepAmethyst, MaatraTheme.primaryAmethyst],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: selectedAshaId == null
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);
                                final success = await _doctorController.assignAshaToPatient(
                                  patientId: patient.patientId,
                                  ashaWorkerId: selectedAshaId!,
                                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                );
                                if (success && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: MaatraTheme.emeraldSuccess,
                                      content: Text(
                                        'ASHA worker assigned to ${patient.fullName}!',
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Confirm & Connect Assignment',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final docUser = widget.authController.currentUser;
    final docName = docUser?.fullName ?? 'Doctor';

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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.all_inclusive_rounded, size: 22, color: MaatraTheme.accentLilac),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MAATRA CLINICAL',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Dr. $docName',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.accentLilac,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: MaatraTheme.textSecondary, size: 20),
            tooltip: 'Refresh Roster',
            onPressed: () => _doctorController.loadDoctorData(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: MaatraTheme.textSecondary, size: 20),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MaatraTheme.primaryAmethyst,
          indicatorWeight: 3,
          labelColor: MaatraTheme.accentLilac,
          unselectedLabelColor: MaatraTheme.textTertiary,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Registered Patients', icon: Icon(Icons.people_alt_rounded, size: 18)),
            Tab(text: 'Needs ASHA Care', icon: Icon(Icons.assignment_ind_rounded, size: 18)),
            Tab(text: 'ASHA Directory', icon: Icon(Icons.health_and_safety_rounded, size: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _doctorController,
          builder: (context, _) {
            if (_doctorController.isLoading && _doctorController.allPatients.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: MaatraTheme.primaryAmethyst),
              );
            }

            final all = _doctorController.allPatients;
            final unassigned = _doctorController.unassignedPatients;
            final ashas = _doctorController.availableAshas;

            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All Patients
                _buildPatientList(
                  patients: all,
                  emptyMessage: 'No patients registered in the database yet.\nWhen patients create accounts with their Gmail, they will appear here.',
                ),
                // Tab 2: Needs ASHA Care
                _buildPatientList(
                  patients: unassigned,
                  emptyMessage: 'All registered patients are currently assigned to ASHA workers.',
                ),
                // Tab 3: ASHA Directory
                _buildAshaList(ashas: ashas),
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
  }) {
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MaatraTheme.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: MaatraTheme.borderMuted),
                ),
                child: const Icon(Icons.person_search_rounded, size: 36, color: MaatraTheme.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: MaatraTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: MaatraTheme.primaryAmethyst,
      backgroundColor: MaatraTheme.surfaceDark,
      onRefresh: () => _doctorController.loadDoctorData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final p = patients[index];
          final isAssigned = p.assignedAshaName != null && p.assignedAshaName!.isNotEmpty;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            color: MaatraTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: MaatraTheme.borderMuted),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gmail: ${p.email}',
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.accentLilac,
                                fontSize: 13,
                              ),
                            ),
                            if (p.phone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Phone: ${p.phone}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: MaatraTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? MaatraTheme.emeraldSuccess.withValues(alpha: 0.15)
                              : MaatraTheme.amberWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAssigned
                                ? MaatraTheme.emeraldSuccess.withValues(alpha: 0.4)
                                : MaatraTheme.amberWarning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          isAssigned ? 'Assigned' : 'Unassigned',
                          style: GoogleFonts.plusJakartaSans(
                            color: isAssigned ? MaatraTheme.emeraldSuccess : MaatraTheme.amberWarning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: MaatraTheme.borderMuted, height: 1),
                  const SizedBox(height: 12),

                  // ASHA Assignment Info
                  Row(
                    children: [
                      Icon(
                        isAssigned ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                        size: 16,
                        color: isAssigned ? MaatraTheme.accentLilac : MaatraTheme.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAssigned
                              ? 'Assigned Worker: ${p.assignedAshaName}'
                              : 'No ASHA worker assigned yet.',
                          style: GoogleFonts.plusJakartaSans(
                            color: isAssigned ? MaatraTheme.textPrimary : MaatraTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: isAssigned ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorPatientDetailScreen(
                                  patient: p,
                                  doctorController: _doctorController,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: MaatraTheme.borderMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            'View Details',
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showAssignAshaModal(p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MaatraTheme.primaryAmethyst,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            isAssigned ? 'Reassign ASHA' : 'Assign ASHA',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  Widget _buildAshaList({required List<DoctorAshaModel> ashas}) {
    if (ashas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MaatraTheme.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: MaatraTheme.borderMuted),
                ),
                child: const Icon(Icons.health_and_safety_rounded, size: 36, color: MaatraTheme.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(
                'No ASHA healthcare workers provisioned yet.\nAdmin creates ASHA accounts via Administrator Console.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: MaatraTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: MaatraTheme.primaryAmethyst,
      backgroundColor: MaatraTheme.surfaceDark,
      onRefresh: () => _doctorController.loadDoctorData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ashas.length,
        itemBuilder: (context, index) {
          final a = ashas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: MaatraTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: MaatraTheme.borderMuted),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MaatraTheme.cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: MaatraTheme.accentLilac, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gmail: ${a.email}',
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.accentLilac,
                            fontSize: 12,
                          ),
                        ),
                        if (a.assignedArea != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Area: ${a.assignedArea}',
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: MaatraTheme.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MaatraTheme.borderMuted),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${a.activePatientsCount}',
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.primaryAmethyst,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Patients',
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
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
