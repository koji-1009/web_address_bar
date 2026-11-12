# AGENTS.md

`web_address_bar` lets the mobile browser address bar collapse in full-page Flutter web apps on Android and iOS, without changing the engine. See [README.md](README.md) for what it does and how.

## Layout

- `lib/src/web_address_bar.dart`: the public API (`WebAddressBar`); `lib/src/widgets/`: its widget, `WebAddressBarScrollToTop`.
- `lib/src/platform/`: `shared.dart` exports `web.dart` on the web and `unsupported.dart`, the no-op implementation, on every other platform.
- `lib/src/web/`: the web implementation, one `SessionPart` per concern, set up and taken down by `controller.dart`.
- `test/stub_test.dart` runs on the VM; `test/web/` runs in Chrome.
- `example/`: the test app, also served on GitHub Pages, and `example/tool/example_cdp.mjs`, the end-to-end check.

## Toolchain

Flutter stable, 3.50.0 or later.

## Checks

Run these before committing; CI runs the same, with `dart format -o none --set-exit-if-changed .` for the formatting, on stable; the E2E workflow runs the analysis and the Chrome tests on beta.

```
dart format .
flutter analyze
flutter test
flutter test --platform chrome
flutter test --platform chrome --wasm
```

For a change that affects input or the page setup, also run the example's checks from `example/`; CI builds the example, and the E2E workflow also runs the end-to-end check, on beta:

```
flutter test --platform chrome
flutter build web --profile
node tool/example_cdp.mjs --check
flutter build web --wasm
node tool/example_cdp.mjs --check
```

## Running the example on a phone

From `example/`, serve it on every network interface of the machine and open `http://<machine's IP>:8080/` on the phone:

```
flutter run -d web-server --web-hostname any --web-port 8080
```

Chrome on Android fires `pointerrawupdate` only in a secure context. Connect the phone with USB, run `adb reverse tcp:8080 tcp:8080`, and open `http://localhost:8080/` instead.

## Working on the code

- The package depends on engine internals: the DOM the engine builds and the listeners `PointerBinding` registers. Read the engine source in `engine/src/flutter/lib/web_ui/lib/src/engine/` of the Flutter SDK (its path is `flutterRoot` in `flutter --version --machine`) before relying on its behaviour, and find which release an engine change is in with `git -C <flutterRoot> tag --contains <sha>`.
- Code must work compiled to both JavaScript and WebAssembly. Compare JS values with `strictEquals`, not `identical`, and read fractional `MouseEvent` coordinates as `JSNumber`, since `package:web` types them `int`.
- Format with the default `dart format` settings.

## Commits

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

## GitHub Actions

Actions are pinned to commit SHAs with [pinact](https://github.com/suzuki-shunsuke/pinact) (`pinact run -u`) and updated by Dependabot.
