import 'package:flutter/material.dart';

/// Opens [child] as a bottom sheet above the floating tab bar.
///
/// Sheets must use the root navigator: a tab's own navigator sits underneath
/// the tab bar, which would cover the bottom of the sheet (and its buttons).
/// The sheet can grow to full height, so long forms scroll inside it.
Future<T?> showAurexSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => child,
  );
}
