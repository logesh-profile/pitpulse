import 'package:flutter/material.dart';
import '../../data/local_speech_service.dart';
import '../../data/local_tts_service.dart';
import '../../domain/models/ai_screening_warning.dart';
import '../../domain/models/patient_ai_context.dart';
import '../../domain/models/patient_ai_message.dart';
import '../controllers/patient_ai_controller.dart';

/// Classy, Minimalist Black & White Chatbot UI/UX for MAATRA.
/// Inspired by ChatGPT & Claude: pristine monochrome palette, refined typography,
/// subtle pulsing micro-animations, and fluid conversational interactions.
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

class _PatientAiChatScreenState extends State<PatientAiChatScreen> with TickerProviderStateMixin {
  late final PatientAiController _controller;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _hasInputText = false;

  // Classy Monochrome Palette (ChatGPT / Claude Aesthetic)
  static const Color bgDark = Color(0xFF0D0D0D); // Deep Obsidian
  static const Color surfaceDark = Color(0xFF171717); // Card Background
  static const Color surfaceInput = Color(0xFF212121); // Input Pill
  static const Color borderMuted = Color(0xFF262626); // Subtle Divider
  static const Color borderActive = Color(0xFF383838); // Hover/Focus Border
  static const Color textPrimary = Color(0xFFF5F5F5); // Crisp Ivory White
  static const Color textSecondary = Color(0xFF9E9E9E); // Muted Neutral
  static const Color textTertiary = Color(0xFF616161); // Hint / Timestamp
  static const Color userBubble = Color(0xFF262626); // User Chat Bubble

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientAiController(context: widget.contextSnapshot);
    LocalTtsService().initialize();

    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() {
          _hasInputText = hasText;
        });
      }
    });
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
          duration: const Duration(milliseconds: 250),
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

  void _showVoiceInputDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isListening = LocalSpeechService().isListening;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: textPrimary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic_rounded, color: textPrimary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Voice Input',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isListening
                        ? 'Listening in Tamil / English... speak naturally.'
                        : 'Tap the microphone to speak your question or symptoms.',
                    style: const TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        if (isListening) {
                          await LocalSpeechService().stopListening();
                          setSheetState(() {});
                        } else {
                          await LocalSpeechService().startListening(
                            onResult: (spokenText) {
                              setSheetState(() {});
                              if (spokenText.trim().isNotEmpty) {
                                Navigator.pop(ctx);
                                _inputController.text = spokenText;
                                _handleSend(spokenText);
                              }
                            },
                          );
                          setSheetState(() {});
                          if (!LocalSpeechService().isAvailable && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Microphone not available on this device.'),
                                backgroundColor: Color(0xFF262626),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isListening ? textPrimary : surfaceInput,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderActive),
                          boxShadow: isListening
                              ? [
                                  BoxShadow(
                                    color: textPrimary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 32,
                          color: isListening ? bgDark : textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/maatra_logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.circle_outlined, size: 18, color: textPrimary),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'MAATRA',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Gemini Intelligence',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textSecondary, size: 20),
            tooltip: 'New Conversation',
            onPressed: () {
              _controller.clearConversation();
              _scrollToBottom();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: borderMuted, height: 1, thickness: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message Trajectory
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final messages = _controller.messages;
                  final isTyping = _controller.isTyping;
                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isTyping) {
                        return _buildClaudeTypingIndicator();
                      }
                      final msg = messages[index];
                      return _buildMinimalMessageItem(msg);
                    },
                  );
                },
              ),
            ),

            // Quick Prompt Suggestions (Minimalist Pill Row)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final chips = _controller.quickPromptChips;
                return SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chipText = chips[index];
                      return InkWell(
                        onTap: () => _handleSend(chipText),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: surfaceDark,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderMuted),
                          ),
                          child: Text(
                            chipText,
                            style: const TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Minimalist Pill Composer Bar (ChatGPT / Claude Style)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              decoration: const BoxDecoration(
                color: bgDark,
                border: Border(top: BorderSide(color: borderMuted, width: 0.5)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceInput,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderMuted),
                ),
                child: Row(
                  children: [
                    // Voice Mic Action Button
                    IconButton(
                      icon: const Icon(Icons.mic_rounded, color: textSecondary, size: 20),
                      tooltip: 'Voice Input',
                      onPressed: _showVoiceInputDialog,
                    ),

                    // Clean Text Field
                    Expanded(
                      child: TextField(
                        key: const Key('patient_ai_input_field'),
                        controller: _inputController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: textPrimary, fontSize: 14),
                        textInputAction: TextInputAction.send,
                        maxLines: 4,
                        minLines: 1,
                        onSubmitted: (_) => _handleSend(),
                        decoration: const InputDecoration(
                          hintText: 'Ask MAATRA anything...',
                          hintStyle: TextStyle(color: textTertiary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Signature Circular Up-Arrow Send Button (ChatGPT/Claude Style)
                    GestureDetector(
                      key: const Key('patient_ai_send_button'),
                      onTap: () => _handleSend(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hasInputText ? textPrimary : const Color(0xFF2E2E2E),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: _hasInputText ? bgDark : textTertiary,
                        ),
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

  /// Clean, spacious message item
  Widget _buildMinimalMessageItem(PatientAiMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: userBubble,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderMuted),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: textPrimary, fontSize: 14.5, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant / MAATRA Message (Spacious, Left-Aligned on Canvas)
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtle Minimalist Logo Mark
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceDark,
                  border: Border.all(color: borderMuted),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/maatra_logo.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, size: 12, color: textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Formatted Message Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // Triage Warning Card (If Red Flag Symptom)
                    if (msg.warning != null) ...[
                      const SizedBox(height: 14),
                      _buildClassyWarningCard(msg.warning!),
                    ],

                    const SizedBox(height: 10),

                    // Bottom Row: Audio Readout & Source Tag
                    Row(
                      children: [
                        // TTS Audio Read Aloud
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
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isThisPlaying ? textPrimary.withValues(alpha: 0.15) : surfaceDark,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderMuted),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isThisPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                                      size: 14,
                                      color: isThisPlaying ? textPrimary : textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isThisPlaying ? 'Stop' : 'Read aloud',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isThisPlaying ? textPrimary : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 10),

                        // Intelligence Indicator Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderMuted),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline_rounded, size: 12, color: textSecondary),
                              SizedBox(width: 4),
                              Text(
                                'Grok Grounded',
                                style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Claude / ChatGPT Style Pulsing Typing Indicator
  Widget _buildClaudeTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 38),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _PulsingDot(delayMs: 0),
          SizedBox(width: 4),
          _PulsingDot(delayMs: 200),
          SizedBox(width: 4),
          _PulsingDot(delayMs: 400),
        ],
      ),
    );
  }

  /// Minimalist Classy Warning Card (Monochrome with subtle urgency)
  Widget _buildClassyWarningCard(AiScreeningWarning warning) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              Text(
                warning.title,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            warning.message,
            style: const TextStyle(color: textPrimary, fontSize: 12.5, height: 1.4),
          ),
          if (warning.recommendedAction != null) ...[
            const SizedBox(height: 8),
            Text(
              'Action: ${warning.recommendedAction}',
              style: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

/// Subtle breathing dot animation like Claude & ChatGPT
class _PulsingDot extends StatefulWidget {
  final int delayMs;
  const _PulsingDot({required this.delayMs});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _anim.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Opacity(
          opacity: 0.25 + (_anim.value * 0.75),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFD4D4D4),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
