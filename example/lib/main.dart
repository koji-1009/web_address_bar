import 'package:flutter/services.dart' show FlutterVersion;
import 'package:material_ui/material_ui.dart';
import 'package:web_address_bar/web_address_bar.dart';

import 'screens/basic_vertical_list.dart';
import 'screens/collapsed_extent.dart';
import 'screens/interactive_widgets.dart';
import 'screens/long_drag.dart';
import 'screens/nested_scroll.dart';
import 'screens/tap_only.dart';

/// The query parameters the app understands:
///
/// * `enable=0`: leave WebAddressBar off, to compare with stock behavior.
/// * `screen=<name>`: open a test screen directly (the keys of [screens]).
void main() {
  final Map<String, String> query = Uri.base.queryParameters;
  if (query['enable'] != '0') {
    WebAddressBar.enable();
  }
  runApp(WebScrollTestApp(home: screens[query['screen']]));
}

/// The test screens, by the name `?screen=` takes.
const Map<String, Widget> screens = <String, Widget>{
  'basic': BasicVerticalListTest(),
  'nested': NestedScrollTest(),
  'interactive': InteractiveWidgetsTest(),
  'tap-only': TapOnlyTest(),
  'collapsed-extent': CollapsedExtentTest(),
  'long-drag': LongDragTest(),
};

class WebScrollTestApp extends StatelessWidget {
  const WebScrollTestApp({super.key, this.home});

  /// The first screen; the test menu if null.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'web_address_bar example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      builder: (BuildContext context, Widget? child) =>
          WebAddressBarScrollToTop(child: child!),
      home: home ?? const TestMenu(),
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
            destination: BasicVerticalListTest(),
          ),
          const _TestTile(
            title: NestedScrollTest.title,
            subtitle: 'A horizontal page view inside a vertical list',
            destination: NestedScrollTest(),
          ),
          const _TestTile(
            title: InteractiveWidgetsTest.title,
            subtitle: 'Buttons, a slider, a switch and a text field in a list',
            destination: InteractiveWidgetsTest(),
          ),
          const _TestTile(
            title: TapOnlyTest.title,
            subtitle: 'A page that does not scroll, with a tappable box',
            destination: TapOnlyTest(),
          ),
          const _TestTile(
            title: CollapsedExtentTest.title,
            subtitle: 'WebAddressBar.collapsedExtent and the view metrics',
            destination: CollapsedExtentTest(),
          ),
          const _TestTile(
            title: LongDragTest.title,
            subtitle:
                'One long, slow drag leaves no pointer down '
                '(flutter/flutter#194104)',
            destination: LongDragTest(),
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
    required this.destination,
  });

  final String title;
  final String subtitle;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => destination));
        },
      ),
    );
  }
}
