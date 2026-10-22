import 'package:material_ui/material_ui.dart';

/// A pinned [SliverAppBar] expanded to a [FlexibleSpaceBar], whose background
/// is drawn edge-to-edge, under the status bar.
class ExpandingAppBarTest extends StatelessWidget {
  const ExpandingAppBarTest({super.key});

  static const String title = 'Expanding app bar';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = ColorScheme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(title),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primaryContainer, colors.tertiaryContainer],
                  ),
                ),
              ),
            ),
          ),
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
