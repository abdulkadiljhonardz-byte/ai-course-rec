import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_course_rec/config/app_secrets.dart';
import 'package:ai_course_rec/data/seed_data.dart';
import 'package:ai_course_rec/services/ai_recommendation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  const runLive = bool.fromEnvironment('RUN_LIVE_GROQ');

  test(
    'Groq ranks the complete course catalog',
    () async {
      final secrets = await AppSecrets.load();
      GroqRecommendationService.configure(
        apiKey: secrets.groqApiKey,
        model: secrets.groqModel,
        endpoint: secrets.groqApiUrl,
      );

      final service = GroqRecommendationService();
      expect(service.isConfigured, isTrue);

      final rulesByCode = {
        for (final rule in SeedData.rules) rule.courseCode: rule,
      };
      final courses = SeedData.courses.map((course) {
        final rule = rulesByCode[course.code]!;
        return <String, Object?>{
          'code': course.code,
          'name': course.name,
          'category': course.category,
          'description': course.description,
          'minimum_grades': {
            'math': rule.minMath,
            'science': rule.minScience,
            'english': rule.minEnglish,
          },
          'preferred_interest': rule.preferredInterest,
          'local_baseline_score': 85,
        };
      }).toList();

      final results = await service.rankCourses(
        studentProfile: const {
          'strand': 'STEM',
          'grades': {
            'math': 90,
            'science': 91,
            'english': 88,
            'ict': 92,
            'filipino': 86,
            'social_science': 87,
          },
          'sase_score': 86,
          'primary_interest': 'Technology',
          'interest_ratings': {'Technology': 5, 'Health': 3},
          'strengths': ['Analytical Thinking'],
          'skills': ['Basic Coding', 'Problem Solving'],
          'weaknesses': ['Shyness'],
        },
        courses: courses,
      );

      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(5));
    },
    skip: !runLive,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
