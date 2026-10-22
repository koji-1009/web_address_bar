import 'package:material_ui/material_ui.dart';

class TapOnlyTest extends StatefulWidget {
  const TapOnlyTest({super.key});

  @override
  State<TapOnlyTest> createState() => _TapOnlyTestState();
}

class _TapOnlyTestState extends State<TapOnlyTest> {
  Color _color = Colors.blue;
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tap Only (No Scroll)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This page has no scrollable content.\n'
              'Taps, drags, and other gestures should work normally.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                setState(() {
                  _counter++;
                  _color = Colors.primaries[_counter % Colors.primaries.length];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_counter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tap the box to change color'),
          ],
        ),
      ),
    );
  }
}
