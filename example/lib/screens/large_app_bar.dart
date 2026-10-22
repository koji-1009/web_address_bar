import 'package:material_ui/material_ui.dart';

/// A pinned [SliverAppBar.large], whose large title collapses into the toolbar
/// while the list scrolls under it.
class LargeAppBarTest extends StatelessWidget {
  const LargeAppBarTest({super.key});

  static const String title = 'Large app bar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text(title)),
          SliverList.builder(
            itemCount: 60,
            itemBuilder: (BuildContext context, int index) =>
                ListTile(title: Text('Item ${index + 1}')),
          ),
        ],
      ),
    );
  }
}
