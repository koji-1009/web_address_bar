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
      home: home ?? const TestMenu(),
    );
  }
}

class TestMenu extends StatelessWidget {
  const TestMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tests')),
      body: ListView(
        padding: const .all(16),
        children: const [
          Padding(
            padding: .only(bottom: 8),
            child: Text(
              'Flutter ${FlutterVersion.version} '
              '(${FlutterVersion.channel}, ${FlutterVersion.frameworkRevision})',
            ),
          ),
          _TestTile(
            title: 'Basic Vertical ListView',
            subtitle: 'Address bar should collapse when scrolling down',
            destination: BasicVerticalListTest(),
          ),
          _TestTile(
            title: 'Nested Scrollables',
            subtitle: 'Horizontal PageView inside a vertical ListView',
            destination: NestedScrollTest(),
          ),
          _TestTile(
            title: 'Interactive Widgets',
            subtitle: 'Buttons, sliders, text fields inside a scroll view',
            destination: InteractiveWidgetsTest(),
          ),
          _TestTile(
            title: 'Tap-Only Page (No Scroll)',
            subtitle: 'Non-scrollable page with tappable buttons',
            destination: TapOnlyTest(),
          ),
          _TestTile(
            title: 'Collapsed Extent',
            subtitle: 'WebAddressBar.collapsedExtent and the view metrics',
            destination: CollapsedExtentTest(),
          ),
          _TestTile(
            title: 'Long Drag (flutter/flutter#194104)',
            subtitle: 'One long, slow drag must leave no pointer down',
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
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => destination));
        },
      ),
    );
  }
}
