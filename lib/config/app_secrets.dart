import 'dart:convert';

import 'package:flutter/services.dart';

class AppSecrets {
  const AppSecrets({
    required this.groqApiKey,
    required this.groqModel,
    required this.groqApiUrl,
  });

  final String groqApiKey;
  final String groqModel;
  final String groqApiUrl;

  static Future<AppSecrets> load() async {
    try {
      final raw = await rootBundle.loadString('secrets.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppSecrets(
        groqApiKey: json['GROQ_API_KEY']?.toString().trim() ?? '',
        groqModel: json['GROQ_MODEL']?.toString().trim() ?? '',
        groqApiUrl: json['GROQ_API_URL']?.toString().trim() ?? '',
      );
    } on Object {
      return const AppSecrets(
        groqApiKey: '',
        groqModel: '',
        groqApiUrl: '',
      );
    }
  }
}
