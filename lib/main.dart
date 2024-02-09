import 'package:flutter/material.dart';
import 'package:nimbus/screens/home_screen.dart';
import 'package:nimbus/widgets/weather_widget.dart';

void main() {
  runApp(ThemeManager(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beautiful Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
