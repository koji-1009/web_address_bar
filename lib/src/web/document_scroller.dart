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
/// The spacer is 10000px tall and `scroll-snap-type: y mandatory` parks the
/// document in its middle, out of reach of pull-to-refresh and rubber-banding
/// at either end (`overscroll-behavior` does not prevent them on iOS). The
/// snap points differ per platform:
///
/// * Android: two, in the middle and 1px below it. Chrome scrolls the page some
///   way before it starts hiding its bar, so the range has to be long, and
///   after a scroll it shows the bar again if the page then moves back up. With
///   two points, a scroll comes to rest on the one in the direction it went.
/// * iOS: one, in the middle, which also cuts Safari's momentum scrolling
///   short.
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

    _setStyle(html, 'scroll-snap-type', 'y mandatory');
    spacer.style.height = '${spacerHeight}px';
    const int middle = spacerHeight ~/ 2;
    switch (os) {
      case MobileOs.android:
        spacer
          ..append(_createSnapTarget(middle))
          ..append(_createSnapTarget(middle + 1));
      case MobileOs.iOS:
        spacer.append(_createSnapTarget(middle));
    }

    html.append(spacer);
    _spacer = spacer;
  }

  /// The tag of the element that gives the document its overflow.
  static const String spacerTagName = 'web-address-bar-spacer';

  /// The tag of the element the document snaps to.
  static const String snapTargetTagName = 'web-address-bar-snap-target';

  /// The height of the spacer, in CSS pixels.
  static const int spacerHeight = 10000;

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
