import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LikeButton extends ConsumerStatefulWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback onToggle;
  final VoidCallback? onLikersTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.onToggle,
    this.onLikersTap,
  });

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: widget.isLiked ? 'Beğeniyi kaldır' : 'Beğen',
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: AppTheme.spacingXS,
              ),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(widget.isLiked),
                    color: widget.isLiked
                        ? AppTheme.accentPink
                        : AppTheme.textMuted,
                    size: 24,
                    semanticLabel:
                        widget.isLiked ? 'Beğenildi' : 'Beğenilmedi',
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.onLikersTap != null)
          GestureDetector(
            onTap: widget.onLikersTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _formatCount(widget.likesCount),
                  key: ValueKey(widget.likesCount),
                  style: TextStyle(
                    color: widget.isLiked
                        ? AppTheme.accentPink
                        : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _formatCount(widget.likesCount),
                key: ValueKey(widget.likesCount),
                style: TextStyle(
                  color: widget.isLiked
                      ? AppTheme.accentPink
                      : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
