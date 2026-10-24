// The implementation used on the web, where it hands everything to
// [WebAddressBarController].

import 'package:flutter/foundation.dart';

import '../web/controller.dart';
import '../web_address_bar.dart';

/// See [WebAddressBar.enable].
void enable(Set<TargetPlatform> platforms) =>
    WebAddressBarController.instance.enable(platforms);

/// See [WebAddressBar.disable].
void disable() => WebAddressBarController.instance.disable();

/// See [WebAddressBar.isActive].
bool get isActive => WebAddressBarController.instance.isActive;

/// See [WebAddressBar.collapsedExtent].
ValueListenable<double> get collapsedExtent =>
    WebAddressBarController.instance.collapsedExtent;

/// Taps on the iOS status bar.
Listenable get statusBarTaps => WebAddressBarController.instance.statusBarTaps;
