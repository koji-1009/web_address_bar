import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'controller.dart';
import 'pointer_injector.dart';

/// Rebuilds the touch input of the view from Touch Events and
/// `pointerrawupdate`, which keep reporting a finger after the browser has
/// cancelled its PointerEvents to scroll the document.
///
/// * A contact's lifetime, down to up or cancel, comes from Touch Events:
///   `pointerrawupdate` does not fire for the changes that come with a down or
///   an up.
/// * Movement comes from `pointerrawupdate` while exactly one finger is down,
///   because the browser throttles `touchmove` while it scrolls. A raw update
///   carries no id that matches a Touch, so with more than one finger down the
///   `touchmove`s, which do, take over. Safari does not implement
///   `pointerrawupdate`, and Chrome only fires it in a secure context; which
///   one applies is decided by what arrives.
/// * `touchmove`, `touchend` and `touchcancel` are taken on the element the
///   contact started on, not on the view root: they keep firing at that
///   element after it leaves the DOM, as the engine's semantics placeholder can
///   in the middle of a drag, but then no longer reach the root
///   (flutter/flutter#194104).
class TouchInputSource implements SessionPart {
  /// Starts rebuilding the touch input of the view rooted at [_root].
  TouchInputSource(this._root, this._injector) {
    _onTouchStart = ((web.Event event) => _translate(
      event as web.TouchEvent,
      ContactChange.down,
    )).toJS;
    _onTouchMove = ((web.Event event) => _translate(
      event as web.TouchEvent,
      ContactChange.move,
    )).toJS;
    _onTouchEnd = ((web.Event event) => _translate(
      event as web.TouchEvent,
      ContactChange.up,
    )).toJS;
    _onTouchCancel = ((web.Event event) => _translate(
      event as web.TouchEvent,
      ContactChange.cancel,
    )).toJS;
    _onRawUpdate = _translateRawUpdate.toJS;
    _root.addEventListener('touchstart', _onTouchStart, _passive);
    // On the window, where PointerBinding also takes moves in full-page mode.
    web.window.addEventListener('pointerrawupdate', _onRawUpdate, _passive);
  }

  final web.HTMLElement _root;
  final PointerInjector _injector;

  late final JSFunction _onTouchStart;
  late final JSFunction _onTouchMove;
  late final JSFunction _onTouchEnd;
  late final JSFunction _onTouchCancel;
  late final JSFunction _onRawUpdate;

  static final web.AddEventListenerOptions _passive =
      web.AddEventListenerOptions(passive: true);

  /// The contacts that are down, with the element each started on.
  final Map<int, web.EventTarget> _contacts = <int, web.EventTarget>{};

  /// The elements carrying the follow-up listeners, with how many contacts
  /// that started on each are still down.
  final Map<web.EventTarget, int> _listenedTargets = <web.EventTarget, int>{};

  /// The contact whose movement `pointerrawupdate` is reporting, which makes
  /// its next `touchmove` redundant.
  int? _rawUpdatedContact;

  /// Whether [dispose] has run, which it can in the middle of [_translate]:
  /// an injected event runs the framework's callbacks, such as `onTap`, which
  /// can call `WebAddressBar.disable`.
  bool _disposed = false;

  void _listenToTarget(web.EventTarget target) {
    final int count = _listenedTargets[target] ?? 0;
    _listenedTargets[target] = count + 1;
    if (count == 0) {
      target.addEventListener('touchmove', _onTouchMove, _passive);
      target.addEventListener('touchend', _onTouchEnd, _passive);
      target.addEventListener('touchcancel', _onTouchCancel, _passive);
    }
  }

  void _releaseTarget(web.EventTarget target) {
    final int count = _listenedTargets[target]! - 1;
    if (count > 0) {
      _listenedTargets[target] = count;
      return;
    }
    _listenedTargets.remove(target);
    _removeFollowUpListeners(target);
  }

  void _removeFollowUpListeners(web.EventTarget target) {
    target.removeEventListener('touchmove', _onTouchMove, _passive);
    target.removeEventListener('touchend', _onTouchEnd, _passive);
    target.removeEventListener('touchcancel', _onTouchCancel, _passive);
  }

  void _translateRawUpdate(web.Event event) {
    final web.PointerEvent pointerEvent = event as web.PointerEvent;
    if (pointerEvent.pointerType != 'touch' || _contacts.length != 1) {
      return;
    }
    final int device = _contacts.keys.first;
    _rawUpdatedContact = device;
    _injector.inject(
      ContactChange.move,
      device: device,
      clientX: _coordinate(pointerEvent, 'clientX'),
      clientY: _coordinate(pointerEvent, 'clientY'),
      target: _contacts[device],
    );
  }

  /// Reads a coordinate of a MouseEvent as the fractional number it is.
  ///
  /// `package:web` types MouseEvent's `clientX` and `clientY` as `int`, after
  /// their original IDL. A touch reports fractions, which dart2js lets through
  /// but dart2wasm rejects.
  static double _coordinate(web.MouseEvent event, String name) =>
      ((event as JSObject)[name]! as JSNumber).toDartDouble;

  void _translate(web.TouchEvent event, ContactChange change) {
    final web.TouchList touches = event.changedTouches;
    for (int i = 0; i < touches.length && !_disposed; i++) {
      final web.Touch touch = touches.item(i)!;
      final int device = touch.identifier;
      switch (change) {
        case ContactChange.down:
          if (_contacts.containsKey(device)) {
            continue;
          }
          _contacts[device] = touch.target;
          _listenToTarget(touch.target);
          if (_contacts.length > 1) {
            _rawUpdatedContact = null;
          }
        case ContactChange.move:
          if (!_contacts.containsKey(device)) {
            continue;
          }
          if (device == _rawUpdatedContact) {
            // Already reported by `pointerrawupdate`, with less latency.
            // Cleared as it is consumed, so that a gesture whose raw updates
            // stop coming falls back to the next `touchmove`.
            _rawUpdatedContact = null;
            continue;
          }
        case ContactChange.up:
        case ContactChange.cancel:
          if (!_contacts.containsKey(device)) {
            continue;
          }
          _rawUpdatedContact = null;
      }
      final bool lifting =
          change == ContactChange.up || change == ContactChange.cancel;
      final web.EventTarget target = lifting
          ? _contacts.remove(device)!
          : _contacts[device]!;
      _injector.inject(
        change,
        device: device,
        clientX: touch.clientX,
        clientY: touch.clientY,
        target: target,
      );
      if (lifting && !_disposed) {
        _releaseTarget(target);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _root.removeEventListener('touchstart', _onTouchStart, _passive);
    web.window.removeEventListener('pointerrawupdate', _onRawUpdate, _passive);
    // Cancel the touches still down, so that no pointer outlives the
    // translation. The engine puts a cancel at the pointer's last known
    // position, whatever position it is given.
    for (final MapEntry<int, web.EventTarget> contact in _contacts.entries) {
      _injector.inject(
        ContactChange.cancel,
        device: contact.key,
        clientX: 0,
        clientY: 0,
        target: contact.value,
      );
    }
    _contacts.clear();
    for (final web.EventTarget target in _listenedTargets.keys) {
      _removeFollowUpListeners(target);
    }
    _listenedTargets.clear();
    _rawUpdatedContact = null;
  }
}
