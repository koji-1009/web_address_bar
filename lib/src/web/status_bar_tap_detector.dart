import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' show VoidCallback;

import 'package:web/web.dart' as web;

import 'controller.dart';
import 'document_scroller.dart';

/// Tells a tap on the iOS status bar apart from the rest of the document's
/// scrolling, reports it to [_onTap], and puts the document back where
/// [DocumentScroller] parked it.
///
/// Safari answers a tap on the status bar by scrolling the document to the
/// top; no event names it as such. The document is parked in the middle of
/// [DocumentScroller]'s spacer, and a drag cannot take it more than a screen
/// or so from there, so a scroll that reaches the upper half of the way to the
/// top with no finger on the screen is taken for one. It is reported once, and
/// again only after the document has come back past that point.
///
/// Safari leaves the document at the top, out of the snapping's reach, which
/// would bring pull-to-refresh and rubber-banding back. Once the scroll has
/// settled, the document is moved back to the middle.
class StatusBarTapDetector implements SessionPart {
  /// Starts watching the document's scroll position.
  StatusBarTapDetector(this._onTap) {
    _onTouch = ((web.Event event) {
      _touching = (event as web.TouchEvent).touches.length > 0;
      if (!_touching && _reported) {
        _parkWhenSettled();
      }
    }).toJS;
    _onScroll = ((web.Event _) => _check()).toJS;
    for (final String type in _touchTypes) {
      web.window.addEventListener(type, _onTouch, _captureOptions);
    }
    web.window.addEventListener('scroll', _onScroll, _passiveOptions);
  }

  final VoidCallback _onTap;
  late final JSFunction _onTouch;
  late final JSFunction _onScroll;
  bool _touching = false;
  bool _reported = false;
  Timer? _settle;

  static const List<String> _touchTypes = <String>[
    'touchstart',
    'touchend',
    'touchcancel',
  ];

  static final web.AddEventListenerOptions _captureOptions =
      web.AddEventListenerOptions(capture: true, passive: true);
  static final web.AddEventListenerOptions _passiveOptions =
      web.AddEventListenerOptions(passive: true);

  /// The scroll position below which a scroll is taken for a status bar tap:
  /// half way from the middle of the spacer to the top.
  static const double threshold = DocumentScroller.spacerHeight / 4;

  /// How long the document has to stay still before it is moved back.
  static const Duration settleDelay = Duration(milliseconds: 150);

  void _check() {
    final double scrollTop = web.document.scrollingElement?.scrollTop ?? 0;
    if (_reported) {
      if (scrollTop >= threshold) {
        _reported = false;
        _settle?.cancel();
      } else {
        _parkWhenSettled();
      }
      return;
    }
    if (scrollTop >= threshold || _touching) {
      return;
    }
    _reported = true;
    _onTap();
    _parkWhenSettled();
  }

  void _parkWhenSettled() {
    _settle?.cancel();
    _settle = Timer(settleDelay, () {
      if (_touching) {
        return;
      }
      web.window.scrollTo(
        web.ScrollToOptions(
          top: DocumentScroller.spacerHeight / 2,
          behavior: 'instant',
        ),
      );
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    for (final String type in _touchTypes) {
      web.window.removeEventListener(type, _onTouch, _captureOptions);
    }
    web.window.removeEventListener('scroll', _onScroll, _passiveOptions);
  }
}
