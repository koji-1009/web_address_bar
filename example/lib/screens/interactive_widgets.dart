import 'package:material_ui/material_ui.dart';

class InteractiveWidgetsTest extends StatefulWidget {
  const InteractiveWidgetsTest({super.key});

  @override
  State<InteractiveWidgetsTest> createState() => _InteractiveWidgetsTestState();
}

class _InteractiveWidgetsTestState extends State<InteractiveWidgetsTest> {
  double _sliderValue = 0.5;
  bool _switchValue = false;
  int _tapCount = 0;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Widgets')),
      body: ListView(
        padding: const .all(16),
        children: [
          const Text(
            'All widgets below should remain fully interactive '
            'with WebAddressBar enabled.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const .all(16),
              child: Column(
                children: [
                  Text(
                    'Tap count: $_tapCount',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
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
            child: SwitchListTile(
              title: const Text('Toggle switch'),
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
            child: GestureDetector(
              onLongPress: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Long press detected!')),
                );
              },
              child: Container(
                padding: const .all(24),
                alignment: Alignment.center,
                child: const Text('Long press me'),
              ),
            ),
          ),
          for (int i = 0; i < 30; i++)
            ListTile(
              title: Text('Filler item ${i + 1}'),
              tileColor: i.isEven ? Colors.grey.shade50 : null,
            ),
        ],
      ),
    );
  }
}
