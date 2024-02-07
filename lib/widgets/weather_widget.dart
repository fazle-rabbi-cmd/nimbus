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

  double aqi = 0.0; // Add AQI variable
  double humidity = 0.0;
  double realFeel = 0.0;
  double pressure = 0.0;
  double chanceOfRain = 0.0;
  String sunriseTime = '';
  String sunsetTime = '';
  double minTemperature = 0.0;
  double maxTemperature = 0.0;

  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> weeklyForecast = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
            ),
            ElevatedButton(
              onPressed: () {
                _getLocationAndWeather(); // Set current location
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Row(
                children: [
                  Icon(Icons.my_location),
                  SizedBox(width: 8),
                  Text(
                      'Set current location'), // Include tooltip text in button label
                ],
              ),
            ),
          ],
        );
      },
    ).then((value) {
      // Automatically hide the search tab after selecting the current location
      if (location == 'Loading...') {
        Navigator.of(context).pop(); // Close the WeatherWidget
      }
    });
  }

  void _showLocationSuggestions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Location'),
          content: TextField(
            onChanged: (value) {
              // Implement your logic to fetch location suggestions based on input
            },
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
                // Implement your logic to select the location and fetch weather data
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _getWeatherForLocation(String cityName) async {
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
          aqi = _parseAQI(weatherData);

          // Get highest and lowest temperature of the day
          double tempMin = weatherData['main']['temp_min'] - 273.15;
          double tempMax = weatherData['main']['temp_max'] - 273.15;
          minTemperature = tempMin;
          maxTemperature = tempMax;

          // Clear the input field after successfully fetching weather data
          _locationController.clear();
        });
      }
    } catch (e) {
      print('Error fetching weather for location: $e');
    }
  }

  double _parseAQI(Map<String, dynamic> weatherData) {
    if (weatherData.containsKey('main') &&
        weatherData['main'].containsKey('aqi')) {
      dynamic aqiData = weatherData['main']['aqi'];
      if (aqiData is double) {
        return aqiData;
      }
    }
    return 0.0; // Default value if AQI data is not available
  }

  Future<void> _getLocationAndWeather() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, show a dialog to enable location services
        // Implement your logic to show a dialog or request the user to enable location services
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        // Location permissions are permanently denied, take the user to app settings
        // Implement your logic to navigate the user to app settings
        return;
      }

      if (permission == LocationPermission.denied) {
        // Location permissions are denied, ask for permissions
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          // Permissions are denied, show a message to the user or handle as needed
          // Implement your logic to inform the user about the necessity of location permissions
          return;
        }
      }

      // Fetch current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Fetch weather using the obtained location
      await _getWeather(position.latitude, position.longitude);
      await _getHourlyForecast(position.latitude, position.longitude);
      await _getWeeklyForecast(position.latitude, position.longitude);
    } catch (e) {
      print('Error fetching location/weather: $e');
      // Handle errors here, such as displaying an error message to the user
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
          aqi = 0.0;

          // Get highest and lowest temperature of the day
          double tempMin = weatherData['main']['temp_min'] - 273.15;
          double tempMax = weatherData['main']['temp_max'] - 273.15;
          minTemperature = tempMin;
          maxTemperature = tempMax;
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  Future<void> _getHourlyForecast(double lat, double lon) async {
    try {
      // Hourly forecast URL
      String hourlyForecastUrl =
          '$forecastUrl?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&appid=$apiKey';
      final response = await http.get(Uri.parse(hourlyForecastUrl));

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
      // Weekly forecast URL
      String weeklyForecastUrl =
          '$forecastUrl?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&appid=$apiKey';
      final response = await http.get(Uri.parse(weeklyForecastUrl));

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
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('NIMBUS', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              ThemeManager.of(_scaffoldKey.currentContext!).toggleTheme();
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
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu item selection
              switch (value) {
                case 'Theme Change':
                  ThemeManager.of(_scaffoldKey.currentContext!).toggleTheme();
                  break;
                case 'Crop Suggestions':
                  _showCropSuggestion();
                  break;
                case 'Location':
                  _showLocationPicker();
                  break;
                // Add more menu items as needed
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Theme Change',
                  child: Text('Theme Change'),
                ),
                PopupMenuItem<String>(
                  value: 'Crop Suggestions',
                  child: Text('Crop Suggestions'),
                ),
                PopupMenuItem<String>(
                  value: 'Location',
                  child: Text('Location'),
                ),
                // Add more menu items as needed
              ];
            },
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: Icon(
                  weatherIcon,
                  key: ValueKey<int>(weatherIcon.codePoint),
                  size: 100,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 50),
              Text(
                location,
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _toggleTemperatureUnit,
                child: Text(
                  '${isCelsius ? temperature.toStringAsFixed(1) : (temperature * 9 / 5 + 32).toStringAsFixed(1)}°${isCelsius ? 'C' : 'F'}',
                  style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 20),
              _buildWeatherInfoRow(
                  'AQI', '${aqi.toStringAsFixed(1)}', Icons.air),
              _buildWeatherInfoRow(
                  'Humidity', '${humidity.toString()}%', Icons.water_drop),
              _buildWeatherInfoRow('Real Feel',
                  '${realFeel.toStringAsFixed(1)}°', Icons.thermostat),
              _buildWeatherInfoRow(
                  'Pressure', '${pressure.toString()} hPa', Icons.compress),
              _buildWeatherInfoRow('Chance of Rain',
                  '${chanceOfRain.toString()}%', Icons.beach_access),
              _buildWeatherInfoRow('Sunrise', sunriseTime, Icons.wb_sunny),
              _buildWeatherInfoRow('Sunset', sunsetTime, Icons.brightness_3),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_downward, color: Colors.white),
                  Text(
                    '${minTemperature.toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.arrow_upward, color: Colors.white),
                  Text(
                    '${maxTemperature.toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                'Hourly Forecast',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildHourlyForecast(),
              SizedBox(height: 20),
              Text(
                'Weekly Forecast',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildWeeklyForecast(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfoRow(String title, String value, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(iconData, color: Colors.white),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyForecast.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Text(
                  DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(
                      hourlyForecast[index]['dt'] * 1000)),
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Icon(
                  _getWeatherIcon(hourlyForecast[index]['weather'][0]['icon']),
                  color: Colors.white,
                ),
                Text(
                  '${hourlyForecast[index]['temp'].toStringAsFixed(1)}°',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weeklyForecast.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Text(
                  DateFormat('E, MMM d').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          weeklyForecast[index]['dt'] * 1000)),
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Icon(
                  _getWeatherIcon(weeklyForecast[index]['weather'][0]['icon']),
                  color: Colors.white,
                ),
                Text(
                  '${weeklyForecast[index]['temp']['day'].toStringAsFixed(1)}°',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ThemeManager extends StatefulWidget {
  final Widget child;
  final ThemeMode initialTheme;

  ThemeManager({required this.child, this.initialTheme = ThemeMode.light});

  static _ThemeManagerState of(BuildContext context) {
    return context.findAncestorStateOfType<_ThemeManagerState>()!;
  }

  @override
  _ThemeManagerState createState() => _ThemeManagerState();
}

class _ThemeManagerState extends State<ThemeManager> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
