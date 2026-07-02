import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/feed/domain/models/outfit_item_model.dart';
import '../../../../services/api_service.dart';

final createPostProvider = ChangeNotifierProvider((ref) => CreatePostProvider());

class CreatePostProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  String _caption = '';
  String get caption => _caption;

  String _visibility = 'public';
  String get visibility => _visibility;

  bool _aiTrainingConsent = false;
  bool get aiTrainingConsent => _aiTrainingConsent;

  List<OutfitItem> _selectedOutfitItems = [];
  List<OutfitItem> get selectedOutfitItems => _selectedOutfitItems;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isSuggestingCaption = false;
  bool get isSuggestingCaption => _isSuggestingCaption;

  String _suggestedCaption = '';
  String get suggestedCaption => _suggestedCaption;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Form geçerliliği: en azından görsel seçilmiş olmalı
  bool get isFormValid => _selectedImage != null;

  // ─── Mock Outfit Items ──────────────────────────────────────
  List<OutfitItem> get mockOutfitItems => const [
        OutfitItem(
          itemId: 'item-001',
          category: 'Üst Giyim',
          imageUrl: 'https://picsum.photos/seed/top1/200/200',
        ),
        OutfitItem(
          itemId: 'item-002',
          category: 'Alt Giyim',
          imageUrl: 'https://picsum.photos/seed/bottom1/200/200',
        ),
        OutfitItem(
          itemId: 'item-003',
          category: 'Ayakkabı',
          imageUrl: 'https://picsum.photos/seed/shoes1/200/200',
        ),
        OutfitItem(
          itemId: 'item-004',
          category: 'Aksesuar',
          imageUrl: 'https://picsum.photos/seed/acc1/200/200',
        ),
        OutfitItem(
          itemId: 'item-005',
          category: 'Dış Giyim',
          imageUrl: 'https://picsum.photos/seed/jacket1/200/200',
        ),
        OutfitItem(
          itemId: 'item-006',
          category: 'Çanta',
          imageUrl: 'https://picsum.photos/seed/bag1/200/200',
        ),
      ];

  // ─── Görsel Seçimi ──────────────────────────────────────────
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        _selectedImage = File(image.path);
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Görsel seçilirken bir hata oluştu.';
      debugPrint('Görsel seçme hatası: $e');
      notifyListeners();
    }
  }

  // ─── Caption Ayarla ─────────────────────────────────────────
  void setCaption(String value) {
    _caption = value;
    notifyListeners();
  }

  // ─── Gizlilik Ayarla ───────────────────────────────────────
  void setVisibility(String value) {
    _visibility = value;
    notifyListeners();
  }

  // ─── AI Eğitim İzni ────────────────────────────────────────
  void setAiTrainingConsent(bool value) {
    _aiTrainingConsent = value;
    notifyListeners();
  }

  // ─── Outfit Item Seç/Kaldır ─────────────────────────────────
  void toggleOutfitItem(OutfitItem item) {
    if (_selectedOutfitItems.contains(item)) {
      _selectedOutfitItems.remove(item);
    } else {
      _selectedOutfitItems.add(item);
    }
    notifyListeners();
  }

  // ─── AI Caption Önerisi ─────────────────────────────────────
  Future<void> suggestCaption() async {
    if (_selectedOutfitItems.isEmpty) {
      _errorMessage = 'Önce kombin parçalarını seçin.';
      notifyListeners();
      return;
    }

    _isSuggestingCaption = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final caption = await _api.suggestCaption(
        outfitItems: _selectedOutfitItems,
      );
      _suggestedCaption = caption;
      _caption = caption;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('Caption önerisi hatası: ${e.message}');
    } catch (e) {
      _errorMessage = 'Caption önerisi alınamadı.';
      debugPrint('Caption önerisi hatası: $e');
    }

    _isSuggestingCaption = false;
    notifyListeners();
  }

  // ─── Gönderi Paylaş ─────────────────────────────────────────
  Future<String?> submitPost(String userId) async {
    if (!isFormValid) {
      _errorMessage = 'Lütfen bir görsel seçin.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gerçek uygulamada önce görseli upload edip URL alacaksınız
      // Şimdilik mock URL kullanıyoruz
      final imageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/1000';

      final postId = await _api.createPost(
        userId: userId,
        imageUrl: imageUrl,
        caption: _caption,
        outfitItems: _selectedOutfitItems,
        visibility: _visibility,
        aiTrainingConsent: _aiTrainingConsent,
      );

      _isSubmitting = false;
      notifyListeners();
      return postId.isNotEmpty ? postId : null;
    } on ApiException catch (e) {
      _isSubmitting = false;
      _errorMessage = e.message;
      notifyListeners();
      debugPrint('Paylaşım hatası: ${e.message}');
      return null;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Paylaşım sırasında bir hata oluştu.';
      notifyListeners();
      debugPrint('Paylaşım hatası: $e');
      return null;
    }
  }

  // ─── Formu Temizle ──────────────────────────────────────────
  void clearForm() {
    _selectedImage = null;
    _caption = '';
    _visibility = 'public';
    _aiTrainingConsent = false;
    _selectedOutfitItems = [];
    _isSubmitting = false;
    _isSuggestingCaption = false;
    _suggestedCaption = '';
    _errorMessage = null;
    notifyListeners();
  }
}
