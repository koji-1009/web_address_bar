import 'package:material_ui/material_ui.dart';

class TapOnlyTest extends StatefulWidget {
  const TapOnlyTest({super.key});

  static const String title = 'Tap only';

  @override
  State<TapOnlyTest> createState() => _TapOnlyTestState();
}

class _TapOnlyTestState extends State<TapOnlyTest> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = ColorScheme.of(context);
    final Color color = _counter.isEven ? colors.primary : colors.tertiary;
    final Color onColor = _counter.isEven
        ? colors.onPrimary
        : colors.onTertiary;
    return Scaffold(
      appBar: AppBar(title: const Text(TapOnlyTest.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'This page does not scroll.\n'
              'A drag still collapses the address bar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => setState(() => _counter++),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_counter',
                  style: TextTheme.of(context).displayMedium
                      ?.copyWith(color: onColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tap the box to count'),
          ],
        ),
      ),
    );
  }
}
