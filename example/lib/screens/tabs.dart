import 'package:material_ui/material_ui.dart';

/// Tabs that each keep their own navigator and list, the way a bottom
/// navigation shell does. The tabs not shown stay mounted, with their routes
/// current.
class TabsTest extends StatefulWidget {
  const TabsTest({super.key});

  static const String title = 'Tabs';

  @override
  State<TabsTest> createState() => _TabsTestState();
}

class _TabsTestState extends State<TabsTest> {
  static const List<String> _tabs = <String>['One', 'Two'];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(TabsTest.title)),
      body: IndexedStack(
        index: _index,
        children: [
          for (final String tab in _tabs)
            Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => ListView.builder(
                  itemCount: 60,
                  itemBuilder: (BuildContext context, int index) =>
                      ListTile(title: Text('$tab ${index + 1}')),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.looks_one), label: 'One'),
          NavigationDestination(icon: Icon(Icons.looks_two), label: 'Two'),
        ],
      ),
    );
  }
}
