import 'package:flutter/material.dart';

import '../models/recommendation_result.dart';
import '../theme/app_palette.dart';
import '../widgets/responsive_app_frame.dart';

class RecommendationResultsScreen extends StatelessWidget {
  const RecommendationResultsScreen({
    super.key,
    required this.studentName,
    required this.results,
    required this.saseScore,
    required this.topInterest,
    required this.improvementArea,
    this.aiAttempted = false,
    this.usedAi = false,
  });

  final String studentName;
  final List<RecommendationResult> results;
  final int saseScore;
  final String topInterest;
  final String improvementArea;
  final bool aiAttempted;
  final bool usedAi;

  @override
  Widget build(BuildContext context) {
    final topResults = results.take(5).toList();

    return ResponsiveAppFrame(
      title: 'Your Recommendations',
      subtitle: studentName,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: SafeArea(
        top: false,
        child: topResults.isEmpty
            ? const Center(child: Text('No recommendations found.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                children: [
                  if (aiAttempted) ...[
                    _aiStatusCard(),
                    const SizedBox(height: 8),
                  ],
                  _analysisSummary(),
                  const SizedBox(height: 8),
                  _recommendationsPanel(context, topResults),
                ],
              ),
      ),
    );
  }

  Widget _aiStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: usedAi ? const Color(0xFFEAF7F0) : AppPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(
            usedAi ? Icons.auto_awesome_rounded : Icons.cloud_off_rounded,
            color: usedAi ? AppPalette.success : AppPalette.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              usedAi ? 'Groq AI ranking used' : 'Local ranking used',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisSummary() {
    final saseEligible = saseScore >= 75;

    return Column(
      children: [
        _summaryCard(
          icon: Icons.check_circle_rounded,
          iconColor: AppPalette.success,
          background: const Color(0xFFEAF7F0),
          title: 'SASE Eligibility',
          value: saseEligible ? 'Eligible' : 'Needs Review',
        ),
        const SizedBox(height: 6),
        _summaryCard(
          icon: Icons.favorite_rounded,
          iconColor: AppPalette.danger,
          background: const Color(0xFFFFF0F3),
          title: 'Top Interest',
          value: topInterest,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required Color background,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationsPanel(
    BuildContext context,
    List<RecommendationResult> topResults,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Top course matches',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            ...topResults.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _recommendationCard(
                      context,
                      rank: entry.key + 1,
                      result: entry.value,
                      alternatives: topResults
                          .where((r) => r != entry.value)
                          .take(3)
                          .toList(),
                    ),
                  ),
                ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('View All Courses'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(
    BuildContext context, {
    required int rank,
    required RecommendationResult result,
    required List<RecommendationResult> alternatives,
  }) {
    final badgeColor = switch (rank) {
      1 => AppPalette.primary,
      2 => AppPalette.secondary,
      3 => const Color(0xFF4FA7B7),
      _ => const Color(0xFF6BA7C9),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showCourseDetail(context, result, alternatives),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.course.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${result.course.code} • ${result.course.category}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.score.round()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.primary,
                  ),
                ),
                const Text(
                  'MATCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseDetail(
    BuildContext context,
    RecommendationResult result,
    List<RecommendationResult> alternatives,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppPalette.surface,
      isScrollControlled: true,
      builder: (context) {
        final reasons = _buildReasons(result);
        final improvements = _buildImprovements(result);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.course.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: result.score / 100,
                            strokeWidth: 10,
                            backgroundColor: AppPalette.surfaceAlt,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              result.score >= 85
                                  ? AppPalette.primary
                                  : AppPalette.warning,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${result.score.round()}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.primary,
                              ),
                            ),
                            const Text(
                              'COMPATIBILITY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(result.course.code)),
                    Chip(label: Text(result.course.category)),
                    if (result.aiGenerated)
                      const Chip(
                        avatar: Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text('Groq AI'),
                      ),
                    Chip(
                      label: Text(
                        saseScore >= 75 ? 'SASE Eligible' : 'SASE Needs Review',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Why this course matches you',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _bulletRow(
                      icon: Icons.check_circle_rounded,
                      color: AppPalette.success,
                      text: reason,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Areas to Improve',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...improvements.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _bulletRow(
                      icon: Icons.warning_amber_rounded,
                      color: AppPalette.warning,
                      text: item,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (alternatives.isNotEmpty) ...[
                  const Text(
                    'Similar Courses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...alternatives.map(
                    (alternative) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppPalette.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(alternative.course.name)),
                            Text(
                              '${alternative.score.round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bulletRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _buildReasons(RecommendationResult result) {
    if (result.reasons.isNotEmpty) {
      return result.reasons;
    }

    final reasons = <String>[
      'Your profile aligns well with ${result.course.category}.',
      'Your current academic profile supports this program.',
      'The course is one of your strongest overall matches.',
    ];

    if (result.interestMatched) {
      reasons.insert(
          0, 'Your stated interest directly aligns with this course.');
    }

    return reasons;
  }

  List<String> _buildImprovements(RecommendationResult result) {
    if (result.improvements.isNotEmpty) {
      return result.improvements;
    }

    final improvements = <String>[
      improvementArea,
      'Continue improving communication and study habits.',
    ];

    if (!result.interestMatched) {
      improvements
          .add('Review whether this course matches your long-term interest.');
    }

    return improvements;
  }
}
