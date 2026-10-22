@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_address_bar/src/web/controller.dart';
import 'package:web_address_bar/web_address_bar.dart';

// What the package assumes about the page the engine builds. When an engine
// change breaks one of these, this test says which assumption went.

web.HTMLElement get _body => web.document.body!;

List<String> _childNames(web.Element element) => <String>[
  for (int i = 0; i < element.children.length; i++)
    element.children.item(i)!.localName,
];

void main() {
  test('the implicit view is hosted by <body> in full-page mode', () {
    final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;
    expect(view, isNotNull);
    final JSAny? host = ui_web.views.getHostElement(view!.viewId);
    expect(host != null && host.strictEquals(_body).toDart, isTrue);
    expect(_body.getAttribute('flt-embedding'), 'full-page');
  });

  test('<body> holds <flutter-view flt-view-id> with the hosts the interceptor listens on', () {
    final int viewId = ui.PlatformDispatcher.instance.implicitView!.viewId;
    final web.Element? root = _body.querySelector(
      ':scope > flutter-view[flt-view-id="$viewId"]',
    );
    expect(root, isNotNull);
    expect(
      _childNames(root!),
      containsAll(<String>[
        'flt-glass-pane',
        'flt-text-editing-host',
        'flt-semantics-host',
      ]),
    );
  });

  test('the engine styles <body> the way the scroll setup overrides', () {
    final web.CSSStyleDeclaration style = web.window.getComputedStyle(_body);
    expect(style.getPropertyValue('touch-action'), 'none');
    expect(style.getPropertyValue('overflow-y'), 'hidden');
    expect(style.getPropertyValue('position'), 'fixed');
    expect(
      web.window
          .getComputedStyle(web.document.documentElement!)
          .getPropertyValue('overflow-y'),
      'visible',
    );
  });

  test('so enable takes effect on Android', () {
    ui_web.browser.debugOperatingSystemOverride =
        ui_web.OperatingSystem.android;
    addTearDown(() {
      WebAddressBar.disable();
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    WebAddressBar.enable();

    expect(
      WebAddressBar.isActive,
      isTrue,
      reason: WebAddressBarController.instance.debugLastUnsupported?.reason,
    );
  });
}
