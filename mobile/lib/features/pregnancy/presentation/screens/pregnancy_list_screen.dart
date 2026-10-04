import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/controllers/pregnancy_controller.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/add_pregnancy_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/presentation/screens/pregnancy_detail_screen.dart';

class PregnancyListScreen extends StatefulWidget {
  final PregnancyController controller;

  const PregnancyListScreen({
    super.key,
    required this.controller,
  });

  @override
  State<PregnancyListScreen> createState() => _PregnancyListScreenState();
}

class _PregnancyListScreenState extends State<PregnancyListScreen> {
  static const Color primaryTeal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fetchMyPregnancies();
    });
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.controller.fetchMyPregnancies(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Pregnancy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await Navigator.push<PregnancyModel>(
            context,
            MaterialPageRoute(
              builder: (context) => AddPregnancyScreen(controller: widget.controller),
            ),
          );
          if (created != null && mounted) {
            widget.controller.fetchMyPregnancies();
          }
        },
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.errorMessage != null && widget.controller.pregnancies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      widget.controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => widget.controller.fetchMyPregnancies(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final list = widget.controller.pregnancies;

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryTeal.withValues(alpha: 0.15),
                      child: const Icon(Icons.pregnant_woman, size: 40, color: primaryTeal),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Pregnancy Records Found',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You haven\'t added any maternal pregnancy records yet. Tap below to register a new pregnancy.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Register Pregnancy', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddPregnancyScreen(controller: widget.controller),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = list[index];
              final statusColor = _getStatusColor(p.status);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: p.isActive ? primaryTeal : Colors.grey[800]!),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PregnancyDetailScreen(
                          pregnancy: p,
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pregnancy #${p.pregnancyNumber}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                p.status,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('LMP', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                  Text(
                                    _formatDateShort(p.lmp),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('EDD', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                  Text(
                                    _formatDateShort(p.edd),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF14B8A6)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Gestation', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                  Text(
                                    p.gestationalAgeDisplay,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
