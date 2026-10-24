import 'package:flutter/semantics.dart' show SemanticsBinding;
import 'package:flutter/services.dart' show FlutterVersion;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web_address_bar/web_address_bar.dart';

import 'screens/basic_vertical_list.dart';
import 'screens/collapsed_extent.dart';
import 'screens/expanding_app_bar.dart';
import 'screens/floating_app_bar.dart';
import 'screens/interactive_widgets.dart';
import 'screens/large_app_bar.dart';
import 'screens/long_drag.dart';
import 'screens/nested_scroll.dart';
import 'screens/pinch.dart';
import 'screens/platform_view.dart';
import 'screens/refresh.dart';
import 'screens/runtime_toggle.dart';
import 'screens/tabs.dart';
import 'screens/tap_only.dart';

/// The query parameters the app understands:
///
/// * `enable=0`: leave WebAddressBar off, to compare with stock behavior.
/// * `semantics=1`: turn semantics on, as a screen reader would.
///
/// A test screen opens at `#/<name>`, the keys of [screens], so a reload keeps
/// it open.
void main() {
  final Map<String, String> query = Uri.base.queryParameters;
  if (query['enable'] != '0') {
    WebAddressBar.enable();
  }
  runApp(const WebScrollTestApp());
  if (query['semantics'] == '1') {
    SemanticsBinding.instance.ensureSemantics();
  }
}

/// The test screens, by the path they open at.
const Map<String, Widget> screens = <String, Widget>{
  'basic': BasicVerticalListTest(),
  'nested': NestedScrollTest(),
  'interactive': InteractiveWidgetsTest(),
  'tap-only': TapOnlyTest(),
  'large-app-bar': LargeAppBarTest(),
  'expanding-app-bar': ExpandingAppBarTest(),
  'floating-app-bar': FloatingAppBarTest(),
  'tabs': TabsTest(),
  'refresh': RefreshTest(),
  'pinch': PinchTest(),
  'platform-view': PlatformViewTest(),
  'runtime-toggle': RuntimeToggleTest(),
  'collapsed-extent': CollapsedExtentTest(),
  'long-drag': LongDragTest(),
};

/// The menu at `/`, with each test screen on top of it.
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (_, _) => const TestMenu(),
      routes: <RouteBase>[
        for (final MapEntry(:String key, :Widget value) in screens.entries)
          GoRoute(path: key, builder: (_, _) => value),
      ],
    ),
  ],
);

class WebScrollTestApp extends StatelessWidget {
  const WebScrollTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'web_address_bar example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      builder: (BuildContext context, Widget? child) =>
          WebAddressBarScrollToTop(child: child!),
      routerConfig: _router,
    );
  }
}

class TestMenu extends StatelessWidget {
  const TestMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = TextTheme.of(context);
    final ColorScheme colors = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('web_address_bar example')),
      body: ListView(
        padding: const .all(16),
        children: [
          Padding(
            padding: const .only(left: 4, bottom: 8),
            child: Text(
              'Flutter ${FlutterVersion.version} '
              '(${FlutterVersion.channel}, ${FlutterVersion.frameworkRevision})',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const _TestTile(
            title: BasicVerticalListTest.title,
            subtitle: 'Scrolling down collapses the address bar',
            screen: 'basic',
          ),
          const _TestTile(
            title: NestedScrollTest.title,
            subtitle: 'A horizontal page view inside a vertical list',
            screen: 'nested',
          ),
          const _TestTile(
            title: InteractiveWidgetsTest.title,
            subtitle: 'Buttons, a slider, a switch and a text field in a list',
            screen: 'interactive',
          ),
          const _TestTile(
            title: TapOnlyTest.title,
            subtitle: 'A page that does not scroll, with a tappable box',
            screen: 'tap-only',
          ),
          const _TestTile(
            title: LargeAppBarTest.title,
            subtitle: 'A pinned large title that collapses into the toolbar',
            screen: 'large-app-bar',
          ),
          const _TestTile(
            title: ExpandingAppBarTest.title,
            subtitle:
                'A flexible space drawn edge-to-edge, under the status bar',
            screen: 'expanding-app-bar',
          ),
          const _TestTile(
            title: FloatingAppBarTest.title,
            subtitle: 'An app bar that snaps back on any scroll toward the top',
            screen: 'floating-app-bar',
          ),
          const _TestTile(
            title: TabsTest.title,
            subtitle: 'Tabs with a navigator and a list each',
            screen: 'tabs',
          ),
          const _TestTile(
            title: RefreshTest.title,
            subtitle: "The app's own pull to refresh",
            screen: 'refresh',
          ),
          const _TestTile(
            title: PinchTest.title,
            subtitle: 'Pinch and pan with two fingers',
            screen: 'pinch',
          ),
          const _TestTile(
            title: PlatformViewTest.title,
            subtitle: 'HTML buttons and a text field in an HtmlElementView',
            screen: 'platform-view',
          ),
          const _TestTile(
            title: RuntimeToggleTest.title,
            subtitle: 'Turn WebAddressBar off and on while the app runs',
            screen: 'runtime-toggle',
          ),
          const _TestTile(
            title: CollapsedExtentTest.title,
            subtitle: 'WebAddressBar.collapsedExtent and the view metrics',
            screen: 'collapsed-extent',
          ),
          const _TestTile(
            title: LongDragTest.title,
            subtitle:
                'One long, slow drag leaves no pointer down '
                '(flutter/flutter#194104)',
            screen: 'long-drag',
          ),
        ],
      ),
    );
  }
}

class _TestTile extends StatelessWidget {
  const _TestTile({
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final String title;
  final String subtitle;

  /// The key of the screen in [screens].
  final String screen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/$screen'),
      ),
    );
  }
}
