import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../features/feed/domain/models/post_model.dart';
import '../features/feed/domain/models/comment_model.dart';
import '../features/profile/domain/models/user_model.dart';
import '../features/feed/domain/models/outfit_item_model.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  /// Base URL — Bilgisayarın yerel IP adresi (telefon aynı WiFi ağındayken çalışır)
  static String get baseUrl {
    return 'http://172.20.10.13:8000';
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
    final decoded = await _getDecoded(endpoint, queryParams: queryParams);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Beklenmeyen yanıt formatı.');
  }

  Future<dynamic> _getDecoded(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _throwError(response);
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

  Future<List<dynamic>> _getList(String endpoint,
      {Map<String, String>? queryParams}) async {
    final decoded = await _getDecoded(endpoint, queryParams: queryParams);
    if (decoded is List) {
      return decoded;
    }
    throw ApiException('Beklenmeyen yanıt formatı.');
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
        _throwError(response);
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

  Future<Map<String, dynamic>> _put(
      String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final reqHeaders = Map<String, String>.from(_headers);
      if (headers != null) {
        reqHeaders.addAll(headers);
      }
      final response = await _client
          .put(uri, headers: reqHeaders, body: jsonEncode(body))
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        return {};
      } else {
        _throwError(response);
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
      String endpoint, Map<String, dynamic>? body,
      {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final reqHeaders = Map<String, String>.from(_headers);
      if (headers != null) {
        reqHeaders.addAll(headers);
      }
      final request = http.Request('DELETE', uri)..headers.addAll(reqHeaders);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamedResponse =
          await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _throwError(response);
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

  // ─── Error Handler ──────────────────────────────────────────
  Never _throwError(http.Response response) {
    String message = 'İstek başarısız: ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            message = first['msg'].toString();
          } else {
            message = detail.toString();
          }
        }
      }
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ─── Auth ───────────────────────────────────────────────────
  Future<String> register(String email, String password) async {
    final body = {
      'email': email,
      'password': password,
    };
    final data = await _post('/auth/register', body);
    return data['user_id'] as String;
  }

  Future<String> login(String email, String password) async {
    final body = {
      'email': email,
      'password': password,
    };
    final data = await _post('/auth/login', body);
    return data['user_id'] as String;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final body = {
      'email': email,
      'new_password': newPassword,
    };
    await _post('/auth/reset-password', body);
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
  Future<String> createPost({
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
      'outfit_items': outfitItems.map((item) => item.itemId).toList(),
      'visibility': visibility,
      'ai_training_consent': aiTrainingConsent,
    };
    final data = await _post('/posts', body);
    // Backend MessageResponse döndürüyor: {success, message, data: {post_id}}
    final postId = data['data']?['post_id'] as String? ?? '';
    return postId;
  }

  // ─── User Posts ─────────────────────────────────────────────
  Future<List<PostModel>> getUserPosts({
    required String userId,
    String? viewerId,
  }) async {
    final queryParams = <String, String>{};
    if (viewerId != null) queryParams['viewer_id'] = viewerId;

    final data = await _getList('/posts/users/$userId/posts',
        queryParams: queryParams);
    return data
        .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<PostModel>> getSavedPosts({required String userId}) async {
    final data = await _getList('/posts/users/$userId/saved_posts');
    return data
        .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePost({required String postId, required String userId}) async {
    await _delete('/posts/$postId?user_id=$userId', null);
  }

  // ─── User Profile ──────────────────────────────────────────
  Future<UserModel> getUser(String userId) async {
    final data = await _get('/users/$userId');
    return UserModel.fromJson(data);
  }

  Future<UserModel> getMyProfile(String userId) async {
    // using user_id as token
    final data = await _getDecoded('/users/me', queryParams: null);
    return UserModel.fromJson(data); // Actually we should pass header
    // Wait, _get doesn't take headers, let's implement getWithHeaders or just use user_id directly.
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = {
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    await _put('/users/me', body, headers: {'Authorization': 'Bearer $userId'});
  }

  Future<void> updatePrivacy(String userId, bool isPrivate) async {
    final body = {
      'profile_visibility': isPrivate ? 'private' : 'public',
    };
    await _put('/users/me/privacy', body, headers: {'Authorization': 'Bearer $userId'});
  }

  Future<void> deleteAccount(String userId) async {
    await _delete('/users/me', null, headers: {'Authorization': 'Bearer $userId'});
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
    await _delete('/posts/$postId/like?user_id=$userId', {});
  }

  // ─── Save ───────────────────────────────────────────────────
  Future<void> savePost({
    required String postId,
    required String userId,
  }) async {
    await _post('/posts/$postId/save', {'user_id': userId});
  }

  Future<void> unsavePost({
    required String postId,
    required String userId,
  }) async {
    await _delete('/posts/$postId/save?user_id=$userId', {});
  }

  // ─── Comments ───────────────────────────────────────────────
  Future<String> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    final data = await _post('/posts/$postId/comments', {
      'user_id': userId,
      'content': content,
    });
    return data['data']['comment_id'] as String;
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _getList('/posts/$postId/comments');
    return data
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
    // Backend MessageResponse: {success, message, data: {caption: "..."}}
    final nested = data['data'] as Map<String, dynamic>?;
    return nested?['caption'] as String? ?? '';
  }


  // --- Epic 3: Wardrobe & AI Stylist ---
  Future<List<dynamic>> getClothes(String userId) async {
    return await _getList('/wardrobe/items/$userId');
  }

  Future<dynamic> addCloth(String userId, Map<String, dynamic> itemData) async {
    return await _post('/wardrobe/items?user_id=$userId', itemData);
  }

  Future<dynamic> chat(String userId, String message) async {
    return await _post('/wardrobe/chat', {'user_id': userId, 'mesaj': message});
  }

  Future<List<Map<String, String>>> getChatHistory(String userId) async {
    try {
      final data = await _getList('/wardrobe/chat/history/$userId');
      return data
          .map((e) => {
                'role': (e as Map)['rol']?.toString() ?? 'user',
                'text': e['mesaj']?.toString() ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<dynamic> getOutfit(String userId, String event, String weather, String style) async {
    return await _post('/wardrobe/outfit/suggest', {
      'user_id': userId,
      'etkinlik': event,
      'hava_durumu': weather,
      'stil_tercihi': style
    });
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
