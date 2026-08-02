import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';

class VtonScreen extends StatefulWidget {
  final Map<String, dynamic> clothItem;

  const VtonScreen({super.key, required this.clothItem});

  @override
  State<VtonScreen> createState() => _VtonScreenState();
}

class _VtonScreenState extends State<VtonScreen> with TickerProviderStateMixin {
  File? _modelImage;
  bool _isLoading = false;
  String? _resultImageUrl;
  String? _errorMessage;
  bool _showResult = false;
  final _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _modelImage = File(pickedFile.path);
          _resultImageUrl = null;
          _errorMessage = null;
          _showResult = false;
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<void> _tryOn() async {
    if (_modelImage == null) return;

    final garmentUrl = widget.clothItem['foto_url']?.toString() ??
        widget.clothItem['image_url']?.toString() ??
        '';
    if (garmentUrl.isEmpty) {
      setState(() => _errorMessage = "Garment image not found.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultImageUrl = null;
      _showResult = false;
    });

    try {
      final bytes = await _modelImage!.readAsBytes();
      final String base64Image =
          "data:image/jpeg;base64,${base64Encode(bytes)}";

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/wardrobe/vton/tryon'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'garment_url': ApiService.fixImageUrl(garmentUrl),
          'model_image_b64': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['image_url'] != null) {
          setState(() {
            _resultImageUrl = data['image_url'];
            _showResult = true;
          });
        } else {
          setState(() {
            _errorMessage =
                data['message'] ?? "An unknown error occurred.";
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "API Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawGarmentUrl = widget.clothItem['foto_url']?.toString() ??
        widget.clothItem['image_url']?.toString() ??
        '';
    final garmentUrl = ApiService.fixImageUrl(rawGarmentUrl);
    final itemName = widget.clothItem['isim']?.toString() ??
        widget.clothItem['kategori']?.toString() ??
        'Garment';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Virtual Try-On",
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Info ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentViolet.withOpacity(0.1),
                    AppTheme.accentPink.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.accentViolet.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Upload your photo and see how \"$itemName\" looks on you!",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Two-column: Garment + Your Photo ──
            Row(
              children: [
                // Garment
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.checkroom_rounded,
                              size: 16,
                              color: AppTheme.accentViolet),
                          const SizedBox(width: 6),
                          Text("Garment",
                              style: TextStyle(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          image: garmentUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(garmentUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentViolet.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: garmentUrl.isEmpty
                            ? const Center(
                                child: Icon(Icons.checkroom,
                                    size: 40, color: Colors.grey))
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Icon(Icons.add_rounded,
                      color: AppTheme.accentViolet, size: 24),
                ),

                const SizedBox(width: 12),

                // Your Photo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_rounded,
                              size: 16,
                              color: AppTheme.accentPink),
                          const SizedBox(width: 6),
                          Text("Your Photo",
                              style: TextStyle(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImagePicker(),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            image: _modelImage != null
                                ? DecorationImage(
                                    image: FileImage(_modelImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(
                              color: _modelImage != null
                                  ? Colors.transparent
                                  : AppTheme.accentPink.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPink.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _modelImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentPink
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.add_a_photo_rounded,
                                          size: 28,
                                          color: AppTheme.accentPink),
                                    ),
                                    const SizedBox(height: 8),
                                    Text("Tap to upload",
                                        style: TextStyle(
                                          color: AppTheme.accentPink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Try On Button ──
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _modelImage != null && !_isLoading && !_showResult
                      ? _pulseAnimation.value
                      : 1.0,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: _modelImage != null && !_isLoading
                      ? AppTheme.primaryGradient
                      : null,
                  color: _modelImage == null || _isLoading
                      ? Theme.of(context).cardColor
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _modelImage != null && !_isLoading
                      ? [
                          BoxShadow(
                            color: AppTheme.accentViolet.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap:
                        _isLoading || _modelImage == null ? null : _tryOn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Text("Processing...",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_fix_high_rounded,
                                    color: _modelImage != null
                                        ? Colors.white
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  "Try On 🪄",
                                  style: TextStyle(
                                    color: _modelImage != null
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Error Message ──
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[300], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Result Section ──
            if (_showResult && _resultImageUrl != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text("Result",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      )),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppTheme.successColor, size: 14),
                        const SizedBox(width: 4),
                        Text("Done",
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentViolet.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _resultImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.accentViolet,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded,
                                    size: 48, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text("Could not load image",
                                    style:
                                        TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          );
                        },
                      ),
                      // Subtle gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Text(itemName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text("AI Generated",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Retry button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showResult = false;
                    _resultImageUrl = null;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Try Again"),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentViolet,
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentViolet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      color: AppTheme.accentViolet),
                ),
                title: const Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Take a full-body photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: AppTheme.accentPink),
                ),
                title: const Text('Gallery',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Pick from your gallery',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
