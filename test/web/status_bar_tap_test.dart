@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_address_bar/src/web/controller.dart';
import 'package:web_address_bar/src/web/document_scroller.dart';
import 'package:web_address_bar/src/web/environment.dart';
import 'package:web_address_bar/src/web/status_bar_tap_detector.dart';
import 'package:web_address_bar/web_address_bar.dart';

web.Element get _scroller => web.document.scrollingElement!;

/// Puts the document at [top] and tells the detector it scrolled.
void _scrollTo(double top) {
  _scroller.scrollTop = top;
  web.window.dispatchEvent(web.Event('scroll'));
}

void _dispatchTouch(String type, {required bool fingerDown}) {
  final JSObject init = JSObject()
    ..setProperty('bubbles'.toJS, true.toJS)
    ..setProperty(
      'touches'.toJS,
      <web.Touch>[
        if (fingerDown)
          web.Touch(
            (JSObject()
                  ..setProperty('identifier'.toJS, 1.toJS)
                  ..setProperty('target'.toJS, web.document.body))
                as web.TouchInit,
          ),
      ].toJS,
    );
  web.document.body!.dispatchEvent(
    web.TouchEvent(type, init as web.TouchEventInit),
  );
}

void main() {
  group('StatusBarTapDetector', () {
    late DocumentScroller scroller;
    late StatusBarTapDetector detector;
    late int taps;

    setUp(() {
      taps = 0;
      scroller = DocumentScroller(MobileOs.iOS);
      // Without snapping, so that the test can put the document anywhere.
      (web.document.documentElement! as web.HTMLElement).style.setProperty(
        'scroll-snap-type',
        'none',
      );
      _scrollTo(DocumentScroller.spacerHeight / 2);
      detector = StatusBarTapDetector(() => taps++);
    });

    tearDown(() {
      detector.dispose();
      scroller.dispose();
    });

    test('a scroll toward the top with no finger down is a tap', () {
      _scrollTo(100);

      expect(taps, 1);
    });

    test('is reported once per trip to the top', () {
      _scrollTo(100);
      _scrollTo(0);
      expect(taps, 1);

      _scrollTo(DocumentScroller.spacerHeight / 2);
      _scrollTo(0);
      expect(taps, 2);
    });

    test('puts the document back in the middle once it settles', () async {
      _scrollTo(0);
      expect(_scroller.scrollTop, 0);

      await Future<void>.delayed(
        StatusBarTapDetector.settleDelay + const Duration(milliseconds: 100),
      );

      expect(_scroller.scrollTop, DocumentScroller.spacerHeight / 2);
    });

    test('a scroll that stays around the middle is not', () {
      _scrollTo(DocumentScroller.spacerHeight / 2 - 900);

      expect(taps, 0);
    });

    test('a scroll with a finger down is not', () {
      _dispatchTouch('touchstart', fingerDown: true);
      _scrollTo(100);
      expect(taps, 0);

      _dispatchTouch('touchend', fingerDown: false);
      _scrollTo(50);
      expect(taps, 1);
    });

    test('stops after dispose', () {
      detector.dispose();
      _scrollTo(100);

      expect(taps, 0);
      detector = StatusBarTapDetector(() {});
    });
  });

  group('WebAddressBarScrollToTop', () {
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

    Widget page(String name) => ListView.builder(
      key: ValueKey<String>(name),
      primary: true,
      itemExtent: 100,
      itemBuilder: (BuildContext context, int index) => Text('$name $index'),
    );

    /// The scroll offset of the page called [name], on screen or not.
    double offsetOf(WidgetTester tester, String name) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(ValueKey<String>(name), skipOffstage: false),
            matching: find.byType(Scrollable, skipOffstage: false),
          ),
        )
        .position
        .pixels;

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          navigatorKey: navigator,
          color: const Color(0xFF000000),
          builder: (BuildContext context, Widget? child) =>
              WebAddressBarScrollToTop(child: child!),
          pageRouteBuilder:
              <T>(RouteSettings settings, WidgetBuilder builder) =>
                  PageRouteBuilder<T>(
                    settings: settings,
                    pageBuilder: (BuildContext context, _, _) =>
                        builder(context),
                  ),
          home: page('first'),
        ),
      );
    }

    testWidgets('scrolls the current route to the top on a tap', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tester.drag(
        find.byKey(const ValueKey<String>('first')),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      expect(offsetOf(tester, 'first'), greaterThan(0));

      WebAddressBarController.instance.statusBarTaps.notify();
      await tester.pumpAndSettle();

      expect(offsetOf(tester, 'first'), 0);
    });

    testWidgets('leaves the routes below the current one alone', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tester.drag(
        find.byKey(const ValueKey<String>('first')),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      final double firstOffset = offsetOf(tester, 'first');
      navigator.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder: (BuildContext context, _, _) => page('second'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey<String>('second')),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();

      WebAddressBarController.instance.statusBarTaps.notify();
      await tester.pumpAndSettle();

      expect(offsetOf(tester, 'second'), 0);
      expect(offsetOf(tester, 'first'), firstOffset);
    });

    testWidgets('stops listening when it is removed', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tester.pumpWidget(const SizedBox());

      WebAddressBarController.instance.statusBarTaps.notify();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
