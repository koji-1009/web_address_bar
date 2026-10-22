@TestOn('browser')
library;

import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_address_bar/src/web/viewport_metrics.dart';
import 'package:web_address_bar/web_address_bar.dart';

/// Lets the engine's resize listener, which goes through an async stream, run
/// before the next test.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  group('computeCollapsedExtent', () {
    test('the bar showing covers the difference between the viewports', () {
      expect(
        computeCollapsedExtent((large: 800, small: 700, visible: 700)),
        100,
      );
    });

    test('partway through its animation', () {
      expect(
        computeCollapsedExtent((large: 800, small: 700, visible: 760)),
        40,
      );
    });

    test('the bar collapsed covers nothing', () {
      expect(computeCollapsedExtent((large: 800, small: 700, visible: 800)), 0);
    });

    test('the keyboard is not counted', () {
      expect(
        computeCollapsedExtent((large: 800, small: 700, visible: 400)),
        100,
      );
    });

    test('heights that cannot be measured read as no bar', () {
      expect(computeCollapsedExtent((large: 0, small: 0, visible: 0)), 0);
      expect(computeCollapsedExtent((large: 800, small: 700, visible: 0)), 0);
    });
  });

  group('through WebAddressBar', () {
    late ViewportHeights heights;

    setUp(() {
      heights = (large: 800, small: 700, visible: 700);
      ViewportMetrics.debugHeightsOverride = () => heights;
      ui_web.browser.debugOperatingSystemOverride =
          ui_web.OperatingSystem.android;
    });

    tearDown(() async {
      WebAddressBar.disable();
      ViewportMetrics.debugHeightsOverride = null;
      ui_web.browser.debugOperatingSystemOverride = null;
      await _settle();
    });

    test('collapsedExtent follows the viewport', () {
      // flutter_test fixes the view at a physical size that the real visual
      // viewport does not match, so the engine, which handles the resize
      // dispatched below too, would report negative insets and fail an
      // assertion. Let the engine measure the real viewport meanwhile. The
      // override is only on ui.window, which is how flutter_test sets it.
      // ignore: deprecated_member_use
      final ui.SingletonFlutterWindow window = ui.window;
      final ui.Size testSize = window.physicalSize;
      window.debugPhysicalSizeOverride = null;
      addTearDown(() => window.debugPhysicalSizeOverride = testSize);
      final List<double> values = <double>[];
      WebAddressBar.collapsedExtent.addListener(
        () => values.add(WebAddressBar.collapsedExtent.value),
      );

      WebAddressBar.enable();
      expect(WebAddressBar.collapsedExtent.value, 100);

      heights = (large: 800, small: 700, visible: 800);
      web.window.visualViewport!.dispatchEvent(web.Event('resize'));
      expect(WebAddressBar.collapsedExtent.value, 0);

      WebAddressBar.disable();
      expect(WebAddressBar.collapsedExtent.value, 0);
      expect(values, <double>[100, 0]);
    });
  });
}
