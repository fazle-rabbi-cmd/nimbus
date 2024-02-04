import 'package:flutter/material.dart';
import 'package:nimbus/widgets/weather_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WeatherWidget(),
    );
  }
}
