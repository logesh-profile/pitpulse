import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/maatra_theme.dart';
import 'nearby_facilities_screen.dart';
import 'fetal_kick_counter_screen.dart';
import 'contraction_timer_screen.dart';

class OfflineEmergencyHubScreen extends StatelessWidget {
  const OfflineEmergencyHubScreen({super.key});

  Future<void> _callAmbulance() async {
    final uri = Uri(scheme: 'tel', path: '108');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatraTheme.bgIvory,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MaatraTheme.textCharcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Offline Emergency Care Hub',
          style: TextStyle(
            color: MaatraTheme.textCharcoal,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zero Login Badge Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC53030).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: Color(0xFFC53030), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero Login Required • 100% Offline',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC53030),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'All tools below operate through phone GPS and cellular voice without mobile data or internet account.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF7A1C1C), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Giant Red Dial 108 Button
            ElevatedButton(
              onPressed: _callAmbulance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC53030),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_in_talk_rounded, size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIAL 108 AMBULANCE',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      Text(
                        'National Emergency Medical Service',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Offline Clinical & Navigation Tools',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: MaatraTheme.textCharcoal,
              ),
            ),
            const SizedBox(height: 12),

            // Tool 1: Nearby Medical Radar
            _buildToolCard(
              context: context,
              icon: Icons.radar_rounded,
              iconColor: MaatraTheme.brandEmerald,
              iconBg: MaatraTheme.brandSageWash,
              title: 'Nearby Medical Radar (GPS)',
              subtitle: 'Locate closest PHCs, GHs, Clinics, 24x7 Delivery Units & Medical Shops via satellite GPS.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyFacilitiesScreen()),
                );
              },
            ),

            const SizedBox(height: 10),

            // Tool 2: Daily Fetal Kick Counter
            _buildToolCard(
              context: context,
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFB46A10),
              iconBg: const Color(0xFFFEF5E7),
              title: 'Daily Fetal Kick Counter (DFMC)',
              subtitle: 'Track 10 baby movements within 2 hours. Medical benchmark for third-trimester safety.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FetalKickCounterScreen()),
                );
              },
            ),

            const SizedBox(height: 10),

            // Tool 3: Contraction Timer (5-1-1 Rule)
            _buildToolCard(
              context: context,
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFE0F2FE),
              title: 'Labor Contraction Timer',
              subtitle: 'Track contraction frequency and duration. Clinical 5-1-1 active labor warning system.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContractionTimerScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // Offline First Aid Guidelines Accordion
            const Text(
              'Emergency Offline First-Aid Steps',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: MaatraTheme.textCharcoal,
              ),
            ),
            const SizedBox(height: 10),

            _buildGuidelineCard(
              title: 'Severe Vaginal Bleeding',
              steps: 'Lie completely flat immediately. Elevate feet 30 cm using pillows. Keep patient warm with blankets. Do not allow walking or standing.',
              color: const Color(0xFFC53030),
            ),
            _buildGuidelineCard(
              title: 'Eclampsia / Fits / Convulsions',
              steps: 'Turn patient on her left side immediately to maintain airway. Do not insert fingers, cloth, or metal spoons into mouth. Move sharp objects away.',
              color: const Color(0xFFB46A10),
            ),
            _buildGuidelineCard(
              title: 'Premature Water Breaking (Amniotic Rupture)',
              steps: 'Note exact time and color of fluid (clear vs greenish/brown). Stay lying down. Do not insert tampons. Proceed directly to the nearest PHC or GH.',
              color: MaatraTheme.brandEmerald,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaatraTheme.surfacePorcelain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaatraTheme.borderHairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: MaatraTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: MaatraTheme.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: MaatraTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineCard({
    required String title,
    required String steps,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MaatraTheme.surfacePorcelain,
        borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            steps,
            style: const TextStyle(fontSize: 12, color: MaatraTheme.textCharcoal, height: 1.3),
          ),
        ],
      ),
    );
  }
}
