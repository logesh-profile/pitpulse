import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/controllers/pregnancy_controller.dart';

class PregnancyDetailScreen extends StatefulWidget {
  final PregnancyModel pregnancy;
  final PregnancyController controller;

  const PregnancyDetailScreen({
    super.key,
    required this.pregnancy,
    required this.controller,
  });

  @override
  State<PregnancyDetailScreen> createState() => _PregnancyDetailScreenState();
}

class _PregnancyDetailScreenState extends State<PregnancyDetailScreen> {
  late PregnancyModel _pregnancy;
  static const Color primaryTeal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _pregnancy = widget.pregnancy;
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateLong(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF14B8A6);
      case 'COMPLETED':
        return Colors.green;
      case 'TERMINATED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showStatusDialog() async {
    String selectedStatus = _pregnancy.status;
    final notesCtrl = TextEditingController(text: _pregnancy.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Update Pregnancy #${_pregnancy.pregnancyNumber}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Pregnancy Status', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                      DropdownMenuItem(value: 'TERMINATED', child: Text('TERMINATED')),
                      DropdownMenuItem(value: 'UNKNOWN', child: Text('UNKNOWN')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedStatus = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save Update')),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final success = await widget.controller.updatePregnancyStatus(
        pregnancyId: _pregnancy.id,
        status: selectedStatus,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      if (success && widget.controller.selectedPregnancy != null) {
        setState(() {
          _pregnancy = widget.controller.selectedPregnancy!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pregnancy record updated successfully.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(_pregnancy.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pregnancy #${_pregnancy.pregnancyNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Update Status / Notes',
            onPressed: _showStatusDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Maternal Banner
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.4),
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
                        Text(
                          'Pregnancy #${_pregnancy.pregnancyNumber}',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            _pregnancy.status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            context,
                            icon: Icons.timelapse,
                            title: 'Gestational Age',
                            value: _pregnancy.gestationalAgeDisplay,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetric(
                            context,
                            icon: Icons.layers,
                            title: 'Trimester',
                            value: _pregnancy.trimesterDisplay,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clinical Calculation Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maternal Baseline & Dates', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    _buildDataRow(
                      icon: Icons.calendar_today,
                      label: 'Last Menstrual Period (LMP)',
                      value: _formatDateLong(_pregnancy.lmp),
                    ),
                    const SizedBox(height: 10),
                    _buildDataRow(
                      icon: Icons.event_available,
                      label: 'Estimated Due Date (EDD)',
                      value: _formatDateLong(_pregnancy.edd),
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    _buildDataRow(
                      icon: Icons.schedule,
                      label: 'Calculated Gestation',
                      value: '${_pregnancy.gestationalAgeWeeks} Weeks, ${_pregnancy.gestationalAgeDays} Days',
                    ),
                    if (_pregnancy.notes != null && _pregnancy.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDataRow(
                        icon: Icons.notes,
                        label: 'Clinical / Baseline Notes',
                        value: _pregnancy.notes!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pregnancy Timeline Foundation Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timeline, color: primaryTeal),
                        SizedBox(width: 8),
                        Text('Pregnancy Timeline Foundation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTimelineStep(
                      context,
                      isCompleted: true,
                      title: 'Last Menstrual Period (LMP)',
                      date: _formatDateShort(_pregnancy.lmp),
                      subtitle: 'Baseline anchor for pregnancy progression calculation',
                    ),
                    _buildTimelineStep(
                      context,
                      isCompleted: true,
                      title: 'Pregnancy Registered',
                      date: _formatDateShort(_pregnancy.createdAt),
                      subtitle: 'Record created in PitPulse health registry',
                    ),
                    _buildTimelineStep(
                      context,
                      isCompleted: true,
                      title: 'Current Gestational Progress',
                      date: _pregnancy.gestationalAgeDisplay,
                      subtitle: _pregnancy.trimesterDisplay,
                    ),
                    _buildTimelineStep(
                      context,
                      isCompleted: false,
                      isLast: true,
                      title: 'Estimated Due Date (EDD)',
                      date: _formatDateShort(_pregnancy.edd),
                      subtitle: 'Expected 40-week delivery milestone',
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[900]?.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey[700]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Clinical events (ANC visits, maternal vitals, lab reports, doctor consultations, vaccinations) will appear chronologically here as recorded in upcoming modules.',
                              style: TextStyle(fontSize: 12, color: Colors.blue[100]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: highlight ? const Color(0xFF14B8A6) : Colors.grey[400]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? const Color(0xFF14B8A6) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required bool isCompleted,
    required String title,
    required String date,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: isCompleted ? primaryTeal : Colors.grey[700],
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? primaryTeal.withValues(alpha: 0.5) : Colors.grey[800],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(date, style: const TextStyle(fontSize: 12, color: primaryTeal, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
