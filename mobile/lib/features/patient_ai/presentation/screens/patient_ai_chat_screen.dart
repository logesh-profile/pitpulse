import 'package:flutter/material.dart';
import '../../data/local_speech_service.dart';
import '../../data/local_tts_service.dart';
import '../../domain/models/ai_screening_warning.dart';
import '../../domain/models/patient_ai_context.dart';
import '../../domain/models/patient_ai_message.dart';
import '../controllers/patient_ai_controller.dart';

class PatientAiChatScreen extends StatefulWidget {
  final PatientAiController? controller;
  final PatientAiContext? contextSnapshot;

  const PatientAiChatScreen({
    super.key,
    this.controller,
    this.contextSnapshot,
  });

  @override
  State<PatientAiChatScreen> createState() => _PatientAiChatScreenState();
}

class _PatientAiChatScreenState extends State<PatientAiChatScreen> {
  late final PatientAiController _controller;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color accentCyan = Color(0xFF14B8A6);
  static const Color darkCardBg = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientAiController(context: widget.contextSnapshot);
    LocalTtsService().initialize();
  }

  @override
  void dispose() {
    LocalTtsService().stop();
    LocalSpeechService().stopListening();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? textToSend]) {
    final text = textToSend ?? _inputController.text;
    if (text.trim().isEmpty) return;

    _controller.sendUserMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  /// Voice Input Sheet with offline speech capture and instant Tamil/English query chips
  void _showVoiceInputDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isListening = LocalSpeechService().isListening;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.mic_rounded, color: Colors.amberAccent, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Offline Voice Input / குரல் உள்ளீடு',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Speak in Tamil or English (uses native offline speech recognizer). Or tap a sample voice question below:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Mic Pulse Button
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        if (LocalSpeechService().isListening) {
                          await LocalSpeechService().stopListening();
                          setSheetState(() {});
                        } else {
                          await LocalSpeechService().startListening(
                            onResult: (words) {
                              setSheetState(() {});
                              if (words.trim().isNotEmpty) {
                                _inputController.text = words;
                              }
                            },
                          );
                          setSheetState(() {});
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isListening ? Colors.redAccent : primaryTeal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isListening ? Colors.redAccent : primaryTeal).withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      isListening ? '🎙️ Listening... (பேசுங்கள்)' : 'Tap mic to start speaking',
                      style: TextStyle(
                        color: isListening ? Colors.amberAccent : Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_inputController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: darkCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentCyan.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '"${_inputController.text}"',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleSend();
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Recognized Voice Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Quick Maternal Voice Prompts (மாதிரிகள்):',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildVoiceSampleChip(
                        ctx,
                        'Enaku moonu maasam aaguthu, naan enna saapadanum?',
                        '🥗 3rd Month Diet (Tamil)',
                      ),
                      _buildVoiceSampleChip(
                        ctx,
                        'கர்ப்ப கால உணவு முறை என்ன?',
                        '🥦 Pregnancy Diet Guide',
                      ),
                      _buildVoiceSampleChip(
                        ctx,
                        'எனக்கு இரத்தப்போக்கு ஏற்படுகிறது',
                        '🚨 Bleeding Red Flag',
                      ),
                      _buildVoiceSampleChip(
                        ctx,
                        'என் இரத்த அழுத்தம் (BP) இயல்பாக உள்ளதா?',
                        '🩺 BP & Vitals Check',
                      ),
                      _buildVoiceSampleChip(
                        ctx,
                        'டாக்டரிடம் நான் என்ன கேட்க வேண்டும்?',
                        '📋 Doctor Prep',
                      ),
                      _buildVoiceSampleChip(
                        ctx,
                        'What should I eat during the 1st trimester?',
                        '🥗 1st Trimester Diet (English)',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVoiceSampleChip(BuildContext ctx, String query, String label) {
    return ActionChip(
      avatar: const Icon(Icons.record_voice_over_rounded, size: 14, color: Colors.amberAccent),
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: darkCardBg,
      side: BorderSide(color: accentCyan.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        Navigator.pop(ctx);
        _handleSend(query);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: accentCyan, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PitPulse Maternal AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${_controller.context.patientName}${_controller.context.healthRecordNumber != null ? " • ${_controller.context.healthRecordNumber}" : ""}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.offline_bolt, color: Colors.greenAccent, size: 14),
                SizedBox(width: 4),
                Text('ON-DEVICE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 100MB Architecture Badge Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PitPulse v1.0.2 • Stateful Agentic RAG Controller • 100% Offline Multi-Turn',
                      style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final messages = _controller.messages;
                  final isTyping = _controller.isTyping;
                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isTyping) {
                        return _buildTypingIndicator();
                      }
                      final msg = messages[index];
                      return _buildMessageBubble(msg);
                    },
                  );
                },
              ),
            ),

            // Quick Prompt Chips
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final chips = _controller.quickPromptChips;
                return Container(
                  height: 42,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chipText = chips[index];
                      return ActionChip(
                        label: Text(chipText, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        backgroundColor: darkCardBg,
                        side: BorderSide(color: accentCyan.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () => _handleSend(chipText),
                      );
                    },
                  ),
                );
              },
            ),

            // Bottom Input Bar with Voice Mic & Text Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('patient_ai_input_field'),
                      controller: _inputController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Type or speak in Tamil or English...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: darkCardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Voice Mic Button
                  CircleAvatar(
                    backgroundColor: Colors.amber[700],
                    radius: 20,
                    child: IconButton(
                      key: const Key('patient_ai_voice_button'),
                      icon: const Icon(Icons.mic_rounded, size: 20, color: Colors.white),
                      tooltip: 'Voice Input / தமிழில் பேசுங்கள்',
                      onPressed: _showVoiceInputDialog,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send Button
                  CircleAvatar(
                    backgroundColor: primaryTeal,
                    radius: 20,
                    child: IconButton(
                      key: const Key('patient_ai_send_button'),
                      icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PatientAiMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryTeal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(2),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Response Bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: accentCyan.withValues(alpha: 0.2),
                child: const Icon(Icons.auto_awesome, size: 14, color: accentCyan),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: darkCardBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agentic Tools Badge (if routed through tools)
                      if (msg.executedTools.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentCyan.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.hub_rounded, size: 12, color: accentCyan),
                              const SizedBox(width: 4),
                              Text(
                                'Agentic Tools: ${msg.executedTools.join(' → ')}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentCyan),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Formatted Response Text
                      Text(
                        msg.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),

                      // Warning Banner (if present)
                      if (msg.warning != null) ...[
                        const SizedBox(height: 12),
                        _buildWarningCard(msg.warning!),
                      ],

                      // Offline TTS Voice Speaker Button
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: LocalTtsService().isPlayingNotifier,
                        builder: (context, isPlaying, _) {
                          final isThisPlaying = isPlaying && LocalTtsService().currentlySpeakingId == msg.id;

                          return InkWell(
                            onTap: () {
                              LocalTtsService().speak(
                                text: msg.text,
                                messageId: msg.id,
                                isTamil: msg.isTamil,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isThisPlaying ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isThisPlaying ? Colors.amberAccent : const Color(0xFF334155),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isThisPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                    size: 16,
                                    color: isThisPlaying ? Colors.amberAccent : accentCyan,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isThisPlaying
                                        ? (msg.isTamil ? 'நிறுத்து (Stop Audio)' : 'Stop Listening')
                                        : (msg.isTamil ? '🔊 தமிழில் கேளுங்கள் (Listen in Tamil)' : '🔊 Read Aloud (TTS)'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isThisPlaying ? Colors.amberAccent : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Source Cards (if present)
                      if (msg.sources.isNotEmpty) ...[
                        const Divider(color: Color(0xFF334155), height: 20),
                        Row(
                          children: const [
                            Icon(Icons.verified_user_outlined, size: 12, color: accentCyan),
                            SizedBox(width: 4),
                            Text(
                              'Grounded in your authenticated clinical data:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentCyan),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...msg.sources.map((src) => _buildSourceBadge(src)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Suggested followup questions chips
          if (msg.suggestedQuestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.suggestedQuestions.map((q) {
                  return ActionChip(
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    label: Text('💡 $q', style: const TextStyle(fontSize: 11, color: accentCyan)),
                    backgroundColor: const Color(0xFF0F172A),
                    side: BorderSide(color: accentCyan.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => _handleSend(q),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningCard(AiScreeningWarning warning) {
    final isEmergency = warning.isEmergency;
    final color = isEmergency ? Colors.redAccent : Colors.amber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isEmergency ? Icons.warning_rounded : Icons.info_outline, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                warning.title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(warning.message, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            'Recommended Action: ${warning.recommendedAction}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(dynamic src) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bookmark_outline, size: 12, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '${src.title}: ',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                children: [
                  TextSpan(
                    text: src.detail,
                    style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: darkCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accentCyan),
                ),
                SizedBox(width: 8),
                Text(
                  'PitPulse AI analyzing your health records...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
