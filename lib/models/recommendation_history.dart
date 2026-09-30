import 'dart:convert';

import 'recommendation_result.dart';

class RecommendationHistory {
  const RecommendationHistory({
    this.id,
    required this.createdAt,
    required this.studentName,
    this.age = '',
    this.school = '',
    this.examYear = '',
    this.strand = '',
    required this.mathGrade,
    required this.scienceGrade,
    required this.englishGrade,
    this.ictGrade = 0,
    this.filipinoGrade = 0,
    this.socialScienceGrade = 0,
    required this.interest,
    required this.strengths,
    required this.skills,
    required this.weaknesses,
    required this.results,
    this.cetScore,
    this.interestRatings = const {},
  });

  final int? id;
  final DateTime createdAt;
  final String studentName;
  final String age;
  final String school;
  final String examYear;
  final String strand;
  final int mathGrade;
  final int scienceGrade;
  final int englishGrade;
  final int ictGrade;
  final int filipinoGrade;
  final int socialScienceGrade;
  final int? cetScore;
  final String interest;
  final Map<String, int> interestRatings;
  final List<String> strengths;
  final List<String> skills;
  final List<String> weaknesses;
  final List<RecommendationResult> results;

  factory RecommendationHistory.fromMap(Map<String, Object?> map) {
    final rawResults =
        jsonDecode(map['results_json'] as String) as List<dynamic>;
    final rawStrengths =
        jsonDecode((map['strengths_json'] as String?) ?? '[]') as List<dynamic>;
    final rawSkills =
        jsonDecode((map['skills_json'] as String?) ?? '[]') as List<dynamic>;
    final rawWeaknesses =
        jsonDecode((map['weaknesses_json'] as String?) ?? '[]')
            as List<dynamic>;
    final rawInterestRatings =
        jsonDecode((map['interest_ratings_json'] as String?) ?? '{}') as Map;

    return RecommendationHistory(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      studentName: (map['student_name'] as String?) ?? '',
      age: (map['age'] as String?) ?? '',
      school: (map['school'] as String?) ?? '',
      examYear: (map['exam_year'] as String?) ?? '',
      strand: (map['strand'] as String?) ?? '',
      mathGrade: map['math_grade'] as int,
      scienceGrade: map['science_grade'] as int,
      englishGrade: map['english_grade'] as int,
      ictGrade: (map['ict_grade'] as int?) ?? 0,
      filipinoGrade: (map['filipino_grade'] as int?) ?? 0,
      socialScienceGrade: (map['social_science_grade'] as int?) ?? 0,
      cetScore: map['cet_score'] as int?,
      interest: map['interest'] as String,
      interestRatings: rawInterestRatings.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      strengths: rawStrengths.map((item) => item.toString()).toList(),
      skills: rawSkills.map((item) => item.toString()).toList(),
      weaknesses: rawWeaknesses.map((item) => item.toString()).toList(),
      results: rawResults
          .map(
            (item) => RecommendationResult.fromStoredMap(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'student_name': studentName,
      'age': age,
      'school': school,
      'exam_year': examYear,
      'strand': strand,
      'math_grade': mathGrade,
      'science_grade': scienceGrade,
      'english_grade': englishGrade,
      'ict_grade': ictGrade,
      'filipino_grade': filipinoGrade,
      'social_science_grade': socialScienceGrade,
      'cet_score': cetScore,
      'interest': interest,
      'interest_ratings_json': jsonEncode(interestRatings),
      'strengths_json': jsonEncode(strengths),
      'skills_json': jsonEncode(skills),
      'weaknesses_json': jsonEncode(weaknesses),
      'results_json':
          jsonEncode(results.map((result) => result.toStoredMap()).toList()),
    };
  }
}
