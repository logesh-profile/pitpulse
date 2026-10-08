import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/maatra_theme.dart';

class FetalKickCounterScreen extends StatefulWidget {
  final String? ashaPhoneNumber;

  const FetalKickCounterScreen({super.key, this.ashaPhoneNumber});

  @override
  State<FetalKickCounterScreen> createState() => _FetalKickCounterScreenState();
}

class _FetalKickCounterScreenState extends State<FetalKickCounterScreen> {
  static const int _targetKicks = 10;
  static const int _sessionSecondsMax = 7200; // 2 hours

  int _kickCount = 0;
  final List<DateTime> _kickTimestamps = [];

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isSessionActive = false;
  bool _isSessionCompleted = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _isSessionActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed >= _sessionSecondsMax) {
          _timer?.cancel();
          _isSessionActive = false;
        }
      });
    });
  }

  void _recordKick() {
    HapticFeedback.mediumImpact();

    if (!_isSessionActive && !_isSessionCompleted) {
      _startTimer();
    }

    if (_kickCount < _targetKicks) {
      final now = DateTime.now();
      setState(() {
        _kickCount++;
        _kickTimestamps.add(now);

        if (_kickCount >= _targetKicks) {
          _timer?.cancel();
          _isSessionActive = false;
          _isSessionCompleted = true;
        }
      });
    }
  }

  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _kickCount = 0;
      _kickTimestamps.clear();
      _secondsElapsed = 0;
      _isSessionActive = false;
      _isSessionCompleted = false;
    });
  }

  String _formatTimer(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(DateTime dt) {
    final int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _callEmergency(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_kickCount / _targetKicks).clamp(0.0, 1.0);
    final bool isTimeExpired = _secondsElapsed >= _sessionSecondsMax && _kickCount < _targetKicks;

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
          'Fetal Kick Counter (DFMC)',
          style: TextStyle(
            color: MaatraTheme.textCharcoal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MaatraTheme.textMuted),
            tooltip: 'Reset Session',
            onPressed: _resetSession,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          children: [
            // Clinical Benchmark Guide Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MaatraTheme.brandSageWash,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: MaatraTheme.brandEmerald),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Clinical Target: 10 movements within 2 hours. Start counting after a healthy meal or cold glass of water while resting on your left side.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: MaatraTheme.brandEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Timer & Status Inset
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: MaatraTheme.surfacePorcelain,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MaatraTheme.borderHairline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Session Timer', style: TextStyle(fontSize: 11, color: MaatraTheme.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimer(_secondsElapsed),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: MaatraTheme.textCharcoal,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isSessionCompleted
                          ? const Color(0xFFE8F5EF)
                          : (_isSessionActive ? MaatraTheme.brandSageWash : MaatraTheme.surfaceSubtle),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isSessionCompleted
                          ? 'TARGET ACHIEVED'
                          : (_isSessionActive ? 'COUNTING ACTIVE' : 'TAP BELOW TO START'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isSessionCompleted
                            ? const Color(0xFF1B7A58)
                            : (_isSessionActive ? MaatraTheme.brandEmerald : MaatraTheme.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Large Central Tactile Kick Tap Circle
            GestureDetector(
              onTap: _isSessionCompleted ? null : _recordKick,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MaatraTheme.surfacePorcelain,
                  border: Border.all(
                    color: _isSessionCompleted
                        ? const Color(0xFF1B7A58)
                        : MaatraTheme.brandEmerald,
                    width: 6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MaatraTheme.brandEmerald.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 32,
                      color: _isSessionCompleted
                          ? const Color(0xFF1B7A58)
                          : MaatraTheme.brandEmerald,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_kickCount',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: _isSessionCompleted
                            ? const Color(0xFF1B7A58)
                            : MaatraTheme.textCharcoal,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'of $_targetKicks Kicks',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MaatraTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isSessionCompleted
                            ? const Color(0xFFE8F5EF)
                            : MaatraTheme.brandSageWash,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isSessionCompleted ? 'Completed' : 'Tap on Each Kick',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isSessionCompleted
                              ? const Color(0xFF1B7A58)
                              : MaatraTheme.brandEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: MaatraTheme.borderHairline,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isSessionCompleted ? const Color(0xFF1B7A58) : MaatraTheme.brandEmerald,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Clinical Conclusion / Alert Banners
            if (_isSessionCompleted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1B7A58).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF1B7A58), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Normal Fetal Activity',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B7A58),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '10 movements recorded in ${_formatTimer(_secondsElapsed)}. Baby activity is reassuring and healthy.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1B7A58)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (isTimeExpired)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC53030).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFC53030), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Reduced Movement Warning',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC53030),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fewer than 10 kicks logged within 2 hours. Drink a glass of cold milk or water, lie comfortably on your left side, and recount for 1 hour.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFC53030)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.ashaPhoneNumber != null && widget.ashaPhoneNumber!.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC53030),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call ASHA Worker'),
                              onPressed: () => _callEmergency(widget.ashaPhoneNumber!),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC53030),
                              side: const BorderSide(color: Color(0xFFC53030)),
                            ),
                            icon: const Icon(Icons.phone_in_talk, size: 16),
                            label: const Text('Dial 108'),
                            onPressed: () => _callEmergency('108'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Kick Timestamp Timeline List
            if (_kickTimestamps.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Movement Timeline',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: MaatraTheme.textCharcoal,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: MaatraTheme.surfacePorcelain,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MaatraTheme.borderHairline),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _kickTimestamps.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: MaatraTheme.borderHairline),
                  itemBuilder: (context, index) {
                    final kickIndex = index + 1;
                    final time = _kickTimestamps[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: MaatraTheme.brandSageWash,
                                child: Text(
                                  '$kickIndex',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: MaatraTheme.brandEmerald,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Kick #$kickIndex Logged',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: MaatraTheme.textCharcoal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatTimeOnly(time),
                            style: const TextStyle(fontSize: 12, color: MaatraTheme.textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
