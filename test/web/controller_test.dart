@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_address_bar/src/web/controller.dart';
import 'package:web_address_bar/src/web/environment.dart';
import 'package:web_address_bar/web_address_bar.dart';

class _RecordingPart implements SessionPart {
  _RecordingPart(this.log, this.name);

  final List<String> log;
  final String name;

  @override
  void dispose() => log.add('dispose $name');
}

void main() {
  final WebAddressBarController controller = WebAddressBarController.instance;
  final List<String> log = <String>[];
  final List<SupportedEnvironment> environments = <SupportedEnvironment>[];

  setUp(() {
    log.clear();
    environments.clear();
    WebAddressBarController.createParts =
        (SupportedEnvironment environment, _) {
          environments.add(environment);
          log.add('create');
          return <SessionPart>[
            _RecordingPart(log, 'first'),
            _RecordingPart(log, 'second'),
          ];
        };
  });

  tearDown(() {
    WebAddressBar.disable();
    ui_web.browser.debugOperatingSystemOverride = null;
  });

  group('environment', () {
    test('does nothing on desktop', () {
      ui_web.browser.debugOperatingSystemOverride =
          ui_web.OperatingSystem.macOs;

      WebAddressBar.enable();

      expect(WebAddressBar.isActive, isFalse);
      expect(
        controller.debugLastUnsupported?.reason,
        contains('not a mobile browser'),
      );
      expect(log, isEmpty);
    });

    for (final ui_web.OperatingSystem os in <ui_web.OperatingSystem>[
      ui_web.OperatingSystem.linux,
      ui_web.OperatingSystem.windows,
      ui_web.OperatingSystem.unknown,
    ]) {
      test('does nothing on ${os.name}', () {
        ui_web.browser.debugOperatingSystemOverride = os;

        WebAddressBar.enable();

        expect(WebAddressBar.isActive, isFalse);
      });
    }

    test('takes effect on Android, on the implicit view root', () {
      ui_web.browser.debugOperatingSystemOverride =
          ui_web.OperatingSystem.android;

      WebAddressBar.enable();

      expect(WebAddressBar.isActive, isTrue);
      expect(environments.single.os, MobileOs.android);
      expect(environments.single.root.localName, 'flutter-view');
      expect(
        environments.single.root.getAttribute('flt-view-id'),
        '${ui.PlatformDispatcher.instance.implicitView!.viewId}',
      );
    });

    test('takes effect on iOS', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.iOs;

      WebAddressBar.enable();

      expect(WebAddressBar.isActive, isTrue);
      expect(environments.single.os, MobileOs.iOS);
    });

    group('stands back when the page already scrolls itself', () {
      void expectConflict(
        void Function() arrange,
        void Function() restore,
        String reason,
      ) {
        ui_web.browser.debugOperatingSystemOverride =
            ui_web.OperatingSystem.android;
        arrange();
        addTearDown(restore);

        WebAddressBar.enable();

        expect(WebAddressBar.isActive, isFalse);
        expect(controller.debugLastUnsupported?.reason, contains(reason));
        expect(log, isEmpty);
      }

      test('<body> touch-action', () {
        final web.CSSStyleDeclaration style = web.document.body!.style;
        expectConflict(
          () => style.setProperty('touch-action', 'pan-y'),
          () => style.setProperty('touch-action', 'none'),
          'touch-action: pan-y',
        );
      });

      test('<html> overflow', () {
        final web.CSSStyleDeclaration style =
            (web.document.documentElement! as web.HTMLElement).style;
        expectConflict(
          () => style.setProperty('overflow-y', 'auto'),
          () => style.removeProperty('overflow-y'),
          'overflow-y: auto',
        );
      });

      test('a document taller than the viewport', () {
        final web.HTMLElement spacer =
            web.document.createElement('div') as web.HTMLElement;
        spacer.style
          ..position = 'absolute'
          ..top = '0'
          ..height = '300vh'
          ..width = '1px';
        expectConflict(
          () => web.document.documentElement!.append(spacer),
          () => spacer.remove(),
          'the document is',
        );
      });
    });
  });

  group('lifecycle', () {
    setUp(() {
      ui_web.browser.debugOperatingSystemOverride =
          ui_web.OperatingSystem.android;
    });

    test('enable is idempotent', () {
      WebAddressBar.enable();
      WebAddressBar.enable();

      expect(log, <String>['create']);
    });

    test('disable takes the parts down in reverse order, once', () {
      WebAddressBar.enable();
      WebAddressBar.disable();
      WebAddressBar.disable();

      expect(WebAddressBar.isActive, isFalse);
      expect(log, <String>['create', 'dispose second', 'dispose first']);
    });

    test('can be enabled again after disable', () {
      WebAddressBar.enable();
      WebAddressBar.disable();
      WebAddressBar.enable();

      expect(WebAddressBar.isActive, isTrue);
      expect(log, <String>[
        'create',
        'dispose second',
        'dispose first',
        'create',
      ]);
    });

    test('disable resets the metrics', () {
      WebAddressBar.enable();
      controller.collapsedExtent.value = 42;
      WebAddressBar.disable();

      expect(WebAddressBar.collapsedExtent.value, 0);
    });

    test(
      "takes the previous run's session down first, as after a hot restart",
      () {
        final List<String> calls = <String>[];
        globalContext.setProperty(
          r'$webAddressBarTeardown'.toJS,
          (() {
            calls.add('previous teardown');
          }).toJS,
        );

        WebAddressBar.enable();

        expect(calls, <String>['previous teardown']);
        expect(WebAddressBar.isActive, isTrue);
      },
    );
  });

  group('findViewRoot', () {
    test('matches the view id', () {
      final web.HTMLElement host =
          web.document.createElement('div') as web.HTMLElement;
      final web.Element other = web.document.createElement('flutter-view')
        ..setAttribute('flt-view-id', '1');
      final web.Element mine = web.document.createElement('flutter-view')
        ..setAttribute('flt-view-id', '2');
      host
        ..append(other)
        ..append(mine);

      // strictEquals rather than same(): dart2wasm wraps JS values, so two
      // wrappers of one element are equal but not identical.
      expect(findViewRoot(host, 2)!.strictEquals(mine).toDart, isTrue);
      expect(findViewRoot(host, 3), isNull);
    });
  });
}
