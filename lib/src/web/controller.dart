// The web implementation behind `WebAddressBar`, chosen by the conditional
// import in `../web_address_bar.dart`.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import '../web_address_bar.dart';
import 'document_scroller.dart';
import 'environment.dart';
import 'pointer_injector.dart';
import 'touch_input_source.dart';
import 'touch_interceptor.dart';
import 'viewport_metrics.dart';

/// See [WebAddressBar.enable].
void enable() => WebAddressBarController.instance.enable();

/// See [WebAddressBar.disable].
void disable() => WebAddressBarController.instance.disable();

/// See [WebAddressBar.isActive].
bool get isActive => WebAddressBarController.instance.isActive;

/// See [WebAddressBar.collapsedExtent].
ValueListenable<double> get collapsedExtent =>
    WebAddressBarController.instance.collapsedExtent;

/// Something [WebAddressBarController] sets up on [enable] and takes down on
/// [disable].
abstract interface class SessionPart {
  /// Undoes everything the part did.
  void dispose();
}

/// Owns everything `WebAddressBar.enable` puts on the page.
class WebAddressBarController {
  WebAddressBarController._();

  /// The one controller; there is one implicit view to take over.
  static final WebAddressBarController instance = WebAddressBarController._();

  /// The parts of the active session, in the order they were set up.
  List<SessionPart>? _parts;

  /// Whether a session is active.
  bool get isActive => _parts != null;

  /// See `WebAddressBar.collapsedExtent`.
  final ValueNotifier<double> collapsedExtent = ValueNotifier<double>(0);

  /// The environment of the last [enable] that did not take effect, for tests.
  @visibleForTesting
  UnsupportedEnvironment? debugLastUnsupported;

  /// Builds the [SessionPart]s of a session for a supported environment, in
  /// the order they are set up. Replaceable in tests.
  @visibleForTesting
  static List<SessionPart> Function(
    SupportedEnvironment environment,
    WebAddressBarController controller,
  )
  createParts = defaultCreateParts;

  /// The [createParts] used outside tests.
  static List<SessionPart> defaultCreateParts(
    SupportedEnvironment environment,
    WebAddressBarController controller,
  ) {
    final PointerInjector injector = PointerInjector(environment.root);
    return <SessionPart>[
      DocumentScroller(environment.os),
      // The interceptor goes up before the input source and comes down after
      // it, so that no touch is ever reported both ways: the input source
      // cancels the contacts still down while the browser's own events for
      // them are still withheld.
      TouchInterceptor(environment.root, injector),
      TouchInputSource(environment.root, injector),
      ViewportMetrics(controller),
    ];
  }

  /// The name of the global that holds the active session's teardown, so that
  /// a hot restart, which drops the Dart state but keeps the DOM, can take the
  /// previous session's changes off the page before starting a new one.
  static const String _hotRestartTeardownKey = r'$webAddressBarTeardown';

  /// See `WebAddressBar.enable`.
  void enable() {
    if (isActive) {
      return;
    }
    _tearDownPreviousRun();

    final EnvironmentCheck check = checkEnvironment();
    switch (check) {
      case UnsupportedEnvironment():
        debugLastUnsupported = check;
        assert(() {
          debugPrint('web_address_bar: not enabled: ${check.reason}');
          return true;
        }());
        return;
      case SupportedEnvironment():
        debugLastUnsupported = null;
        _parts = createParts(check, this);
        globalContext.setProperty(_hotRestartTeardownKey.toJS, disable.toJS);
    }
  }

  /// See `WebAddressBar.disable`.
  void disable() {
    final List<SessionPart>? parts = _parts;
    if (parts == null) {
      return;
    }
    _parts = null;
    for (final SessionPart part in parts.reversed) {
      part.dispose();
    }
    collapsedExtent.value = 0;
    globalContext.delete(_hotRestartTeardownKey.toJS);
  }

  void _tearDownPreviousRun() {
    final JSFunction? teardown = globalContext.getProperty<JSFunction?>(
      _hotRestartTeardownKey.toJS,
    );
    teardown?.callAsFunction();
  }
}
