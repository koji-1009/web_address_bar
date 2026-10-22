import 'package:material_ui/material_ui.dart';

class NestedScrollTest extends StatelessWidget {
  const NestedScrollTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nested Scrollables')),
      body: ListView(
        children: [
          const Padding(
            padding: .all(16),
            child: Text(
              'Vertical scroll should collapse address bar.\n'
              'Horizontal swipe should switch pages without interfering.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => Card(
                margin: const .symmetric(horizontal: 16, vertical: 8),
                color:
                    Colors.primaries[index % Colors.primaries.length].shade200,
                child: Center(
                  child: Text(
                    'Page ${index + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (int i = 0; i < 50; i++)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Text('${i + 1}'),
              ),
              title: Text('List item ${i + 1}'),
            ),
        ],
      ),
    );
  }
}
