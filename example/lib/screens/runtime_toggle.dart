import 'package:material_ui/material_ui.dart';
import 'package:web_address_bar/web_address_bar.dart';

/// Turns the package off and on from a switch, while the app runs.
class RuntimeToggleTest extends StatefulWidget {
  const RuntimeToggleTest({super.key});

  static const String title = 'Runtime toggle';

  @override
  State<RuntimeToggleTest> createState() => _RuntimeToggleTestState();
}

class _RuntimeToggleTestState extends State<RuntimeToggleTest> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(RuntimeToggleTest.title)),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('WebAddressBar'),
            subtitle: Text(WebAddressBar.isActive ? 'Active' : 'Off'),
            value: WebAddressBar.isActive,
            onChanged: (bool on) {
              // Called once the finger has lifted, as enable requires.
              on ? WebAddressBar.enable() : WebAddressBar.disable();
              setState(() {});
            },
          ),
          ListTile(
            title: Text('Tap count: $_tapCount'),
            trailing: FilledButton(
              onPressed: () => setState(() => _tapCount++),
              child: const Text('Tap me'),
            ),
          ),
          for (int i = 0; i < 60; i++) ListTile(title: Text('Item ${i + 1}')),
        ],
      ),
    );
  }
}
