import 'package:flutter/material.dart';
import '../controllers/asha_controller.dart';
import '../../data/models/asha_models.dart';
import 'record_home_visit_screen.dart';
import 'record_vitals_screen.dart';

class AshaPatientDetailScreen extends StatefulWidget {
  final AshaController ashaController;
  final AshaAssignmentModel patient;

  const AshaPatientDetailScreen({
    super.key,
    required this.ashaController,
    required this.patient,
  });

  @override
  State<AshaPatientDetailScreen> createState() => _AshaPatientDetailScreenState();
}

class _AshaPatientDetailScreenState extends State<AshaPatientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.ashaController.loadPatientFullDetail(widget.patient.patientId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.patientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.ashaController.loadPatientFullDetail(widget.patient.patientId),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            key: const Key('record_home_visit_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.home_work),
            label: const Text('Record Field Home Visit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordHomeVisitScreen(
                    ashaController: widget.ashaController,
                    patient: widget.patient,
                  ),
                ),
              );
              widget.ashaController.loadPatientFullDetail(widget.patient.patientId);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.ashaController,
          builder: (context, _) {
            final isLoading = widget.ashaController.isLoading;
            final visits = widget.ashaController.patientVisits;
            final vitals = widget.ashaController.patientVitals;
            final patientDetail = widget.ashaController.selectedPatient ?? widget.patient;

            if (isLoading && visits.isEmpty && vitals.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Patient Summary Header Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF14B8A6),
                                child: Text(
                                  patientDetail.patientName.isNotEmpty ? patientDetail.patientName[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientDetail.patientName,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (patientDetail.patientPhone != null)
                                      Text(patientDetail.patientPhone!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Record #: ${patientDetail.healthRecordNumber ?? "HR-PENDING"}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (patientDetail.hasActivePregnancy)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF14B8A6)),
                                  ),
                                  child: Text(
                                    'Pregnancy #${patientDetail.pregnancyNumber ?? 1}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('HOME VISITS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${visits.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('VITALS RECORDED', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${vitals.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('ASSIGNMENT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    patientDetail.status,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: patientDetail.status == 'ACTIVE' ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tabs Header
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0284C7),
                  labelColor: const Color(0xFF0284C7),
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Home Visits (${visits.length})'),
                    Tab(text: 'Maternal Vitals (${vitals.length})'),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Home Visits Tab
                      RefreshIndicator(
                        onRefresh: () => widget.ashaController.loadPatientFullDetail(widget.patient.patientId),
                        child: visits.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 48),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.home_work_outlined, size: 48, color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text('No home visits recorded yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text('Tap "Record Field Home Visit" below to create the first visit.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: visits.length,
                                itemBuilder: (context, index) {
                                  final v = visits[index];
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.event, size: 16, color: Color(0xFF0284C7)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatDateShort(v.visitDate),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  v.status,
                                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 14),
                                          Text(
                                            'Purpose: ${v.purpose}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          if (v.observations != null && v.observations!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Observations: ${v.observations}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                          if (v.followUpRequired) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Follow-up: ${v.followUpNotes ?? "Required"}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                icon: const Icon(Icons.favorite, size: 14),
                                                label: const Text('Record Vitals for Visit', style: TextStyle(fontSize: 12)),
                                                onPressed: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => RecordVitalsScreen(
                                                        ashaController: widget.ashaController,
                                                        patientId: widget.patient.patientId,
                                                        patientName: widget.patient.patientName,
                                                        visitId: v.id,
                                                      ),
                                                    ),
                                                  );
                                                  widget.ashaController.loadPatientFullDetail(widget.patient.patientId);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // 2. Maternal Vitals Tab
                      RefreshIndicator(
                        onRefresh: () => widget.ashaController.loadPatientFullDetail(widget.patient.patientId),
                        child: vitals.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 48),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text('No maternal vitals recorded yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text('Record a home visit to log blood pressure and maternal observations.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: vitals.length,
                                itemBuilder: (context, index) {
                                  final vit = vitals[index];
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.favorite, size: 16, color: Color(0xFF14B8A6)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatDateShort(vit.recordedAt),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                                  const Text('BLOOD PRESSURE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    vit.bpDisplay,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('WEIGHT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    vit.weightDisplay,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('TEMP', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    vit.temperatureDisplay,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (vit.notes != null && vit.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Notes: ${vit.notes}',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
