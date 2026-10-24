import 'package:material_ui/material_ui.dart';

import '../automation.dart';

class InteractiveWidgetsTest extends StatefulWidget {
  const InteractiveWidgetsTest({super.key});

  static const String title = 'Interactive widgets';

  @override
  State<InteractiveWidgetsTest> createState() => _InteractiveWidgetsTestState();
}

class _InteractiveWidgetsTestState extends State<InteractiveWidgetsTest> {
  double _sliderValue = 0.5;
  bool _switchValue = false;
  int _tapCount = 0;
  final _textController = TextEditingController();
  final _tapMe = GlobalKey();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Publishes where "Tap me" is, for the tap the end-to-end check makes.
  void _publishTapTarget() {
    final RenderBox? box =
        _tapMe.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final Offset center = box.localToGlobal(box.size.center(Offset.zero));
    publishAutomationState(<String, Object?>{
      'tapTarget': <double>[center.dx, center.dy],
    });
  }

  @override
  Widget build(BuildContext context) {
    publishAutomationState(<String, Object?>{'tapCount': _tapCount});
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishTapTarget());
    return Scaffold(
      appBar: AppBar(title: const Text(InteractiveWidgetsTest.title)),
      body: ListView(
        padding: const .all(16),
        children: [
          Text(
            'Every widget below works as usual with WebAddressBar enabled.',
            style: TextStyle(color: ColorScheme.of(context).onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const .all(16),
              child: Column(
                children: [
                  Text(
                    'Tap count: $_tapCount',
                    style: TextTheme.of(context).titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        key: _tapMe,
                        onPressed: () => setState(() => _tapCount++),
                        child: const Text('Tap me'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _tapCount = 0),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const .all(16),
              child: Column(
                children: [
                  Text('Slider: ${_sliderValue.toStringAsFixed(2)}'),
                  Slider(
                    value: _sliderValue,
                    onChanged: (v) => setState(() => _sliderValue = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: const Text('Switch'),
              value: _switchValue,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const .all(16),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Type something',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onLongPress: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Long press detected')),
                );
              },
              child: const Padding(
                padding: .all(24),
                child: Center(child: Text('Long press me')),
              ),
            ),
          ),
          for (int i = 0; i < 30; i++) ListTile(title: Text('Item ${i + 1}')),
        ],
      ),
    );
  }
}
