import 'package:flutter/material.dart';

import '../services/internet_connection_service.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_palette.dart';
import 'recommendation_results_screen.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({
    super.key,
    required this.engine,
  });

  final RecommendationEngine engine;

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _schoolController = TextEditingController();
  final _saseController = TextEditingController();
  final _examYearController = TextEditingController();
  final _mathController = TextEditingController();
  final _englishController = TextEditingController();
  final _scienceController = TextEditingController();
  final _filipinoController = TextEditingController();
  String? _selectedStrand;

  static const List<String> _strandOptions = [
    'STEM',
    'ABM',
    'HUMSS',
    'GAS',
    'TVL',
  ];

  static const List<_InterestItem> _interestItems = [
    _InterestItem(
      label: 'Technology',
      icon: Icons.memory_rounded,
      engineInterest: 'Technology',
    ),
    _InterestItem(
      label: 'Health',
      icon: Icons.health_and_safety_rounded,
      engineInterest: 'Health',
    ),
    _InterestItem(
      label: 'Business',
      icon: Icons.storefront_rounded,
      engineInterest: 'Business',
    ),
    _InterestItem(
      label: 'Agriculture',
      icon: Icons.agriculture_rounded,
      engineInterest: 'Agriculture',
    ),
    _InterestItem(
      label: 'Language',
      icon: Icons.translate_rounded,
      engineInterest: 'Language',
    ),
    _InterestItem(
      label: 'Islamic',
      icon: Icons.menu_book_rounded,
      engineInterest: 'Islamic',
    ),
    _InterestItem(
      label: 'Education',
      icon: Icons.school_rounded,
      engineInterest: 'Education',
    ),
  ];

  static const Map<String, String> _basicStrengthQuestions = {
    'Do you enjoy solving problems?': 'Analytical Thinking',
    'Are you comfortable sharing your ideas?': 'Communication',
    'Do you like leading a group?': 'Leadership',
    'Do you enjoy creating new ideas?': 'Creativity',
  };

  static const Map<String, String> _basicWeaknessQuestions = {
    'Do you find Math difficult?': 'Math Difficulty',
    'Do you find Science difficult?': 'Science Difficulty',
    'Do you find English difficult?': 'English Difficulty',
    'Are you shy when speaking to a group?': 'Shyness',
    'Do you struggle with time management?': 'Time Management',
  };

  int _currentStep = 0;
  bool _loading = false;

  late final Map<String, int?> _interestRatings = {
    for (final item in _interestItems) item.label: 3,
  };
  late final Map<String, int?> _strengthQuestionRatings = {
    for (final value in _basicStrengthQuestions.values) value: 3,
  };
  late final Map<String, int?> _weaknessQuestionRatings = {
    for (final value in _basicWeaknessQuestions.values) value: 3,
  };

  static const _stepTitles = [
    'Student Information',
    'SASE Result',
    'Academic Grades',
    'Basic Interests',
    'Strengths & Weaknesses',
    'Summary',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    _saseController.dispose();
    _examYearController.dispose();
    _mathController.dispose();
    _englishController.dispose();
    _scienceController.dispose();
    _filipinoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _loading,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _wizardHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: _buildStepBody(),
                    ),
                  ),
                ),
                _actionBar(),
              ],
            ),
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x66000000),
              child: Center(
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(strokeWidth: 4),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing your profile...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Finding your best course matches',
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
          ),
      ],
    );
  }

  Widget _wizardHeader() {
    return Container(
      color: AppPalette.background,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: _loading ? null : _resetForm,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
              ),
            ],
          ),
          Row(
            children: List.generate(
              _stepTitles.length,
              (index) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index == _stepTitles.length - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppPalette.primary
                        : AppPalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppPalette.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    '${_currentStep + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
                      _stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _studentInfoStep();
      case 1:
        return _saseStep();
      case 2:
        return _gradesStep();
      case 3:
        return _interestsStep();
      case 4:
        return _strengthsAndWeaknessesStep();
      case 5:
        return _summaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _studentInfoStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _labeledField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              validator: _requiredText,
            ),
            const SizedBox(height: 10),
            _labeledField(
              controller: _ageController,
              label: 'Age',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: _requiredNumber,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedStrand,
              decoration: const InputDecoration(
                labelText: 'SHS Strand',
                prefixIcon: Icon(Icons.route_outlined),
              ),
              items: _strandOptions
                  .map(
                    (strand) => DropdownMenuItem(
                      value: strand,
                      child: Text(strand),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStrand = value;
                });
              },
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _labeledField(
              controller: _schoolController,
              label: 'School',
              icon: Icons.business_outlined,
              validator: _requiredText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _saseStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Enter Your SASE Result',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border),
              ),
              child: Column(
                children: [
                  _labeledField(
                    controller: _saseController,
                    label: 'SASE Rating / Score',
                    icon: Icons.assessment_outlined,
                    keyboardType: TextInputType.number,
                    validator: _scoreValidator,
                    centered: true,
                    valueStyle: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _labeledField(
                          controller: _examYearController,
                          label: 'Exam Year',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          validator: _requiredNumber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradesStep() {
    const lowGradeColor = Color(0xFFD32F2F);
    final subjects = [
      ('Mathematics', _mathController),
      ('English', _englishController),
      ('Science', _scienceController),
      ('Filipino', _filipinoController),
    ];
    final lowSubjects = subjects
        .where((subject) {
          final grade = _parse(subject.$2);
          return grade != null && grade < 75;
        })
        .map((subject) => subject.$1)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Enter Your Grades',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            ...subjects.map((subject) {
              final grade = _parse(subject.$2);
              final isLow = grade != null && grade < 75;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          subject.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isLow ? lowGradeColor : AppPalette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 118,
                      child: TextFormField(
                        controller: subject.$2,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isLow ? lowGradeColor : AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor:
                              isLow ? const Color(0xFFFFEBEE) : Colors.white,
                          helperText: isLow ? 'Below 75' : null,
                          helperStyle: const TextStyle(
                            color: lowGradeColor,
                            fontWeight: FontWeight.w700,
                          ),
                          suffixIcon: isLow
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  color: lowGradeColor,
                                  size: 20,
                                )
                              : null,
                          enabledBorder: isLow
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: lowGradeColor,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          focusedBorder: isLow
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: lowGradeColor,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        validator: _scoreValidator,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (lowSubjects.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: lowGradeColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: lowGradeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: ${lowSubjects.join(', ')} below 75. This may reduce course eligibility.',
                        style: const TextStyle(
                          color: lowGradeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _interestsStep() {
    return _ratingStepCard(
      title: 'Rate your interests',
      subtitle: 'Optional • 1 = Low, 5 = High • Default = 3',
      children: _interestItems
          .map(
            (item) => _ratingRow(
              icon: item.icon,
              label: item.label,
              value: _interestRatings[item.label],
              onChanged: (value) {
                setState(() {
                  _interestRatings[item.label] = value;
                });
              },
            ),
          )
          .toList(),
    );
  }

  Widget _strengthsAndWeaknessesStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Strengths',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            const Text(
              '1 = Not like me, 5 = Very much like me',
              style: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 8),
            ..._basicStrengthQuestions.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ratingRow(
                  icon: Icons.star_outline_rounded,
                  label: entry.key,
                  value: _strengthQuestionRatings[entry.value],
                  onChanged: (rating) {
                    setState(() {
                      _strengthQuestionRatings[entry.value] = rating;
                    });
                  },
                  multiLine: true,
                ),
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Weaknesses',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            const Text(
              '1 = Not difficult, 5 = Very difficult',
              style: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 8),
            ..._basicWeaknessQuestions.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ratingRow(
                  icon: Icons.warning_amber_rounded,
                  label: entry.key,
                  value: _weaknessQuestionRatings[entry.value],
                  onChanged: (rating) {
                    setState(() {
                      _weaknessQuestionRatings[entry.value] = rating;
                    });
                  },
                  multiLine: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingStepCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...children.expand((child) => [child, const SizedBox(height: 6)]),
          ],
        ),
      ),
    );
  }

  Widget _ratingRow({
    required IconData icon,
    required String label,
    required int? value,
    required ValueChanged<int> onChanged,
    bool multiLine = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: multiLine
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppPalette.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: multiLine ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (value == null) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select a score from 1 to 5.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppPalette.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              5,
              (index) {
                final score = index + 1;
                final selected = score == value;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(score),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppPalette.primary
                          : AppPalette.surfaceAltSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            selected ? AppPalette.primary : AppPalette.border,
                      ),
                    ),
                    child: Text(
                      '$score',
                      style: TextStyle(
                        color:
                            selected ? Colors.white : AppPalette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStep() {
    final eligibility = _saseScore >= 75;
    final topInterest = _topInterestLabel;

    return Column(
      children: [
        _summaryCard(
          icon: Icons.check_circle_rounded,
          iconColor: AppPalette.success,
          background: const Color(0xFFEAF7F0),
          title: 'SASE Eligibility',
          value: eligibility ? 'Eligible' : 'Needs Review',
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

  Widget _actionBar() {
    final lastStep = _currentStep == _stepTitles.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppPalette.border),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _loading ? null : (lastStep ? _generate : _nextStep),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(lastStep ? 'View Recommendations' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool centered = false,
    TextStyle? valueStyle,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: valueStyle,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: centered ? null : Icon(icon),
      ),
      validator: validator,
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        final fieldsValid = _validateFields([
          _fullNameController,
          _ageController,
          _schoolController,
        ]);
        if (!fieldsValid) {
          return false;
        }
        if (_selectedStrand?.isNotEmpty != true) {
          _showMessage('Select your SHS strand before moving on.');
          return false;
        }
        return true;
      case 1:
        return _validateScore(_saseController) &&
            _validateFields([_examYearController]);
      case 2:
        return _validateScore(_mathController) &&
            _validateScore(_englishController) &&
            _validateScore(_scienceController) &&
            _validateScore(_filipinoController);
      case 3:
        return true;
      default:
        return true;
    }
  }

  bool _validateFields(List<TextEditingController> controllers) {
    final hasEmpty =
        controllers.any((controller) => controller.text.trim().isEmpty);
    if (hasEmpty) {
      _showMessage('Complete the required fields before moving on.');
      return false;
    }
    return true;
  }

  bool _validateScore(TextEditingController controller) {
    final score = int.tryParse(controller.text.trim());
    if (score == null || score < 0 || score > 100) {
      _showMessage('Use a valid score from 0 to 100.');
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _requiredText(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _requiredNumber(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Required';
    }
    if (int.tryParse(value!.trim()) == null) {
      return 'Use number';
    }
    return null;
  }

  String? _scoreValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'Use number';
    }
    if (parsed < 0 || parsed > 100) {
      return 'Use 0-100';
    }
    return null;
  }

  int? _parse(TextEditingController controller) {
    return int.tryParse(controller.text.trim());
  }

  List<(String, int?)> _subjectEntries() {
    return [
      ('Mathematics', _parse(_mathController)),
      ('English', _parse(_englishController)),
      ('Science', _parse(_scienceController)),
      ('Filipino', _parse(_filipinoController)),
    ];
  }

  int get _saseScore => _parse(_saseController) ?? 0;

  String get _topInterestLabel {
    final interests = _aggregatedInterestRatings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return interests.isEmpty ? 'Not rated' : interests.first.key;
  }

  String get _improvementLabel {
    final subjects = _subjectEntries()
        .where((entry) => entry.$2 != null)
        .map((entry) => MapEntry(entry.$1, entry.$2!))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return subjects.isEmpty ? 'General preparation' : subjects.first.key;
  }

  RecommendationInput _buildInput() {
    final aggregatedInterestRatings = _aggregatedInterestRatings;
    final topInterest = aggregatedInterestRatings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strengths = _strengthQuestionRatings.entries
        .where((entry) => (entry.value ?? 3) >= 4)
        .map((entry) => entry.key)
        .toList();
    final weaknesses = _weaknessQuestionRatings.entries
        .where((entry) => (entry.value ?? 3) >= 4)
        .map((entry) => entry.key)
        .toSet();

    final math = _parse(_mathController) ?? 0;
    final science = _parse(_scienceController) ?? 0;
    final english = _parse(_englishController) ?? 0;
    final filipino = _parse(_filipinoController) ?? 0;
    if (math < 85) {
      weaknesses.add('Math Difficulty');
    }
    if (science < 85) {
      weaknesses.add('Science Difficulty');
    }
    if (english < 85) {
      weaknesses.add('English Difficulty');
    }

    return RecommendationInput(
      studentName: _fullNameController.text.trim(),
      age: _ageController.text.trim(),
      school: _schoolController.text.trim(),
      examYear: _examYearController.text.trim(),
      strand: _selectedStrand ?? '',
      mathGrade: math,
      scienceGrade: science,
      englishGrade: english,
      // ICT is no longer collected in the form. A neutral value preserves
      // compatibility with existing scoring and saved-history schemas without
      // rewarding or penalizing the student for an unavailable grade.
      ictGrade: 75,
      filipinoGrade: filipino,
      // Social Science is no longer collected in the form. Keep a neutral
      // internal value for compatibility with existing scoring/history data.
      socialScienceGrade: 75,
      cetScore: _parse(_saseController),
      interest: topInterest.isEmpty ? 'Technology' : topInterest.first.key,
      interestRatings: aggregatedInterestRatings,
      strengths: strengths,
      skills: const [],
      weaknesses: weaknesses.toList(),
    );
  }

  Map<String, int> get _aggregatedInterestRatings {
    final groupedRatings = <String, List<int>>{};
    for (final item in _interestItems) {
      final rating = _interestRatings[item.label] ?? 3;
      groupedRatings.putIfAbsent(item.engineInterest, () => <int>[]).add(
            rating,
          );
    }

    return {
      for (final entry in groupedRatings.entries)
        entry.key:
            (entry.value.reduce((a, b) => a + b) / entry.value.length).round(),
    };
  }

  void _resetForm() {
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();
    setState(() {
      _currentStep = 0;
      _fullNameController.clear();
      _ageController.clear();
      _schoolController.clear();
      _saseController.clear();
      _examYearController.clear();
      _mathController.clear();
      _englishController.clear();
      _scienceController.clear();
      _filipinoController.clear();
      _selectedStrand = null;
      for (final key in _interestRatings.keys) {
        _interestRatings[key] = 3;
      }
      for (final key in _strengthQuestionRatings.keys) {
        _strengthQuestionRatings[key] = 3;
      }
      for (final key in _weaknessQuestionRatings.keys) {
        _weaknessQuestionRatings[key] = 3;
      }
    });
  }

  Future<void> _generate() async {
    if (!_validateCurrentStep()) {
      return;
    }

    final input = _buildInput();

    setState(() {
      _loading = true;
    });

    try {
      final isOnlineBeforeGeneration = await hasInternetConnection();
      if (!isOnlineBeforeGeneration) {
        if (mounted) {
          _showMessage(
            'Check your internet connection before generating recommendations.',
          );
        }
        return;
      }

      final results = await widget.engine.generateRecommendations(input);

      final isOnlineAfterGeneration = await hasInternetConnection();
      if (!isOnlineAfterGeneration) {
        if (mounted) {
          _showMessage(
            'Internet connection lost. Please reconnect and try again.',
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecommendationResultsScreen(
            studentName: input.studentName,
            results: results,
            saseScore: input.cetScore ?? 0,
            topInterest: _topInterestLabel,
            improvementArea: _improvementLabel,
            aiAttempted: widget.engine.isAiConfigured,
            usedAi: widget.engine.lastGenerationUsedAi,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not generate recommendation.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _InterestItem {
  const _InterestItem({
    required this.label,
    required this.icon,
    required this.engineInterest,
  });

  final String label;
  final IconData icon;
  final String engineInterest;
}
