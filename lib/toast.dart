import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';

enum AurexToastType { error, success }

OverlayEntry? _currentToast;

/// Slides a toast in from the top of the screen. It disappears after a few
/// seconds, or earlier when tapped or swiped away. Only one is shown at once.
void showAurexToast(
  BuildContext context, {
  required String title,
  required String message,
  AurexToastType type = AurexToastType.error,
  IconData? icon,
}) {
  AurexToaster.of(
    context,
  ).show(title: title, message: message, type: type, icon: icon);
}

/// Shows toasts after an `await`: grab it with [AurexToaster.of] before the
/// async gap (like `ScaffoldMessenger.of`), then call [success] or [error].
class AurexToaster {
  AurexToaster.of(BuildContext context)
    : _overlay = Overlay.of(context, rootOverlay: true);

  final OverlayState _overlay;

  void success(String title, String message) =>
      show(title: title, message: message, type: AurexToastType.success);

  void error(String title, String message, {IconData? icon}) =>
      show(title: title, message: message, icon: icon);

  void show({
    required String title,
    required String message,
    AurexToastType type = AurexToastType.error,
    IconData? icon,
  }) {
    if (_overlay.mounted) {
      _insertToast(_overlay, title, message, type, icon);
    }
  }
}

void _insertToast(
  OverlayState overlay,
  String title,
  String message,
  AurexToastType type,
  IconData? icon,
) {
  if (_currentToast?.mounted ?? false) _currentToast!.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _AurexToast(
      title: title,
      message: message,
      type: type,
      icon:
          icon ??
          (type == AurexToastType.success
              ? Icons.check_circle_outline
              : Icons.error_outline),
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (identical(_currentToast, entry)) _currentToast = null;
      },
    ),
  );

  _currentToast = entry;
  overlay.insert(entry);
}

/// Error toast for a failed sign-in request, with a title and icon that
/// match the kind of failure.
void showAuthErrorToast(
  BuildContext context,
  AurexApiException error, {
  String title = 'Login failed',
}) {
  final (String heading, IconData icon) = switch (error.statusCode) {
    0 => ("Can't connect", Icons.wifi_off_rounded),
    429 => ('Too many attempts', Icons.hourglass_bottom_rounded),
    401 || 422 => (title, Icons.lock_outline_rounded),
    >= 500 => ('Server problem', Icons.cloud_off_rounded),
    _ => (title, Icons.error_outline_rounded),
  };

  showAurexToast(context, title: heading, message: error.message, icon: icon);
}

class _AurexToast extends StatefulWidget {
  const _AurexToast({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final AurexToastType type;
  final IconData icon;
  final VoidCallback onDismissed;

  @override
  State<_AurexToast> createState() => _AurexToastState();
}

class _AurexToastState extends State<_AurexToast>
    with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(seconds: 4);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(_visibleFor, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.type == AurexToastType.success
        ? const Color(0xFF69C94B)
        : const Color(0xFFFF5A4F);
    final top = MediaQuery.paddingOf(context).top + 14;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: FadeTransition(
              opacity: _controller,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, -0.6),
                  end: Offset.zero,
                ).animate(_curve),
                child: Semantics(
                  liveRegion: true,
                  label: '${widget.title}. ${widget.message}',
                  excludeSemantics: true,
                  child: Dismissible(
                    key: const ValueKey('aurex-toast'),
                    direction: DismissDirection.up,
                    onDismissed: (_) {
                      _timer?.cancel();
                      widget.onDismissed();
                    },
                    child: GestureDetector(
                      onTap: _close,
                      child: Material(
                        color: Colors.transparent,
                        child: _ToastCard(
                          title: widget.title,
                          message: widget.message,
                          icon: widget.icon,
                          accent: accent,
                        ),
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

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF2151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 6, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10, right: 10),
              child: Icon(Icons.close_rounded, color: Colors.white38, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
