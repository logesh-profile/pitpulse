import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
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
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.offline_bolt, size: 12, color: Colors.greenAccent),
                SizedBox(width: 4),
                Text('ON-DEVICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Clear conversation',
            onPressed: () => _controller.clearConversation(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF0F172A),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Informational guide grounded in your records. Not a substitute for clinical diagnosis.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        hintText: 'Ask about your pregnancy or vitals...',
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
          crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF334155),
              child: Icon(Icons.person, size: 14, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // AI Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: accentCyan, size: 16),
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
                      // Formatted Text
                      Text(
                        msg.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),

                      // Warning Banner (if present)
                      if (msg.warning != null) ...[
                        const SizedBox(height: 12),
                        _buildWarningCard(msg.warning!),
                      ],

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
          Text('Recommended Action: ${warning.recommendedAction}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
                Text('PitPulse AI analyzing your health records...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
