import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherInfo {
  final double temperature;
  final int weatherCode;

  WeatherInfo({required this.temperature, required this.weatherCode});

  bool get isRainy {
    const rainCodes = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99];
    return rainCodes.contains(weatherCode);
  }

  bool get isSnowy {
    const snowCodes = [71, 73, 75, 77, 85, 86];
    return snowCodes.contains(weatherCode);
  }

  String get suggestionKey {
    if (temperature < 5) return 'weather_suggestion_cold';
    if (temperature < 15) return 'weather_suggestion_cool';
    if (temperature < 25) return 'weather_suggestion_mild';
    return 'weather_suggestion_hot';
  }
}

class WeatherService {
  static Future<WeatherInfo?> fetchWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current_weather=true',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final current = data['current_weather'];

      return WeatherInfo(
        temperature: (current['temperature'] as num).toDouble(),
        weatherCode: current['weathercode'] as int,
      );
    } catch (e) {
      return null;
    }
  }
}