import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Find Your Best-Fit Course',
      description:
          'Answer a guided set of steps so the app can compare your scores, interests, and strengths with the right degree options.',
      icon: Icons.explore_rounded,
      chips: ['SASE Ready', 'Grade-Based', 'Personal Fit'],
    ),
    _OnboardingData(
      title: 'Move Step by Step',
      description:
          'Complete student details, grades, and self-assessment in a simple wizard designed for quick and focused advising.',
      icon: Icons.format_list_numbered_rounded,
      chips: ['Student Info', 'Academic Grades', 'Assessments'],
    ),
    _OnboardingData(
      title: 'Review Ranked Results',
      description:
          'See your top recommendations, compare match percentages, and open detailed course insights before deciding.',
      icon: Icons.bar_chart_rounded,
      chips: ['Top Matches', 'Course Details', 'AI Insights'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Course Guide',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onFinished,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -150 && !lastPage) {
                      setState(() => _currentPage++);
                    } else if (velocity > 150 && _currentPage > 0) {
                      setState(() => _currentPage--);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _OnboardingPage(
                      key: ValueKey(_currentPage),
                      data: _pages[_currentPage],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _currentPage ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? AppPalette.primary
                            : AppPalette.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (lastPage) {
                        widget.onFinished();
                        return;
                      }

                      setState(() => _currentPage++);
                    },
                    child: Text(lastPage ? 'Start Now' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({super.key, required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.primary, AppPalette.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xF2FFFFFF),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.chips
                    .map(
                      (chip) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Text(
                          chip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.chips,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> chips;
}
