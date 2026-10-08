import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/maatra_theme.dart';

class ContractionRecord {
  final DateTime startTime;
  final Duration duration;
  final Duration? intervalFromPrevious;

  const ContractionRecord({
    required this.startTime,
    required this.duration,
    this.intervalFromPrevious,
  });

  String get durationDisplay => '${duration.inSeconds} sec';
  String get intervalDisplay =>
      intervalFromPrevious != null ? '${(intervalFromPrevious!.inSeconds / 60).toStringAsFixed(1)} min' : 'First';
}

class ContractionTimerScreen extends StatefulWidget {
  final String? ashaPhoneNumber;

  const ContractionTimerScreen({super.key, this.ashaPhoneNumber});

  @override
  State<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends State<ContractionTimerScreen> {
  final List<ContractionRecord> _records = [];
  bool _isContracting = false;
  DateTime? _contractionStartTime;
  DateTime? _lastContractionEndTime;

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startContraction() {
    HapticFeedback.heavyImpact();
    final now = DateTime.now();
    _contractionStartTime = now;
    _secondsElapsed = 0;
    _isContracting = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });
    });
    setState(() {});
  }

  void _stopContraction() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    final now = DateTime.now();
    final duration = now.difference(_contractionStartTime ?? now);

    Duration? interval;
    if (_lastContractionEndTime != null) {
      interval = (_contractionStartTime ?? now).difference(_lastContractionEndTime!);
    }

    setState(() {
      _records.insert(
        0,
        ContractionRecord(
          startTime: _contractionStartTime ?? now,
          duration: duration,
          intervalFromPrevious: interval,
        ),
      );
      _isContracting = false;
      _lastContractionEndTime = now;
      _secondsElapsed = 0;
    });
  }

  bool get _isActiveLaborDetected {
    if (_records.length < 3) return false;
    final recent = _records.take(3).toList();
    final allLongEnough = recent.every((r) => r.duration.inSeconds >= 45);
    final allCloseTogether = recent.skip(1).every((r) => r.intervalFromPrevious != null && r.intervalFromPrevious!.inMinutes <= 5);
    return allLongEnough && allCloseTogether;
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  String _formatTimer(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(DateTime dt) {
    final int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
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
          'Labor Contraction Timer',
          style: TextStyle(
            color: MaatraTheme.textCharcoal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MaatraTheme.textMuted),
            tooltip: 'Clear Log',
            onPressed: () {
              setState(() {
                _records.clear();
                _isContracting = false;
                _secondsElapsed = 0;
                _timer?.cancel();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          children: [
            // Clinical 5-1-1 Guide
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MaatraTheme.brandSageWash,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 20, color: MaatraTheme.brandEmerald),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '5-1-1 Clinical Benchmark: When contractions are 5 minutes apart, lasting 1 minute (60s), for 1 full hour, active labor has begun. Head to the hospital.',
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

            // Active Labor Alert Banner
            if (_isActiveLaborDetected)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC53030), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Color(0xFFC53030), size: 26),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Active Labor Pattern Detected!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC53030),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contractions are 5 minutes or less apart and lasting over 45 seconds. Contact your hospital or ASHA worker immediately.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF7A1C1C)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC53030),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.phone_in_talk, size: 18),
                            label: const Text('Dial 108 Ambulance'),
                            onPressed: () => _makeCall('108'),
                          ),
                        ),
                        if (widget.ashaPhoneNumber != null && widget.ashaPhoneNumber!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFC53030),
                                side: const BorderSide(color: Color(0xFFC53030)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.volunteer_activism, size: 18),
                              label: const Text('Call ASHA'),
                              onPressed: () => _makeCall(widget.ashaPhoneNumber!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

            // Large Start / Stop Contraction Button
            GestureDetector(
              onTap: _isContracting ? _stopContraction : _startContraction,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isContracting ? const Color(0xFFFDE8E8) : MaatraTheme.surfacePorcelain,
                  border: Border.all(
                    color: _isContracting ? const Color(0xFFC53030) : MaatraTheme.brandEmerald,
                    width: 6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isContracting ? const Color(0xFFC53030) : MaatraTheme.brandEmerald)
                          .withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isContracting ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                      size: 38,
                      color: _isContracting ? const Color(0xFFC53030) : MaatraTheme.brandEmerald,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimer(_secondsElapsed),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: _isContracting ? const Color(0xFFC53030) : MaatraTheme.textCharcoal,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isContracting ? const Color(0xFFC53030) : MaatraTheme.brandEmerald,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isContracting ? 'TAP TO STOP' : 'TAP ON START',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Contraction History Table
            if (_records.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contraction History',
                  style: TextStyle(
                    fontSize: 16,
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
                  itemCount: _records.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: MaatraTheme.borderHairline),
                  itemBuilder: (context, index) {
                    final item = _records[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: MaatraTheme.brandSageWash,
                                child: Text(
                                  '${_records.length - index}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: MaatraTheme.brandEmerald,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTimeOnly(item.startTime),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: MaatraTheme.textCharcoal,
                                    ),
                                  ),
                                  Text(
                                    'Duration: ${item.durationDisplay}',
                                    style: const TextStyle(fontSize: 12, color: MaatraTheme.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MaatraTheme.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Gap: ${item.intervalDisplay}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MaatraTheme.textCharcoal,
                              ),
                            ),
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
