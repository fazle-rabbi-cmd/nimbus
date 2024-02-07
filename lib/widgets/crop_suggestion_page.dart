import 'dart:convert';

import 'package:flutter/material.dart';

class CropSuggestion {
  final String cropName;
  final String description;

  CropSuggestion({required this.cropName, required this.description});

  factory CropSuggestion.fromJson(Map<String, dynamic> json) {
    return CropSuggestion(
      cropName: json['cropName'],
      description: json['description'],
    );
  }
}

class CropSuggestionService {
  static const String apiUrl = 'YOUR_API_URL_HERE';

  static get http => null;

  static Future<List<CropSuggestion>> fetchCropSuggestions(
      double temperature, double humidity, double chanceOfRain) async {
    final response = await http.get(Uri.parse(
        '$apiUrl?temperature=$temperature&humidity=$humidity&chanceOfRain=$chanceOfRain'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CropSuggestion.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch crop suggestions');
    }
  }
}

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
      body: FutureBuilder<List<CropSuggestion>>(
        future: CropSuggestionService.fetchCropSuggestions(
            temperature, humidity, chanceOfRain),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final cropSuggestions = snapshot.data!;
            return ListView.builder(
              itemCount: cropSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = cropSuggestions[index];
                return ListTile(
                  title: Text(suggestion.cropName),
                  subtitle: Text(suggestion.description),
                );
              },
            );
          }
        },
      ),
    );
  }
}
