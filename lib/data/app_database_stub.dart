import '../models/course.dart';
import '../models/recommendation_history.dart';
import 'app_database_contract.dart';
import 'seed_data.dart';

AppDatabase createAppDatabase() => _MemoryAppDatabase();

class _MemoryAppDatabase implements AppDatabase {
  final List<RecommendationHistory> _history = [];
  int _nextId = 1;

  @override
  Future<List<Course>> fetchCourses() async {
    final courses = SeedData.courses
        .asMap()
        .entries
        .map(
          (entry) => Course(
            id: entry.key + 1,
            code: entry.value.code,
            name: entry.value.name,
            category: entry.value.category,
            description: entry.value.description,
            isPaid: entry.value.isPaid,
          ),
        )
        .toList();

    courses.sort((a, b) => a.name.compareTo(b.name));
    return courses;
  }

  @override
  Future<List<Map<String, Object?>>> fetchCoursesWithRules() async {
    final courseIdsByCode = <String, int>{};
    for (final entry in SeedData.courses.asMap().entries) {
      courseIdsByCode[entry.value.code] = entry.key + 1;
    }

    final rows = SeedData.rules.map((rule) {
      final courseIndex = SeedData.courses
          .indexWhere((course) => course.code == rule.courseCode);
      final course = SeedData.courses[courseIndex];
      return <String, Object?>{
        'course_id': courseIdsByCode[rule.courseCode],
        'course_code': course.code,
        'course_name': course.name,
        'course_category': course.category,
        'course_description': course.description,
        'course_is_paid': course.isPaid,
        'min_math': rule.minMath,
        'min_science': rule.minScience,
        'min_english': rule.minEnglish,
        'weight_math': rule.weightMath,
        'weight_science': rule.weightScience,
        'weight_english': rule.weightEnglish,
        'preferred_interest': rule.preferredInterest,
      };
    }).toList();

    rows.sort(
      (a, b) =>
          (a['course_name'] as String).compareTo(b['course_name'] as String),
    );
    return rows;
  }

  @override
  Future<void> insertHistory(RecommendationHistory history) async {
    _history.insert(
      0,
      RecommendationHistory(
        id: _nextId++,
        createdAt: history.createdAt,
        studentName: history.studentName,
        age: history.age,
        school: history.school,
        examYear: history.examYear,
        strand: history.strand,
        mathGrade: history.mathGrade,
        scienceGrade: history.scienceGrade,
        englishGrade: history.englishGrade,
        ictGrade: history.ictGrade,
        filipinoGrade: history.filipinoGrade,
        socialScienceGrade: history.socialScienceGrade,
        cetScore: history.cetScore,
        interest: history.interest,
        interestRatings: history.interestRatings,
        strengths: history.strengths,
        skills: history.skills,
        weaknesses: history.weaknesses,
        results: history.results,
      ),
    );
  }

  @override
  Future<void> updateHistory(RecommendationHistory history) async {
    final id = history.id;
    if (id == null) {
      throw ArgumentError('History ID is required when updating a session.');
    }

    final index = _history.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      throw StateError('History entry $id was not found.');
    }
    _history[index] = history;
    _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<RecommendationHistory>> fetchHistory() async {
    return List<RecommendationHistory>.from(_history);
  }

  @override
  Future<void> deleteHistoryById(int id) async {
    _history.removeWhere((entry) => entry.id == id);
  }
}
