import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_course_rec/models/course.dart';
import 'package:ai_course_rec/models/recommendation_history.dart';
import 'package:ai_course_rec/models/recommendation_result.dart';

void main() {
  const result = RecommendationResult(
    course: Course(
      id: 1,
      code: 'BSIT',
      name: 'BS in Information Technology',
      category: 'Technology',
      description: 'Technology program',
    ),
    score: 91,
    interestMatched: true,
  );

  test('round-trips the complete editable student profile', () {
    final history = RecommendationHistory(
      id: 7,
      createdAt: DateTime(2026, 9, 27),
      studentName: 'Student One',
      age: '18',
      school: 'Sample School',
      examYear: '2026',
      strand: 'STEM',
      mathGrade: 90,
      scienceGrade: 91,
      englishGrade: 89,
      ictGrade: 94,
      filipinoGrade: 88,
      socialScienceGrade: 87,
      cetScore: 86,
      interest: 'Technology',
      interestRatings: const {'Technology': 5, 'Health': 2},
      strengths: const ['Analytical Thinking'],
      skills: const ['Basic Coding'],
      weaknesses: const ['Shyness'],
      results: const [result],
    );

    final restored = RecommendationHistory.fromMap(history.toMap());

    expect(restored.id, 7);
    expect(restored.studentName, 'Student One');
    expect(restored.age, '18');
    expect(restored.school, 'Sample School');
    expect(restored.examYear, '2026');
    expect(restored.strand, 'STEM');
    expect(restored.ictGrade, 94);
    expect(restored.filipinoGrade, 88);
    expect(restored.socialScienceGrade, 87);
    expect(restored.interestRatings['Technology'], 5);
    expect(restored.results.single.course.code, 'BSIT');
  });

  test('loads old history rows with safe defaults for new fields', () {
    final oldRow = <String, Object?>{
      'id': 3,
      'created_at': DateTime(2025, 1, 1).toIso8601String(),
      'student_name': 'Old Student',
      'math_grade': 80,
      'science_grade': 81,
      'english_grade': 82,
      'cet_score': null,
      'interest': 'Technology',
      'strengths_json': '[]',
      'skills_json': '[]',
      'weaknesses_json': '[]',
      'results_json': jsonEncode([result.toStoredMap()]),
    };

    final restored = RecommendationHistory.fromMap(oldRow);

    expect(restored.strand, isEmpty);
    expect(restored.ictGrade, 0);
    expect(restored.interestRatings, isEmpty);
  });
}
