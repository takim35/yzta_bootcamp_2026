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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
  final FocusNode _focusNode = FocusNode();
  final List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
        parentId: _replyingToCommentId,
      );
      _controller.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUsername = null;
      });
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

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Yorumu Sil', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
        content: Text('Bu yorumu silmek istediğinize emin misiniz?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteComment(commentId: commentId, userId: widget.currentUserId);
      await _loadComments();
      widget.onCommentsCountChanged?.call(_comments.length);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum silinemedi.')),
      );
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
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Text(
                'Yorumlar (${_comments.isNotEmpty ? _comments.length : widget.initialCommentsCount})',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(child: _buildBody()),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            if (_replyingToUsername != null) ...[
              Container(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '@$_replyingToUsername kullanıcısına yanıt veriliyor...',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToCommentId = null;
                          _replyingToUsername = null;
                        });
                      },
                      child: Icon(Icons.close_rounded, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, size: 18),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
            ],
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Text(
          'Henüz yorum yok. İlk yorumu sen yap!',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
        ),
      );
    }

    // parentId'si null olanlar veya bizim listemizde parentId'si bulunmayanlar ana yorumdur
    final commentIds = _comments.map((c) => c.commentId).toSet();
    final parents = _comments.where((c) => c.parentId == null || !commentIds.contains(c.parentId)).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: parents.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingM),
      itemBuilder: (context, index) {
        final parent = parents[index];
        final replies = _comments.where((c) => c.parentId == parent.commentId).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommentRow(parent, isReply: false),
            if (replies.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingS),
              ...replies.map((reply) => Padding(
                    padding: const EdgeInsets.only(left: 36.0, top: 8.0),
                    child: _buildCommentRow(reply, isReply: true),
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCommentRow(CommentModel comment, {required bool isReply}) {
    final isOwnComment = comment.userId == widget.currentUserId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 12 : 16,
          backgroundColor: Theme.of(context).cardColor,
          backgroundImage: comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty
              ? CachedNetworkImageProvider(comment.avatarUrl!)
              : null,
          child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
              ? Text(
                  comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                    fontSize: isReply ? 10 : 12,
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
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: comment.content,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    comment.timeAgo,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (!isReply) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToCommentId = comment.commentId;
                          _replyingToUsername = comment.username;
                        });
                        _focusNode.requestFocus();
                      },
                      child: Text(
                        'Yanıtla',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (isOwnComment) ...[
          const SizedBox(width: AppTheme.spacingS),
          GestureDetector(
            onTap: () => _deleteComment(comment.commentId),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              size: 18,
            ),
          ),
        ],
      ],
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
              focusNode: _focusNode,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
              decoration: InputDecoration(
                hintText: _replyingToUsername != null ? 'Yanıt ekle...' : 'Yorum ekle...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                filled: true,
                fillColor: Theme.of(context).cardColor,
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
                : Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
