@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_address_bar/web_address_bar.dart';

// The events below are dispatched by the test, so the browser marks them
// untrusted, like the injected ones. The package tells its own events apart
// by marking them, which is what lets these stand in for the browser's.

web.HTMLElement get _root =>
    web.document.querySelector('flutter-view')! as web.HTMLElement;

web.Touch _touch(web.EventTarget target, int identifier, double x, double y) {
  final JSObject init = JSObject()
    ..setProperty('identifier'.toJS, identifier.toJS)
    ..setProperty('target'.toJS, target)
    ..setProperty('clientX'.toJS, x.toJS)
    ..setProperty('clientY'.toJS, y.toJS)
    ..setProperty('screenX'.toJS, x.toJS)
    ..setProperty('screenY'.toJS, y.toJS);
  return web.Touch(init as web.TouchInit);
}

/// Dispatches a TouchEvent of [type] at [target] for [changed], with
/// [touches] (default: [changed] for start/move, none for end/cancel) still on
/// the surface.
void _dispatchTouch(
  web.EventTarget target,
  String type,
  List<web.Touch> changed, {
  List<web.Touch>? touches,
}) {
  final bool lifting = type == 'touchend' || type == 'touchcancel';
  final JSObject init = JSObject()
    ..setProperty('bubbles'.toJS, true.toJS)
    ..setProperty('cancelable'.toJS, true.toJS)
    ..setProperty('composed'.toJS, true.toJS)
    ..setProperty('changedTouches'.toJS, changed.toJS)
    ..setProperty(
      'touches'.toJS,
      (touches ?? (lifting ? <web.Touch>[] : changed)).toJS,
    )
    ..setProperty(
      'targetTouches'.toJS,
      (touches ?? (lifting ? <web.Touch>[] : changed)).toJS,
    );
  target.dispatchEvent(web.TouchEvent(type, init as web.TouchEventInit));
}

web.PointerEvent _dispatchPointer(
  web.EventTarget target,
  String type, {
  String pointerType = 'touch',
  int pointerId = 1,
  double x = 10,
  double y = 10,
  bool? down,
  int? buttons,
}) {
  down ??=
      type == 'pointerdown' ||
      type == 'pointermove' ||
      type == 'pointerrawupdate';
  final JSObject init = JSObject()
    ..setProperty('bubbles'.toJS, true.toJS)
    ..setProperty('cancelable'.toJS, true.toJS)
    ..setProperty('composed'.toJS, true.toJS)
    ..setProperty('pointerId'.toJS, pointerId.toJS)
    ..setProperty('pointerType'.toJS, pointerType.toJS)
    ..setProperty('isPrimary'.toJS, true.toJS)
    ..setProperty('clientX'.toJS, x.toJS)
    ..setProperty('clientY'.toJS, y.toJS)
    ..setProperty(
      'button'.toJS,
      (type == 'pointermove' || type == 'pointerrawupdate' ? -1 : 0).toJS,
    )
    ..setProperty('buttons'.toJS, (buttons ?? (down ? 1 : 0)).toJS)
    ..setProperty('pressure'.toJS, (down ? 0.5 : 0).toJS);
  final web.PointerEvent event = web.PointerEvent(
    type,
    init as web.PointerEventInit,
  );
  target.dispatchEvent(event);
  return event;
}

void main() {
  late List<ui.PointerData> data;
  late double dpr;

  List<ui.PointerChange> changes() => <ui.PointerChange>[
    for (final d in data) d.change,
  ];
  List<ui.PointerData> moves() => <ui.PointerData>[
    for (final d in data)
      if (d.change == ui.PointerChange.move && !d.synthesized) d,
  ];

  setUp(() {
    data = <ui.PointerData>[];
    ui.PlatformDispatcher.instance.onPointerDataPacket =
        (ui.PointerDataPacket packet) {
          data.addAll(packet.data);
        };
    dpr = ui.PlatformDispatcher.instance.implicitView!.devicePixelRatio;
    ui_web.browser.debugOperatingSystemOverride =
        ui_web.OperatingSystem.android;
    WebAddressBar.enable();
    expect(WebAddressBar.isActive, isTrue);
  });

  tearDown(() {
    WebAddressBar.disable();
    ui_web.browser.debugOperatingSystemOverride = null;
    ui.PlatformDispatcher.instance.onPointerDataPacket = null;
  });

  test('a tap becomes a touch pointer sequence', () {
    final web.Touch touch = _touch(_root, 7, 10, 20);
    _dispatchTouch(_root, 'touchstart', <web.Touch>[touch]);
    _dispatchTouch(_root, 'touchend', <web.Touch>[touch]);

    expect(changes(), <ui.PointerChange>[
      ui.PointerChange.add,
      ui.PointerChange.down,
      ui.PointerChange.up,
      ui.PointerChange.remove,
    ]);
    final ui.PointerData down = data[1];
    expect(down.kind, ui.PointerDeviceKind.touch);
    expect(down.device, 7);
    expect(down.physicalX, 10 * dpr);
    expect(down.physicalY, 20 * dpr);
  });

  test('touchmove carries the movement where no raw update arrives', () {
    _dispatchTouch(_root, 'touchstart', <web.Touch>[_touch(_root, 13, 10, 10)]);
    _dispatchTouch(_root, 'touchmove', <web.Touch>[_touch(_root, 13, 10, 30)]);

    expect(moves().single.physicalY, 30 * dpr);
  });

  test('a raw update takes the contact over from touchmove', () {
    _dispatchTouch(_root, 'touchstart', <web.Touch>[_touch(_root, 14, 10, 10)]);
    _dispatchPointer(_root, 'pointerrawupdate', y: 30);
    _dispatchTouch(_root, 'touchmove', <web.Touch>[_touch(_root, 14, 10, 50)]);

    expect(moves().single.physicalY, 30 * dpr);
  });

  test('fractional positions survive, raw updates included', () {
    // dart2wasm rejects a fraction read through an `int`-typed binding, which
    // is how package:web types MouseEvent.clientX.
    _dispatchTouch(_root, 'touchstart', <web.Touch>[
      _touch(_root, 15, 10.25, 10.5),
    ]);
    _dispatchPointer(_root, 'pointerrawupdate', x: 11.75, y: 30.5);

    expect(data[1].physicalX, 10.25 * dpr);
    expect(data[1].physicalY, 10.5 * dpr);
    expect(moves().single.physicalX, 11.75 * dpr);
    expect(moves().single.physicalY, 30.5 * dpr);
  });

  test('movement outlives the pointercancel the browser fires', () {
    _dispatchPointer(_root, 'pointerdown');
    _dispatchTouch(_root, 'touchstart', <web.Touch>[_touch(_root, 12, 10, 10)]);
    _dispatchPointer(_root, 'pointercancel', y: 20);
    _dispatchPointer(_root, 'pointerrawupdate', y: 40);
    _dispatchTouch(_root, 'touchend', <web.Touch>[_touch(_root, 12, 10, 40)]);

    expect(moves().single.physicalY, 40 * dpr);
    expect(changes(), isNot(contains(ui.PointerChange.cancel)));
    expect(changes().last, ui.PointerChange.remove);
  });

  test(
    "the browser's touch pointer events are withheld from PointerBinding",
    () {
      for (final String type in <String>[
        'pointerdown',
        'pointermove',
        'pointerup',
      ]) {
        _dispatchPointer(_root, type);
      }
      expect(data, isEmpty);
    },
  );

  test('a touch pointerdown withheld at the root does not move focus', () {
    final web.PointerEvent down = _dispatchPointer(_root, 'pointerdown');
    _dispatchPointer(_root, 'pointerup');

    expect(down.defaultPrevented, isTrue);
  });

  test('mouse pointer events still go to PointerBinding', () {
    _dispatchPointer(_root, 'pointerdown', pointerType: 'mouse');

    expect(data, isNotEmpty);
    expect(data.last.change, ui.PointerChange.down);
    expect(data.last.kind, ui.PointerDeviceKind.mouse);
    _dispatchPointer(_root, 'pointerup', pointerType: 'mouse');
  });

  group('a pen', () {
    test(
      'on the screen reaches the framework once, through its Touch Events',
      () {
        final web.Touch touch = _touch(_root, 51, 10, 10);
        _dispatchPointer(
          _root,
          'pointerdown',
          pointerType: 'pen',
          pointerId: 5,
        );
        _dispatchTouch(_root, 'touchstart', <web.Touch>[touch]);
        _dispatchPointer(
          _root,
          'pointermove',
          pointerType: 'pen',
          pointerId: 5,
        );
        _dispatchPointer(_root, 'pointerup', pointerType: 'pen', pointerId: 5);
        _dispatchTouch(_root, 'touchend', <web.Touch>[touch]);

        expect(changes(), <ui.PointerChange>[
          ui.PointerChange.add,
          ui.PointerChange.down,
          ui.PointerChange.up,
          ui.PointerChange.remove,
        ]);
        expect(<int>{for (final d in data) d.device}, <int>{51});
      },
    );

    test('hovering still goes to PointerBinding', () {
      _dispatchPointer(
        _root,
        'pointermove',
        pointerType: 'pen',
        pointerId: 6,
        down: false,
      );
      addTearDown(
        () => _dispatchPointer(
          _root,
          'pointerleave',
          pointerType: 'pen',
          pointerId: 6,
          down: false,
        ),
      );

      expect(data, isNotEmpty);
      expect(data.last.change, ui.PointerChange.hover);
      expect(data.last.kind, ui.PointerDeviceKind.stylus);
    });

    test('once lifted, hovers go to PointerBinding again', () {
      _dispatchPointer(_root, 'pointerdown', pointerType: 'pen', pointerId: 7);
      _dispatchPointer(_root, 'pointerup', pointerType: 'pen', pointerId: 7);
      expect(data, isEmpty);

      _dispatchPointer(
        _root,
        'pointermove',
        pointerType: 'pen',
        pointerId: 7,
        down: false,
      );
      addTearDown(
        () => _dispatchPointer(
          _root,
          'pointerleave',
          pointerType: 'pen',
          pointerId: 7,
          down: false,
        ),
      );

      expect(data.last.change, ui.PointerChange.hover);
    });

    test('pressing only the barrel button while hovering goes to '
        'PointerBinding', () {
      _dispatchPointer(
        _root,
        'pointerdown',
        pointerType: 'pen',
        pointerId: 8,
        down: false,
        buttons: 2,
      );
      addTearDown(
        () => _dispatchPointer(
          _root,
          'pointerup',
          pointerType: 'pen',
          pointerId: 8,
          down: false,
        ),
      );

      expect(data, isNotEmpty);
      expect(data.last.change, ui.PointerChange.down);
      expect(data.last.kind, ui.PointerDeviceKind.stylus);
    });
  });

  test('an element inside the view sees the event before it is withheld', () {
    final web.Element host = _root.querySelector('flt-semantics-host')!;
    final web.HTMLElement child =
        web.document.createElement('div') as web.HTMLElement;
    host.append(child);
    addTearDown(() => child.remove());
    final List<String> received = <String>[];
    child.addEventListener(
      'pointerdown',
      ((web.Event e) => received.add(e.type)).toJS,
    );

    _dispatchPointer(child, 'pointerdown');

    expect(received, <String>['pointerdown']);
    expect(data, isEmpty);
  });

  test('a contact whose element leaves the DOM mid-gesture still ends', () {
    final web.HTMLElement placeholder = web.document.createElement(
      'flt-semantics-placeholder',
    ) as web.HTMLElement;
    _root.prepend(placeholder);
    addTearDown(() => placeholder.remove());

    _dispatchTouch(placeholder, 'touchstart', <web.Touch>[
      _touch(placeholder, 21, 10, 10),
    ]);
    placeholder.remove();
    // Detached: the events no longer reach the view root.
    _dispatchTouch(placeholder, 'touchmove', <web.Touch>[
      _touch(placeholder, 21, 10, 50),
    ]);
    _dispatchTouch(placeholder, 'touchend', <web.Touch>[
      _touch(placeholder, 21, 10, 50),
    ]);

    expect(changes(), <ui.PointerChange>[
      ui.PointerChange.add,
      ui.PointerChange.down,
      ui.PointerChange.move,
      ui.PointerChange.up,
      ui.PointerChange.remove,
    ]);
    expect(moves().single.physicalY, 50 * dpr);
  });

  test('a contact on a platform view reaches the engine without a second copy for the view', () {
    final web.Element glassPane = _root.querySelector('flt-glass-pane')!;
    final web.HTMLElement platformView =
        web.document.createElement('div') as web.HTMLElement;
    glassPane.append(platformView);
    addTearDown(() => platformView.remove());
    final List<String> seenByPlatformView = <String>[];
    platformView.addEventListener(
      'pointerdown',
      ((web.Event e) => seenByPlatformView.add(e.type)).toJS,
    );

    _dispatchPointer(platformView, 'pointerdown');
    final web.Touch touch = _touch(platformView, 31, 10, 10);
    _dispatchTouch(platformView, 'touchstart', <web.Touch>[touch]);
    _dispatchTouch(platformView, 'touchend', <web.Touch>[touch]);

    expect(seenByPlatformView, <String>['pointerdown']);
    expect(changes(), contains(ui.PointerChange.down));
    expect(changes(), contains(ui.PointerChange.up));
  });

  group('two fingers', () {
    test('raw updates are ignored, touchmoves carry each finger', () {
      final web.Touch a = _touch(_root, 1, 10, 10);
      final web.Touch b = _touch(_root, 2, 100, 10);
      _dispatchTouch(_root, 'touchstart', <web.Touch>[a]);
      _dispatchTouch(
        _root,
        'touchstart',
        <web.Touch>[b],
        touches: <web.Touch>[a, b],
      );
      _dispatchPointer(_root, 'pointerrawupdate', y: 99);
      _dispatchTouch(_root, 'touchmove', <web.Touch>[
        _touch(_root, 1, 10, 20),
        _touch(_root, 2, 100, 30),
      ]);

      expect(
        <double>[for (final m in moves()) m.physicalY],
        <double>[20 * dpr, 30 * dpr],
      );
      expect(<int>[for (final m in moves()) m.device], <int>[1, 2]);
    });

    test('lifting one leaves the other down', () {
      final web.Touch a = _touch(_root, 1, 10, 10);
      final web.Touch b = _touch(_root, 2, 100, 10);
      _dispatchTouch(_root, 'touchstart', <web.Touch>[a]);
      _dispatchTouch(
        _root,
        'touchstart',
        <web.Touch>[b],
        touches: <web.Touch>[a, b],
      );
      _dispatchTouch(
        _root,
        'touchend',
        <web.Touch>[a],
        touches: <web.Touch>[b],
      );

      final List<int> lifted = <int>[
        for (final d in data)
          if (d.change == ui.PointerChange.up) d.device,
      ];
      expect(lifted, <int>[1]);
    });
  });

  test('disable cancels the touches still down and stops translating', () {
    _dispatchTouch(_root, 'touchstart', <web.Touch>[_touch(_root, 41, 10, 10)]);

    WebAddressBar.disable();

    expect(changes(), contains(ui.PointerChange.cancel));
    data.clear();
    _dispatchTouch(_root, 'touchstart', <web.Touch>[_touch(_root, 42, 10, 10)]);
    expect(data, isEmpty);
    // The browser's own touch pointer events reach PointerBinding again.
    _dispatchPointer(_root, 'pointerdown', pointerId: 43);
    expect(changes(), contains(ui.PointerChange.down));
    _dispatchPointer(_root, 'pointerup', pointerId: 43);
  });

  test('disable can be called as a contact lifts, as from onTap', () {
    final List<String> errors = <String>[];
    final JSFunction onError = ((web.ErrorEvent event) {
      errors.add(event.message);
    }).toJS;
    web.window.addEventListener('error', onError);
    ui.PlatformDispatcher.instance.onPointerDataPacket =
        (ui.PointerDataPacket packet) {
          data.addAll(packet.data);
          if (packet.data.any((d) => d.change == ui.PointerChange.up)) {
            WebAddressBar.disable();
          }
        };

    final web.Touch touch = _touch(_root, 44, 10, 10);
    _dispatchTouch(_root, 'touchstart', <web.Touch>[touch]);
    _dispatchTouch(_root, 'touchend', <web.Touch>[touch]);
    web.window.removeEventListener('error', onError);

    expect(errors, isEmpty);
    expect(WebAddressBar.isActive, isFalse);
    expect(changes(), contains(ui.PointerChange.up));
  });
}
