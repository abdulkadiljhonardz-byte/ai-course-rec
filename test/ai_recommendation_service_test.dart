import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_course_rec/services/ai_recommendation_service.dart';

void main() {
  test('sends a compact JSON-only Groq request and parses recommendations',
      () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'output': [
            {
              'type': 'message',
              'content': [
                {
                  'type': 'output_text',
                  'text': jsonEncode({
                    'recommendations': [
                      {
                        'course_code': 'BSIT',
                        'score': 91,
                        'interest_matched': true,
                        'reasons': ['Strong technology interest.'],
                        'improvements': ['Keep practicing programming.'],
                      },
                    ],
                  }),
                },
              ],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = GroqRecommendationService(
      client: client,
      apiKey: 'test-key',
      model: 'test-model',
    );

    final recommendations = await service.rankCourses(
      studentProfile: const {
        'strand': 'TVL',
        'grades': {'math': 88, 'science': 85, 'english': 87},
      },
      courses: const [
        {
          'code': 'BSIT',
          'name': 'BS in Information Technology',
          'local_baseline_score': 89,
        },
      ],
    );

    expect(recommendations, hasLength(1));
    expect(recommendations.single.courseCode, 'BSIT');
    expect(recommendations.single.score, 91);
    expect(recommendations.single.reasons, ['Strong technology interest.']);
    expect(capturedRequest.headers['authorization'], 'Bearer test-key');
    expect(
      capturedRequest.url.toString(),
      'https://api.groq.com/openai/v1/responses',
    );

    final requestJson =
        jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(requestJson['model'], 'test-model');
    expect(
      requestJson['text']['format']['type'],
      'text',
    );
    expect(requestJson['max_output_tokens'], 1200);
    expect(requestJson['reasoning']['effort'], 'low');
    final input = jsonDecode(requestJson['input'] as String);
    expect(
        input['available_courses'].single.containsKey('description'), isFalse);
  });

  test('rejects an unsuccessful API response', () async {
    final service = GroqRecommendationService(
      client: MockClient((_) async => http.Response('rate limited', 429)),
      apiKey: 'test-key',
    );

    expect(
      () => service.rankCourses(
        studentProfile: const {},
        courses: const [
          {'code': 'BSIT'},
        ],
      ),
      throwsA(isA<GroqRecommendationException>()),
    );
  });

  test('parses fenced JSON returned by the model', () async {
    final service = GroqRecommendationService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'output_text': '''```json
{"recommendations":[{"course_code":"BSIT","score":89,"interest_matched":true,"reasons":["Strong match."],"improvements":["Keep learning."]}]}
```''',
          }),
          200,
        );
      }),
      apiKey: 'test-key',
    );

    final recommendations = await service.rankCourses(
      studentProfile: const {},
      courses: const [
        {'code': 'BSIT'},
      ],
    );

    expect(recommendations.single.courseCode, 'BSIT');
    expect(recommendations.single.score, 89);
  });
}
