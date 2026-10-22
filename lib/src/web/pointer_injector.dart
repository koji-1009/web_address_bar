import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// What happened to a contact.
enum ContactChange {
  /// The finger touched down.
  down,

  /// The finger moved.
  move,

  /// The finger lifted.
  up,

  /// The browser gave up on the finger.
  cancel,
}

/// Hands a rebuilt touch contact to the engine as touch-type PointerEvents.
///
/// The engine's `PointerBinding` keeps converting them, so its click
/// debouncing, focus handling and semantics bookkeeping work as they do for the
/// browser's own events. The events are marked so that [isInjected] can tell
/// them apart from the browser's, which the interceptor withholds.
class PointerInjector {
  /// Creates an injector for the view rooted at [_root].
  PointerInjector(this._root);

  final web.HTMLElement _root;

  // A WeakSet, so that the marks never keep an event alive.
  final JSObject _injected = (globalContext['WeakSet']! as JSFunction)
      .callAsConstructor<JSObject>();

  static const Map<ContactChange, String> _types = <ContactChange, String>{
    ContactChange.down: 'pointerdown',
    ContactChange.move: 'pointermove',
    ContactChange.up: 'pointerup',
    ContactChange.cancel: 'pointercancel',
  };

  /// The pressure of a finger that is down, as reported by hardware that cannot
  /// measure pressure.
  static const double _fingerPressure = 0.5;

  /// Whether [event] is one this injector dispatched.
  bool isInjected(web.Event event) =>
      _injected.callMethod<JSBoolean>('has'.toJS, event).toDart;

  /// Dispatches the PointerEvent for [change] of the contact [device].
  ///
  /// [target] is the element the contact started on. The event goes to the
  /// element [dispatchTargetFor] picks for it.
  void inject(
    ContactChange change, {
    required int device,
    required double clientX,
    required double clientY,
    required web.EventTarget? target,
  }) {
    final bool isDown =
        change == ContactChange.down || change == ContactChange.move;
    // What PointerBinding reads, and `view`, without which the browser does not
    // compute `offsetX`/`offsetY`, the position PointerBinding takes, in CSS
    // pixels. A plain object rather than web.PointerEventInit, whose
    // clientX/clientY are typed `int` and would drop the fractional part a
    // touch carries.
    final JSObject init = JSObject()
      ..setProperty('bubbles'.toJS, true.toJS)
      ..setProperty('view'.toJS, web.window)
      ..setProperty('pointerId'.toJS, device.toJS)
      ..setProperty('pointerType'.toJS, 'touch'.toJS)
      ..setProperty('clientX'.toJS, clientX.toJS)
      ..setProperty('clientY'.toJS, clientY.toJS)
      ..setProperty('buttons'.toJS, (isDown ? 1 : 0).toJS)
      ..setProperty('pressure'.toJS, (isDown ? _fingerPressure : 0.0).toJS);
    final web.PointerEvent event = web.PointerEvent(
      _types[change]!,
      init as web.PointerEventInit,
    );
    _injected.callMethod<JSAny?>('add'.toJS, event);
    dispatchTargetFor(target).dispatchEvent(event);
  }

  /// Where the event for a contact that started on [target] is dispatched.
  ///
  /// * [target] when it is still in the view, so that the engine sees the
  ///   element the contact is on: the click debouncer and the semantics
  ///   placeholder key on it, and it decides how the event's position is
  ///   computed.
  /// * The view root when [target] has left the DOM, or is not in the view:
  ///   an event dispatched to a detached element never reaches the root and the
  ///   window, where `PointerBinding` listens.
  /// * `<flt-glass-pane>` for a contact in the contents of a platform view,
  ///   which received the browser's own events already and must not get a
  ///   second copy. The glass pane is not the view root, so the engine still
  ///   leaves the platform view's focus alone, and computes the same position.
  web.EventTarget dispatchTargetFor(web.EventTarget? target) {
    if (target == null || !target.isA<web.Node>()) {
      return _root;
    }
    final web.Node node = target as web.Node;
    if (!node.isConnected || !_root.contains(node)) {
      return _root;
    }
    web.Node? child = node;
    while (child != null && child.parentNode != _root) {
      child = child.parentNode;
    }
    if (child != null &&
        child != node &&
        child.isA<web.Element>() &&
        (child as web.Element).localName == 'flt-glass-pane') {
      return child;
    }
    return node;
  }
}
