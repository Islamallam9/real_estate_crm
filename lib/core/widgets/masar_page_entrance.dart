import 'package:flutter/material.dart';

class MasarPageEntrance extends StatefulWidget {
  const MasarPageEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<MasarPageEntrance> createState() => _MasarPageEntranceState();
}

class _MasarPageEntranceState extends State<MasarPageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    _bindAnimations();
    _controller.forward();
  }

  static const Duration _entranceDuration = Duration(milliseconds: 260);

  void _bindAnimations() {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.986, end: 1).animate(curve);
  }

  @override
  void didUpdateWidget(covariant MasarPageEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _controller
        ..duration = _entranceDuration
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ),
    );
  }
}
