@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web_address_bar_example/main.dart';
import 'package:web_address_bar_example/screens/basic_vertical_list.dart';
import 'package:web_address_bar_example/screens/collapsed_extent.dart';
import 'package:web_address_bar_example/screens/interactive_widgets.dart';
import 'package:web_address_bar_example/screens/long_drag.dart';
import 'package:web_address_bar_example/screens/nested_scroll.dart';
import 'package:web_address_bar_example/screens/tap_only.dart';

void main() {
  testWidgets('the menu opens every test screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WebScrollTestApp());

    for (final String title in <String>[
      BasicVerticalListTest.title,
      NestedScrollTest.title,
      InteractiveWidgetsTest.title,
      TapOnlyTest.title,
      CollapsedExtentTest.title,
      LongDragTest.title,
    ]) {
      await tester.scrollUntilVisible(find.text(title), 100);
      await tester.tap(find.text(title));
      // Not pumpAndSettle: the long drag screen refreshes on a timer.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BackButton), findsOneWidget, reason: title);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(title)),
        findsOneWidget,
        reason: title,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
