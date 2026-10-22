import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import '../automation.dart';

/// The repro of flutter/flutter#194104: after one long, slow drag on the list
/// and lifting the finger, "Pointers down" must be 0 and the list idle.
///
/// The drag starts on the engine's semantics placeholder on mobile (it covers
/// the view until 20 events have gone by without a screen reader turning up),
/// and an engine that removes it mid-drag takes the rest of the drag's Touch
/// Events off the view root with it.
class LongDragTest extends StatefulWidget {
  const LongDragTest({super.key});

  static const String title = 'Long drag';

  @override
  State<LongDragTest> createState() => _LongDragTestState();
}

class _LongDragTestState extends State<LongDragTest> {
  final Set<int> _pointersDown = <int>{};
  String _listState = 'idle';
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refreshes the placeholder status, which changes outside Flutter.
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    final String state = switch (notification) {
      ScrollStartNotification() => 'scrolling',
      ScrollUpdateNotification(dragDetails: _?) => 'dragging',
      ScrollUpdateNotification() => 'flinging',
      ScrollEndNotification() => 'idle',
      _ => _listState,
    };
    if (state != _listState) {
      setState(() => _listState = state);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool placeholder =
        web.document.querySelector('flt-semantics-placeholder') != null;
    publishAutomationState(<String, Object?>{
      'pointersDown': _pointersDown.length,
      'listState': _listState,
      'placeholder': placeholder,
    });
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        setState(() => _pointersDown.add(event.pointer));
      },
      onPointerUp: (PointerUpEvent event) {
        setState(() => _pointersDown.remove(event.pointer));
      },
      onPointerCancel: (PointerCancelEvent event) {
        setState(() => _pointersDown.remove(event.pointer));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(LongDragTest.title)),
        body: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: _pointersDown.isEmpty
                  ? null
                  : ColorScheme.of(context).tertiaryContainer,
              padding: const .all(8),
              child: Text(
                'Pointers down: ${_pointersDown.length}\n'
                'List: $_listState\n'
                'Semantics placeholder: ${placeholder ? 'present' : 'removed'}',
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(title: Text('Item $index'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
