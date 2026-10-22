# web_address_bar example

The test app of `package:web_address_bar`: test screens for scrolling and input, a screen for `WebAddressBar.collapsedExtent`, and the long-drag repro of flutter/flutter#194104.

It is served, built with Flutter master, at <https://koji-1009.github.io/web_address_bar/> (over HTTPS, so Chrome on Android fires `pointerrawupdate`). To build it yourself:

```
flutter build web --profile        # or --wasm
python3 -m http.server 8080 --bind 0.0.0.0 -d build/web
```

Open `http://<your machine>:8080/` on an Android or iOS phone. For Chrome on Android in a secure context (where `pointerrawupdate` is available), run `adb reverse tcp:8080 tcp:8080` and open `http://localhost:8080/`.

Query parameters:

- `screen=basic|nested|interactive|tap-only|collapsed-extent|long-drag` opens a screen directly.
- `enable=0` leaves the package off, for comparing with stock behavior.

## What to check on a device

Reload the page before each check.

| Screen | Expected |
|---|---|
| Basic Vertical ListView | Dragging up collapses the address bar. The list follows the finger and flings on release. The page does not pull to refresh, rubber-band or keep scrolling. |
| Nested Scrollables | A vertical drag collapses the bar; a horizontal swipe changes the page. |
| Interactive Widgets | Each tap counts once; the slider drags; the switch toggles; the text field takes input with the keyboard up; a long press shows a SnackBar. |
| Tap-Only Page | A drag collapses the bar even though nothing scrolls; each tap on the box counts once. |
| Collapsed Extent | `collapsedExtent` is the bar's height while it shows and 0 once collapsed. |
| Long Drag | After one long, slow drag, "Pointers down" is 0 and the list is idle. |

## Automated check

`tool/example_cdp.mjs` serves `build/web`, drives it in headless Chrome emulating an Android phone with trusted touch input through the Chrome DevTools Protocol, and prints what the long-drag and collapsed-extent screens report and any exception the page threw. `--check` makes it exit with status 1 on a problem; CI runs it.

```
node tool/example_cdp.mjs --check
```
