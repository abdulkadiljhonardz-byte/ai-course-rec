import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_course_rec/main.dart';

void main() {
  testWidgets('shows loading then an offline warning',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CourseRecommendationApp(connectionChecker: () async => false),
    );

    expect(find.text('Loading Course Guide...'), findsOneWidget);
    expect(find.text('Checking your internet connection'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Check your internet connection'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('app loads recommendation form', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      CourseRecommendationApp(connectionChecker: () async => true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Course Guide'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
  });
}
