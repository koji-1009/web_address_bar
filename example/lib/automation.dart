import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// State the screens publish for `tool/example_cdp.mjs`, read back through
/// `window.$webAddressBarExample()`.
final Map<String, Object?> automationState = <String, Object?>{};

bool _exposed = false;

/// Merges [values] into [automationState] and makes sure it can be read.
void publishAutomationState(Map<String, Object?> values) {
  automationState.addAll(values);
  if (!_exposed) {
    _exposed = true;
    globalContext.setProperty(
      r'$webAddressBarExample'.toJS,
      (() => jsonEncode(automationState)).toJS,
    );
  }
}
