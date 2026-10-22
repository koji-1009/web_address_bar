import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// The mobile operating systems this package takes effect on.
enum MobileOs {
  /// Android.
  android,

  /// iOS and iPadOS.
  iOS,
}

/// The outcome of [checkEnvironment].
sealed class EnvironmentCheck {
  const EnvironmentCheck();
}

/// The page is one this package can take over.
final class SupportedEnvironment extends EnvironmentCheck {
  /// Creates a supported environment.
  const SupportedEnvironment({required this.os, required this.root});

  /// The operating system the browser runs on.
  final MobileOs os;

  /// The implicit view's root element, `<flutter-view>`.
  final web.HTMLElement root;
}

/// The page is not one this package can take over.
final class UnsupportedEnvironment extends EnvironmentCheck {
  /// Creates an unsupported environment with the [reason] for the debug log.
  const UnsupportedEnvironment(this.reason);

  /// Why, for the debug log.
  final String reason;
}

/// Decides whether `WebAddressBar.enable` can take effect on this page.
///
/// Checks, in order: the operating system, which has to be Android or iOS and
/// one of [platforms]; that Flutter owns the whole page
/// (an implicit view hosted by `<body>`, which rules out multi-view and a
/// custom `hostElement`); that the DOM has the shape this package was written
/// against; and that the page does not already let the browser scroll it,
/// which would mean another library, or a future engine, does the same job.
EnvironmentCheck checkEnvironment(Set<TargetPlatform> platforms) {
  final MobileOs os;
  final TargetPlatform platform;
  switch (ui_web.browser.operatingSystem) {
    case ui_web.OperatingSystem.android:
      os = MobileOs.android;
      platform = TargetPlatform.android;
    case ui_web.OperatingSystem.iOs:
      os = MobileOs.iOS;
      platform = TargetPlatform.iOS;
    case final ui_web.OperatingSystem other:
      return UnsupportedEnvironment(
        'not a mobile browser (operating system: ${other.name})',
      );
  }
  if (!platforms.contains(platform)) {
    return UnsupportedEnvironment('not enabled for ${platform.name}');
  }

  final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;
  if (view == null) {
    return const UnsupportedEnvironment('no implicit view (multi-view mode)');
  }
  final web.HTMLElement? body = web.document.body;
  final JSAny? host = ui_web.views.getHostElement(view.viewId);
  if (body == null || host == null || !host.strictEquals(body).toDart) {
    return const UnsupportedEnvironment(
      'Flutter is embedded in a host element, not the full page',
    );
  }
  final String? embedding = body.getAttribute('flt-embedding');
  if (embedding != 'full-page') {
    return UnsupportedEnvironment(
      'unexpected <body flt-embedding="$embedding">',
    );
  }

  final web.HTMLElement? root = findViewRoot(body, view.viewId);
  if (root == null) {
    return UnsupportedEnvironment(
      'no <flutter-view flt-view-id="${view.viewId}"> under <body>',
    );
  }

  final String? conflict = findPageScrollConflict();
  if (conflict != null) {
    return UnsupportedEnvironment('the page already scrolls itself: $conflict');
  }

  return SupportedEnvironment(os: os, root: root);
}

/// The `<flutter-view>` child of [body] for [viewId], if there is one.
web.HTMLElement? findViewRoot(web.HTMLElement body, int viewId) {
  final web.HTMLCollection children = body.children;
  for (int i = 0; i < children.length; i++) {
    final web.Element child = children.item(i)!;
    if (child.localName == 'flutter-view' &&
        child.getAttribute('flt-view-id') == '$viewId') {
      return child as web.HTMLElement;
    }
  }
  return null;
}

/// Describes what makes the page scroll in the browser already, or returns
/// null.
///
/// The engine gives `<body>` `touch-action: none` and `overflow: hidden`, and
/// leaves `<html>` and the document's height alone. Anything else means
/// something on the page has set it up for the browser to scroll.
String? findPageScrollConflict() {
  final web.HTMLElement body = web.document.body!;
  final web.Element html = web.document.documentElement!;
  final web.CSSStyleDeclaration bodyStyle = web.window.getComputedStyle(body);
  final web.CSSStyleDeclaration htmlStyle = web.window.getComputedStyle(html);

  final String touchAction = bodyStyle.getPropertyValue('touch-action');
  if (touchAction != 'none') {
    return '<body> has touch-action: $touchAction';
  }
  final String htmlOverflow = htmlStyle.getPropertyValue('overflow-y');
  if (htmlOverflow != 'visible') {
    return '<html> has overflow-y: $htmlOverflow';
  }
  final String bodyOverflow = bodyStyle.getPropertyValue('overflow-y');
  if (bodyOverflow != 'hidden') {
    return '<body> has overflow-y: $bodyOverflow';
  }
  final web.Element? scroller = web.document.scrollingElement;
  if (scroller != null && scroller.scrollHeight > scroller.clientHeight + 1) {
    return 'the document is ${scroller.scrollHeight}px tall in a '
        '${scroller.clientHeight}px viewport';
  }
  return null;
}
