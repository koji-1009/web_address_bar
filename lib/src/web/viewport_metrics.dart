import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'controller.dart';

/// The viewport heights [ViewportMetrics] works from, in CSS pixels.
typedef ViewportHeights = ({
  /// The viewport with the browser bars hidden, `100lvh`.
  double large,

  /// The viewport with the browser bars shown, `100svh`.
  double small,

  /// What is visible right now: the visual viewport, unzoomed.
  double visible,
});

/// What the browser bars cover of the large viewport, given [heights].
///
/// The bars cover at most the difference between the large and the small
/// viewport. A visible area shorter than the small viewport is the on-screen
/// keyboard, which is not counted. Heights that could not be measured (zero)
/// give zero: "the bar is not showing" rather than "the bar covers
/// everything".
double computeCollapsedExtent(ViewportHeights heights) {
  if (heights.large <= 0 || heights.small <= 0 || heights.visible <= 0) {
    return 0;
  }
  final double barHeight = math.max(0, heights.large - heights.small);
  return (heights.large - heights.visible).clamp(0, barHeight).toDouble();
}

/// Measures how much of the viewport the browser's own UI covers, for
/// `WebAddressBar.collapsedExtent`.
class ViewportMetrics implements SessionPart {
  /// Starts measuring.
  ViewportMetrics(this._controller) {
    _onResize = ((web.Event _) => _update()).toJS;
    _viewport.addEventListener('resize', _onResize);
    _update();
  }

  final WebAddressBarController _controller;
  final web.VisualViewport _viewport = web.window.visualViewport!;
  final web.HTMLElement _large = _createProbe('100lvh');
  final web.HTMLElement _small = _createProbe('100svh');
  late final JSFunction _onResize;

  /// Replaces the measured heights, for tests.
  @visibleForTesting
  static ViewportHeights Function()? debugHeightsOverride;

  static web.HTMLElement _createProbe(String height) {
    final web.HTMLElement probe =
        web.document.createElement('web-address-bar-probe') as web.HTMLElement;
    probe.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..width = '0'
      ..height = height
      ..visibility = 'hidden'
      ..pointerEvents = 'none';
    web.document.documentElement!.append(probe);
    return probe;
  }

  ViewportHeights _measure() =>
      debugHeightsOverride?.call() ??
      (
        large: _large.getBoundingClientRect().height,
        small: _small.getBoundingClientRect().height,
        visible: _viewport.height * _viewport.scale,
      );

  void _update() {
    _controller.collapsedExtent.value = computeCollapsedExtent(_measure());
  }

  @override
  void dispose() {
    _viewport.removeEventListener('resize', _onResize);
    _large.remove();
    _small.remove();
  }
}
