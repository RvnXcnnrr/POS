import 'package:flutter/material.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    required this.onPressed,
    required this.gradient,
    required this.child,
    required this.foregroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.minHeight = 48,
    super.key,
  });

  final VoidCallback? onPressed;
  final Gradient gradient;
  final Widget child;
  final Color foregroundColor;

  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scheme = Theme.of(context).colorScheme;

    final bg = enabled ? null : scheme.surfaceContainerHigh;
    final fg = enabled ? widget.foregroundColor : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        scale: _pressed ? 0.985 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1.0 : 0.55,
          child: Material(
            color: const Color(0x00000000),
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                gradient: enabled ? widget.gradient : null,
                borderRadius: widget.borderRadius,
              ),
              child: InkWell(
                borderRadius: widget.borderRadius,
                onTap: widget.onPressed,
                onHighlightChanged: (v) {
                  if (!enabled) return;
                  setState(() => _pressed = v);
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: widget.minHeight),
                  child: Padding(
                    padding: widget.padding,
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900, color: fg),
                      child: IconTheme.merge(
                        data: IconThemeData(color: fg),
                        child: Center(child: widget.child),
                      ),
                    ),
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
