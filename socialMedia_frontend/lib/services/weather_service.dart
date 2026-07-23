import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  /// Gets the current location of the user after checking permissions.
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are disabled.
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissions are permanently denied
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }

  /// Fetches weather string for AI stylist (e.g., "15°C, Yağmurlu")
  Future<String?> getCurrentWeatherContext() async {
    try {
      final position = await _getCurrentLocation();
      if (position == null) return null;

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'];
        final code = current['weathercode'];

        final description = _getWeatherDescription(code);
        return '$temp°C, $description';
      }
    } catch (e) {
      // Ssssh, silent fail. Weather is just a bonus feature.
      print('Weather fetch failed: $e');
    }
    return null;
  }

  String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes (simplified)
    if (code == 0) return 'Güneşli / Açık';
    if (code >= 1 && code <= 3) return 'Parçalı Bulutlu';
    if (code == 45 || code == 48) return 'Sisli';
    if (code >= 51 && code <= 57) return 'Çiseleyen Yağmur';
    if (code >= 61 && code <= 67) return 'Yağmurlu';
    if (code >= 71 && code <= 77) return 'Karlı';
    if (code >= 80 && code <= 82) return 'Sağanak Yağışlı';
    if (code >= 95 && code <= 99) return 'Fırtınalı';
    return 'Belirsiz';
  }
}
