import 'package:flutter/material.dart';
import '../../../asha/presentation/controllers/asha_controller.dart';
import '../../../asha/data/models/asha_models.dart';

const Color _primaryTeal = Color(0xFF14B8A6);
const Color _primaryBlue = Color(0xFF0284C7);

class AdminAssignmentsScreen extends StatefulWidget {
  final AshaController ashaController;

  const AdminAssignmentsScreen({super.key, required this.ashaController});

  @override
  State<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends State<AdminAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.ashaController.loadAdminAssignmentsData();
    });
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  void _showAssignDialog(BuildContext context) {
    String? selectedAshaId;
    String? selectedPatientId;
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final patients = widget.ashaController.adminPatients;
    final ashas = widget.ashaController.adminAshaWorkers;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Patient to ASHA'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ashas.isEmpty)
                    const Text('No ASHA workers available. Provision an ASHA account first.', style: TextStyle(color: Colors.amber, fontSize: 13))
                  else ...[
                    const Text('Select ASHA Worker:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedAshaId,
                      items: ashas.map((a) {
                        final user = a['user'] ?? {};
                        final name = user['full_name'] ?? 'ASHA Worker';
                        final code = a['worker_id_code'] ?? '';
                        return DropdownMenuItem<String>(
                          value: a['id'] as String,
                          child: Text('$name ($code)', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedAshaId = val),
                      validator: (val) => val == null ? 'Please select an ASHA worker' : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (patients.isEmpty)
                    const Text('No registered patients available for assignment.', style: TextStyle(color: Colors.amber, fontSize: 13))
                  else ...[
                    const Text('Select Patient:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedPatientId,
                      items: patients.map((p) {
                        final user = p['user'] ?? {};
                        final name = user['full_name'] ?? 'Patient';
                        final hr = p['health_record']?['record_number'] ?? '';
                        return DropdownMenuItem<String>(
                          value: p['id'] as String,
                          child: Text('$name ($hr)', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedPatientId = val),
                      validator: (val) => val == null ? 'Please select a patient' : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Allocation Notes (Optional):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Sector 4 primary allocation',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal),
              onPressed: (ashas.isEmpty || patients.isEmpty)
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() == true) {
                        final ashaId = selectedAshaId!;
                        final patId = selectedPatientId!;
                        final notesText = notesController.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final success = await widget.ashaController.assignPatient(
                          ashaWorkerId: ashaId,
                          patientId: patId,
                          notes: notesText.isNotEmpty ? notesText : null,
                        );
                        if (!mounted) return;
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Patient assigned to ASHA successfully.')),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(widget.ashaController.errorMessage ?? 'Failed to assign patient.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASHA Patient Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.ashaController.loadAdminAssignmentsData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('admin_assign_patient_fab'),
        icon: const Icon(Icons.person_add),
        label: const Text('New Assignment'),
        backgroundColor: _primaryTeal,
        onPressed: () => _showAssignDialog(context),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.ashaController,
          builder: (context, _) {
            final isLoading = widget.ashaController.isLoading;
            final assignments = widget.ashaController.adminAssignments;

            if (isLoading && assignments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => widget.ashaController.loadAdminAssignmentsData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Field Healthcare Roster (${assignments.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assign and monitor patient-to-ASHA allocations in real-time.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    if (assignments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_ind_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'No ASHA assignments found.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use the button below to assign a registered patient to an ASHA worker.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ...assignments.map((a) => _buildAssignmentCard(context, a)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, AshaAssignmentModel a) {
    final isActive = a.status == 'ACTIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive ? _primaryTeal.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person, color: isActive ? _primaryTeal : Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isActive ? Colors.green : Colors.grey),
                  ),
                  child: Text(
                    a.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.volunteer_activism, size: 16, color: _primaryBlue),
                const SizedBox(width: 6),
                Text(
                  'ASHA: ${a.ashaWorkerName ?? "Health Worker"}',
                  style: const TextStyle(fontSize: 13, color: _primaryBlue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (a.healthRecordNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Record #: ${a.healthRecordNumber}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              a.unassignedAt != null
                  ? 'Assigned on ${_formatDateShort(a.assignedAt)} • Deactivated ${_formatDateShort(a.unassignedAt!)}'
                  : 'Assigned on ${_formatDateShort(a.assignedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (a.notes != null && a.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Notes: ${a.notes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[300],
                      side: BorderSide(color: Colors.red[700]!),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.block, size: 14),
                    label: const Text('Deactivate', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Deactivate Assignment?'),
                          content: Text('Are you sure you want to unassign ${a.patientName} from ${a.ashaWorkerName}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Deactivate'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        widget.ashaController.deactivateAssignment(a.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
