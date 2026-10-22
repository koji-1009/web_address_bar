import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:web_address_bar/web_address_bar.dart';

import '../automation.dart';

/// Shows [WebAddressBar.collapsedExtent] next to what the app is told about
/// its size and padding, over a list to scroll the address bar away with.
class CollapsedExtentTest extends StatelessWidget {
  const CollapsedExtentTest({super.key});

  static const String title = 'Collapsed extent';

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final ui.FlutterView view = View.of(context);
    String size(Size s) =>
        '${s.width.toStringAsFixed(1)} × ${s.height.toStringAsFixed(1)}';
    String insets(EdgeInsets e) =>
        'T ${e.top.toStringAsFixed(1)} B ${e.bottom.toStringAsFixed(1)}';
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: Column(
        children: <Widget>[
          ValueListenableBuilder<double>(
            valueListenable: WebAddressBar.collapsedExtent,
            builder: (BuildContext context, double extent, Widget? _) {
              publishAutomationState(<String, Object?>{
                'isActive': WebAddressBar.isActive,
                'collapsedExtent': extent,
              });
              return Card(
                margin: const .all(8),
                child: Padding(
                  padding: const .all(12),
                  child: Text(
                    'isActive: ${WebAddressBar.isActive}\n'
                    'collapsedExtent: ${extent.toStringAsFixed(1)}\n'
                    'MediaQuery.size: ${size(media.size)}\n'
                    'padding: ${insets(media.padding)}\n'
                    'viewPadding: ${insets(media.viewPadding)}\n'
                    'viewInsets: ${insets(media.viewInsets)}\n'
                    'view.physicalSize: ${size(view.physicalSize)} '
                    '(dpr ${view.devicePixelRatio})',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) =>
                  ListTile(title: Text('Scroll to collapse the bar ($index)')),
            ),
          ),
        ],
      ),
    );
  }
}
