// The implementation used on every platform other than the web, where there is
// no browser address bar. Everything is a no-op.

import 'package:flutter/foundation.dart';

import '../web_address_bar.dart';

/// See [WebAddressBar.enable]. Does nothing.
void enable() {}

/// See [WebAddressBar.disable]. Does nothing.
void disable() {}

/// See [WebAddressBar.isActive]. Always false.
bool get isActive => false;

/// See [WebAddressBar.collapsedExtent]. Always 0.
final ValueListenable<double> collapsedExtent = ValueNotifier<double>(0);
