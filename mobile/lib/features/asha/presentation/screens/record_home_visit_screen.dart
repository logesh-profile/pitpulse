import 'package:flutter/material.dart';
import '../controllers/asha_controller.dart';
import '../../data/models/asha_models.dart';
import 'record_vitals_screen.dart';

class RecordHomeVisitScreen extends StatefulWidget {
  final AshaController ashaController;
  final AshaAssignmentModel patient;

  const RecordHomeVisitScreen({
    super.key,
    required this.ashaController,
    required this.patient,
  });

  @override
  State<RecordHomeVisitScreen> createState() => _RecordHomeVisitScreenState();
}

class _RecordHomeVisitScreenState extends State<RecordHomeVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  final _purposeController = TextEditingController();
  final _observationsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _followUpRequired = false;
  final _followUpNotesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _observationsController.dispose();
    _notesController.dispose();
    _followUpNotesController.dispose();
    super.dispose();
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitVisit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final visit = await widget.ashaController.createHomeVisit(
      patientId: widget.patient.patientId,
      visitDate: _selectedDate.toIso8601String().split('T')[0],
      pregnancyId: widget.patient.pregnancyId,
      purpose: _purposeController.text.trim(),
      observations: _observationsController.text.trim().isNotEmpty
          ? _observationsController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      followUpRequired: _followUpRequired,
      followUpNotes: (_followUpRequired && _followUpNotesController.text.trim().isNotEmpty)
          ? _followUpNotesController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (visit != null) {
      // Offer recording maternal vitals immediately
      final recordVitalsNow = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Home Visit Saved'),
          content: const Text(
            'The field visit was successfully recorded in PostgreSQL. Would you like to record maternal vitals for this visit now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Done'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              icon: const Icon(Icons.favorite),
              label: const Text('Record Vitals'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (recordVitalsNow == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordVitalsScreen(
              ashaController: widget.ashaController,
              patientId: widget.patient.patientId,
              patientName: widget.patient.patientName,
              visitId: visit.id,
            ),
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, visit);
      } else {
        Navigator.pop(context, visit);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.ashaController.errorMessage ?? 'Failed to record home visit.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Home Visit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient Summary
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          child: const Icon(Icons.home, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patient.patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (widget.patient.healthRecordNumber != null)
                                Text(
                                  'Record #: ${widget.patient.healthRecordNumber}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              if (widget.patient.hasActivePregnancy)
                                const Text(
                                  'Status: Active Pregnancy',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Visit Date Picker
                Text(
                  'Visit Date',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF0284C7)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    child: Text(
                      _formatDateShort(_selectedDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Purpose
                Text(
                  'Visit Purpose *',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('visit_purpose_field'),
                  controller: _purposeController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Routine Prenatal Home Checkup',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Visit purpose is required' : null,
                ),
                const SizedBox(height: 16),

                // Observations
                Text(
                  'Clinical & Household Observations',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('visit_observations_field'),
                  controller: _observationsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Mother is taking iron supplements. Diet and hydration discussed.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // General Notes
                Text(
                  'General Field Notes (Optional)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('visit_notes_field'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Next visit planned before hospital checkup.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Follow-up Required Switch
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: SwitchListTile(
                    title: const Text('Follow-up Checkup Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Flag for mandatory subsequent field review', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _followUpRequired,
                    activeThumbColor: const Color(0xFF0284C7),
                    onChanged: (val) => setState(() => _followUpRequired = val),
                  ),
                ),

                if (_followUpRequired) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('visit_follow_up_notes_field'),
                    controller: _followUpNotesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up Instructions / Notes',
                      hintText: 'e.g., Re-check blood pressure in 2 weeks.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  key: const Key('submit_home_visit_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSubmitting ? 'Recording Visit...' : 'Complete & Save Home Visit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSubmitting ? null : _submitVisit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
