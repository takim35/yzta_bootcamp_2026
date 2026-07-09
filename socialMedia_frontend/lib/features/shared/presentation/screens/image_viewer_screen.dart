import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: heroTag != null
              ? Hero(
                  tag: heroTag!,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 64, color: AppTheme.textMuted),
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 64, color: AppTheme.textMuted),
                ),
        ),
      ),
    );
  }
}
