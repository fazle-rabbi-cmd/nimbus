import 'package:flutter/material.dart';

class CropSuggestionPage extends StatelessWidget {
  final double temperature;
  final double humidity;
  final double chanceOfRain;

  CropSuggestionPage({
    required this.temperature,
    required this.humidity,
    required this.chanceOfRain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Suggestions'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Crop Suggestions Based on Weather Conditions:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            _buildCropSuggestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSuggestion() {
    // Here you can implement logic to suggest crops based on weather conditions
    // This is just a placeholder suggestion, you should replace it with your own logic
    if (temperature > 20 && humidity > 60 && chanceOfRain < 30) {
      return Text(
        'Suggested Crop: Tomato',
        style: TextStyle(fontSize: 18),
      );
    } else {
      return Text(
        'Suggested Crop: Wheat',
        style: TextStyle(fontSize: 18),
      );
    }
  }
}
