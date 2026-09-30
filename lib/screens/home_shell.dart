import 'package:flutter/material.dart';

import '../services/recommendation_engine.dart';
import '../widgets/responsive_app_frame.dart';
import 'courses_screen.dart';
import 'recommend_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final RecommendationEngine _engine = RecommendationEngine();

  late final List<Widget> _pages;
  int _currentIndex = 0;

  static const _titles = ['Home', 'Courses'];
  static const List<String?> _subtitles = [
    null,
    'Browse courses',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      RecommendScreen(engine: _engine),
      CoursesScreen(engine: _engine),
    ];
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
        ],
      ),
    );
  }
}
