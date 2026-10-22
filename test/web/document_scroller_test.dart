@TestOn('browser')
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_address_bar/src/web/document_scroller.dart';
import 'package:web_address_bar/src/web/environment.dart';
import 'package:web_address_bar/web_address_bar.dart';

web.HTMLElement get _html => web.document.documentElement! as web.HTMLElement;
web.HTMLElement get _body => web.document.body!;

web.HTMLElement? _findSpacer() =>
    web.document.querySelector(DocumentScroller.spacerTagName)
        as web.HTMLElement?;

/// Everything [DocumentScroller] may touch, to compare before and after.
({String? html, String? body, int htmlChildren, num scrollTop}) _snapshot() => (
  html: _html.getAttribute('style'),
  body: _body.getAttribute('style'),
  htmlChildren: _html.children.length,
  scrollTop: web.document.scrollingElement!.scrollTop,
);

void main() {
  group('on Android', () {
    late DocumentScroller scroller;
    setUp(() => scroller = DocumentScroller(MobileOs.android));
    tearDown(() => scroller.dispose());

    test('lets the browser pan vertically and scroll the document', () {
      expect(_body.style.getPropertyValue('touch-action'), 'pan-y');
      expect(_body.style.getPropertyValue('overflow-y'), 'auto');
      expect(_html.style.getPropertyValue('scrollbar-width'), 'none');
      // `proximity` is the default strictness and is dropped when serialized.
      expect(_html.style.getPropertyValue('scroll-snap-type'), 'y');
    });

    test('adds a spacer one pixel past the collapsed-bar viewport', () {
      final web.HTMLElement spacer = _findSpacer()!;
      expect(spacer.parentElement, _html);
      expect(spacer.style.height, 'calc(100lvh + 1px)');
      final web.HTMLElement target =
          spacer.children.item(0)! as web.HTMLElement;
      expect(target.localName, DocumentScroller.snapTargetTagName);
      expect(target.style.top, '1px');
      expect(target.style.getPropertyValue('scroll-snap-align'), 'start');
    });

    test('gives the document overflow', () {
      final web.Element scroller = web.document.scrollingElement!;
      expect(scroller.scrollHeight, greaterThan(scroller.clientHeight));
    });

    test('keeps the app in place: <body> stays fixed', () {
      expect(web.window.getComputedStyle(_body).position, 'fixed');
    });
  });

  group('on iOS', () {
    late DocumentScroller scroller;
    setUp(() => scroller = DocumentScroller(MobileOs.iOS));
    tearDown(() => scroller.dispose());

    test('snaps mandatorily to the middle of a 10000px spacer', () {
      expect(_html.style.getPropertyValue('scroll-snap-type'), 'y mandatory');
      final web.HTMLElement spacer = _findSpacer()!;
      expect(spacer.style.height, '10000px');
      final web.HTMLElement target =
          spacer.children.item(0)! as web.HTMLElement;
      expect(target.style.top, '5000px');
    });
  });

  group('dispose', () {
    for (final MobileOs os in MobileOs.values) {
      test('restores the page exactly on ${os.name}', () {
        final before = _snapshot();

        DocumentScroller(os).dispose();

        expect(_snapshot(), before);
        expect(_findSpacer(), isNull);
      });
    }

    test('restores styles the page had set inline, with their priority', () {
      _html.style.setProperty('scroll-snap-type', 'x mandatory', 'important');
      addTearDown(() => _html.style.removeProperty('scroll-snap-type'));

      DocumentScroller(MobileOs.android).dispose();

      expect(_html.style.getPropertyValue('scroll-snap-type'), 'x mandatory');
      expect(_html.style.getPropertyPriority('scroll-snap-type'), 'important');
    });
  });

  group('through WebAddressBar', () {
    tearDown(() {
      WebAddressBar.disable();
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('enable then disable leaves the page as it was', () {
      ui_web.browser.debugOperatingSystemOverride =
          ui_web.OperatingSystem.android;
      final before = _snapshot();

      WebAddressBar.enable();
      expect(WebAddressBar.isActive, isTrue);
      expect(_findSpacer(), isNotNull);
      WebAddressBar.disable();

      expect(_snapshot(), before);
    });

    test('changes nothing on desktop', () {
      ui_web.browser.debugOperatingSystemOverride =
          ui_web.OperatingSystem.macOs;
      final before = _snapshot();

      WebAddressBar.enable();

      expect(WebAddressBar.isActive, isFalse);
      expect(_snapshot(), before);
    });
  });
}
