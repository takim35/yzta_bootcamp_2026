import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/create_post/presentation/providers/create_post_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/feed/presentation/providers/feed_provider.dart';
import '../../../../features/create_post/presentation/widgets/visibility_selector.dart';
import '../../../../features/create_post/presentation/widgets/outfit_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../navigation/app_navigator.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late TextEditingController _captionController;
  CreatePostProvider? _provider;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = ref.read(createPostProvider);
      _provider!.addListener(_syncCaption);
    });
  }

  void _syncCaption() {
    final provider = ref.read(createPostProvider);
    if (_captionController.text != provider.caption) {
      _captionController.text = provider.caption;
      _captionController.selection = TextSelection.fromPosition(
        TextPosition(offset: provider.caption.length),
      );
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_syncCaption);
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yeni Paylaşım',
          semanticsLabel: 'Yeni paylaşım oluştur',
        ),
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(createPostProvider).clearForm();
            Navigator.of(context).pop();
          },
          tooltip: 'Kapat',
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
        final provider = ref.watch(createPostProvider);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Section 1: Görsel Seçimi ─────────────────
                _buildSectionTitle('Görsel Seçimi'),
                const SizedBox(height: AppTheme.spacingM),
                _buildImagePicker(provider),

                const SizedBox(height: AppTheme.spacingXL),

                // ─── Section 2: Kombin Parçaları ──────────────
                _buildSectionTitle('Kombin Parçaları'),
                const SizedBox(height: AppTheme.spacingM),
                OutfitPicker(
                  items: provider.mockOutfitItems,
                  selectedItems: provider.selectedOutfitItems,
                  onToggle: (item) => provider.toggleOutfitItem(item),
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // ─── Section 3: Caption ───────────────────────
                _buildSectionTitle('Açıklama'),
                const SizedBox(height: AppTheme.spacingM),
                _buildCaptionField(provider),

                const SizedBox(height: AppTheme.spacingXL),

                // ─── Section 4: Gizlilik ──────────────────────
                _buildSectionTitle('Gizlilik'),
                const SizedBox(height: AppTheme.spacingM),
                VisibilitySelector(
                  currentValue: provider.visibility,
                  onChanged: (value) => provider.setVisibility(value),
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // ─── Section 5: AI Eğitim İzni ───────────────
                _buildAiConsentRow(provider),

                const SizedBox(height: AppTheme.spacingXL),

                // ─── Error Message ────────────────────────────
                if (provider.errorMessage != null)
                  _buildErrorMessage(provider.errorMessage!),

                // ─── Section 6: Paylaş Butonu ─────────────────
                _buildSubmitButton(provider),

                const SizedBox(height: AppTheme.spacingXXL),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildImagePicker(CreatePostProvider provider) {
    if (provider.selectedImage != null) {
      return _buildSelectedImage(provider);
    }
    return _buildImagePlaceholder(provider);
  }

  Widget _buildImagePlaceholder(CreatePostProvider provider) {
    return GestureDetector(
      onTap: () => provider.pickImage(),
      child: Semantics(
        label: 'Galeriden görsel seç',
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.accentViolet.withValues(alpha: 0.4),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            color: AppTheme.accentViolet.withValues(alpha: 0.05),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: AppTheme.accentViolet.withValues(alpha: 0.3),
              borderRadius: AppTheme.radiusLarge,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 56,
                  color: AppTheme.accentViolet,
                ),
                SizedBox(height: AppTheme.spacingM),
                Text(
                  'Galeriden Seç',
                  style: TextStyle(
                    color: AppTheme.accentPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  'Kombinini paylaşmak için bir fotoğraf seç',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImage(CreatePostProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.file(
              provider.selectedImage!,
              fit: BoxFit.cover,
              semanticLabel: 'Seçilen görsel',
            ),
          ),
          // ─── Change Button Overlay ──────────────────────────
          Positioned(
            top: AppTheme.spacingM,
            right: AppTheme.spacingM,
            child: GestureDetector(
              onTap: () => provider.pickImage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    Text(
                      'Değiştir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionField(CreatePostProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _captionController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (value) => provider.setCaption(value),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Kombinin hakkında bir şeyler yaz...',
            counterStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide:
                  const BorderSide(color: AppTheme.accentViolet, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        // AI Öneri Butonu
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: provider.isSuggestingCaption
                ? null
                : () => provider.suggestCaption(),
            icon: provider.isSuggestingCaption
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentPurple,
                    ),
                  )
                : const Text('✨', style: TextStyle(fontSize: 16)),
            label: Text(
              provider.isSuggestingCaption
                  ? 'Öneri alınıyor...'
                  : 'AI Öneri Al',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentPurple,
              side: BorderSide(
                color: AppTheme.accentPurple.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingM,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiConsentRow(CreatePostProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.glassDecoration(opacity: 0.05),
      child: Row(
        children: [
          Checkbox(
            value: provider.aiTrainingConsent,
            onChanged: (value) =>
                provider.setAiTrainingConsent(value ?? false),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Semantics(
              label: 'AI eğitim izni',
              child: GestureDetector(
                onTap: () => provider
                    .setAiTrainingConsent(!provider.aiTrainingConsent),
                child: const Text(
                  'Bu görsel, modelin gelişmesi için kullanılabilir',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(CreatePostProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: provider.isFormValid ? 1.0 : 0.5,
        child: Container(
          decoration: AppTheme.gradientButtonDecoration(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: provider.isFormValid && !provider.isSubmitting
                  ? () => _handleSubmit(provider)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              child: Center(
                child: provider.isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Paylaş',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(CreatePostProvider provider) async {
    final authProv = ref.read(authProvider);
    final userId = authProv.currentUserId ?? '';
    if (userId.isEmpty) return;

    final result = await provider.submitPost(userId);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppTheme.successColor, size: 20),
              SizedBox(width: AppTheme.spacingS),
              Text('Paylaşım başarıyla oluşturuldu! 🎉'),
            ],
          ),
          backgroundColor: AppTheme.cardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      provider.clearForm();
      // Yönlendirmeyi değiştir: Ana sayfa navigasyonundan pop yapmak yerine tab indeksini 0 (Feed) yap
      ref.read(bottomNavIndexProvider.notifier).state = 0;
      // Yeni gönderiyi anında akışta görmek için beslemeyi (feed) yenile
      ref.read(feedProvider).refresh();
    }
  }
}

/// Dashed border painter for image placeholder
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // No-op: using container border instead for simplicity
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
