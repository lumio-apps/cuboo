import 'package:flutter/material.dart';

import '../theme.dart';

/// The big rounded button with a hard shadow under it.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 72,
    this.fontSize = 28,
    this.color = kCoral,
    this.textColor = kInk,
    this.shadowColor = const Color(0xFFC94A3C),
    this.radius = 24,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;
  final Color color;
  final Color textColor;
  final Color shadowColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final borderRadius = BorderRadius.circular(radius);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 5)),
          ],
        ),
        child: Material(
          color: color,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: textColor, size: fontSize),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A flat, soft button (Themes, Settings, Undo, Home...).
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 60,
    this.fontSize = 18,
    this.useAlt = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;

  /// Use the slightly stronger surface colour.
  final bool useAlt;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final enabled = onPressed != null;
    final borderRadius = BorderRadius.circular(20);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: useAlt ? c.surfaceAlt : c.surface,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: c.text, size: fontSize + 4),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.text,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small square icon button in the game header.
class IconSquareButton extends StatelessWidget {
  const IconSquareButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = CubooColors.of(context);
    final borderRadius = BorderRadius.circular(16);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: c.text, size: 24),
          ),
        ),
      ),
    );
  }
}
