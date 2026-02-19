import 'package:flutter/material.dart';

/// Wraps [child] and applies a subtle scale on hover (web/desktop).
class HoverScaleWrapper extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const HoverScaleWrapper({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<HoverScaleWrapper> createState() => _HoverScaleWrapperState();
}

class _HoverScaleWrapperState extends State<HoverScaleWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
