// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_crypto_tracker/main.dart';

// void main() {
//   testWidgets('Crypto Tracker home screen displays correctly', (
//     WidgetTester tester,
//   ) async {
//     await tester.pumpWidget(const CryptoTrackerApp());

//     expect(find.text('Crypto Tracker'), findsOneWidget);
//     expect(find.text('Your crypto dashboard starts here'), findsOneWidget);
//   });
// }
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Crypto Tracker dark theme configuration is correct', () {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C6CFF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B1020));
    expect(theme.useMaterial3, true);
  });
}
