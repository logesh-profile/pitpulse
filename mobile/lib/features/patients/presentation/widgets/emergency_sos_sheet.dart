import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../screens/nearby_facilities_screen.dart';

class EmergencySosSheet extends StatelessWidget {
  final String? ashaWorkerName;
  final String? ashaWorkerPhone;

  const EmergencySosSheet({
    super.key,
    this.ashaWorkerName,
    this.ashaWorkerPhone,
  });

  static void show(BuildContext context, {String? ashaName, String? ashaPhone}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencySosSheet(
        ashaWorkerName: ashaName,
        ashaWorkerPhone: ashaPhone,
      ),
    );
  }

  Future<void> _makeCall(BuildContext context, String number) async {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    final Uri uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot launch cellular call to $number')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dial directly on keypad: $number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MaatraTheme.surfacePorcelain,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MaatraTheme.borderHairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency, color: Color(0xFFC53030), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency SOS (Offline)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: MaatraTheme.textCharcoal,
                      ),
                    ),
                    Text(
                      'Direct cellular telephony (No data required)',
                      style: TextStyle(fontSize: 12, color: MaatraTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Emergency Call Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC53030),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 20),
                  label: const Text(
                    'Dial 108\nAmbulance',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  onPressed: () => _makeCall(context, '108'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaatraTheme.brandEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.volunteer_activism, size: 20),
                  label: Text(
                    'Call ASHA\n${ashaWorkerName ?? "Health Worker"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  onPressed: () {
                    final phone = ashaWorkerPhone ?? '108';
                    _makeCall(context, phone);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Radar Link Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: MaatraTheme.brandEmerald,
              side: const BorderSide(color: MaatraTheme.brandEmerald),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.radar, size: 18),
            label: const Text(
              'Open Nearby Emergency Hospital Radar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyFacilitiesScreen()),
              );
            },
          ),

          const SizedBox(height: 20),

          // Offline First Aid Guidelines Accordion
          const Text(
            'Immediate Offline First-Aid Steps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: MaatraTheme.textCharcoal,
            ),
          ),
          const SizedBox(height: 8),

          _buildFirstAidTile(
            title: 'Severe Bleeding',
            steps: 'Lie completely flat, elevate feet by 30 cm using pillows. Keep patient warm with a blanket. Do not allow walking.',
            color: const Color(0xFFC53030),
          ),
          _buildFirstAidTile(
            title: 'Fits / Convulsions (Eclampsia)',
            steps: 'Turn patient on her left side immediately to maintain airway. Do not put fingers, cloth, or metal in mouth. Move sharp objects away.',
            color: const Color(0xFFB46A10),
          ),
          _buildFirstAidTile(
            title: 'Water Bag Leakage (Amniotic Rupture)',
            steps: 'Note the exact time and color of fluid (clear, green, or blood-tinged). Remain lying down. Start travel to PHC/GH immediately.',
            color: MaatraTheme.brandEmerald,
          ),
        ],
      ),
    );
  }

  Widget _buildFirstAidTile({
    required String title,
    required String steps,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MaatraTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MaatraTheme.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            steps,
            style: const TextStyle(fontSize: 11, color: MaatraTheme.textCharcoal, height: 1.3),
          ),
        ],
      ),
    );
  }
}
