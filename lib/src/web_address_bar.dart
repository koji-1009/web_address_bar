import 'package:flutter/foundation.dart';

import 'stub/web_address_bar_stub.dart'
    if (dart.library.js_interop) 'web/controller.dart'
    as platform;

/// Lets the mobile browser address bar collapse in a full-page Flutter web
/// app, while scrolling stays in the app's own scroll views.
///
/// Call [enable] once. It takes effect in browsers on Android and iOS when
/// Flutter owns the whole page (no `hostElement`, no multi-view), and does
/// nothing everywhere else, including on platforms other than the web.
abstract final class WebAddressBar {
  /// Starts letting the address bar collapse.
  ///
  /// Can be called before or after `runApp`. Calling it again while active does
  /// nothing, even with different [platforms]; call [disable] first.
  ///
  /// [platforms] are the operating systems whose browsers it takes effect in:
  /// [TargetPlatform.android], [TargetPlatform.iOS] (iPadOS included), or
  /// both, the default. Other platforms are not supported: desktop browsers do
  /// not collapse their toolbars on scroll.
  ///
  /// Do not call it while a finger is on the screen, such as from `onTapDown`,
  /// `onPanStart` or `onLongPress`. A touch that started before [enable] is
  /// not translated, so on Android the framework never sees it end and keeps
  /// the pointer down until the page is reloaded. Callbacks that run once the
  /// finger has lifted, such as `onTap` and the `onChanged` of a `Switch`, are
  /// fine; the `onChanged` of a `Slider` runs while the finger is down.
  ///
  /// Does nothing, and leaves [isActive] false, outside [platforms], when
  /// Flutter does not own the whole page, when the page structure is not the
  /// one this package was written against, or when the page already scrolls
  /// itself. The reason is printed in debug builds.
  static void enable({Set<TargetPlatform> platforms = supportedPlatforms}) {
    assert(
      supportedPlatforms.containsAll(platforms),
      'WebAddressBar supports ${supportedPlatforms.map((p) => p.name)} only, '
      'not ${platforms.difference(supportedPlatforms).map((p) => p.name)}',
    );
    platform.enable(platforms);
  }

  /// The platforms [enable] can take effect on, and its default.
  static const Set<TargetPlatform> supportedPlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

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
  /// height of the bar while it shows and 0 once it has collapsed. Pinch zoom
  /// is not counted. The on-screen keyboard is not counted either, but while it
  /// is up the bar cannot be told apart from it, and this is the bar's full
  /// height. It is 0 while [isActive] is false and whenever it cannot be
  /// measured, which reads as "the bar is not showing" rather than "the bar
  /// covers everything".
  ///
  /// The engine resizes the Flutter view as the bar moves (on iOS, engines with
  /// flutter/flutter#193744), so the view does not extend under the bar and
  /// this is informational.
  static ValueListenable<double> get collapsedExtent =>
      platform.collapsedExtent;
}
