import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final double borderWidth;

  const GlassTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.borderRadius = 16.0,
    this.blur = 8.0,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.3);

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isFocused
                ? theme.colorScheme.primary.withOpacity(0.6)
                : (widget.borderColor ?? defaultBorderColor),
            width: _isFocused ? widget.borderWidth + 1 : widget.borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.15),
                        ],
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: TextField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                maxLines: widget.maxLines,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  labelStyle: TextStyle(
                    color: _isFocused
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
