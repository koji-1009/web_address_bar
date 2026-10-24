import 'package:material_ui/material_ui.dart';

/// The app's own pull to refresh, which the page's is replaced by.
class RefreshTest extends StatefulWidget {
  const RefreshTest({super.key});

  static const String title = 'Refresh indicator';

  @override
  State<RefreshTest> createState() => _RefreshTestState();
}

class _RefreshTestState extends State<RefreshTest> {
  int _refreshCount = 0;

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() => _refreshCount++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(RefreshTest.title)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: 60,
          itemBuilder: (BuildContext context, int index) => ListTile(
            title: Text(
              index == 0 ? 'Refreshed: $_refreshCount' : 'Item $index',
            ),
          ),
        ),
      ),
    );
  }
}
