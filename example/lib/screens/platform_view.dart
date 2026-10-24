import 'dart:js_interop';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

/// An [HtmlElementView] with a scrollable list of HTML buttons and an HTML
/// text field, between Flutter content.
class PlatformViewTest extends StatefulWidget {
  const PlatformViewTest({super.key});

  static const String title = 'Platform view';

  @override
  State<PlatformViewTest> createState() => _PlatformViewTestState();
}

class _PlatformViewTestState extends State<PlatformViewTest> {
  int _htmlTapCount = 0;

  void _buildHtml(Object element) {
    final web.HTMLElement root = element as web.HTMLElement;
    root.style
      ..overflowY = 'auto'
      ..backgroundColor = '#eef'
      ..padding = '8px';
    final web.HTMLInputElement input =
        web.document.createElement('input') as web.HTMLInputElement
          ..placeholder = 'HTML text field';
    root.append(input);
    for (int i = 0; i < 20; i++) {
      final web.HTMLButtonElement button =
          web.document.createElement('button') as web.HTMLButtonElement
            ..textContent = 'HTML button ${i + 1}';
      button.style
        ..display = 'block'
        ..margin = '8px 0';
      button.onclick = ((web.Event _) {
        setState(() => _htmlTapCount++);
      }).toJS;
      root.append(button);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(PlatformViewTest.title)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const .all(8),
            child: Text('HTML button taps: $_htmlTapCount'),
          ),
          SizedBox(
            height: 300,
            child: HtmlElementView.fromTagName(
              tagName: 'div',
              onElementCreated: _buildHtml,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 60,
              itemBuilder: (BuildContext context, int index) =>
                  ListTile(title: Text('Flutter item ${index + 1}')),
            ),
          ),
        ],
      ),
    );
  }
}
