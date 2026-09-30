import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/course.dart';
import '../models/recommendation_history.dart';
import 'app_database_contract.dart';
import 'seed_data.dart';

AppDatabase createAppDatabase() => _IoAppDatabase();

class _IoAppDatabase implements AppDatabase {
  static const _databaseName = 'ai_course_rec.db';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      join(dbPath, _databaseName),
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _syncCourseCatalog(db);
    await _syncCourseRules(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE course_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        min_math INTEGER NOT NULL,
        min_science INTEGER NOT NULL,
        min_english INTEGER NOT NULL,
        weight_math REAL NOT NULL,
        weight_science REAL NOT NULL,
        weight_english REAL NOT NULL,
        preferred_interest TEXT NOT NULL,
        FOREIGN KEY(course_id) REFERENCES courses(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recommendation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        student_name TEXT NOT NULL,
        age TEXT NOT NULL DEFAULT '',
        school TEXT NOT NULL DEFAULT '',
        exam_year TEXT NOT NULL DEFAULT '',
        strand TEXT NOT NULL DEFAULT '',
        math_grade INTEGER NOT NULL,
        science_grade INTEGER NOT NULL,
        english_grade INTEGER NOT NULL,
        ict_grade INTEGER NOT NULL DEFAULT 0,
        filipino_grade INTEGER NOT NULL DEFAULT 0,
        social_science_grade INTEGER NOT NULL DEFAULT 0,
        cet_score INTEGER,
        interest TEXT NOT NULL,
        interest_ratings_json TEXT NOT NULL DEFAULT '{}',
        strengths_json TEXT NOT NULL DEFAULT '[]',
        skills_json TEXT NOT NULL DEFAULT '[]',
        weaknesses_json TEXT NOT NULL DEFAULT '[]',
        results_json TEXT NOT NULL
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN strengths_json TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN skills_json TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN weaknesses_json TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN student_name TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE courses ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 0',
      );
      await _syncCourseCatalog(db);
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN age TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN school TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN exam_year TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN strand TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE recommendation_history ADD COLUMN ict_grade INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE recommendation_history ADD COLUMN filipino_grade INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE recommendation_history ADD COLUMN social_science_grade INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "ALTER TABLE recommendation_history ADD COLUMN interest_ratings_json TEXT NOT NULL DEFAULT '{}'",
      );
    }
    await _syncCourseRules(db);
  }

  Future<void> _seedDatabase(Database db) async {
    await db.transaction((txn) async {
      final courseIdsByCode = <String, int>{};

      for (final course in SeedData.courses) {
        final id = await txn.insert('courses', {
          'code': course.code,
          'name': course.name,
          'category': course.category,
          'description': course.description,
          'is_paid': course.isPaid ? 1 : 0,
        });

        courseIdsByCode[course.code] = id;
      }

      for (final rule in SeedData.rules) {
        final courseId = courseIdsByCode[rule.courseCode];
        if (courseId == null) {
          continue;
        }

        await txn.insert('course_rules', {
          'course_id': courseId,
          'min_math': rule.minMath,
          'min_science': rule.minScience,
          'min_english': rule.minEnglish,
          'weight_math': rule.weightMath,
          'weight_science': rule.weightScience,
          'weight_english': rule.weightEnglish,
          'preferred_interest': rule.preferredInterest,
        });
      }
    });
  }

  @override
  Future<List<Course>> fetchCourses() async {
    final db = await database;
    final rows = await db.query('courses', orderBy: 'name ASC');
    return rows.map(Course.fromMap).toList();
  }

  @override
  Future<List<Map<String, Object?>>> fetchCoursesWithRules() async {
    final db = await database;

    return db.rawQuery('''
      SELECT
        c.id AS course_id,
        c.code AS course_code,
        c.name AS course_name,
        c.category AS course_category,
        c.description AS course_description,
        c.is_paid AS course_is_paid,
        r.min_math,
        r.min_science,
        r.min_english,
        r.weight_math,
        r.weight_science,
        r.weight_english,
        r.preferred_interest
      FROM courses c
      INNER JOIN course_rules r ON c.id = r.course_id
      ORDER BY c.name ASC
    ''');
  }

  @override
  Future<void> insertHistory(RecommendationHistory history) async {
    final db = await database;
    final map = history.toMap()..remove('id');
    await db.insert('recommendation_history', map);
  }

  @override
  Future<void> updateHistory(RecommendationHistory history) async {
    final id = history.id;
    if (id == null) {
      throw ArgumentError('History ID is required when updating a session.');
    }

    final db = await database;
    final map = history.toMap()..remove('id');
    await db.update(
      'recommendation_history',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<RecommendationHistory>> fetchHistory() async {
    final db = await database;
    final rows =
        await db.query('recommendation_history', orderBy: 'created_at DESC');
    return rows.map(RecommendationHistory.fromMap).toList();
  }

  @override
  Future<void> deleteHistoryById(int id) async {
    final db = await database;
    await db.delete(
      'recommendation_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _syncCourseCatalog(Database db) async {
    final batch = db.batch();
    for (final course in SeedData.courses) {
      batch.update(
        'courses',
        {
          'name': course.name,
          'category': course.category,
          'description': course.description,
          'is_paid': course.isPaid ? 1 : 0,
        },
        where: 'code = ?',
        whereArgs: [course.code],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _syncCourseRules(Database db) async {
    final batch = db.batch();
    for (final rule in SeedData.rules) {
      batch.rawUpdate(
        '''
        UPDATE course_rules
        SET
          min_math = ?,
          min_science = ?,
          min_english = ?,
          weight_math = ?,
          weight_science = ?,
          weight_english = ?,
          preferred_interest = ?
        WHERE course_id = (SELECT id FROM courses WHERE code = ?)
        ''',
        [
          rule.minMath,
          rule.minScience,
          rule.minEnglish,
          rule.weightMath,
          rule.weightScience,
          rule.weightEnglish,
          rule.preferredInterest,
          rule.courseCode,
        ],
      );
    }
    await batch.commit(noResult: true);
  }
}
