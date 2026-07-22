import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../services/weather_service.dart';

class AiStylistScreen extends ConsumerStatefulWidget {
  const AiStylistScreen({super.key});

  @override
  ConsumerState<AiStylistScreen> createState() => _AiStylistScreenState();
}

class _AiStylistScreenState extends ConsumerState<AiStylistScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _historyLoaded = false;
  String? _weatherContext;

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

    // Arka planda hava durumunu çek
    WeatherService().getCurrentWeatherContext().then((weather) {
      if (mounted) _weatherContext = weather;
    });

    try {
      final history = await _apiService.getChatHistory(userId);
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages.addAll(history);
          _historyLoaded = true;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Geçmiş yüklenemezse boş başla
    }
    if (mounted) setState(() => _historyLoaded = true);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _apiService.chat(userId, text, weather: _weatherContext);
      final aiText = response['asistan_mesaji']?.toString() ??
          response['reply']?.toString() ??
          'Yanıt üretilemedi.';

      setState(() {
        _messages.add({'role': 'ai', 'text': aiText});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Hata: $e'});
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(s.aiStylist, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Mesaj Listesi ───────────────────────────────────
          Expanded(
            child: !_historyLoaded
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _messages.isEmpty
                    ? _buildEmptyState(s)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // ── Yükleniyor göstergesi ───────────────────────────
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Stilistiniz düşünüyor...',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 12)),
                ],
              ),
            ),

          // ── Mesaj Giriş Alanı ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: s.askForSuggestions,
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                msg['text'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState(dynamic s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            s.aiStylist,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Merhaba! Bugün ne giyeceğinizi birlikte seçelim. Nereye gidiyorsunuz?',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
