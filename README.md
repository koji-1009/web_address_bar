# web_address_bar

Lets the mobile browser address bar collapse in full-page Flutter web apps on Android and iOS, while scrolling stays in Flutter's own scroll views.

## Why the bar does not collapse, and how it does here

A mobile browser collapses its address bar when the user scrolls the document, which needs two things: a document taller than the viewport, and a drag the browser is allowed to take as a scroll. A full-page Flutter web app has neither. The page is exactly as tall as the viewport, and `<body>` has `touch-action: none`, so the browser hands every touch to Flutter.

This package gives the browser a document to scroll, separate from the app:

![On a vertical drag the browser scrolls the document under the Flutter view, which stays fixed to the viewport, and collapses its address bar; the engine resizes the view to the grown viewport, and the document comes to rest on a snap point around 5000px](doc/how_it_works.svg)

![The scroll range per platform, both with scroll-snap-type y mandatory and a 10000px spacer: on Android, two snap targets at 4999px and 5001px, on which the document rests with the bar shown and with the bar hidden, in a range long enough for the 130–180px Chrome scrolls before it starts hiding its bar, with both ends out of reach of pull-to-refresh; on iOS, the document parked on one snap target at 5000px, which keeps pull-to-refresh, rubber-banding and momentum scrolling out of reach](doc/scroll_range.svg)

- The document gets a scroll range of its own, from a spacer under `<html>`, and `<body>` allows vertical panning (`touch-action: pan-y`). A vertical drag scrolls the document, and the browser spends that scroll on its address bar.
- The Flutter view does not scroll with the document. `<body>`, which holds it, is `position: fixed`, so the view stays on the viewport and floats over the document while the document scrolls under it. As the bar collapses, the viewport grows and the engine resizes the view to fill it (on iOS, see [Compatibility](#compatibility)).
- The app keeps doing its own scrolling. The document's scroll range does not depend on the app's content, so the bar collapses on every page, including ones that do not scroll, and nothing about the app's layout changes.

Because the browser takes a vertical drag over as a scroll, it cancels that touch's Pointer Events, which is what Flutter reads touch input from. The package rebuilds the touch input from Touch Events instead (see [How it works](#how-it-works)).

![The touch input path: the browser's Pointer Events of a finger or a pen on the screen reach the elements they target in the view, then TouchInterceptor withholds them from the engine's PointerBinding; TouchInputSource rebuilds the contact from Touch Events and pointerrawupdate, and PointerInjector dispatches synthetic touch Pointer Events, which PointerBinding converts as usual](doc/touch_input.svg)

## Usage

```dart
import 'package:web_address_bar/web_address_bar.dart';

void main() {
  WebAddressBar.enable();
  runApp(const MyApp());
}
```

`enable` can be called before or after `runApp`. It takes effect in browsers on Android and iOS (iPadOS included); pass `platforms` to limit it to one of them, for example `WebAddressBar.enable(platforms: {TargetPlatform.iOS})`. It does nothing outside those browsers, when Flutter does not own the whole page (a custom `hostElement`, multi-view), or on platforms other than the web. `WebAddressBar.isActive` tells whether it took effect; in debug builds the reason it did not is printed. `WebAddressBar.disable()` undoes everything.

`WebAddressBar.collapsedExtent` reports how much of the viewport the browser's UI covers right now, in logical pixels: the bar's height while it shows, 0 once it has collapsed.

### Scrolling to the top on a status bar tap (iOS)

Safari answers a tap on the iOS status bar by scrolling the document, which the package has taken over. Add `WebAddressBarScrollToTop` above the `Navigator` to scroll the current route's primary scroll view to the top instead, as a native iOS app does:

```dart
MaterialApp(
  builder: (context, child) => WebAddressBarScrollToTop(child: child!),
  // ...
);
```

It animates the `PrimaryScrollController` of the current route, the way `Scaffold` does on iOS; routes that are not current, such as a page under a dialog, are left alone.

## How it works

On Android and iOS, when Flutter owns the whole page:

1. `<body>` gets `touch-action: pan-y`, so the browser reads a vertical drag as a scroll.
2. A spacer under `<html>` gives the document real overflow for the browser to spend on its address bar. `<body>` stays `position: fixed`, so the app does not move.
3. The scroll range is kept from doing anything else:
   - Android: `scroll-snap-type: y mandatory`, with a 10000px spacer and two snap points 2px apart in its middle. Chrome scrolls the page some way before it starts hiding its bar, and shows the bar again if the page then moves back up; with a snap point on either side, a scroll comes to rest on the one in the direction it went, and both ends stay out of reach of pull-to-refresh.
   - iOS: `scroll-snap-type: y mandatory`, parked on a snap point in the middle of a 10000px spacer, which keeps pull-to-refresh, rubber-banding and momentum scrolling of the page out of reach.
4. Touch input is rebuilt from Touch Events and `pointerrawupdate`, because under `pan-y` the browser cancels the touch Pointer Events mid-drag. A pen touching the screen fires Touch Events too, so it is rebuilt the same way. The browser's Pointer Events of fingers and of pens on the screen are withheld from the engine after the elements they target (platform views, text fields) have had them, and the rebuilt contact is handed to the engine as touch Pointer Events, so its click debouncing, focus handling and accessibility bookkeeping work unchanged. Movement comes from `pointerrawupdate` while one finger is down, and from `touchmove` otherwise.

Based on [flutter/flutter#184281](https://github.com/flutter/flutter/pull/184281).

## Compatibility

- Flutter 3.47 or later, on the web, compiled to JavaScript or WebAssembly.
- Takes effect in browsers on Android and iOS/iPadOS, for a full-page app with the implicit view. It checks the page structure it relies on (`<flutter-view>` under `<body>`) and does nothing if that is not there, or if the page already scrolls itself (`touch-action` other than `none` on `<body>`, `overflow` on `<html>`, a document taller than the viewport).
- On iOS, engines with [flutter/flutter#193744](https://github.com/flutter/flutter/pull/193744) (Flutter 3.50 beta and later) grow the view as the toolbar collapses. Earlier engines keep the view at the toolbar-expanded height, which leaves a strip at the bottom once the toolbar has collapsed.
- Engines without [flutter/flutter#194109](https://github.com/flutter/flutter/pull/194109) can remove the accessibility placeholder in the middle of a drag that started on it. The package follows a contact on the element it started on, so the drag still ends.

## Limitations

- In-app browser sheets that rely on the page's scroll position are not handled: the page's scroll position does not follow the app's content.
- A status bar tap is recognised from the document's scroll position, as nothing else marks it: a scroll that reaches the upper half of the way to the top with no finger on the screen.
- Touch input arrives as Touch Events, which carry no tilt, and multi-touch movement follows the browser's throttled `touchmove`.
- A pen on the screen reaches the app as a touch, without pressure or tilt, and its movement follows `touchmove`. A hovering pen is reported as a stylus as usual. Apps that need pressure or tilt should not enable the package.
- With semantics enabled, the engine gives its scrollable semantics nodes `touch-action: none`, so a drag that starts on one does not collapse the bar.
- Pull-to-refresh of the page is unavailable by design.

## Example

Try it on a phone at <https://koji-1009.github.io/web_address_bar/>.

[example/](example/) holds test screens (a vertical list, nested scrollables, interactive widgets, a page that does not scroll), a screen showing `collapsedExtent` next to the view metrics, and the long-drag repro of flutter/flutter#194104, with what to check on a device.

## License

MIT.
