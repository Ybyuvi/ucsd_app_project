import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Helper: Convert weekday number to abbreviated string.
String getWeekdayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
    default:
      return '';
  }
}

// Helper: Reorder forecast days so that the list starts on Monday.
List<dynamic> reorderForecast(List<dynamic> forecastList) {
  int mondayIndex = forecastList.indexWhere((dayForecast) {
    DateTime date = DateTime.parse(dayForecast['date']);
    return date.weekday == DateTime.monday;
  });
  if (mondayIndex == -1) {
    return forecastList;
  } else {
    return forecastList.sublist(mondayIndex) + forecastList.sublist(0, mondayIndex);
  }
}

class WeatherWidget extends StatefulWidget {
  final String city;
  const WeatherWidget({Key? key, this.city = "San Diego"}) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? currentWeather;
  List<dynamic>? forecast;
  bool isLoading = true;

  final String apiKey = "3b95c186c70a4aedaf680043251104"; 

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    // Request forecast for 7 days so we have enough days.
    final url = Uri.parse(
        "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=${widget.city}&days=7&aqi=yes&alerts=no");
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      setState(() {
        currentWeather = data['current'];
        forecast = data['forecast']['forecastday'];
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (currentWeather == null || forecast == null) {
      return const Text('Failed to load weather');
    }

    // Current weather container (top part)
    Widget currentContainer = Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 80, 80, 80),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Image.network(
            'https:${currentWeather!['condition']['icon']}',
            width: 48,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.city}: ${currentWeather!['temp_f']}°F",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${currentWeather!['condition']['text']} • Feels like ${currentWeather!['feelslike_f']}°F",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                "UV Index: ${currentWeather!['uv']}",
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );

    // Reorder forecast data to start from Monday.
    List<dynamic> orderedForecast = reorderForecast(forecast!);

    // Build forecast row with one column per day.
    Widget forecastRow = Row(
      children: orderedForecast.map((dayForecast) {
        DateTime date = DateTime.parse(dayForecast['date']);
        String weekday = getWeekdayName(date.weekday);
        String maxTemp = "${dayForecast['day']['maxtemp_f']}°";
        String minTemp = "${dayForecast['day']['mintemp_f']}°";
        String iconUrl = "https:${dayForecast['day']['condition']['icon']}";
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(weekday,
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 4),
                Image.network(iconUrl, width: 36, height: 36),
                const SizedBox(height: 4),
                Text(maxTemp,
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
                Text(minTemp,
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        currentContainer,
        const SizedBox(height: 16),
        forecastRow,
      ],
    );
  }
}