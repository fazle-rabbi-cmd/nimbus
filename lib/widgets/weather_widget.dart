import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';

import 'crop_suggestion_page.dart'; // Import the CropSuggestionPage

void main() {
  runApp(ThemeManager(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WeatherWidget(),
    );
  }
}

class WeatherWidget extends StatefulWidget {
  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String apiKey = 'c0d1009550c934bb96a545c2d2f38878';
  String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  String forecastUrl = 'https://api.openweathermap.org/data/2.5/onecall';
  String iconBaseUrl = 'http://openweathermap.org/img/w/';

  String location = 'Loading...';
  double temperature = 0.0;
  String description = 'Loading...';
  IconData weatherIcon = WeatherIcons.day_sunny;
  bool isCelsius = true;
  TextEditingController _locationController = TextEditingController();

  double humidity = 0.0;
  double realFeel = 0.0;
  double pressure = 0.0;
  double chanceOfRain = 0.0;
  String sunriseTime = '';
  String sunsetTime = '';

  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> weeklyForecast = [];

  @override
  void initState() {
    super.initState();
    _getLocationAndWeather();
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Location'),
          content: TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Location'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String location = _locationController.text;
                if (location.isNotEmpty) {
                  _getWeatherForLocation(location);
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getWeatherForLocation(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=$cityName&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        setState(() {
          location = weatherData['name'];
          temperature = (weatherData['main']['temp'] - 273.15);
          description = weatherData['weather'][0]['description'];
          weatherIcon = _getWeatherIcon(weatherData['weather'][0]['icon']);

          humidity = weatherData['main']['humidity'].toDouble();
          realFeel = (weatherData['main']['feels_like'] - 273.15);
          pressure = weatherData['main']['pressure'].toDouble();
          chanceOfRain =
              (weatherData.containsKey('rain') ? weatherData['rain']['1h'] : 0)
                  .toDouble();
          sunriseTime = _formatTime(weatherData['sys']['sunrise']);
          sunsetTime = _formatTime(weatherData['sys']['sunset']);
        });
      }
    } catch (e) {
      print('Error fetching weather for location: $e');
    }
  }

  Future<void> _getLocationAndWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      await _getWeather(position.latitude, position.longitude);
      await _getHourlyForecast(position.latitude, position.longitude);
      await _getWeeklyForecast(position.latitude, position.longitude);
    } catch (e) {
      print('Error fetching location/weather: $e');
    }
  }

  Future<void> _getWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        setState(() {
          location = weatherData['name'];
          temperature = weatherData['main']['temp'] - 273.15;
          description = weatherData['weather'][0]['description'];
          weatherIcon = _getWeatherIcon(weatherData['weather'][0]['icon']);

          humidity = weatherData['main']['humidity'].toDouble();
          realFeel = (weatherData['main']['feels_like'] - 273.15);
          pressure = weatherData['main']['pressure'].toDouble();
          chanceOfRain =
              (weatherData.containsKey('rain') ? weatherData['rain']['1h'] : 0)
                  .toDouble();
          sunriseTime = _formatTime(weatherData['sys']['sunrise']);
          sunsetTime = _formatTime(weatherData['sys']['sunset']);
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  Future<void> _getHourlyForecast(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$forecastUrl?lat=$lat&lon=$lon&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        final forecastData = json.decode(response.body);
        setState(() {
          hourlyForecast = (forecastData['hourly'] as List<dynamic>)
              .take(24)
              .cast<Map<String, dynamic>>()
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching hourly forecast: $e');
    }
  }

  Future<void> _getWeeklyForecast(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$forecastUrl?lat=$lat&lon=$lon&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        final forecastData = json.decode(response.body);
        setState(() {
          weeklyForecast = (forecastData['daily'] as List<dynamic>)
              .skip(1)
              .take(7)
              .cast<Map<String, dynamic>>()
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching weekly forecast: $e');
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return WeatherIcons.day_sunny;
      case '02d':
        return WeatherIcons.day_cloudy;
      case '03d':
        return WeatherIcons.cloud;
      case '04d':
        return WeatherIcons.cloudy;
      case '09d':
        return WeatherIcons.rain_mix;
      case '10d':
        return WeatherIcons.rain;
      case '11d':
        return WeatherIcons.thunderstorm;
      case '13d':
        return WeatherIcons.snow;
      case '50d':
        return WeatherIcons.fog;
      default:
        return WeatherIcons.day_sunny;
    }
  }

  void _toggleTemperatureUnit() {
    setState(() {
      isCelsius = !isCelsius;
    });
  }

  String _formatTime(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.Hm().format(dateTime);
  }

  void _showCropSuggestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropSuggestionPage(
          temperature: temperature,
          humidity: humidity,
          chanceOfRain: chanceOfRain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NIMBUS'),
        actions: [
          IconButton(
            onPressed: () {
              ThemeManager.of(context).toggleTheme();
            },
            icon: Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            onPressed: _showLocationPicker,
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: _showCropSuggestion,
            icon: Icon(Icons.agriculture),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade200,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Icon(
                  weatherIcon,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 60),
                Text(
                  location,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _toggleTemperatureUnit,
                  child: Text(
                    '${isCelsius ? temperature.toStringAsFixed(1) : (temperature * 9 / 5 + 32).toStringAsFixed(1)}°${isCelsius ? 'C' : 'F'}',
                    style: TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  description,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                SizedBox(height: 20),
                _buildWeatherInfoRow('Humidity', '${humidity.toString()}%'),
                _buildWeatherInfoRow(
                    'Real Feel', '${realFeel.toStringAsFixed(1)}°'),
                _buildWeatherInfoRow('Pressure', '${pressure.toString()} hPa'),
                _buildWeatherInfoRow(
                    'Chance of Rain', '${chanceOfRain.toString()}%'),
                _buildWeatherInfoRow('Sunrise', sunriseTime),
                _buildWeatherInfoRow('Sunset', sunsetTime),
                SizedBox(height: 20),
                Text(
                  'Hourly Forecast',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 10),
                _buildHourlyForecast(), // Display dynamic hourly forecast
                SizedBox(height: 20),
                Text(
                  'Weekly Forecast',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 10),
                _buildWeeklyForecast(), // Display dynamic weekly forecast
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyForecast.length,
        itemBuilder: (context, index) {
          final forecast = hourlyForecast[index];
          final time =
              DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
          final temp = forecast['temp'] as double;

          return Card(
            color: Colors.blue.shade100,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('${time.hour}:${time.minute}'),
                  Text('${temp.toStringAsFixed(1)}°'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weeklyForecast.length,
        itemBuilder: (context, index) {
          final forecast = weeklyForecast[index];
          final date =
              DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
          final temp = forecast['temp']['day'] as double;

          return Card(
            color: Colors.blue.shade100,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('${date.day}/${date.month}'),
                  Text('${temp.toStringAsFixed(1)}°'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ThemeManager extends StatefulWidget {
  final Widget child;

  ThemeManager({required this.child});

  static ThemeManagerState of(BuildContext context) {
    return context.findAncestorStateOfType<ThemeManagerState>()!;
  }

  @override
  ThemeManagerState createState() => ThemeManagerState();
}

class ThemeManagerState extends State<ThemeManager> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: widget.child,
    );
  }
}
