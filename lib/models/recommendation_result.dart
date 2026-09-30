import 'course.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.course,
    required this.score,
    required this.interestMatched,
    this.reasons = const [],
    this.improvements = const [],
    this.aiGenerated = false,
  });

  final Course course;
  final double score;
  final bool interestMatched;
  final List<String> reasons;
  final List<String> improvements;
  final bool aiGenerated;

  Map<String, Object?> toStoredMap() {
    return {
      'course_id': course.id,
      'course_code': course.code,
      'course_name': course.name,
      'course_category': course.category,
      'course_description': course.description,
      'course_is_paid': course.isPaid,
      'score': score,
      'interest_matched': interestMatched,
      'reasons': reasons,
      'improvements': improvements,
      'ai_generated': aiGenerated,
    };
  }

  factory RecommendationResult.fromStoredMap(Map<String, Object?> map) {
    return RecommendationResult(
      course: Course(
        id: map['course_id'] as int?,
        code: map['course_code'] as String,
        name: map['course_name'] as String,
        category: map['course_category'] as String,
        description: map['course_description'] as String,
        isPaid: map['course_is_paid'] == true || map['course_is_paid'] == 1,
      ),
      score: (map['score'] as num).toDouble(),
      interestMatched: map['interest_matched'] as bool,
      reasons: (map['reasons'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      improvements: (map['improvements'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      aiGenerated: map['ai_generated'] == true,
    );
  }
}
