import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/core/theme/maatra_theme.dart';
import '../controllers/patient_controller.dart';
import 'edit_patient_profile_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  final PatientController patientController;

  const PatientProfileScreen({super.key, required this.patientController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patient Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPatientProfileScreen(patientController: patientController),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: patientController,
          builder: (context, _) {
            final profile = patientController.profile;

            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Health Record Badge
                  Card(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF14B8A6)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('PERMANENT HEALTH RECORD ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6))),
                          const SizedBox(height: 6),
                          Text(
                            profile.healthRecord?.recordNumber ?? 'HR-INITIALIZING',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 4),
                          Text('PostgreSQL Anchor ID: ${profile.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Details Card
                  Card(
                    color: MaatraTheme.surfacePorcelain, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: MaatraTheme.borderHairline)),
                    // shape set above
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24, color: MaatraTheme.borderHairline),
                          _buildDetailRow('Full Name', profile.fullName),
                          _buildDetailRow('Email Address', profile.email),
                          _buildDetailRow('Phone Number', profile.phone ?? 'Not provided'),
                          _buildDetailRow('Date of Birth', profile.dateOfBirth ?? 'Not provided'),
                          _buildDetailRow('Sex', profile.sex ?? 'Not provided'),
                          _buildDetailRow('Blood Group', profile.bloodGroup ?? 'Not provided'),
                          _buildDetailRow('Village / Locality', profile.villageLocality ?? 'Not provided'),
                          _buildDetailRow('Residential Address', profile.address ?? 'Not provided'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emergency & Baseline Card
                  Card(
                    color: MaatraTheme.surfacePorcelain, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: MaatraTheme.borderHairline)),
                    // shape set above
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency & Baseline Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24, color: MaatraTheme.borderHairline),
                          _buildDetailRow('Emergency Contact', profile.emergencyContactName ?? 'Not provided'),
                          _buildDetailRow('Emergency Phone', profile.emergencyContactPhone ?? 'Not provided'),
                          _buildDetailRow('Baseline Notes', profile.baselineHealthInfo ?? 'No known health conditions recorded'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Edit Profile Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF14B8A6),
                      side: const BorderSide(color: Color(0xFF14B8A6)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPatientProfileScreen(patientController: patientController),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: MaatraTheme.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: MaatraTheme.textCharcoal)),
          ),
        ],
      ),
    );
  }
}
