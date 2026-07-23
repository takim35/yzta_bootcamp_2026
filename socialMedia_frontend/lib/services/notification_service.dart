import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Bildirim servisi — kıyafet hatırlatmaları ve düşük stok uyarıları
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Bildirim ID'leri ────────────────────────────────────────
  static const int _dailyReminderId = 1001;
  static const int _lowStockId = 1002;
  static const int _dirtyClothesId = 1003;

  // ─── Başlatma ────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Türkiye saat dilimi
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {
      // Timezone bulunamazsa sistem saatini kullan
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('NotificationService başlatıldı.');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Bildirime tıklandı: ${response.payload}');
    // TODO: Bildirime tıklanınca ilgili ekrana yönlendir
  }

  // ─── İzin Kontrolü ──────────────────────────────────────────
  Future<bool> requestPermission() async {
    // Android 13+ için bildirim izni
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS için
    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // ─── Günlük Sabah Hatırlatıcısı ─────────────────────────────
  /// Her sabah 08:00'de kıyafet hatırlatma bildirimi gönderir
  Future<void> scheduleDailyClothesReminder(
      {int hour = 8, int minute = 0}) async {
    if (!_initialized) await init();

    await _notifications.cancel(_dailyReminderId);

    const androidDetails = AndroidNotificationDetails(
      'clothes_reminder_channel',
      'Kıyafet Hatırlatmaları',
      channelDescription: 'Günlük kıyafet kontrol hatırlatmaları',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'clothes_reminder',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Bir sonraki belirtilen saati hesapla
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _dailyReminderId,
      '👗 Dijital Gardrop',
      'Bugün ne giymek istersin? Kıyafetlerini kontrol et!',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarla
      payload: 'daily_reminder',
    );

    debugPrint(
        'Günlük hatırlatıcı ayarlandı: $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Günlük hatırlatıcıyı iptal eder
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
    debugPrint('Günlük hatırlatıcı iptal edildi.');
  }

  // ─── Düşük Stok Uyarısı ─────────────────────────────────────
  /// Temiz kıyafet sayısı eşiğin altına düştüğünde bildirim gönderir
  Future<void> checkLowClothesCount(List<dynamic> clothes,
      {int threshold = 3}) async {
    if (!_initialized) await init();

    // Temiz kıyafetleri say
    final cleanCount = clothes.where((c) {
      if (c is Map) {
        final temiz = c['temiz'];
        return temiz == true || temiz == 1;
      }
      return false;
    }).length;

    if (cleanCount < threshold) {
      await _showLowStockNotification(cleanCount);
    }

    // Kirli kıyafet uyarısı (tamamı kirli veya çok az temiz)
    if (clothes.isNotEmpty && cleanCount == 0) {
      await _showAllDirtyNotification();
    }
  }

  Future<void> _showLowStockNotification(int cleanCount) async {
    const androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Kıyafet Stok Uyarıları',
      channelDescription: 'Temiz kıyafet sayısı azaldığında uyarı',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7C3AED),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _lowStockId,
      '⚠️ Kıyafet Stoğunuz Azalıyor',
      'Sadece $cleanCount temiz kıyafetiniz kaldı! Çamaşırlarınızı yıkama vakti gelmiş olabilir.',
      details,
      payload: 'low_stock',
    );
  }

  Future<void> _showAllDirtyNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'dirty_clothes_channel',
      'Temiz Kıyafet Uyarısı',
      channelDescription: 'Tüm kıyafetler kirli olduğunda uyarı',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _dirtyClothesId,
      '🧺 Temiz Kıyafetin Kalmadı!',
      'Çamaşır yıkama zamanı geldi. Temiz kıyafet yokken modayı sürdürmek zor!',
      details,
      payload: 'all_dirty',
    );
  }

  // ─── Anlık Bildirim ─────────────────────────────────────────
  /// Test amaçlı anlık bildirim
  Future<void> showTestNotification() async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Bildirimleri',
      channelDescription: 'Test amaçlı bildirimler',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      9999,
      '✅ Bildirimler Çalışıyor',
      'Dijital Gardrop bildirimleri aktif!',
      details,
    );
  }

  // ─── Tüm Bildirimleri İptal Et ──────────────────────────────
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
