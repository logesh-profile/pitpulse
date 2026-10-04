import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/controllers/pregnancy_controller.dart';

class AddPregnancyScreen extends StatefulWidget {
  final PregnancyController controller;

  const AddPregnancyScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AddPregnancyScreen> createState() => _AddPregnancyScreenState();
}

class _AddPregnancyScreenState extends State<AddPregnancyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pregnancyNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedLmp;
  DateTime? _previewEdd;
  String? _localError;

  static const Color primaryTeal = Color(0xFF0D9488);

  @override
  void dispose() {
    _pregnancyNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateLong(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  void _onDatePicked(DateTime date) {
    setState(() {
      _selectedLmp = date;
      _previewEdd = date.add(const Duration(days: 280));
      _localError = null;
    });
  }

  Future<void> _pickLmpDate() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 300));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedLmp ?? now.subtract(const Duration(days: 30)),
      firstDate: firstDate,
      lastDate: now,
      helpText: 'Select Last Menstrual Period (LMP)',
    );

    if (picked != null) {
      _onDatePicked(picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedLmp == null) {
      setState(() => _localError = 'Please select your Last Menstrual Period (LMP) date.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    int? pNum;
    if (_pregnancyNumberController.text.trim().isNotEmpty) {
      pNum = int.tryParse(_pregnancyNumberController.text.trim());
    }

    final created = await widget.controller.createPregnancy(
      lmp: _selectedLmp!,
      pregnancyNumber: pNum,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[800],
          content: Text('Pregnancy #${created.pregnancyNumber} record registered successfully!'),
        ),
      );
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorToShow = _localError ?? widget.controller.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Pregnancy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryTeal,
                        child: Icon(Icons.pregnant_woman, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maternal Record Setup',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enter your LMP date. EDD, gestational age, and trimester will be calculated automatically.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (errorToShow != null && errorToShow.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Text(
                      errorToShow,
                      style: TextStyle(color: Colors.red[200], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // LMP Date Selector
                Text('Last Menstrual Period (LMP) *', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  key: const Key('pick_lmp_button'),
                  onTap: _pickLmpDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black26,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: primaryTeal),
                        const SizedBox(width: 12),
                        Text(
                          _selectedLmp != null
                              ? _formatDateLong(_selectedLmp!)
                              : 'Select LMP Date (Required)',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedLmp != null ? Colors.white : Colors.grey[400],
                            fontWeight: _selectedLmp != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Calculated EDD Preview
                if (_previewEdd != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF14B8A6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available, color: Color(0xFF14B8A6), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Calculated Estimated Due Date (EDD):', style: TextStyle(fontSize: 12, color: Color(0xFF14B8A6))),
                              Text(
                                _formatDateLong(_previewEdd!),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pregnancy Number (Optional)
                TextFormField(
                  key: const Key('pregnancy_number_field'),
                  controller: _pregnancyNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pregnancy Number (Optional, e.g. 1, 2)',
                    hintText: 'Leave empty to auto-assign next number',
                    prefixIcon: Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final n = int.tryParse(val);
                      if (n == null || n < 1) return 'Must be a positive integer (>= 1)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  key: const Key('pregnancy_notes_field'),
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Maternal Baseline Notes (Optional)',
                    hintText: 'Conception notes, relevant history, or concerns...',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    return ElevatedButton(
                      key: const Key('submit_pregnancy_button'),
                      onPressed: widget.controller.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: widget.controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Confirm & Register Pregnancy',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
