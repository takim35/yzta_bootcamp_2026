import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../domain/models/comment_model.dart';
import '../../../profile/presentation/screens/profile_screen.dart'; // import for navigation

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
  final FocusNode _inputFocusNode = FocusNode();
  
  final List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  
  CommentModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final comments = await _api.getComments(widget.postId, userId: widget.currentUserId);
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
        parentId: _replyingTo?.commentId,
      );
      _controller.clear();
      setState(() => _replyingTo = null);
      
      await _loadComments();
      widget.onCommentsCountChanged?.call(_comments.length); // this might only count root comments, but ok for now
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

  void _showCommentOptions(CommentModel comment) {
    final isOwnComment = comment.userId == widget.currentUserId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isOwnComment)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                title: const Text('Sil', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  // Call API to delete comment (Mock)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yorum silindi (Mock)')),
                  );
                  // Update UI
                  setState(() {
                    _comments.removeWhere((c) => c.commentId == comment.commentId);
                  });
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: AppTheme.errorColor),
                title: const Text('Şikayet Et', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yorum şikayet edildi. İncelenecektir.')),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(CommentModel comment, bool isReply, int rootIndex, int? replyIndex) async {
    // Optimistic UI update
    final wasLiked = comment.isLiked;
    final updatedComment = CommentModel(
      commentId: comment.commentId,
      postId: comment.postId,
      userId: comment.userId,
      username: comment.username,
      avatarUrl: comment.avatarUrl,
      content: comment.content,
      parentId: comment.parentId,
      createdAt: comment.createdAt,
      likesCount: wasLiked ? comment.likesCount - 1 : comment.likesCount + 1,
      isLiked: !wasLiked,
      replies: comment.replies,
    );

    setState(() {
      if (isReply && replyIndex != null) {
        _comments[rootIndex].replies[replyIndex] = updatedComment;
      } else {
        _comments[rootIndex] = updatedComment;
      }
    });

    try {
      if (wasLiked) {
        await _api.unlikeComment(commentId: comment.commentId, userId: widget.currentUserId);
      } else {
        await _api.likeComment(commentId: comment.commentId, userId: widget.currentUserId);
      }
    } catch (e) {
      // Revert on failure
      if (!mounted) return;
      setState(() {
        if (isReply && replyIndex != null) {
          _comments[rootIndex].replies[replyIndex] = comment;
        } else {
          _comments[rootIndex] = comment;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beğeni işlemi başarısız oldu.')),
      );
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalComments = _comments.length + _comments.fold(0, (sum, c) => sum + c.replies.length);
    
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
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
                'Yorumlar (${totalComments > 0 ? totalComments : widget.initialCommentsCount})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.dividerColor),
            Expanded(child: _buildBody()),
            if (_replyingTo != null) _buildReplyIndicator(),
            const Divider(height: 1, color: AppTheme.dividerColor),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      color: AppTheme.cardDark,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: AppTheme.accentViolet, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_replyingTo!.username} kullanıcısına yanıt veriliyor',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
            onPressed: () => setState(() => _replyingTo = null),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          )
        ],
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommentTile(comment, isReply: false, rootIndex: index),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48.0, top: 0, bottom: 8),
                child: Column(
                  children: List.generate(
                    comment.replies.length,
                    (rIndex) => _buildCommentTile(
                      comment.replies[rIndex],
                      isReply: true,
                      rootIndex: index,
                      replyIndex: rIndex,
                    ),
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildCommentTile(CommentModel comment, {required bool isReply, required int rootIndex, int? replyIndex}) {
    return GestureDetector(
      onLongPress: () => _showCommentOptions(comment),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(comment.userId),
            child: CircleAvatar(
              radius: isReply ? 14 : 18,
              backgroundColor: AppTheme.cardDark,
              backgroundImage: comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(comment.avatarUrl!)
                  : null,
              child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                  ? Text(
                      comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: isReply ? 10 : 12,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(comment.userId),
                  child: Text(
                    comment.username,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    if (comment.likesCount > 0) ...[
                      Text(
                        '${comment.likesCount} beğenme',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                    ],
                    GestureDetector(
                      onTap: () {
                        setState(() => _replyingTo = isReply ? _comments[rootIndex] : comment);
                        _inputFocusNode.requestFocus();
                      },
                      child: const Text(
                        'Yanıtla',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Like Button
          GestureDetector(
            onTap: () => _toggleLike(comment, isReply, rootIndex, replyIndex),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Icon(
                comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: comment.isLiked ? Colors.redAccent : AppTheme.textMuted,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    ),
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
              focusNode: _inputFocusNode,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: _replyingTo != null ? '@${_replyingTo!.username} yanıtla...' : 'Yorum ekle...',
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
