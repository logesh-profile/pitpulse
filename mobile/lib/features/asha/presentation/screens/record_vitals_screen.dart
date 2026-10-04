import 'package:flutter/material.dart';
import '../controllers/asha_controller.dart';

class RecordVitalsScreen extends StatefulWidget {
  final AshaController ashaController;
  final String patientId;
  final String patientName;
  final String visitId;

  const RecordVitalsScreen({
    super.key,
    required this.ashaController,
    required this.patientId,
    required this.patientName,
    required this.visitId,
  });

  @override
  State<RecordVitalsScreen> createState() => _RecordVitalsScreenState();
}

class _RecordVitalsScreenState extends State<RecordVitalsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _weightController = TextEditingController();
  final _tempController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _weightController.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitVitals() async {
    if (!_formKey.currentState!.validate()) return;

    final systolic = _systolicController.text.trim().isNotEmpty
        ? int.tryParse(_systolicController.text.trim())
        : null;
    final diastolic = _diastolicController.text.trim().isNotEmpty
        ? int.tryParse(_diastolicController.text.trim())
        : null;
    final weight = _weightController.text.trim().isNotEmpty
        ? double.tryParse(_weightController.text.trim())
        : null;
    final temp = _tempController.text.trim().isNotEmpty
        ? double.tryParse(_tempController.text.trim())
        : null;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    if (systolic == null && diastolic == null && weight == null && temp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one clinical vital observation.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final vital = await widget.ashaController.recordMaternalVitals(
      patientId: widget.patientId,
      visitId: widget.visitId,
      systolicBp: systolic,
      diastolicBp: diastolic,
      weightKg: weight,
      temperatureC: temp,
      notes: notes,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (vital != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maternal vitals recorded and persisted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, vital);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.ashaController.errorMessage ?? 'Failed to record vitals.'),
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
        title: const Text('Record Maternal Vitals'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info Card
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
                          child: const Icon(Icons.favorite, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient: ${widget.patientName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Field Visit Maternal Telemetry Observation',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Blood Pressure Card
                Text(
                  'Blood Pressure (mmHg)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('vitals_systolic_field'),
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Systolic',
                          hintText: 'e.g. 120',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          final n = int.tryParse(val.trim());
                          if (n == null) return 'Integer only';
                          if (n < 40 || n > 300) return '40-300 mmHg';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('vitals_diastolic_field'),
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic',
                          hintText: 'e.g. 80',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          final n = int.tryParse(val.trim());
                          if (n == null) return 'Integer only';
                          if (n < 20 || n > 200) return '20-200 mmHg';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weight & Temperature
                Text(
                  'Anthropometric & Thermal Observations',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('vitals_weight_field'),
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          hintText: 'e.g. 62.5',
                          suffixText: 'kg',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          final n = double.tryParse(val.trim());
                          if (n == null) return 'Valid number';
                          if (n < 20.0 || n > 300.0) return '20-300 kg';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('vitals_temp_field'),
                        controller: _tempController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Body Temp',
                          hintText: 'e.g. 36.8',
                          suffixText: '°C',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          final n = double.tryParse(val.trim());
                          if (n == null) return 'Valid number';
                          if (n < 30.0 || n > 45.0) return '30-45 °C';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes Field
                Text(
                  'Measurement Notes (Optional)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('vitals_notes_field'),
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Resting seated measurement taken after 5 mins rest.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  key: const Key('submit_vitals_button'),
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
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting ? 'Saving to Database...' : 'Save Maternal Vitals',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSubmitting ? null : _submitVitals,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
