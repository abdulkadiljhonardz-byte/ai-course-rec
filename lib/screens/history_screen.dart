import 'package:flutter/material.dart';

import '../models/recommendation_history.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_palette.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.engine,
    this.onEdit,
  });

  final RecommendationEngine engine;
  final ValueChanged<RecommendationHistory>? onEdit;

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  late Future<List<RecommendationHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.engine.fetchHistory();
  }

  void reload() {
    setState(() {
      _historyFuture = widget.engine.fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<RecommendationHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load history.'));
          }

          final history = snapshot.data ?? const <RecommendationHistory>[];
          if (history.isEmpty) {
            return const _EmptyHistory();
          }

          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
              children: [
                Text(
                  '${history.length} saved ${history.length == 1 ? 'result' : 'results'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...history.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _historyCard(entry),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _historyCard(RecommendationHistory entry) {
    final topMatch = entry.results.isEmpty ? null : entry.results.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceAltSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _formatDate(entry.createdAt),
                    style: const TextStyle(
                      color: AppPalette.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onEdit != null)
                  IconButton(
                    tooltip: 'Edit student',
                    onPressed: () => widget.onEdit!(entry),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _onDeleteTap(entry),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.studentName.isEmpty ? 'Unnamed student' : entry.studentName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaChip('Math ${entry.mathGrade}'),
                _metaChip('Science ${entry.scienceGrade}'),
                _metaChip('English ${entry.englishGrade}'),
                if (entry.cetScore != null) _metaChip('CET ${entry.cetScore}'),
                _metaChip(entry.interest),
              ],
            ),
            if (topMatch != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top saved match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${topMatch.course.name} • ${topMatch.score.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (entry.strengths.isNotEmpty) ...[
              const SizedBox(height: 14),
              _detailLine('Strengths', entry.strengths.join(', ')),
            ],
            if (entry.skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailLine('Skills', entry.skills.join(', ')),
            ],
            if (entry.weaknesses.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailLine('Growth areas', entry.weaknesses.join(', ')),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.results
                  .take(3)
                  .map(
                    (result) => Chip(
                      label: Text(
                        '${result.course.code} ${result.score.toStringAsFixed(1)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppPalette.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _metaChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _onDeleteTap(RecommendationHistory entry) async {
    final id = entry.id;
    if (id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete saved session?'),
          content:
              const Text('This history entry will be removed permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.engine.deleteHistoryById(id);
    if (!mounted) {
      return;
    }
    reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History deleted.')),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $year • $hour:$minute';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  size: 44,
                  color: AppPalette.textSecondary,
                ),
                SizedBox(height: 12),
                Text(
                  'No saved sessions yet.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Generate a recommendation first and it will appear here automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.textSecondary,
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
