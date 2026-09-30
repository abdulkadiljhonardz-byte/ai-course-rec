import 'package:flutter_test/flutter_test.dart';

import 'package:ai_course_rec/data/app_database.dart';
import 'package:ai_course_rec/models/course.dart';
import 'package:ai_course_rec/models/recommendation_history.dart';
import 'package:ai_course_rec/services/ai_recommendation_service.dart';
import 'package:ai_course_rec/services/recommendation_engine.dart';

void main() {
  test('AI refinement cannot force an unrelated course to rank first',
      () async {
    final engine = RecommendationEngine(
      database: _TestDatabase(),
      aiService: _TestAiService(),
    );

    final results = await engine.generateRecommendations(
      const RecommendationInput(
        studentName: 'Test Student',
        strand: 'GAS',
        mathGrade: 85,
        scienceGrade: 85,
        englishGrade: 85,
        ictGrade: 85,
        filipinoGrade: 85,
        socialScienceGrade: 85,
        cetScore: 70,
        interest: 'Agriculture',
        interestRatings: {'Agriculture': 5, 'Islamic': 1},
        skills: ['Problem Solving'],
        weaknesses: ['Shyness'],
      ),
    );

    expect(results.first.course.code, 'BSAGRI');
    expect(
      results.map((result) => result.score.round()).toSet(),
      hasLength(results.length),
    );
    final islamicStudies =
        results.singleWhere((result) => result.course.code == 'BAIS');
    expect(islamicStudies.score, lessThan(100));
    expect(islamicStudies.interestMatched, isFalse);
    expect(islamicStudies.aiGenerated, isTrue);
    expect(engine.lastGenerationUsedAi, isTrue);
  });

  test('local fallback keeps distinct scores and prioritizes top interest',
      () async {
    final engine = RecommendationEngine(
      database: _TestDatabase(),
      aiService: _DisabledAiService(),
    );

    final results = await engine.generateRecommendations(
      const RecommendationInput(
        studentName: 'Test Student',
        strand: 'STEM',
        mathGrade: 98,
        scienceGrade: 98,
        englishGrade: 98,
        ictGrade: 75,
        filipinoGrade: 98,
        socialScienceGrade: 75,
        cetScore: 90,
        interest: 'Health',
        interestRatings: {
          'Health': 5,
          'Agriculture': 3,
          'Islamic': 3,
          'Language': 3,
        },
      ),
    );

    expect(results.first.course.code, 'BSNUR');
    expect(results.every((result) => result.score < 100), isTrue);
    expect(
        results.map((result) => result.score).toSet().length, greaterThan(1));
    expect(engine.lastGenerationUsedAi, isFalse);
  });
}

class _TestAiService extends GroqRecommendationService {
  _TestAiService() : super(apiKey: 'test-key');

  @override
  Future<List<AiCourseRecommendation>> rankCourses({
    required Map<String, Object?> studentProfile,
    required List<Map<String, Object?>> courses,
  }) async {
    return const [
      AiCourseRecommendation(
        courseCode: 'BAIS',
        score: 100,
        interestMatched: true,
        reasons: ['Generated reason.'],
        improvements: ['Generated improvement.'],
      ),
    ];
  }
}

class _DisabledAiService extends GroqRecommendationService {
  _DisabledAiService() : super(apiKey: '');

  @override
  bool get isConfigured => false;
}

class _TestDatabase implements AppDatabase {
  @override
  Future<List<Map<String, Object?>>> fetchCoursesWithRules() async => [
        _row(
          id: 1,
          code: 'BSAGRI',
          name: 'BS in Agriculture',
          category: 'Agriculture',
          preferredInterest: 'Agriculture',
        ),
        _row(
          id: 2,
          code: 'BAIS',
          name: 'BA in Islamic Studies',
          category: 'Social Science',
          preferredInterest: 'Islamic',
        ),
        _row(
          id: 3,
          code: 'BSNUR',
          name: 'BS in Nursing',
          category: 'Health',
          preferredInterest: 'Health',
        ),
        _row(
          id: 4,
          code: 'BAELS',
          name: 'BA in English Language Studies',
          category: 'Language',
          preferredInterest: 'Language',
        ),
      ];

  static Map<String, Object?> _row({
    required int id,
    required String code,
    required String name,
    required String category,
    required String preferredInterest,
  }) {
    return {
      'course_id': id,
      'course_code': code,
      'course_name': name,
      'course_category': category,
      'course_description': '$name description',
      'course_is_paid': false,
      'min_math': 70,
      'min_science': 70,
      'min_english': 70,
      'weight_math': 0.33,
      'weight_science': 0.34,
      'weight_english': 0.33,
      'preferred_interest': preferredInterest,
    };
  }

  @override
  Future<void> deleteHistoryById(int id) async {}

  @override
  Future<List<Course>> fetchCourses() async => const [];

  @override
  Future<List<RecommendationHistory>> fetchHistory() async => const [];

  @override
  Future<void> insertHistory(RecommendationHistory history) async {}

  @override
  Future<void> updateHistory(RecommendationHistory history) async {}
}
