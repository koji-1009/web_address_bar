import 'package:flutter/foundation.dart';

import 'stub/web_address_bar_stub.dart'
    if (dart.library.js_interop) 'web/controller.dart'
    as platform;

/// Lets the mobile browser address bar collapse in a full-page Flutter web
/// app, while scrolling stays in the app's own scroll views.
///
/// Flutter web turns off the browser's own touch handling for the page, so the
/// browser never sees a scroll and never collapses its address bar. [enable]
/// gives the document a scroll range for the browser to spend on the bar,
/// keeps that scroll from moving the app, and rebuilds the touch input the
/// browser takes away once it starts treating a vertical drag as a scroll.
///
/// It only takes effect in browsers on Android and iOS, and only when Flutter
/// owns the whole page (no `hostElement`, no multi-view). Everywhere else it
/// does nothing, including on platforms other than the web.
abstract final class WebAddressBar {
  /// Starts letting the address bar collapse.
  ///
  /// Can be called before or after `runApp`. Calling it again while active does
  /// nothing.
  ///
  /// Do not call it while a finger is on the screen, such as from `onTapDown`,
  /// `onPanStart` or `onLongPress`. A touch that started before [enable] is
  /// not translated, so on Android the framework never sees it end and keeps
  /// the pointer down until the page is reloaded. Callbacks that run once the
  /// finger has lifted, such as `onTap` and `onChanged`, are fine.
  ///
  /// Does nothing, and leaves [isActive] false, outside Android and iOS, when
  /// Flutter does not own the whole page, when the page structure is not the
  /// one this package was written against, or when the page already scrolls
  /// itself. The reason is printed in debug builds.
  static void enable() => platform.enable();

  /// Undoes everything [enable] did: the styles, the elements it added and the
  /// event listeners. Touches still down are cancelled.
  ///
  /// Does nothing if [isActive] is false.
  static void disable() => platform.disable();

  /// Whether [enable] took effect and [disable] has not been called since.
  static bool get isActive => platform.isActive;

  /// How much of the viewport the browser's own UI, such as the address bar
  /// and toolbars, covers right now, in logical pixels.
  ///
  /// Measured against the viewport with that UI hidden (`100lvh`), so it is the
  /// height of the bar while it shows and 0 once it has collapsed. The on-screen
  /// keyboard and pinch zoom are not counted. It is 0 while [isActive] is false
  /// and whenever it cannot be measured, which reads as "the bar is not
  /// showing" rather than "the bar covers everything".
  ///
  /// The engine resizes the Flutter view as the bar moves (on iOS, engines with
  /// flutter/flutter#193744), so the view does not extend under the bar and
  /// this is informational.
  static ValueListenable<double> get collapsedExtent =>
      platform.collapsedExtent;
}
