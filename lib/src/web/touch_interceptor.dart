import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'controller.dart';
import 'pointer_injector.dart';

/// Keeps the browser's PointerEvents of a contact with the screen from the
/// engine's `PointerBinding`, which the rebuilt ones from [PointerInjector]
/// replace.
///
/// Under `touch-action: pan-y` the browser cancels a contact's PointerEvents
/// as soon as it takes a vertical drag over for scrolling, so they cannot carry
/// touch input. A contact is any touch, and a pen from the moment its tip or
/// eraser touches the screen until it lifts: a pen touching the screen fires
/// Touch Events too, which the rebuilt input is made from, so letting its
/// PointerEvents through would report it twice. A hovering pen fires no Touch
/// Events, so its hover moves, like mouse events, are left alone.
///
/// `PointerBinding` listens on the view root, in the bubble phase, and on the
/// window, and it registered its listeners before `main()` ran, so a listener
/// added to the root afterwards would run after it. The events are stopped
/// earlier on their path instead:
///
/// * On each child of the view root, in the bubble phase, for an event aimed
///   at an element inside the view. Its own listeners, those of platform views
///   and native text fields included, have had the event by then. The engine
///   adds all of the root's children before `main()` runs.
/// * On the window, in the capture phase, for an event aimed at the view root
///   itself. Nothing inside the view is on its path, and the capture phase on
///   the window comes before the root in every browser, which a capture
///   listener on the root itself would only do in browsers that run capturing
///   listeners first at the target.
class TouchInterceptor implements SessionPart {
  /// Starts withholding contact PointerEvents of the view rooted at [_root].
  TouchInterceptor(this._root, this._injector) {
    _onRootTarget = _interceptAtRoot.toJS;
    _onDescendantTarget = _interceptInView.toJS;
    for (final String type in _rootTypes) {
      web.window.addEventListener(type, _onRootTarget, _captureOptions);
    }
    final web.HTMLCollection children = _root.children;
    for (int i = 0; i < children.length; i++) {
      final web.Element child = children.item(i)!;
      _children.add(child);
      for (final String type in _descendantTypes) {
        child.addEventListener(type, _onDescendantTarget, _bubbleOptions);
      }
    }
  }

  /// The PointerEvents the rebuilt touch input replaces that bubble up to
  /// PointerBinding from inside the view.
  static const List<String> _descendantTypes = <String>[
    'pointerdown',
    'pointermove',
    'pointerup',
    'pointercancel',
  ];

  /// The same, and `pointerleave`, which does not bubble and only reaches
  /// PointerBinding when the root itself is left.
  static const List<String> _rootTypes = <String>[
    ..._descendantTypes,
    'pointerleave',
  ];

  final web.HTMLElement _root;
  final PointerInjector _injector;
  late final JSFunction _onRootTarget;
  late final JSFunction _onDescendantTarget;
  final List<web.Element> _children = <web.Element>[];

  /// The pens touching the screen, by pointer id.
  final Set<int> _penContacts = <int>{};

  /// The `buttons` bits of a pen touching the screen: the tip and the eraser.
  /// A barrel button pressed while hovering fires a `pointerdown` without
  /// them, and no Touch Events.
  static const int _penContactButtons = 1 | 32;

  static final web.AddEventListenerOptions _captureOptions =
      web.AddEventListenerOptions(capture: true, passive: false);
  static final web.AddEventListenerOptions _bubbleOptions =
      web.AddEventListenerOptions(passive: false);

  /// Whether [event] is a browser PointerEvent of a contact. Called once per
  /// event, as it keeps track of the pens touching the screen.
  bool _isBrowserContact(web.Event event) {
    if (!event.isA<web.PointerEvent>() || _injector.isInjected(event)) {
      return false;
    }
    final web.PointerEvent pointer = event as web.PointerEvent;
    switch (pointer.pointerType) {
      case 'touch':
        return true;
      case 'pen':
        final int id = pointer.pointerId;
        switch (pointer.type) {
          case 'pointerdown':
            if (pointer.buttons & _penContactButtons == 0) {
              return false;
            }
            _penContacts.add(id);
            return true;
          case 'pointerup' || 'pointercancel':
            return _penContacts.remove(id);
          default:
            return _penContacts.contains(id);
        }
      default:
        return false;
    }
  }

  void _interceptAtRoot(web.Event event) {
    if (event.target != _root || !_isBrowserContact(event)) {
      return;
    }
    if (event.type == 'pointerdown') {
      // What PointerBinding's pointerdown handler does for the root besides
      // converting the event: keep the browser from moving focus. The handler
      // still runs for the injected pointerdown and asks for the view's focus.
      event.preventDefault();
    }
    event.stopImmediatePropagation();
  }

  void _interceptInView(web.Event event) {
    if (_isBrowserContact(event)) {
      event.stopImmediatePropagation();
    }
  }

  @override
  void dispose() {
    for (final String type in _rootTypes) {
      web.window.removeEventListener(type, _onRootTarget, _captureOptions);
    }
    for (final web.Element child in _children) {
      for (final String type in _descendantTypes) {
        child.removeEventListener(type, _onDescendantTarget, _bubbleOptions);
      }
    }
    _children.clear();
    _penContacts.clear();
  }
}
