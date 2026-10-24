import 'package:flutter/gestures.dart' show HitTestEntry, HitTestResult;
import 'package:flutter/widgets.dart';

import '../platform/shared.dart' as platform;
import '../web_address_bar.dart';

/// Scrolls the current route's primary scroll view to the top when the iOS
/// status bar is tapped, while [WebAddressBar] is active.
///
/// Safari scrolls the document on a status bar tap, which [WebAddressBar] has
/// taken over; this widget turns that into the scroll a native iOS app gets.
/// It animates the [PrimaryScrollController] below it whose scroll view is in
/// the foreground, the way `Scaffold` does on iOS. A page under another route
/// or a dialog, and hidden tabs, such as those an [IndexedStack] or an
/// [Offstage] does not show, are left alone.
///
/// Put it above the `Navigator`, in the `builder` of `MaterialApp`:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => WebAddressBarScrollToTop(child: child!),
/// )
/// ```
class WebAddressBarScrollToTop extends StatefulWidget {
  /// Creates a widget that scrolls the current route below [child] to the top
  /// on a status bar tap.
  const WebAddressBarScrollToTop({super.key, required this.child});

  /// The subtree with the `Navigator`.
  final Widget child;

  @override
  State<WebAddressBarScrollToTop> createState() =>
      _WebAddressBarScrollToTopState();
}

class _WebAddressBarScrollToTopState extends State<WebAddressBarScrollToTop> {
  @override
  void initState() {
    super.initState();
    platform.statusBarTaps.addListener(_scrollToTop);
  }

  @override
  void dispose() {
    platform.statusBarTaps.removeListener(_scrollToTop);
    super.dispose();
  }

  void _scrollToTop() {
    _foregroundPrimaryScrollController()?.animateTo(
      0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCirc,
    );
  }

  /// The innermost [PrimaryScrollController] below this widget with a scroll
  /// view in the foreground.
  ScrollController? _foregroundPrimaryScrollController() {
    ScrollController? found;
    void visit(Element element) {
      if (element.widget
          case PrimaryScrollController(:final ScrollController controller)
          when controller.positions.any(_isInForeground)) {
        found = controller;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  /// Whether a hit test at the middle of [position]'s scroll view reaches it,
  /// the way `Scaffold` checks that it is in the foreground on iOS.
  ///
  /// It does not for a route under another route or a dialog, nor for a
  /// hidden subtree that stays mounted, such as the tabs an [IndexedStack] or
  /// an [Offstage] does not show.
  bool _isInForeground(ScrollPosition position) {
    final RenderObject? box = position.context.storageContext
        .findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      return false;
    }
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      box.localToGlobal(box.size.center(Offset.zero)),
      View.of(context).viewId,
    );
    return result.path.any((HitTestEntry entry) => entry.target == box);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
