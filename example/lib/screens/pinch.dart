import 'package:material_ui/material_ui.dart';

/// An [InteractiveViewer] to pinch and pan with two fingers, with how many
/// pointers the app sees down.
class PinchTest extends StatefulWidget {
  const PinchTest({super.key});

  static const String title = 'Pinch';

  @override
  State<PinchTest> createState() => _PinchTestState();
}

class _PinchTestState extends State<PinchTest> {
  final Set<int> _pointersDown = <int>{};

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(PinchTest.title)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const .all(8),
            child: Text('Pointers down: ${_pointersDown.length}'),
          ),
          Expanded(
            child: Listener(
              onPointerDown: (PointerDownEvent event) =>
                  setState(() => _pointersDown.add(event.pointer)),
              onPointerUp: (PointerUpEvent event) =>
                  setState(() => _pointersDown.remove(event.pointer)),
              onPointerCancel: (PointerCancelEvent event) =>
                  setState(() => _pointersDown.remove(event.pointer)),
              child: InteractiveViewer(
                maxScale: 8,
                child: GridView.count(
                  crossAxisCount: 6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    for (int i = 0; i < 48; i++)
                      ColoredBox(
                        color: i.isEven
                            ? colors.primaryContainer
                            : colors.secondaryContainer,
                        child: Center(child: Text('${i + 1}')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
