import 'package:material_ui/material_ui.dart';

class NestedScrollTest extends StatelessWidget {
  const NestedScrollTest({super.key});

  static const String title = 'Nested scrollables';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: ListView(
        children: [
          Padding(
            padding: const .all(16),
            child: Text(
              'A vertical drag collapses the address bar.\n'
              'A horizontal swipe changes the page without scrolling the list.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => Card(
                margin: const .symmetric(horizontal: 16, vertical: 8),
                color: index.isEven
                    ? colors.primaryContainer
                    : colors.tertiaryContainer,
                child: Center(
                  child: Text(
                    'Page ${index + 1}',
                    style: TextTheme.of(context).headlineMedium,
                  ),
                ),
              ),
            ),
          ),
          for (int i = 0; i < 50; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('Item ${i + 1}'),
            ),
        ],
      ),
    );
  }
}
