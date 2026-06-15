import 'package:flutter/material.dart';

/// Reusable horizontal scroll wrapper for desktop data surfaces.
///
/// Wide audit/list tables must stay reachable on desktop/web. This wrapper
/// gives the child a minimum width and exposes Flutter's interactive horizontal
/// scrollbar without reading scroll metrics before the controller is attached.
class AppHorizontalScrollView extends StatefulWidget {
  const AppHorizontalScrollView({
    super.key,
    required this.child,
    required this.minWidth,
    this.thumbVisibility = true,
  });

  final Widget child;
  final double minWidth;
  final bool thumbVisibility;

  @override
  State<AppHorizontalScrollView> createState() => _AppHorizontalScrollViewState();
}

class _AppHorizontalScrollViewState extends State<AppHorizontalScrollView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final hasBoundedWidth = maxWidth.isFinite;
        final viewportWidth = hasBoundedWidth ? maxWidth : widget.minWidth;
        final contentWidth = widget.minWidth > viewportWidth
            ? widget.minWidth
            : viewportWidth;
        final shouldScroll = hasBoundedWidth && contentWidth > viewportWidth;

        final surface = SizedBox(
          width: contentWidth.isFinite ? contentWidth : widget.minWidth,
          child: widget.child,
        );

        if (!shouldScroll) {
          return surface;
        }

        return Scrollbar(
          controller: _controller,
          thumbVisibility: widget.thumbVisibility,
          trackVisibility: widget.thumbVisibility,
          interactive: true,
          thickness: 9,
          radius: const Radius.circular(999),
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const ClampingScrollPhysics(),
            child: surface,
          ),
        );
      },
    );
  }
}
