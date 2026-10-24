// The implementation behind `WebAddressBar` for the platform the app is
// compiled for: the web one, or the no-op one everywhere else.

export 'unsupported.dart' if (dart.library.js_interop) 'web.dart';
