import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pitpulse_mobile/core/theme/maatra_theme.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pitpulse_mobile/features/asha/presentation/controllers/asha_controller.dart';
import 'package:pitpulse_mobile/features/patients/presentation/controllers/patient_controller.dart';
import 'package:pitpulse_mobile/features/patients/presentation/screens/patient_profile_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/controllers/pregnancy_controller.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/add_pregnancy_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/pregnancy_detail_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/pregnancy_list_screen.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/patient_ai_context.dart';
import 'package:pitpulse_mobile/features/patient_ai/presentation/screens/patient_ai_chat_screen.dart';
import 'package:pitpulse_mobile/features/common/presentation/screens/profile_settings_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final AuthController authController;
  final PatientController patientController;
  final PregnancyController? pregnancyController;
  final AshaController? ashaController;

  const PatientDashboardScreen({
    super.key,
    required this.authController,
    required this.patientController,
    this.pregnancyController,
    this.ashaController,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final PregnancyController _pregnancyController;
  late final AshaController _ashaController;

  @override
  void initState() {
    super.initState();
    _pregnancyController = widget.pregnancyController ?? PregnancyController();
    _ashaController = widget.ashaController ?? AshaController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.patientController.loadProfile();
      _pregnancyController.fetchMyPregnancies();
      _ashaController.loadPatientSelfData();
    });
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  void _openPatientAi() {
    final user = widget.authController.currentUser;
    final profile = widget.patientController.profile;
    final activePregnancy = _pregnancyController.activePregnancy;
    final vitals = _ashaController.myVitals;
    final visits = _ashaController.myVisits;
    final assignment = _ashaController.myAssignment;

    final contextSnapshot = PatientAiContext(
      patientName: user?.fullName ?? 'Patient',
      healthRecordNumber: profile?.healthRecord?.recordNumber,
      activePregnancy: activePregnancy,
      vitals: vitals,
      homeVisits: visits,
      assignedAshaName: assignment?.ashaWorkerName,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAiChatScreen(
          contextSnapshot: contextSnapshot,
        ),
      ),
    );
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
            icon: const Icon(Icons.settings_outlined),
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
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.patientController, _pregnancyController, _ashaController]),
          builder: (context, _) {
            final profile = widget.patientController.profile;
            final isProfileLoading = widget.patientController.status == PatientStateStatus.loading;
            final isPregnancyLoading = _pregnancyController.isLoading;
            final activePregnancy = _pregnancyController.activePregnancy;
            final allPregnancies = _pregnancyController.pregnancies;

            final ashaAssignment = _ashaController.myAssignment;
            final homeVisits = _ashaController.myVisits;
            final vitals = _ashaController.myVitals;

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  widget.patientController.loadProfile(),
                  _pregnancyController.fetchMyPregnancies(),
                  _ashaController.loadPatientSelfData(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Profile Summary Card - Swiss Porcelain Style
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MaatraTheme.borderHairline),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: MaatraTheme.brandEmerald,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'P',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Patient',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: MaatraTheme.textCharcoal,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user?.email ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: MaatraTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: MaatraTheme.brandSageWash,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        'PATIENT / CITIZEN',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: MaatraTheme.brandSage,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28, color: MaatraTheme.borderHairline),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HEALTH RECORD ID',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: MaatraTheme.textQuiet,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile?.healthRecord?.recordNumber ?? (isProfileLoading ? 'Loading...' : 'HR-INITIALIZING'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: MaatraTheme.brandEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: MaatraTheme.brandEmerald),
                                label: Text(
                                  'View Profile',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: MaatraTheme.brandEmerald,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
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
                    const SizedBox(height: 20),
                    // PATIENT AI: Anu — ur ai at ur place
                    // ==========================================
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.3), width: 1.2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openPatientAi,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.4), width: 1.5),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/anu_avatar.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_awesome, color: MaatraTheme.brandEmerald, size: 22),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Anu',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: MaatraTheme.textCharcoal,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ur ai at ur place',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: MaatraTheme.brandSage,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: MaatraTheme.brandSageWash,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: MaatraTheme.statusSafe,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Anu Live',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: MaatraTheme.brandSage,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Ask questions about your pregnancy symptoms, diet, fetal development, or upcoming doctor visits anytime.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: MaatraTheme.textMuted,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 44,
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MaatraTheme.brandEmerald,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                                    label: Text(
                                      'Chat with Anu',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: _openPatientAi,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // STAGE 5: Assigned ASHA Health Worker Section
                    // ==========================================
                    Text(
                      'Assigned Field Healthcare Worker',
                      style: theme.textTheme.titleSmall?.copyWith(color: MaatraTheme.textCharcoal, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: ashaAssignment != null ? const Color(0xFF0284C7).withValues(alpha: 0.5) : Colors.transparent,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ashaAssignment != null
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                    child: const Icon(Icons.volunteer_activism, color: Color(0xFF0284C7), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ashaAssignment.ashaWorkerName ?? 'ASHA Field Worker',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Assigned on ${_formatDateShort(ashaAssignment.assignedAt)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if (ashaAssignment.notes != null)
                                          Text(
                                            'Notes: ${ashaAssignment.notes}',
                                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    child: const Icon(Icons.volunteer_activism, color: Colors.grey, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('No ASHA health worker assigned yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        SizedBox(height: 2),
                                        Text('An administrator will assign a local ASHA worker to your sector.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
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
                          style: theme.textTheme.titleSmall?.copyWith(color: MaatraTheme.textCharcoal, fontWeight: FontWeight.w800),
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
                        color: MaatraTheme.surfacePorcelain,
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (activePregnancy != null)
                      // Real Active Pregnancy Card
                      Card(
                        elevation: 0,
                        color: MaatraTheme.surfacePorcelain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: MaatraTheme.borderHairline, width: 1),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: MaatraTheme.surfacePorcelain,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.pregnant_woman, color: MaatraTheme.brandEmerald, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pregnancy #${activePregnancy.pregnancyNumber}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MaatraTheme.textCharcoal),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: MaatraTheme.brandSageWash,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(color: MaatraTheme.brandSage, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: MaatraTheme.borderHairline),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Gestational Age', style: TextStyle(fontSize: 11, color: MaatraTheme.textMuted)),
                                        const SizedBox(height: 2),
                                        Text(
                                          activePregnancy.gestationalAgeDisplay,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MaatraTheme.textCharcoal),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Trimester', style: TextStyle(fontSize: 11, color: MaatraTheme.textMuted)),
                                        const SizedBox(height: 2),
                                        Text(
                                          activePregnancy.trimesterDisplay,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MaatraTheme.statusWarning),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Estimated Due Date', style: TextStyle(fontSize: 11, color: MaatraTheme.textMuted)),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDateShort(activePregnancy.edd),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MaatraTheme.brandEmerald),
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
                                      backgroundColor: MaatraTheme.brandEmerald,
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
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: MaatraTheme.brandEmerald.withValues(alpha: 0.2),
                                    child: const Icon(Icons.pregnant_woman, color: MaatraTheme.brandEmerald, size: 22),
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
                                    style: ElevatedButton.styleFrom(backgroundColor: MaatraTheme.brandEmerald),
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

                    // ==========================================
                    // STAGE 5: Maternal Vital Observations History
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maternal Vitals (${vitals.length})',
                          style: theme.textTheme.titleSmall?.copyWith(color: MaatraTheme.textCharcoal, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (vitals.isEmpty)
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: const Padding(
                          padding: EdgeInsets.all(18.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.monitor_heart_outlined, color: Colors.grey, size: 32),
                                SizedBox(height: 8),
                                Text('No vital records available yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('Vitals recorded by your ASHA worker during home visits will appear here.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...vitals.map((vit) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.favorite, size: 16, color: MaatraTheme.brandEmerald),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDateShort(vit.recordedAt),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'By: ${vit.recordedByName} (${vit.recordedByRole})',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const Divider(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('BLOOD PRESSURE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(vit.bpDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('WEIGHT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(vit.weightDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('TEMP', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(vit.temperatureDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ],
                                ),
                                if (vit.notes != null && vit.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Notes: ${vit.notes}',
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // ==========================================
                    // STAGE 5: ASHA Field Home Visits History
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ASHA Field Home Visits (${homeVisits.length})',
                          style: theme.textTheme.titleSmall?.copyWith(color: MaatraTheme.textCharcoal, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (homeVisits.isEmpty)
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: const Padding(
                          padding: EdgeInsets.all(18.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.home_work_outlined, color: Colors.grey, size: 32),
                                SizedBox(height: 8),
                                Text('No home visits recorded yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('Visits conducted by your ASHA worker will appear here with observations.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...homeVisits.map((v) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDateShort(v.visitDate),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Text('ASHA: ${v.ashaWorkerName}', style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                                  ],
                                ),
                                const Divider(height: 14),
                                Text('Purpose: ${v.purpose}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                if (v.observations != null && v.observations!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Observations: ${v.observations}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                                if (v.followUpRequired) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Follow-up: ${v.followUpNotes ?? "Required"}',
                                          style: const TextStyle(fontSize: 11, color: Colors.amber),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Health Modules Foundation
                    Text(
                      'Connected Health Network Foundation',
                      style: theme.textTheme.titleSmall?.copyWith(color: MaatraTheme.textCharcoal, fontWeight: FontWeight.w800),
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
                      title: 'Doctor Appointments',
                      subtitle: 'Book and manage doctor consultations',
                      icon: Icons.calendar_month_outlined,
                      status: 'Stage 6+ Foundation',
                    ),
                    _buildModuleCard(
                      title: 'Active Prescriptions',
                      subtitle: 'Medication reminders and digital prescriptions',
                      icon: Icons.medication_outlined,
                      status: 'Stage 6+ Foundation',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Maternal AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openPatientAi,
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
      color: MaatraTheme.surfacePorcelain,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: MaatraTheme.borderHairline),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: MaatraTheme.brandSageWash,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MaatraTheme.brandEmerald, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: MaatraTheme.textCharcoal, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: MaatraTheme.textMuted)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: MaatraTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: MaatraTheme.borderHairline),
          ),
          child: Text(
            status,
            style: const TextStyle(fontSize: 10, color: MaatraTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
