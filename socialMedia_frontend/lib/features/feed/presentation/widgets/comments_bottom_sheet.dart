import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../domain/models/comment_model.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final int initialCommentsCount;
  final ValueChanged<int>? onCommentsCountChanged;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialCommentsCount = 0,
    this.onCommentsCountChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required String currentUserId,
    int initialCommentsCount = 0,
    ValueChanged<int>? onCommentsCountChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommentsBottomSheet(
          postId: postId,
          currentUserId: currentUserId,
          initialCommentsCount: initialCommentsCount,
          onCommentsCountChanged: onCommentsCountChanged,
        ),
      ),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final comments = await _api.getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(comments);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Yorumlar yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _api.addComment(
        postId: widget.postId,
        userId: widget.currentUserId,
        content: content,
      );
      _controller.clear();
      await _loadComments();
      widget.onCommentsCountChanged?.call(_comments.length);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum gönderilemedi.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Text(
                'Yorumlar (${_comments.isNotEmpty ? _comments.length : widget.initialCommentsCount})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.dividerColor),
            Expanded(child: _buildBody()),
            const Divider(height: 1, color: AppTheme.dividerColor),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentViolet),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.errorColor),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'Henüz yorum yok. İlk yorumu sen yap!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingM),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.cardDark,
              backgroundImage: comment.avatarUrl != null &&
                      comment.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(comment.avatarUrl!)
                  : null,
              child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                  ? Text(
                      comment.username.isNotEmpty
                          ? comment.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${comment.username} ',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: comment.content,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.timeAgo,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Yorum ekle...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          IconButton(
            onPressed: _isSending ? null : _sendComment,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: AppTheme.accentViolet),
          ),
        ],
      ),
    );
  }
}
