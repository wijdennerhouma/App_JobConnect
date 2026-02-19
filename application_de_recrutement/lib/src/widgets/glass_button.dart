import 'dart:ui';
import 'package:flutter/material.dart';

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final bool enableHoverEffect;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius = 16.0,
    this.blur = 8.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
    this.width,
    this.height,
    this.enableHoverEffect = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.white.withOpacity(0.4);

    final effectiveBackgroundColor = widget.backgroundColor ??
        (isDark
            ? theme.colorScheme.primary.withOpacity(0.2)
            : theme.colorScheme.primary.withOpacity(0.1));

    return MouseRegion(
      onEnter: widget.enableHoverEffect
          ? (_) {
              setState(() => _isHovered = true);
            }
          : null,
      onExit: widget.enableHoverEffect
          ? (_) {
              setState(() => _isHovered = false);
            }
          : null,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.borderColor ??
                        (_isHovered
                            ? defaultBorderColor.withOpacity(0.6)
                            : defaultBorderColor),
                    width: widget.borderWidth,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: widget.blur, sigmaY: widget.blur),
                    child: Container(
                      padding: widget.padding ??
                          const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: widget.gradient ??
                            LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isHovered
                                  ? [
                                      effectiveBackgroundColor
                                          .withOpacity(0.3),
                                      effectiveBackgroundColor
                                          .withOpacity(0.15),
                                    ]
                                  : [
                                      effectiveBackgroundColor,
                                      effectiveBackgroundColor
                                          .withOpacity(0.5),
                                    ],
                            ),
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
