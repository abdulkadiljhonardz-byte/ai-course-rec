import 'package:flutter/material.dart';

import '../models/recommendation_history.dart';
import '../services/recommendation_engine.dart';
import '../widgets/responsive_app_frame.dart';
import 'courses_screen.dart';
import 'history_screen.dart';
import 'recommend_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final RecommendationEngine _engine = RecommendationEngine();
  final GlobalKey<HistoryScreenState> _historyKey =
      GlobalKey<HistoryScreenState>();

  late final List<Widget> _pages;
  int _currentIndex = 0;

  static const _titles = ['Home', 'Courses', 'Results'];
  static const List<String?> _subtitles = [
    null,
    'Browse courses',
    'Saved results',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildRecommendScreen(),
      CoursesScreen(engine: _engine),
      HistoryScreen(
        key: _historyKey,
        engine: _engine,
        onEdit: _editSavedStudent,
      ),
    ];
  }

  Widget _buildRecommendScreen({RecommendationHistory? history}) {
    return RecommendScreen(
      key: ValueKey(
        history == null
            ? 'new-recommendation'
            : 'edit-${history.id}-${history.createdAt.microsecondsSinceEpoch}',
      ),
      engine: _engine,
      initialHistory: history,
      onSaved: () {
        _historyKey.currentState?.reload();
      },
    );
  }

  void _editSavedStudent(RecommendationHistory history) {
    setState(() {
      _pages[0] = _buildRecommendScreen(history: history);
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAppFrame(
      title: _titles[_currentIndex],
      subtitle: _subtitles[_currentIndex],
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_rounded), label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded), label: 'Results'),
        ],
      ),
    );
  }
}
