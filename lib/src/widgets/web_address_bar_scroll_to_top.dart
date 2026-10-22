import 'package:flutter/widgets.dart';

import '../stub/web_address_bar_stub.dart'
    if (dart.library.js_interop) '../web/controller.dart'
    as platform;
import '../web_address_bar.dart';

/// Scrolls the current route's primary scroll view to the top when the iOS
/// status bar is tapped, while [WebAddressBar] is active.
///
/// Safari scrolls the document on a status bar tap, which [WebAddressBar] has
/// taken over; this widget turns that into the scroll a native iOS app gets.
/// It animates the [PrimaryScrollController] of the current route below it,
/// the way `Scaffold` does on iOS. Routes that are not current, such as a page
/// under a dialog, are left alone.
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
    _currentPrimaryScrollController()?.animateTo(
      0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCirc,
    );
  }

  /// The innermost [PrimaryScrollController] below this widget that belongs to
  /// the current route and has a scroll view attached.
  ScrollController? _currentPrimaryScrollController() {
    ScrollController? found;
    void visit(Element element) {
      if (element.widget
          case PrimaryScrollController(:final ScrollController controller)
          when controller.hasClients &&
              (ModalRoute.isCurrentOf(element) ?? false)) {
        found = controller;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
