import 'package:flutter/material.dart';

/// Width-based breakpoints for an adaptive, touch-friendly POS UI.
///
/// Uses Material-style dp breakpoints:
/// - compact: < 600dp
/// - medium: 600–1024dp
/// - expanded: > 1024dp
enum ScreenBreakpoint { compact, medium, expanded }

ScreenBreakpoint breakpointForWidth(double widthDp) {
  if (widthDp < 600) return ScreenBreakpoint.compact;
  if (widthDp <= 1024) return ScreenBreakpoint.medium;
  return ScreenBreakpoint.expanded;
}

extension ResponsiveBuildContext on BuildContext {
  ScreenBreakpoint get breakpoint =>
      breakpointForWidth(MediaQuery.sizeOf(this).width);

  bool get isCompact => breakpoint == ScreenBreakpoint.compact;
  bool get isMedium => breakpoint == ScreenBreakpoint.medium;
  bool get isExpanded => breakpoint == ScreenBreakpoint.expanded;

  /// Default page padding that stays comfortable on tablets.
  EdgeInsets get pagePadding {
    final horizontal = switch (breakpoint) {
      ScreenBreakpoint.compact => 16.0,
      ScreenBreakpoint.medium => 24.0,
      ScreenBreakpoint.expanded => 32.0,
    };

    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 16);
  }
}
