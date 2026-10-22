import 'package:web/web.dart' as web;

import 'controller.dart';
import 'environment.dart';

/// Gives the document a scroll range for the browser to spend on its address
/// bar, without letting that scroll move the app.
///
/// `<body>`, which the engine has already made `position: fixed`, gets
/// `touch-action: pan-y` so that the browser treats a vertical drag as a
/// scroll, and stops hiding the overflow, which propagates to the viewport. A
/// spacer under `<html>` gives the document real overflow to scroll. The fixed
/// `<body>` keeps the app where it is while the document scrolls.
///
/// The scroll range differs per platform:
///
/// * Android: `scroll-snap-type: y proximity` and a spacer one pixel taller
///   than the viewport with the browser bars hidden (`100lvh`). Chrome does not
///   collapse the bar under `mandatory`, and a longer range would keep
///   scrolling the page after the bar is gone.
/// * iOS: `scroll-snap-type: y mandatory` and a 10000px spacer with its snap
///   point in the middle, which keeps pull-to-refresh and rubber-banding out of
///   reach (`overscroll-behavior` does not prevent them there) and cuts
///   Safari's momentum scrolling short.
///
/// [dispose] puts back every style it changed and removes the spacer, which
/// leaves the document nothing to be scrolled by.
class DocumentScroller implements SessionPart {
  /// Applies the scroll setup for [os].
  DocumentScroller(MobileOs os) {
    final web.HTMLElement body = web.document.body!;
    final web.HTMLElement html =
        web.document.documentElement! as web.HTMLElement;

    // Propagates to the viewport, undoing the engine's `overflow: hidden`.
    _setStyle(body, 'overflow-y', 'auto');
    _setStyle(body, 'touch-action', 'pan-y');
    _setStyle(html, 'scrollbar-width', 'none');

    final web.HTMLElement spacer =
        web.document.createElement(spacerTagName) as web.HTMLElement;
    spacer.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..width = '1px'
      ..pointerEvents = 'none'
      ..opacity = '0';

    switch (os) {
      case MobileOs.android:
        _setStyle(html, 'scroll-snap-type', 'y proximity');
        spacer.style.height = 'calc(100lvh + 1px)';
        spacer.append(_createSnapTarget(1));
      case MobileOs.iOS:
        _setStyle(html, 'scroll-snap-type', 'y mandatory');
        spacer.style.height = '${iOSSpacerHeight}px';
        spacer.append(_createSnapTarget(iOSSpacerHeight ~/ 2));
    }

    html.append(spacer);
    _spacer = spacer;
  }

  /// The tag of the element that gives the document its overflow.
  static const String spacerTagName = 'web-address-bar-spacer';

  /// The tag of the element the document snaps to.
  static const String snapTargetTagName = 'web-address-bar-snap-target';

  /// The height of the spacer on iOS, in CSS pixels.
  static const int iOSSpacerHeight = 10000;

  final List<
    ({web.HTMLElement element, String property, String value, String priority})
  >
  _saved =
      <
        ({
          web.HTMLElement element,
          String property,
          String value,
          String priority,
        })
      >[];

  web.HTMLElement? _spacer;

  void _setStyle(web.HTMLElement element, String property, String value) {
    final web.CSSStyleDeclaration style = element.style;
    _saved.add((
      element: element,
      property: property,
      value: style.getPropertyValue(property),
      priority: style.getPropertyPriority(property),
    ));
    style.setProperty(property, value);
  }

  web.HTMLElement _createSnapTarget(int topOffset) {
    final web.HTMLElement target =
        web.document.createElement(snapTargetTagName) as web.HTMLElement;
    target.style
      ..position = 'absolute'
      ..top = '${topOffset}px'
      ..left = '0'
      ..width = '1px'
      ..height = '1px'
      ..setProperty('scroll-snap-align', 'start');
    return target;
  }

  @override
  void dispose() {
    _spacer?.remove();
    _spacer = null;
    for (final saved in _saved.reversed) {
      if (saved.value.isEmpty) {
        saved.element.style.removeProperty(saved.property);
      } else {
        saved.element.style.setProperty(
          saved.property,
          saved.value,
          saved.priority,
        );
      }
    }
    _saved.clear();
  }
}
