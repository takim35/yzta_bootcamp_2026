import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Konum servisi — konum izni yönetimi ve mevcut konumu alma
class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  /// Konum iznini kontrol eder ve gerekirse ister.
  /// Dönen değer: (lat, lon) veya null (izin verilmezse)
  Future<({double lat, double lon})?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisleri açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Konum servisleri kapalı.');
      return null;
    }

    // İzin durumunu kontrol et
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Konum izni reddedildi.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Konum izni kalıcı olarak reddedildi.');
      // Kullanıcıyı ayarlara yönlendir
      await Geolocator.openAppSettings();
      return null;
    }

    // Mevcut konumu al
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint('Konum alındı: ${position.latitude}, ${position.longitude}');
      return (lat: position.latitude, lon: position.longitude);
    } catch (e) {
      debugPrint('Konum alınırken hata: $e');
      return null;
    }
  }

  /// Sadece izin durumunu kontrol eder (konum almaz)
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// İzin verilmiş mi?
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Uygulama ayarlarını aç (kalıcı red durumunda)
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
