@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web_address_bar_example/main.dart';

void main() {
  testWidgets('the menu opens every test screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WebScrollTestApp());

    for (final String title in <String>[
      'Basic Vertical ListView',
      'Nested Scrollables',
      'Interactive Widgets',
      'Tap-Only Page (No Scroll)',
      'Collapsed Extent',
      'Long Drag (flutter/flutter#194104)',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 100);
      await tester.tap(find.text(title));
      // Not pumpAndSettle: the long drag screen refreshes on a timer.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BackButton), findsOneWidget, reason: title);
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
