import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../services/api_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class AiStylistScreen extends ConsumerStatefulWidget {
  const AiStylistScreen({super.key});

  @override
  ConsumerState<AiStylistScreen> createState() => _AiStylistScreenState();
}

class _AiStylistScreenState extends ConsumerState<AiStylistScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Format: { 'role': 'user' | 'ai', 'text': '...', 'has_outfit': true/false }
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _historyLoaded = false;

  final List<String> _suggestedPrompts = [
    "Siyah kotumla ne kombinleyebilirim?",
    "Bugün hava yağmurlu, ne giysem?",
    "Hafta sonu kahvesi için rahat bir stil öner",
    "İş görüşmesi için profesyonel bir kombin hazırla",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    try {
      final history = await _apiService.getChatHistory(userId);
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages.addAll(history.map((h) => {
            'role': h['role'],
            'text': h['text'],
            'has_outfit': false,
          }));
          _historyLoaded = true;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Geçmiş yüklenemezse boş başla
    }
    if (mounted) setState(() => _historyLoaded = true);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'has_outfit': false});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _apiService.chat(userId, text);
      final aiText = response['asistan_mesaji']?.toString() ??
          response['reply']?.toString() ??
          'Yanıt üretilemedi.';
      
      // Temsili kombin gösterimi mantığı (Eğer mesajda kombin geçiyorsa)
      final hasOutfit = aiText.toLowerCase().contains('kombin') || 
                        aiText.toLowerCase().contains('giyebilirsin') ||
                        Random().nextDouble() > 0.6; // %40 ihtimalle temsili kart göster

      setState(() {
        _messages.add({'role': 'ai', 'text': aiText, 'has_outfit': hasOutfit});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Hata: $e', 'has_outfit': false});
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentPink, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.aiStylist, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Senin Kişisel Stilistin', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Mesaj Listesi ───────────────────────────────────
          Expanded(
            child: !_historyLoaded
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPink))
                : _messages.isEmpty
                    ? _buildEmptyState(s)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // ── Yükleniyor (Yazıyor...) ──────────────────────────
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: _buildTypingIndicator(),
            ),

          // ── Önerilen Sorular (Sadece liste boşsa veya yeni başladıysa) ──
          if (_historyLoaded && _messages.isEmpty)
            _buildSuggestedPrompts(),

          // ── Input Alanı ──────────────────────────────────────
          _buildInputArea(s),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedPrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_suggestedPrompts[index], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              backgroundColor: AppTheme.surfaceDark,
              side: const BorderSide(color: AppTheme.dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _sendMessage(_suggestedPrompts[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final hasOutfit = msg['has_outfit'] == true;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accentPink : AppTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser ? null : Border.all(color: AppTheme.dividerColor),
              ),
              child: isUser
                  ? Text(
                      msg['text'] ?? '',
                      style: const TextStyle(color: AppTheme.primaryDark, fontSize: 15, fontWeight: FontWeight.w500),
                    )
                  : MarkdownBody(
                      data: msg['text'] ?? '',
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        strong: const TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.bold),
                        listBullet: const TextStyle(color: AppTheme.accentPink),
                      ),
                    ),
            ),
            if (hasOutfit && !isUser) _buildRepresentativeOutfitCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRepresentativeOutfitCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: AppTheme.primaryDark,
                  child: const Center(child: Icon(Icons.checkroom_rounded, size: 48, color: AppTheme.textMuted)),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark_border_rounded, color: AppTheme.textPrimary, size: 16),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Önerilen Kombin', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.accentPink, size: 12),
                    const SizedBox(width: 4),
                    Text('AI tarafından oluşturuldu', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotAnimation(delay: 0),
              SizedBox(width: 4),
              _DotAnimation(delay: 200),
              SizedBox(width: 4),
              _DotAnimation(delay: 400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(AppStrings s) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Stilistine bir şeyler sor...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.accentPink.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: AppTheme.primaryDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.accentPink, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Stilistiniz Bekliyor!',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Dolabındaki kıyafetlerle kombin oluşturmasını isteyebilir veya stil tavsiyesi alabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;
  const _DotAnimation({required this.delay});
  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}
class _DotAnimationState extends State<_DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(color: AppTheme.accentPink, shape: BoxShape.circle),
      ),
    );
  }
}
