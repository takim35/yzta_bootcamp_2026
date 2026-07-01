import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../features/feed/domain/models/post_model.dart';
import '../features/profile/domain/models/user_model.dart';
import '../features/feed/domain/models/outfit_item_model.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  /// Base URL — Android emülatörde 10.0.2.2, diğer ortamlarda localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  // ─── Headers ────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── Generic Request Handler ────────────────────────────────
  Future<Map<String, dynamic>> _get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'İstek başarısız: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    } on TimeoutException {
      throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'İstek başarısız: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    } on TimeoutException {
      throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> _delete(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.Request('DELETE', uri)
        ..headers.addAll(_headers)
        ..body = jsonEncode(body);
      final streamedResponse =
          await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'İstek başarısız: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    } on TimeoutException {
      throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // ─── Feed ───────────────────────────────────────────────────
  Future<({List<PostModel> posts, String? nextCursor})> getFeed({
    required String userId,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'user_id': userId,
      'limit': limit.toString(),
    };
    if (cursor != null) queryParams['cursor'] = cursor;

    final data = await _get('/feed', queryParams: queryParams);
    final posts = (data['posts'] as List<dynamic>?)
            ?.map((p) => PostModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];
    final nextCursor = data['next_cursor'] as String?;
    return (posts: posts, nextCursor: nextCursor);
  }

  // ─── Create Post ───────────────────────────────────────────
  Future<PostModel> createPost({
    required String userId,
    required String imageUrl,
    String? caption,
    required List<OutfitItem> outfitItems,
    required String visibility,
    required bool aiTrainingConsent,
  }) async {
    final body = {
      'user_id': userId,
      'image_url': imageUrl,
      'caption': caption ?? '',
      'outfit_items': outfitItems.map((item) => item.toJson()).toList(),
      'visibility': visibility,
      'ai_training_consent': aiTrainingConsent,
    };
    final data = await _post('/posts', body);
    return PostModel.fromJson(data);
  }

  // ─── User Posts ─────────────────────────────────────────────
  Future<List<PostModel>> getUserPosts({
    required String userId,
    String? viewerId,
  }) async {
    final queryParams = <String, String>{};
    if (viewerId != null) queryParams['viewer_id'] = viewerId;

    final data = await _get('/users/$userId/posts', queryParams: queryParams);
    return (data['posts'] as List<dynamic>?)
            ?.map((p) => PostModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];
  }

  // ─── User Profile ──────────────────────────────────────────
  Future<UserModel> getUser(String userId) async {
    final data = await _get('/users/$userId');
    return UserModel.fromJson(data);
  }

  // ─── Follow ─────────────────────────────────────────────────
  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    await _post('/follow', {
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    await _delete('/follow', {
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  // ─── Like ───────────────────────────────────────────────────
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    await _post('/posts/$postId/like', {'user_id': userId});
  }

  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    await _delete('/posts/$postId/like', {'user_id': userId});
  }

  // ─── Caption Suggestion ────────────────────────────────────
  Future<String> suggestCaption({
    required List<OutfitItem> outfitItems,
    String? styleHint,
  }) async {
    final body = <String, dynamic>{
      'outfit_items':
          outfitItems.map((item) => item.toJson()).toList(),
    };
    if (styleHint != null && styleHint.isNotEmpty) {
      body['style_hint'] = styleHint;
    }
    final data = await _post('/captions/suggest', body);
    return data['caption'] as String? ?? '';
  }

  // ─── Dispose ────────────────────────────────────────────────
  void dispose() {
    _client.close();
  }
}

// ─── Custom Exception ──────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
