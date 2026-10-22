import 'package:material_ui/material_ui.dart';

/// A floating [SliverAppBar] that snaps back into view on any scroll toward
/// the top, as the address bar does.
class FloatingAppBarTest extends StatelessWidget {
  const FloatingAppBarTest({super.key});

  static const String title = 'Floating app bar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, snap: true, title: Text(title)),
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
