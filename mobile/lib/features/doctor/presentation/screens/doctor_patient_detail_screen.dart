import 'package:flutter/material.dart';
import '../../../asha/data/datasources/asha_remote_data_source.dart';
import '../../../asha/data/models/asha_models.dart';
import '../../data/models/doctor_models.dart';
import '../controllers/doctor_controller.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final DoctorPatientModel patient;
  final DoctorController doctorController;

  const DoctorPatientDetailScreen({
    super.key,
    required this.patient,
    required this.doctorController,
  });

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AshaRemoteDataSource _ashaDataSource = AshaRemoteDataSource();

  bool _isLoading = true;
  List<HomeVisitModel> _visits = [];
  List<MaternalVitalRecordModel> _vitals = [];
  String? _errorMessage;

  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color accentCyan = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClinicalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final visitsFuture = _ashaDataSource.getAuthorizedPatientHomeVisits(widget.patient.patientId);
      final vitalsFuture = _ashaDataSource.getAuthorizedPatientVitals(widget.patient.patientId);

      final results = await Future.wait([visitsFuture, vitalsFuture]);
      if (mounted) {
        setState(() {
          _visits = results[0] as List<HomeVisitModel>;
          _vitals = results[1] as List<MaternalVitalRecordModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showAssignAshaDialog() {
    final ashas = widget.doctorController.availableAshas;
    String? selectedAshaId = widget.patient.assignedAshaId ?? (ashas.isNotEmpty ? ashas.first.ashaId : null);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Clinical ASHA Allocation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${widget.patient.fullName}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    if (widget.patient.villageLocality != null)
                      Text('Locality: ${widget.patient.villageLocality}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (ashas.isEmpty) ...[
                      const Text(
                        'No active ASHA workers available in this sector.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ] else ...[
                      const Text('Select ASHA Field Worker *',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                        labelText: 'Doctor Allocation Notes / Care Plan',
                        hintText: 'e.g. High-risk weekly checkups, vitals monitoring...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selectedAshaId == null
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await widget.doctorController.assignAshaToPatient(
                            patientId: widget.patient.patientId,
                            ashaWorkerId: selectedAshaId!,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                          if (success && mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green[800],
                                content: Text(
                                    'ASHA worker assigned successfully for ${widget.patient.fullName}!'),
                              ),
                            );
                            widget.doctorController.loadDoctorData();
                            _loadClinicalData();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Assignment'),
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
    final p = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Clinical Data',
            onPressed: _loadClinicalData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentCyan,
          tabs: [
            Tab(
              icon: const Icon(Icons.home_work_outlined, size: 20),
              text: 'Home Visits (${_visits.length})',
            ),
            Tab(
              icon: const Icon(Icons.monitor_heart_outlined, size: 20),
              text: 'Maternal Vitals (${_vitals.length})',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Patient Header Card
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryTeal.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: accentCyan, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              p.email,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                            style: TextStyle(
                                color: Colors.pink[200], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (p.bloodGroup != null)
                        _buildBadge('Blood Group: ${p.bloodGroup}', Colors.redAccent),
                      if (p.villageLocality != null)
                        _buildBadge('Village: ${p.villageLocality}', Colors.teal),
                      if (p.activePregnancyEdd != null)
                        _buildBadge('EDD: ${p.activePregnancyEdd}', Colors.pinkAccent),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_ind,
                              size: 16,
                              color: p.assignedAshaName != null
                                  ? Colors.green[400]
                                  : Colors.amber[400]),
                          const SizedBox(width: 6),
                          Text(
                            p.assignedAshaName != null
                                ? 'ASHA: ${p.assignedAshaName}'
                                : 'No ASHA Assigned',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.assignedAshaName != null
                                  ? Colors.green[300]
                                  : Colors.amber[300],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAssignAshaDialog,
                        icon: Icon(p.assignedAshaName != null ? Icons.swap_horiz : Icons.person_add,
                            size: 14),
                        label: Text(p.assignedAshaName != null ? 'Reassign ASHA' : 'Assign ASHA',
                            style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              p.assignedAshaName != null ? const Color(0xFF334155) : primaryTeal,
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

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.orangeAccent),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _loadClinicalData,
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Home Visits Timeline
                            _buildVisitsTab(),

                            // Tab 2: Vitals History Table
                            _buildVitalsTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildVisitsTab() {
    if (_visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.home_work_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No home visits recorded by ASHA yet.\nWhen the assigned ASHA conducts field visits, entries will appear here in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClinicalData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _visits.length,
        itemBuilder: (context, index) {
          final v = _visits[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Color(0xFF14B8A6)),
                          const SizedBox(width: 6),
                          Text(_formatDateShort(v.visitDate),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (v.status == 'COMPLETED' ? Colors.green : Colors.blue)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: v.status == 'COMPLETED' ? Colors.greenAccent : Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Purpose: ${v.purpose}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                  if (v.observations != null && v.observations!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Observations: ${v.observations}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  if (v.notes != null && v.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Notes: ${v.notes}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  if (v.followUpRequired) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Follow-up Required: ${v.followUpNotes ?? 'Clinical follow-up flagged'}',
                          style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVitalsTab() {
    if (_vitals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No maternal vitals recorded yet.\nField vital sign records (BP, Weight, Temp) submitted by the ASHA worker will be logged here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClinicalData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _vitals.length,
        itemBuilder: (context, index) {
          final vit = _vitals[index];
          final hasBp = vit.systolicBp != null && vit.diastolicBp != null;
          final isBpHigh = hasBp && (vit.systolicBp! >= 140 || vit.diastolicBp! >= 90);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recorded: ${_formatDateShort(vit.recordedAt)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      if (isBpHigh)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('HIGH BP ALERT',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (hasBp)
                        _buildVitalStat(
                          'Blood Pressure',
                          '${vit.systolicBp}/${vit.diastolicBp} mmHg',
                          isBpHigh ? Colors.redAccent : Colors.cyanAccent,
                        ),
                      if (vit.weightKg != null)
                        _buildVitalStat(
                          'Weight',
                          '${vit.weightKg} kg',
                          Colors.amberAccent,
                        ),
                      if (vit.temperatureC != null)
                        _buildVitalStat(
                          'Temperature',
                          '${vit.temperatureC} °C',
                          Colors.greenAccent,
                        ),
                    ],
                  ),
                  if (vit.notes != null && vit.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Clinical Note: ${vit.notes}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVitalStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
