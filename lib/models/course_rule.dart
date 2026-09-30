class CourseRule {
  const CourseRule({
    required this.courseId,
    required this.minMath,
    required this.minScience,
    required this.minEnglish,
    required this.weightMath,
    required this.weightScience,
    required this.weightEnglish,
    required this.preferredInterest,
  });

  final int courseId;
  final int minMath;
  final int minScience;
  final int minEnglish;
  final double weightMath;
  final double weightScience;
  final double weightEnglish;
  final String preferredInterest;

  factory CourseRule.fromMap(Map<String, Object?> map) {
    return CourseRule(
      courseId: map['course_id'] as int,
      minMath: map['min_math'] as int,
      minScience: map['min_science'] as int,
      minEnglish: map['min_english'] as int,
      weightMath: map['weight_math'] as double,
      weightScience: map['weight_science'] as double,
      weightEnglish: map['weight_english'] as double,
      preferredInterest: map['preferred_interest'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'course_id': courseId,
      'min_math': minMath,
      'min_science': minScience,
      'min_english': minEnglish,
      'weight_math': weightMath,
      'weight_science': weightScience,
      'weight_english': weightEnglish,
      'preferred_interest': preferredInterest,
    };
  }
}
