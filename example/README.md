# web_address_bar example

The test app of `package:web_address_bar`: test screens for scrolling and input, a screen for `WebAddressBar.collapsedExtent`, and the long-drag repro of flutter/flutter#194104.

It sets the package up as an app would ([lib/main.dart](lib/main.dart)):

```dart
void main() {
  WebAddressBar.enable();
  runApp(const MyApp());
}

// In MyApp:
MaterialApp(
  builder: (context, child) => WebAddressBarScrollToTop(child: child!),
  // ...
);
```

It is served, built with Flutter beta, at <https://koji-1009.github.io/web_address_bar/> (over HTTPS, so Chrome on Android fires `pointerrawupdate`). To build it yourself:

```
flutter build web --profile        # or --wasm
python3 -m http.server 8080 --bind 0.0.0.0 -d build/web
```

Open `http://<your machine>:8080/` on an Android or iOS phone. For Chrome on Android in a secure context (where `pointerrawupdate` is available), run `adb reverse tcp:8080 tcp:8080` and open `http://localhost:8080/`.

Each screen has its own URL, `#/basic|nested|interactive|tap-only|large-app-bar|expanding-app-bar|floating-app-bar|tabs|refresh|pinch|platform-view|runtime-toggle|collapsed-extent|long-drag`, so a reload keeps it open.

Query parameters, before the `#`:

- `enable=0` leaves the package off, for comparing with stock behavior, as in `?enable=0#/long-drag`.
- `semantics=1` turns semantics on, as a screen reader would. A drag that starts on a scrollable then does not collapse the bar (see the package's Limitations).

## What to check on a device

Reload the page before each check.

| Screen | Expected |
|---|---|
| Vertical list | Dragging up collapses the address bar. The list follows the finger and flings on release. The page does not pull to refresh, rubber-band or keep scrolling. |
| Nested scrollables | A vertical drag collapses the bar; a horizontal swipe changes the page. |
| Interactive widgets | Each tap counts once; the slider drags; the switch toggles; the text field takes input with the keyboard up; a long press shows a SnackBar. With a pen on the screen, taps count once and the slider drags. |
| Tap only | A drag collapses the bar even though nothing scrolls; each tap on the box counts once. |
| Large app bar | Dragging up collapses the address bar and folds the large title into the toolbar; a status bar tap on iOS brings both back. |
| Expanding app bar | The colored background reaches under the status bar; dragging up collapses the address bar and the flexible space. |
| Floating app bar | The app bar scrolls away with the list and snaps back on any downward drag, alongside the address bar. |
| Tabs | After scrolling both tabs, a status bar tap on iOS scrolls only the tab shown to the top. |
| Refresh indicator | Pulling down at the top of the list shows the indicator and refreshes once; the page does not reload. |
| Pinch | Two fingers zoom and pan the grid; once both lift, "Pointers down" is 0. |
| Platform view | The HTML area scrolls; each HTML button tap counts once; the HTML text field takes input; a drag on the Flutter list collapses the bar. |
| Runtime toggle | Off: a drag no longer collapses the bar and taps count once. On again: the bar collapses again and taps count once. |
| Collapsed extent | `collapsedExtent` is the bar's height while it shows and 0 once collapsed, and follows the bar after rotating the phone. With the keyboard up, it is the bar's height. |
| Long drag | After one long, slow drag, "Pointers down" is 0 and the list is idle, with a finger or a pen; the last pointer reads `touch` for both. |

## Automated check

`tool/example_cdp.mjs` serves `build/web`, drives it in headless Chrome emulating an Android phone with trusted touch input through the Chrome DevTools Protocol, and prints what the long-drag, interactive-widgets and collapsed-extent screens report, where the document rests and any exception the page threw. `--check` makes it exit with status 1 on a problem; CI runs it.

```
node tool/example_cdp.mjs --check
```
