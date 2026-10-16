import 'package:flutter/material.dart';

/// Protects screens from extreme narrow viewports (e.g., when browser DevTools
/// shrinks the viewport below 300px) by scaling down a virtual 300px layout.
/// On standard mobile/desktop widths (>= 300px), renders [child] directly.
class ResponsiveBounds extends StatelessWidget {
  const ResponsiveBounds({
    super.key,
    required this.child,
    this.minWidth = 300,
  });

  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 0 && constraints.maxWidth < minWidth) {
          final scale = minWidth / constraints.maxWidth;
          final virtualHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight * scale
              : 800.0;
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: minWidth,
              height: virtualHeight,
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}
