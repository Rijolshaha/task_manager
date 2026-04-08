import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../models/chat_message_payload.dart';
import '../models/message_status.dart';
import '../repositories/message_repository.dart';
import '../services/ai_service.dart';
import '../widgets/app_drawer.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageRepository = MessageRepository();
  final _aiService = AiService();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _initialized = false;

  static const String _systemPrompt =
      'You are a helpful AI assistant integrated into a task manager app. '
      'Help users manage their tasks, set priorities, plan their day, and be productive. '
      'You can also answer general questions. '
      'Respond in the same language the user writes in (Uzbek, Russian, or English). '
      'Be concise, friendly, and practical.';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _messageRepository.init();
    final messages = await _messageRepository.loadMessages();

    if (!mounted) return;
    setState(() {
      _messages = messages;
      _initialized = true;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    await _messageRepository.saveMessage(userMsg);
    _scrollToBottom();

    try {
      // ✅ takeLast yo'q — sublist ishlatiladi
      final recentMessages = _messages.length > 20
          ? _messages.sublist(_messages.length - 20)
          : _messages;

      final payloads = <ChatMessagePayload>[
        ChatMessagePayload(role: 'system', content: _systemPrompt),
        ...recentMessages.map(
          (m) => ChatMessagePayload(
            role: m.isUser ? 'user' : 'assistant',
            content: m.content,
          ),
        ),
      ];

      final response = await _aiService.sendMessage(payloads);

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      await _messageRepository.saveMessage(aiMsg);

      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        content: '❌ ${e.toString().replaceAll('Exception: ', '')}',
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      );

      await _messageRepository.saveMessage(errorMsg);

      if (mounted) {
        setState(() {
          _messages.add(errorMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
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

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chatni tozalash'),
        content:
            const Text('Barcha xabarlar o\'chiriladi. Davom etasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Ha', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _messageRepository.clearMessages();
      if (mounted) setState(() => _messages = []);
    }
  }

  // ───────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, size: 22),
            const SizedBox(width: 8),
            Text(l10n.ai_assistant),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Chatni tozalash',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(l10n)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length +
                              (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return _buildTypingBubble();
                            }
                            return _buildMessageBubble(
                                _messages[index]);
                          },
                        ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  // ───────────────────────────────────────────
  // Widgets
  // ───────────────────────────────────────────

  Widget _buildEmptyState(AppLocalizations l10n) {
    final suggestions = [
      'Bugun nima qilishim kerak?',
      'Vazifalarimni tartibga sol',
      'Mahsuldorlik bo\'yicha maslahat ber',
      'What should I focus on today?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF0DCA9F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  size: 64, color: Color(0xFF0DCA9F)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.ai_assistant,
              style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              'Savol bering yoki quyidagilardan birini bosing',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 28),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _sendMessage(s),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF0DCA9F)
                              .withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF0DCA9F)
                          .withValues(alpha: 0.05),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: Color(0xFF0DCA9F)),
                        const SizedBox(width: 8),
                        Text(
                          s,
                          style: const TextStyle(
                              color: Color(0xFF0DCA9F),
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.status == MessageStatus.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0DCA9F),
              child: const Icon(Icons.smart_toy,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF0DCA9F)
                    : isError
                        ? Colors.red.shade50
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      Radius.circular(isUser ? 18 : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : isError
                              ? Colors.red.shade700
                              : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white60
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person,
                  size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF0DCA9F),
            child:
                Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Xabar yozing...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0DCA9F),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _isLoading ? null : () => _sendMessage(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : const Icon(Icons.send,
                          color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────
// Typing animatsiyasi (3 nuqta)
// ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final raw = (_controller.value - delay) % 1.0;
            final t = raw < 0 ? raw + 1.0 : raw;
            final scale = 0.6 +
                0.4 *
                    (1 -
                        (2 * t - 1)
                            .abs()
                            .clamp(0.0, 1.0));
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0DCA9F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
