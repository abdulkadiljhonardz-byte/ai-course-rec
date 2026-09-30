import '../models/course.dart';
import '../models/recommendation_history.dart';

abstract class AppDatabase {
  Future<List<Course>> fetchCourses();

  Future<List<Map<String, Object?>>> fetchCoursesWithRules();

  Future<void> insertHistory(RecommendationHistory history);

  Future<void> updateHistory(RecommendationHistory history);

  Future<List<RecommendationHistory>> fetchHistory();

  Future<void> deleteHistoryById(int id);
}
