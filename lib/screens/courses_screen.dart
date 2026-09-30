import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_palette.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key, required this.engine});

  final RecommendationEngine engine;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<Course>> _coursesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _coursesFuture = widget.engine.fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load courses.'));
          }

          final courses = snapshot.data ?? const <Course>[];
          final filtered = _filterCourses(courses);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
            children: [
              Row(
                children: [
                  Text(
                    '${courses.length} courses',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_query.trim().isNotEmpty)
                    Text(
                      '${filtered.length} found',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search courses',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const _EmptyCatalog()
              else
                ...filtered.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _courseCard(course),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Course> _filterCourses(List<Course> courses) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      return course.name.toLowerCase().contains(query) ||
          course.code.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query) ||
          course.description.toLowerCase().contains(query);
    }).toList();
  }

  Widget _courseCard(Course course) {
    final accent = _categoryColor(course.category);

    final cardChild = Ink(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${course.code} • ${course.category}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, color: accent),
          ],
        ),
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showCourseDetails(context, course, accent),
      child: cardChild,
    );
  }

  void _showCourseDetails(BuildContext context, Course course, Color accent) {
    final bestFor = _bestForText(course.code);
    final careerPaths = _careerPaths(course.code);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppPalette.surface,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.82,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppPalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.school_rounded, color: accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    course.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(course.code)),
                      Chip(label: Text(course.category)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Course Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    course.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppPalette.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Best For',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bestFor,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppPalette.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Possible Career Paths',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: careerPaths
                        .map(
                          (path) => Chip(
                            label: Text(path),
                            backgroundColor: accent.withOpacity(0.10),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _categoryColor(String category) {
    final palette = <Color>[
      AppPalette.primary,
      AppPalette.secondary,
      const Color(0xFF4FA7B7),
      const Color(0xFF6BA7C9),
      const Color(0xFF3D8E9C),
      const Color(0xFF5A8EB8),
    ];

    final index = category.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
        palette.length;
    return palette[index];
  }

  String _bestForText(String code) {
    switch (code) {
      case 'BSAGRI':
        return 'Students who are interested in farming systems, food production, environmental sustainability, and hands-on field work.';
      case 'BSABM':
        return 'Students who want to combine entrepreneurship, management, and agriculture-related business opportunities.';
      case 'BSNUR':
        return 'Students who are compassionate, patient, and ready for clinical learning and direct healthcare service.';
      case 'BSBIO':
        return 'Students who enjoy science, laboratory work, observation, and understanding living systems in depth.';
      case 'BSMATH':
        return 'Students who are strong in logic, numbers, analysis, and solving abstract or real-world quantitative problems.';
      case 'BAELS':
        return 'Students who enjoy writing, speaking, language analysis, communication, and developing strong English skills.';
      case 'BAIS':
        return 'Students who want deeper understanding of Islamic teachings, culture, ethics, and community leadership.';
      case 'BAPOLS':
        return 'Students who are interested in government, law, public issues, leadership, and critical social analysis.';
      case 'BSBA':
        return 'Students who want a flexible business course focused on management, leadership, operations, and entrepreneurship.';
      case 'BSA':
        return 'Students who are detail-oriented, disciplined, and interested in finance, auditing, and accurate record keeping.';
      case 'BSIT':
        return 'Students who want practical technology skills in programming, support systems, networking, and digital solutions.';
      case 'BSCS':
        return 'Students who enjoy coding, algorithms, problem solving, and building software or intelligent systems.';
      case 'BSED':
        return 'Students who want to teach high school learners and develop strong classroom, lesson planning, and subject expertise.';
      case 'BEED':
        return 'Students who enjoy working with children and helping them build confidence in basic learning skills.';
      default:
        return 'Students who want to understand the course deeply and explore how it matches their interests and strengths.';
    }
  }

  List<String> _careerPaths(String code) {
    switch (code) {
      case 'BSAGRI':
        return const [
          'Farm Manager',
          'Agricultural Technician',
          'Agribusiness Officer',
          'Extension Worker',
        ];
      case 'BSABM':
        return const [
          'Business Manager',
          'Entrepreneur',
          'Marketing Staff',
          'Operations Coordinator',
        ];
      case 'BSNUR':
        return const [
          'Registered Nurse',
          'Community Health Worker',
          'Clinic Staff',
          'Hospital Care Provider',
        ];
      case 'BSBIO':
        return const [
          'Research Assistant',
          'Laboratory Analyst',
          'Environmental Staff',
          'Pre-Med Pathway',
        ];
      case 'BSMATH':
        return const [
          'Data Analyst',
          'Math Teacher',
          'Research Staff',
          'Financial Analyst',
        ];
      case 'BAELS':
        return const [
          'Writer',
          'Editor',
          'Language Instructor',
          'Communication Staff',
        ];
      case 'BAIS':
        return const [
          'Educator',
          'Community Leader',
          'Researcher',
          'Program Coordinator',
        ];
      case 'BAPOLS':
        return const [
          'Public Servant',
          'Policy Staff',
          'Legal Assistant',
          'Advocacy Worker',
        ];
      case 'BSBA':
        return const [
          'Manager',
          'Entrepreneur',
          'HR Staff',
          'Marketing Officer',
        ];
      case 'BSA':
        return const [
          'Accountant',
          'Auditor',
          'Bookkeeper',
          'Finance Staff',
        ];
      case 'BSIT':
        return const [
          'IT Support Specialist',
          'Web Developer',
          'System Administrator',
          'Database Staff',
        ];
      case 'BSCS':
        return const [
          'Software Developer',
          'Programmer',
          'QA Engineer',
          'Systems Analyst',
        ];
      case 'BSED':
        return const [
          'Secondary Teacher',
          'Academic Coordinator',
          'Tutor',
          'Education Staff',
        ];
      case 'BEED':
        return const [
          'Elementary Teacher',
          'Learning Facilitator',
          'Tutor',
          'School Program Staff',
        ];
      default:
        return const ['Teacher', 'Researcher', 'Coordinator', 'Specialist'];
    }
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: AppPalette.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No course matched your search.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Try a broader keyword or search by category or course code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
