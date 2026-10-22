import 'package:material_ui/material_ui.dart';

class BasicVerticalListTest extends StatelessWidget {
  const BasicVerticalListTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Vertical List')),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('Item ${index + 1}'),
          subtitle: const Text('Scroll to collapse the address bar'),
          tileColor: index.isEven ? null : Colors.grey.shade50,
        ),
      ),
    );
  }
}
