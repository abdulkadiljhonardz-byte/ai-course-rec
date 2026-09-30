import 'dart:async';

import 'package:flutter/material.dart';

import 'config/app_secrets.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/ai_recommendation_service.dart';
import 'services/internet_connection_service.dart';
import 'theme/app_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final secrets = await AppSecrets.load();
  GroqRecommendationService.configure(
    apiKey: secrets.groqApiKey,
    endpoint: secrets.groqApiUrl,
    model: secrets.groqModel,
  );
  runApp(const CourseRecommendationApp());
}

class CourseRecommendationApp extends StatelessWidget {
  const CourseRecommendationApp({
    super.key,
    this.connectionChecker,
  });

  final Future<bool> Function()? connectionChecker;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
      surface: AppPalette.surface,
      surfaceContainerHighest: AppPalette.surfaceAlt,
      outline: AppPalette.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.background,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Course Recommendation',
      theme: base.copyWith(
        textTheme: base.textTheme.copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppPalette.textPrimary,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppPalette.textPrimary,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppPalette.textPrimary,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: AppPalette.textSecondary,
            height: 1.35,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.background,
          foregroundColor: AppPalette.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          color: AppPalette.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          labelStyle: const TextStyle(color: AppPalette.textSecondary),
          hintStyle: const TextStyle(color: AppPalette.textSecondary),
          helperStyle: const TextStyle(color: AppPalette.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.primary, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: AppPalette.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.primary,
            side: const BorderSide(color: AppPalette.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: AppPalette.surfaceAlt,
          selectedColor: const Color(0xFFD7F0F7),
          side: const BorderSide(color: AppPalette.border),
          labelStyle: const TextStyle(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppPalette.surface,
          indicatorColor: const Color(0xFFBEE7F5),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppPalette.primary : AppPalette.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppPalette.primary : AppPalette.textSecondary,
            );
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppPalette.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: _StartupGate(
        connectionChecker: connectionChecker ?? hasInternetConnection,
      ),
    );
  }
}

enum _StartupStatus { checking, offline, online }

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.connectionChecker});

  final Future<bool> Function() connectionChecker;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  _StartupStatus _status = _StartupStatus.checking;
  Timer? _retryTimer;
  bool _checkInProgress = false;

  @override
  void initState() {
    super.initState();
    _checkConnection(minimumLoadingTime: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection({
    Duration minimumLoadingTime = Duration.zero,
  }) async {
    if (_checkInProgress) {
      return;
    }
    _checkInProgress = true;

    if (mounted && _status != _StartupStatus.checking) {
      setState(() {
        _status = _StartupStatus.checking;
      });
    }

    var isOnline = false;
    try {
      final results = await Future.wait([
        widget.connectionChecker(),
        Future<bool>.delayed(minimumLoadingTime, () => true),
      ]);
      isOnline = results.first;
    } on Object {
      isOnline = false;
    } finally {
      _checkInProgress = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _status = isOnline ? _StartupStatus.online : _StartupStatus.offline;
    });

    if (isOnline) {
      _retryTimer?.cancel();
      _retryTimer = null;
    } else {
      _startAutomaticRetry();
    }
  }

  void _startAutomaticRetry() {
    if (_retryTimer?.isActive ?? false) {
      return;
    }
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _StartupStatus.checking:
        return const _LoadingScreen();
      case _StartupStatus.offline:
        return _OfflineScreen(
          onRetry: () => _checkConnection(
            minimumLoadingTime: const Duration(milliseconds: 700),
          ),
        );
      case _StartupStatus.online:
        return const _AppEntryGate();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StartupIcon(
                  icon: Icons.school_rounded,
                  color: AppPalette.primary,
                ),
                SizedBox(height: 28),
                CircularProgressIndicator(),
                SizedBox(height: 18),
                Text(
                  'Loading Course Guide...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Checking your internet connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  const _OfflineScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StartupIcon(
                  icon: Icons.wifi_off_rounded,
                  color: AppPalette.danger,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Check your internet connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The app needs an internet connection to open and generate AI course recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
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

class _StartupIcon extends StatelessWidget {
  const _StartupIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 46, color: color),
    );
  }
}

class _AppEntryGate extends StatefulWidget {
  const _AppEntryGate();

  @override
  State<_AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<_AppEntryGate> {
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onFinished: () {
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    }

    return const HomeShell();
  }
}
