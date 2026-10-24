# AGENTS.md

`web_address_bar` lets the mobile browser address bar collapse in full-page Flutter web apps on Android and iOS, without changing the engine. See [README.md](README.md) for what it does and how.

## Layout

- `lib/src/web_address_bar.dart`: the public API (`WebAddressBar`); `lib/src/widgets/`: its widget, `WebAddressBarScrollToTop`.
- `lib/src/web/`: the web implementation, one `SessionPart` per concern, set up and taken down by `controller.dart`.
- `lib/src/stub/`: the no-op implementation for every other platform.
- `test/stub_test.dart` runs on the VM; `test/web/` runs in Chrome.
- `example/`: the test app, also served on GitHub Pages, and `example/tool/example_cdp.mjs`, the end-to-end check.

## Toolchain

Flutter master, pinned with fvm (`.fvmrc`). Run Flutter and Dart as `fvm flutter` and `fvm dart`.

## Checks

Run these before committing; CI runs the same, with `dart format -o none --set-exit-if-changed .` for the formatting, on stable, beta and master.

```
fvm dart format .
fvm flutter analyze
fvm flutter test
fvm flutter test --platform chrome
fvm flutter test --platform chrome --wasm
```

For a change that affects input or the page setup, also run the example's checks from `example/`:

```
fvm flutter test --platform chrome
fvm flutter build web --profile
node tool/example_cdp.mjs --check
fvm flutter build web --wasm
node tool/example_cdp.mjs --check
```

CI also runs `dart pub publish --dry-run` on stable.

## Running the example on a phone

From `example/`, serve it on every network interface of the machine and open `http://<machine's IP>:8080/` on the phone:

```
fvm flutter run -d web-server --web-hostname any --web-port 8080
```

Chrome on Android fires `pointerrawupdate` only in a secure context. Connect the phone with USB, run `adb reverse tcp:8080 tcp:8080`, and open `http://localhost:8080/` instead.

## Working on the code

- The package depends on engine internals: the DOM the engine builds and the listeners `PointerBinding` registers. Read the engine source in `.fvm/flutter_sdk/engine/src/flutter/lib/web_ui/lib/src/engine/` before relying on its behaviour, and find which release an engine change is in with `git -C .fvm/flutter_sdk tag --contains <sha>`.
- Code must work compiled to both JavaScript and WebAssembly. Compare JS values with `strictEquals`, not `identical`, and read fractional `MouseEvent` coordinates as `JSNumber`, since `package:web` types them `int`.
- Format with the default `dart format` settings.

## Commits

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

## GitHub Actions

Actions are pinned to commit SHAs with [pinact](https://github.com/suzuki-shunsuke/pinact) (`pinact run -u`) and updated by Dependabot.
