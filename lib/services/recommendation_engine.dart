import '../data/app_database.dart';
import '../models/course.dart';
import '../models/recommendation_history.dart';
import '../models/recommendation_result.dart';
import 'ai_recommendation_service.dart';

class RecommendationInput {
  const RecommendationInput({
    required this.studentName,
    required this.strand,
    required this.mathGrade,
    required this.scienceGrade,
    required this.englishGrade,
    required this.ictGrade,
    required this.filipinoGrade,
    required this.socialScienceGrade,
    required this.interest,
    this.interestRatings = const {},
    this.cetScore,
    this.strengths = const [],
    this.skills = const [],
    this.weaknesses = const [],
    this.age = '',
    this.school = '',
    this.examYear = '',
  });

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
}

class RecommendationEngine {
  RecommendationEngine({
    AppDatabase? database,
    GroqRecommendationService? aiService,
  })  : _database = database ?? appDatabaseInstance,
        _aiService = aiService ?? GroqRecommendationService();

  static const List<String> interestOptions = [
    'Technology',
    'Health',
    'Business',
    'Education',
    'Agriculture',
    'Islamic',
    'Language',
  ];

  static const List<String> strengthOptions = [
    'Analytical Thinking',
    'Communication',
    'Leadership',
    'Discipline',
    'Creativity',
    'Empathy',
  ];

  static const List<String> skillOptions = [
    'Problem Solving',
    'Basic Coding',
    'Writing',
    'Public Speaking',
    'Research',
    'Teamwork',
  ];

  static const List<String> weaknessOptions = [
    'Math Difficulty',
    'Science Difficulty',
    'English Difficulty',
    'Time Management',
    'Shyness',
    'Test Anxiety',
  ];

  // The deterministic score remains the main ranking signal. AI refines it
  // and supplies explanations, but cannot completely replace academic,
  // interest, strand, and readiness checks performed locally.
  static const double _localScoreWeight = 0.75;
  static const double _aiScoreWeight = 0.25;

  static const Map<String, List<String>> _categoryStrengthFit = {
    'Technology': ['Analytical Thinking', 'Creativity', 'Discipline'],
    'Health': ['Empathy', 'Discipline', 'Communication'],
    'Business': ['Leadership', 'Communication', 'Analytical Thinking'],
    'Education': ['Communication', 'Empathy', 'Creativity'],
    'Agriculture': ['Discipline', 'Analytical Thinking', 'Creativity'],
    'Social Science': ['Communication', 'Leadership', 'Empathy'],
    'Language': ['Communication', 'Creativity', 'Empathy'],
  };

  static const Map<String, List<String>> _categorySkillFit = {
    'Technology': ['Basic Coding', 'Problem Solving', 'Research'],
    'Health': ['Research', 'Teamwork', 'Problem Solving'],
    'Business': ['Public Speaking', 'Writing', 'Teamwork'],
    'Education': ['Public Speaking', 'Writing', 'Teamwork'],
    'Agriculture': ['Research', 'Problem Solving', 'Teamwork'],
    'Social Science': ['Writing', 'Public Speaking', 'Research'],
    'Language': ['Writing', 'Public Speaking', 'Research'],
  };

  static const Map<String, List<String>> _categoryWeaknessRisk = {
    'Technology': ['Math Difficulty', 'Science Difficulty', 'Time Management'],
    'Health': ['Science Difficulty', 'Test Anxiety', 'Time Management'],
    'Business': ['English Difficulty', 'Shyness', 'Time Management'],
    'Education': ['English Difficulty', 'Shyness', 'Time Management'],
    'Agriculture': ['Science Difficulty', 'Time Management'],
    'Social Science': ['English Difficulty', 'Shyness'],
    'Language': ['English Difficulty', 'Shyness'],
  };

  static const Map<String, Map<String, double>>
      _categorySupplementalSubjectFit = {
    'Technology': {'ict': 1.0},
    'Health': {'ict': 0.60, 'social_science': 0.40},
    'Business': {'ict': 0.45, 'social_science': 0.35, 'filipino': 0.20},
    'Education': {
      'filipino': 0.45,
      'social_science': 0.35,
      'ict': 0.20,
    },
    'Agriculture': {'social_science': 0.55, 'ict': 0.45},
    'Social Science': {'social_science': 0.65, 'filipino': 0.35},
    'Language': {'filipino': 0.75, 'social_science': 0.25},
  };

  static const Map<String, int> _courseSaseTargets = {
    'BSAGRI': 75,
    'BSABM': 78,
    'BSNUR': 85,
    'BSBIO': 82,
    'BSMATH': 83,
    'BAELS': 78,
    'BAIS': 75,
    'BAPOLS': 78,
    'BSBA': 78,
    'BSA': 85,
    'BSIT': 82,
    'BSCS': 85,
    'BSED': 78,
    'BEED': 76,
  };

  static const Map<String, List<String>> _coursePreferredStrands = {
    'BSAGRI': ['STEM', 'TVL', 'GAS'],
    'BSABM': ['ABM', 'GAS'],
    'BSNUR': ['STEM'],
    'BSBIO': ['STEM'],
    'BSMATH': ['STEM'],
    'BAELS': ['HUMSS', 'GAS'],
    'BAIS': ['HUMSS', 'GAS'],
    'BAPOLS': ['HUMSS', 'GAS'],
    'BSBA': ['ABM', 'GAS'],
    'BSA': ['ABM', 'STEM'],
    'BSIT': ['STEM', 'TVL'],
    'BSCS': ['STEM', 'TVL'],
    'BSED': ['HUMSS', 'STEM', 'GAS'],
    'BEED': ['HUMSS', 'GAS', 'ABM'],
  };

  final AppDatabase _database;
  final GroqRecommendationService _aiService;

  bool get isAiConfigured => _aiService.isConfigured;
  bool get lastGenerationUsedAi => _lastGenerationUsedAi;
  String? get lastAiError => _lastAiError;

  bool _lastGenerationUsedAi = false;
  String? _lastAiError;

  Future<List<RecommendationResult>> generateRecommendations(
      RecommendationInput input) async {
    final rows = await _database.fetchCoursesWithRules();

    var localResults = rows.map((row) {
      final course = Course(
        id: row['course_id'] as int,
        code: row['course_code'] as String,
        name: row['course_name'] as String,
        category: row['course_category'] as String,
        description: row['course_description'] as String,
        isPaid: row['course_is_paid'] == true || row['course_is_paid'] == 1,
      );

      final minMath = row['min_math'] as int;
      final minScience = row['min_science'] as int;
      final minEnglish = row['min_english'] as int;
      final weightMath = (row['weight_math'] as num).toDouble();
      final weightScience = (row['weight_science'] as num).toDouble();
      final weightEnglish = (row['weight_english'] as num).toDouble();
      final preferredInterest = row['preferred_interest'] as String;
      final (interestBonus, interestMatched) = _interestSignal(
        course: course,
        preferredInterest: preferredInterest,
        input: input,
      );

      final weightedAverage = _weightedAcademicScore(
        input.mathGrade,
        input.scienceGrade,
        input.englishGrade,
        weightMath,
        weightScience,
        weightEnglish,
      );

      final readinessPenalty = _shortfallPenalty(input.mathGrade, minMath) +
          _shortfallPenalty(input.scienceGrade, minScience) +
          _shortfallPenalty(input.englishGrade, minEnglish);

      final saseAdjustment = _saseAdjustment(course.code, input.cetScore);
      final supplementalSubjectBonus =
          _supplementalSubjectBonus(course.category, input);
      final overallAcademicBonus = _overallAcademicBonus(input);
      final strandBonus = _strandBonus(course.code, input.strand);
      final technicalReadinessAdjustment =
          _technicalReadinessAdjustment(course.code, input);
      final profileBonus = _profileBonus(
        category: course.category,
        strengths: input.strengths,
        skills: input.skills,
      );
      final profilePenalty = _weaknessPenalty(
        category: course.category,
        weaknesses: input.weaknesses,
      );

      final rawScore = weightedAverage -
          readinessPenalty +
          interestBonus +
          saseAdjustment +
          supplementalSubjectBonus +
          overallAcademicBonus +
          strandBonus +
          technicalReadinessAdjustment +
          profileBonus -
          profilePenalty;
      final score = _normalizeLocalScore(rawScore);

      return RecommendationResult(
        course: course,
        score: score,
        interestMatched: interestMatched,
      );
    }).toList();

    localResults.sort((a, b) => b.score.compareTo(a.score));
    localResults = _ensureDistinctDisplayedScores(localResults);

    _lastGenerationUsedAi = false;
    _lastAiError = null;
    if (!_aiService.isConfigured) {
      return localResults;
    }

    try {
      final aiRecommendations = await _aiService.rankCourses(
        studentProfile: _studentProfileForAi(input),
        courses: _coursesForAi(rows, localResults),
      );
      final localByCode = {
        for (final result in localResults) result.course.code: result,
      };
      final aiByCode = <String, AiCourseRecommendation>{};

      for (final recommendation in aiRecommendations) {
        final localResult = localByCode[recommendation.courseCode];
        if (localResult == null ||
            aiByCode.containsKey(recommendation.courseCode)) {
          continue;
        }
        aiByCode[recommendation.courseCode] = recommendation;
      }

      if (aiByCode.isEmpty) {
        throw const GroqRecommendationException(
          'Groq did not return a recognized course.',
        );
      }

      final hybridResults = localResults.map((localResult) {
        final ai = aiByCode[localResult.course.code];
        if (ai == null) {
          return localResult;
        }

        return RecommendationResult(
          course: localResult.course,
          score: _clampScore(
            (localResult.score * _localScoreWeight) +
                (ai.score * _aiScoreWeight),
          ),
          // Interest matching is derived from the submitted ratings and course
          // rules, so it is more reliable than a generated boolean.
          interestMatched: localResult.interestMatched,
          reasons: ai.reasons,
          improvements: ai.improvements,
          aiGenerated: true,
        );
      }).toList();
      hybridResults.sort((a, b) => b.score.compareTo(a.score));

      _lastGenerationUsedAi = true;
      return _ensureDistinctDisplayedScores(hybridResults);
    } on Object catch (error) {
      _lastAiError = error.toString();
      return localResults;
    }
  }

  Map<String, Object?> _studentProfileForAi(RecommendationInput input) {
    return {
      'strand': input.strand,
      'grades': {
        'math': input.mathGrade,
        'science': input.scienceGrade,
        'english': input.englishGrade,
        'ict': input.ictGrade,
        'filipino': input.filipinoGrade,
        'social_science': input.socialScienceGrade,
      },
      'sase_score': input.cetScore,
      'primary_interest': input.interest,
      'interest_ratings': input.interestRatings,
      'strengths': input.strengths,
      'skills': input.skills,
      'weaknesses': input.weaknesses,
    };
  }

  List<Map<String, Object?>> _coursesForAi(
    List<Map<String, Object?>> rows,
    List<RecommendationResult> localResults,
  ) {
    final baselineScores = {
      for (final result in localResults)
        result.course.code: double.parse(result.score.toStringAsFixed(2)),
    };

    return rows.map((row) {
      final code = row['course_code'] as String;
      return <String, Object?>{
        'code': code,
        'name': row['course_name'],
        'category': row['course_category'],
        'description': row['course_description'],
        'minimum_grades': {
          'math': row['min_math'],
          'science': row['min_science'],
          'english': row['min_english'],
        },
        'preferred_interest': row['preferred_interest'],
        'preferred_strands': _coursePreferredStrands[code] ?? const [],
        'sase_target': _courseSaseTargets[code] ?? 75,
        'local_baseline_score': baselineScores[code],
      };
    }).toList();
  }

  Future<List<Course>> fetchCourses() => _database.fetchCourses();

  Future<List<RecommendationHistory>> fetchHistory() =>
      _database.fetchHistory();

  Future<void> deleteHistoryById(int id) => _database.deleteHistoryById(id);

  Future<void> saveRecommendationSession({
    required RecommendationInput input,
    required List<RecommendationResult> results,
    int? replaceHistoryId,
  }) async {
    final history = RecommendationHistory(
      id: replaceHistoryId,
      createdAt: DateTime.now(),
      studentName: input.studentName,
      age: input.age,
      school: input.school,
      examYear: input.examYear,
      strand: input.strand,
      mathGrade: input.mathGrade,
      scienceGrade: input.scienceGrade,
      englishGrade: input.englishGrade,
      ictGrade: input.ictGrade,
      filipinoGrade: input.filipinoGrade,
      socialScienceGrade: input.socialScienceGrade,
      cetScore: input.cetScore,
      interest: input.interest,
      interestRatings: input.interestRatings,
      strengths: input.strengths,
      skills: input.skills,
      weaknesses: input.weaknesses,
      results: results.take(5).toList(),
    );

    if (replaceHistoryId == null) {
      await _database.insertHistory(history);
    } else {
      await _database.updateHistory(history);
    }
  }

  double _weightedAcademicScore(
    int math,
    int science,
    int english,
    double weightMath,
    double weightScience,
    double weightEnglish,
  ) {
    final totalWeight = weightMath + weightScience + weightEnglish;
    if (totalWeight == 0) {
      return 0;
    }

    return ((math * weightMath) +
            (science * weightScience) +
            (english * weightEnglish)) /
        totalWeight;
  }

  (double, bool) _interestSignal({
    required Course course,
    required String preferredInterest,
    required RecommendationInput input,
  }) {
    final signalKeys = <String>{preferredInterest};
    if (input.interestRatings.containsKey(course.category)) {
      signalKeys.add(course.category);
    }

    final ratings = signalKeys
        .map((key) => (input.interestRatings[key] ?? 3).clamp(1, 5))
        .toList();
    final strongest = ratings.reduce((a, b) => a > b ? a : b).toDouble();
    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    final topMatchBonus = input.interest == preferredInterest ? 2.0 : 0.0;
    final bonus =
        ((strongest - 3.0) * 4.0) + ((average - 3.0) * 2.0) + topMatchBonus;

    return (bonus, strongest >= 4 || input.interest == preferredInterest);
  }

  double _shortfallPenalty(int grade, int minRequired) {
    final deficit = minRequired - grade;
    if (deficit <= 0) {
      return 0;
    }

    return deficit * 0.7;
  }

  double _profileBonus({
    required String category,
    required List<String> strengths,
    required List<String> skills,
  }) {
    final preferredStrengths =
        _categoryStrengthFit[category] ?? const <String>[];
    final preferredSkills = _categorySkillFit[category] ?? const <String>[];

    final matchedStrengths =
        strengths.where(preferredStrengths.contains).length;
    final matchedSkills = skills.where(preferredSkills.contains).length;

    return (matchedStrengths * 2.0) + (matchedSkills * 2.0);
  }

  double _weaknessPenalty({
    required String category,
    required List<String> weaknesses,
  }) {
    final riskWeaknesses = _categoryWeaknessRisk[category] ?? const <String>[];
    final matchedWeaknesses = weaknesses.where(riskWeaknesses.contains).length;
    return matchedWeaknesses * 2.5;
  }

  double _saseAdjustment(String courseCode, int? cetScore) {
    if (cetScore == null) {
      return 0;
    }

    final target = _courseSaseTargets[courseCode] ?? 75;
    final adjustment = (cetScore - target) * 0.20;
    return adjustment.clamp(-6.0, 6.0);
  }

  double _supplementalSubjectBonus(
    String category,
    RecommendationInput input,
  ) {
    final weights = _categorySupplementalSubjectFit[category];
    if (weights == null || weights.isEmpty) {
      return 0;
    }

    var weightedSum = 0.0;
    var totalWeight = 0.0;
    for (final entry in weights.entries) {
      weightedSum += _subjectScore(entry.key, input) * entry.value;
      totalWeight += entry.value;
    }

    if (totalWeight == 0) {
      return 0;
    }

    final weightedAverage = weightedSum / totalWeight;
    return (weightedAverage - 75.0) * 0.18;
  }

  double _overallAcademicBonus(RecommendationInput input) {
    final average = (input.mathGrade +
            input.scienceGrade +
            input.englishGrade +
            input.ictGrade +
            input.filipinoGrade +
            input.socialScienceGrade) /
        6;
    return (average - 75.0) * 0.10;
  }

  double _technicalReadinessAdjustment(
    String courseCode,
    RecommendationInput input,
  ) {
    if (courseCode != 'BSCS' && courseCode != 'BSIT') {
      return 0;
    }

    var adjustment = 0.0;
    final techInterest = input.interestRatings['Technology'] ?? 3;
    final hasCodingSkill = input.skills.contains('Basic Coding');
    final hasProblemSolving = input.skills.contains('Problem Solving');

    if (techInterest <= 2) {
      adjustment -= courseCode == 'BSCS' ? 8.0 : 6.0;
    } else if (techInterest >= 4) {
      adjustment += 2.0;
    }

    if (!hasCodingSkill) {
      adjustment -= courseCode == 'BSCS' ? 7.0 : 5.0;
    } else {
      adjustment += 2.0;
    }

    if (!hasProblemSolving) {
      adjustment -= courseCode == 'BSCS' ? 5.0 : 3.0;
    } else if (courseCode == 'BSCS') {
      adjustment += 1.5;
    }

    if (input.ictGrade < 75) {
      adjustment -= courseCode == 'BSCS' ? 5.0 : 4.0;
    } else if (input.ictGrade >= 85) {
      adjustment += 2.0;
    }

    if (input.mathGrade < 80) {
      adjustment -= courseCode == 'BSCS' ? 4.0 : 2.0;
    } else if (courseCode == 'BSCS' && input.mathGrade >= 88) {
      adjustment += 1.5;
    }

    return adjustment;
  }

  double _strandBonus(String courseCode, String strand) {
    final normalized = _normalizeStrand(strand);
    if (normalized.isEmpty) {
      return 0;
    }

    final preferredStrands = _coursePreferredStrands[courseCode] ?? const [];
    if (preferredStrands.contains(normalized)) {
      return 8.0;
    }

    final relatedStrands = _relatedStrands(normalized);
    final hasRelatedMatch =
        preferredStrands.any((preferred) => relatedStrands.contains(preferred));
    if (hasRelatedMatch) {
      return 3.0;
    }

    if (normalized == 'GAS') {
      return 2.0;
    }

    return -2.0;
  }

  String _normalizeStrand(String strand) {
    final value = strand.trim().toUpperCase();
    if (value.contains('STEM')) {
      return 'STEM';
    }
    if (value.contains('ABM')) {
      return 'ABM';
    }
    if (value.contains('HUMSS')) {
      return 'HUMSS';
    }
    if (value.contains('GAS')) {
      return 'GAS';
    }
    if (value.contains('TVL') ||
        value.contains('ICT') ||
        value.contains('HE') ||
        value.contains('AFA') ||
        value.contains('INDUSTRIAL')) {
      return 'TVL';
    }
    return value;
  }

  Set<String> _relatedStrands(String strand) {
    switch (strand) {
      case 'STEM':
        return const {'TVL', 'GAS'};
      case 'ABM':
        return const {'GAS', 'HUMSS'};
      case 'HUMSS':
        return const {'GAS', 'ABM'};
      case 'TVL':
        return const {'STEM', 'GAS'};
      case 'GAS':
        return const {'STEM', 'ABM', 'HUMSS', 'TVL'};
      default:
        return const {};
    }
  }

  int _subjectScore(String key, RecommendationInput input) {
    switch (key) {
      case 'ict':
        return input.ictGrade;
      case 'filipino':
        return input.filipinoGrade;
      case 'social_science':
        return input.socialScienceGrade;
      default:
        return 75;
    }
  }

  double _clampScore(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 100;
    }
    return value;
  }

  double _normalizeLocalScore(double rawScore) {
    // Bonuses can legitimately push the raw compatibility score above 100.
    // Compress the upper range instead of clipping it so strong profiles keep
    // meaningful differences and do not produce several identical 100s.
    if (rawScore <= 75) {
      return _clampScore(rawScore);
    }
    return _clampScore(75 + ((rawScore - 75) * 0.55)).clamp(0, 99);
  }

  List<RecommendationResult> _ensureDistinctDisplayedScores(
    List<RecommendationResult> sortedResults,
  ) {
    var previousRoundedScore = 100;
    return sortedResults.map((result) {
      var roundedScore = result.score.round().clamp(0, 99);
      var adjustedScore = result.score;
      if (roundedScore >= previousRoundedScore) {
        roundedScore = (previousRoundedScore - 1).clamp(0, 99);
        adjustedScore = roundedScore.toDouble();
      }
      previousRoundedScore = roundedScore;

      if (adjustedScore == result.score) {
        return result;
      }
      return RecommendationResult(
        course: result.course,
        score: adjustedScore,
        interestMatched: result.interestMatched,
        reasons: result.reasons,
        improvements: result.improvements,
        aiGenerated: result.aiGenerated,
      );
    }).toList();
  }
}
