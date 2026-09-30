import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AiCourseRecommendation {
  const AiCourseRecommendation({
    required this.courseCode,
    required this.score,
    required this.interestMatched,
    required this.reasons,
    required this.improvements,
  });

  final String courseCode;
  final double score;
  final bool interestMatched;
  final List<String> reasons;
  final List<String> improvements;
}

class GroqRecommendationException implements Exception {
  const GroqRecommendationException(this.message);

  final String message;

  @override
  String toString() => 'GroqRecommendationException: $message';
}

/// Calls the Groq Responses API and returns schema-validated course matches.
///
/// For local prototypes, configure this with `--dart-define=GROQ_API_KEY=...`.
/// A production client should set [endpoint] to a trusted backend proxy instead
/// of embedding a Groq key in the Flutter application.
class GroqRecommendationService {
  GroqRecommendationService({
    http.Client? client,
    String? apiKey,
    String? endpoint,
    String? model,
    this.timeout = const Duration(seconds: 25),
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ??
            (_environmentApiKey.isNotEmpty
                ? _environmentApiKey
                : _runtimeApiKey),
        _configuredEndpoint = endpoint ??
            (_environmentEndpoint.isNotEmpty
                ? _environmentEndpoint
                : _runtimeEndpoint),
        model = model ??
            (_environmentModel.isNotEmpty
                ? _environmentModel
                : (_runtimeModel.isNotEmpty ? _runtimeModel : _defaultModel));

  static const String _environmentApiKey =
      String.fromEnvironment('GROQ_API_KEY');
  static const String _environmentEndpoint =
      String.fromEnvironment('GROQ_API_URL');
  static const String _environmentModel = String.fromEnvironment(
    'GROQ_MODEL',
  );
  static const String _defaultModel = 'openai/gpt-oss-20b';

  static String _runtimeApiKey = '';
  static String _runtimeEndpoint = '';
  static String _runtimeModel = '';

  static void configure({
    required String apiKey,
    String endpoint = '',
    String model = '',
  }) {
    _runtimeApiKey = apiKey.trim();
    _runtimeEndpoint = endpoint.trim();
    _runtimeModel = model.trim();
  }

  static const String _groqResponsesUrl =
      'https://api.groq.com/openai/v1/responses';

  final http.Client _client;
  final String _apiKey;
  final String _configuredEndpoint;
  final String model;
  final Duration timeout;

  bool get isConfigured =>
      _apiKey.trim().isNotEmpty || _configuredEndpoint.trim().isNotEmpty;

  Uri get _endpoint => Uri.parse(
        _configuredEndpoint.trim().isEmpty
            ? _groqResponsesUrl
            : _configuredEndpoint.trim(),
      );

  Future<List<AiCourseRecommendation>> rankCourses({
    required Map<String, Object?> studentProfile,
    required List<Map<String, Object?>> courses,
  }) async {
    if (!isConfigured) {
      throw const GroqRecommendationException('Groq API is not configured.');
    }
    if (courses.isEmpty) {
      return const [];
    }

    final courseCodes = courses
        .map((course) => course['code'])
        .whereType<String>()
        .toSet()
        .toList();

    const instructions = '''
You are a careful university course recommendation assistant. Rank only the
courses supplied in the input. Use grades, strand, SASE score, interests,
strengths, skills, weaknesses, course requirements, and the local baseline
score. Do not invent courses or admission guarantees. Scores must be from 0 to
100. Return the five strongest distinct matches (or all courses when fewer than
five are supplied), ordered from strongest to weakest. Give one or two concise,
student-friendly reasons and improvement areas. Return ONLY one valid JSON
object with this exact shape and no Markdown:
{"recommendations":[{"course_code":"ONE_OF_THE_SUPPLIED_CODES","score":0,"interest_matched":true,"reasons":["reason"],"improvements":["improvement"]}]}
''';

    final requestBody = <String, Object?>{
      'model': model,
      'instructions': instructions,
      'input': jsonEncode({
        'student_profile': studentProfile,
        'available_courses': courses.map(_compactCourse).toList(),
      }),
      'temperature': 0.2,
      'max_output_tokens': 1200,
      'reasoning': {'effort': 'low'},
      'text': {
        'format': {'type': 'text'},
      },
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ${_apiKey.trim()}',
    };

    late http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GroqRecommendationException('Groq request timed out.');
    } on http.ClientException catch (error) {
      throw GroqRecommendationException(
        'Groq request failed: ${error.message}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final apiError = _extractApiError(response.body);
      throw GroqRecommendationException(
        'Groq API returned HTTP ${response.statusCode}'
        '${apiError == null ? '.' : ': $apiError'}',
      );
    }

    try {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final outputText = _extractOutputText(responseJson);
      final resultJson = _decodeOutputJson(outputText);
      final rawRecommendations =
          resultJson['recommendations'] as List<dynamic>? ?? const [];

      final seenCodes = <String>{};
      final recommendations = <AiCourseRecommendation>[];
      for (final rawRecommendation in rawRecommendations) {
        final item = Map<String, dynamic>.from(rawRecommendation as Map);
        final courseCode = item['course_code'] as String;
        if (!courseCodes.contains(courseCode) || !seenCodes.add(courseCode)) {
          continue;
        }

        recommendations.add(
          AiCourseRecommendation(
            courseCode: courseCode,
            score: ((item['score'] as num).toDouble()).clamp(0, 100),
            interestMatched: item['interest_matched'] as bool,
            reasons: _stringList(item['reasons']),
            improvements: _stringList(item['improvements']),
          ),
        );
        if (recommendations.length == 5) {
          break;
        }
      }

      if (recommendations.isEmpty) {
        throw const GroqRecommendationException(
          'Groq API returned no valid recommendations.',
        );
      }

      recommendations.sort((a, b) => b.score.compareTo(a.score));
      return recommendations;
    } on GroqRecommendationException {
      rethrow;
    } on FormatException {
      throw const GroqRecommendationException(
        'Groq API returned invalid JSON.',
      );
    } on TypeError {
      throw const GroqRecommendationException(
        'Groq API returned an unexpected response shape.',
      );
    }
  }

  String _extractOutputText(Map<String, dynamic> response) {
    final directOutput = response['output_text'];
    if (directOutput is String && directOutput.isNotEmpty) {
      return directOutput;
    }

    final output = response['output'];
    if (output is List) {
      for (final rawItem in output) {
        if (rawItem is! Map) {
          continue;
        }
        final content = rawItem['content'];
        if (content is! List) {
          continue;
        }
        for (final rawContent in content) {
          if (rawContent is Map &&
              rawContent['type'] == 'output_text' &&
              rawContent['text'] is String) {
            return rawContent['text'] as String;
          }
        }
      }
    }

    final status = response['status']?.toString() ?? 'unknown';
    final outputTypes = output is List
        ? output
            .whereType<Map>()
            .map((item) => item['type']?.toString() ?? 'unknown')
            .join(', ')
        : 'none';
    final details = response['incomplete_details'] ?? response['error'];
    throw GroqRecommendationException(
      'Groq API response did not contain output text '
      '(status: $status, output: $outputTypes'
      '${details == null ? '' : ', details: $details'}).',
    );
  }

  Map<String, dynamic> _decodeOutputJson(String outputText) {
    var candidate = outputText.trim();
    if (candidate.startsWith('```')) {
      final firstNewline = candidate.indexOf('\n');
      final closingFence = candidate.lastIndexOf('```');
      if (firstNewline >= 0 && closingFence > firstNewline) {
        candidate = candidate.substring(firstNewline + 1, closingFence).trim();
      }
    }

    try {
      return jsonDecode(candidate) as Map<String, dynamic>;
    } on FormatException {
      final objectStart = candidate.indexOf('{');
      final objectEnd = candidate.lastIndexOf('}');
      if (objectStart >= 0 && objectEnd > objectStart) {
        return jsonDecode(candidate.substring(objectStart, objectEnd + 1))
            as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  Map<String, Object?> _compactCourse(Map<String, Object?> course) {
    const allowedKeys = {
      'code',
      'name',
      'category',
      'minimum_grades',
      'preferred_interest',
      'preferred_strands',
      'sase_target',
      'local_baseline_score',
    };
    return {
      for (final entry in course.entries)
        if (allowedKeys.contains(entry.key)) entry.key: entry.value,
    };
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _extractApiError(String responseBody) {
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = body['error'];
      if (error is! Map) {
        return null;
      }
      final code = error['code']?.toString().trim();
      final message = error['message']?.toString().trim();
      final parts = [
        if (code != null && code.isNotEmpty) code,
        if (message != null && message.isNotEmpty) message,
      ];
      if (parts.isEmpty) {
        return null;
      }
      final value = parts.join(' — ').replaceAll(RegExp(r'\s+'), ' ');
      return value.length <= 400 ? value : '${value.substring(0, 400)}…';
    } on Object {
      return null;
    }
  }
}
