import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/nomad_kit.dart';

/// Toast hiển thị phía TRÊN màn hình (không đè lên thanh điều hướng dưới).
///
/// Giữ cùng API với `ScaffoldMessenger` (showSnackBar / clearSnackBars...) để
/// các màn chỉ đổi `ScaffoldMessenger.of(context)` thành `ToastMessenger.of(context)`.
/// Toast vẽ trên Overlay gốc nên luôn nằm trên mọi route và thanh điều hướng.
class ToastController {
  ToastController._(this._overlay, this._entry);

  final OverlayState _overlay;
  OverlayEntry? _entry;
  bool _inserted = false;

  bool get isShowing => _entry != null;

  void close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    if (ToastMessenger._active == this) ToastMessenger._active = null;
    if (!_overlay.mounted) return; // Overlay đã hủy: entry đã được dọn cùng.
    if (_inserted) entry.remove();
    entry.dispose();
  }
}

class ToastMessenger {
  const ToastMessenger._(this._overlay);

  final OverlayState _overlay;
  static ToastController? _active;

  static ToastMessenger of(BuildContext context) {
    final messenger = maybeOf(context);
    assert(messenger != null, 'ToastMessenger.of() cần Overlay (MaterialApp).');
    return messenger!;
  }

  static ToastMessenger? maybeOf(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    return overlay == null ? null : ToastMessenger._(overlay);
  }

  ToastController showSnackBar(SnackBar bar) {
    _active?.close();
    late final ToastController controller;
    final entry = OverlayEntry(
      builder: (_) => AppToastCard(bar: bar, onClose: () => controller.close()),
    );
    controller = ToastController._(_overlay, entry);
    _active = controller;

    void insert() {
      if (!controller.isShowing || !_overlay.mounted) return;
      controller._inserted = true;
      _overlay.insert(entry);
    }

    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // Đang build/layout: chèn sau khung hình để tránh setState trong build.
      binding.addPostFrameCallback((_) => insert());
      binding.ensureVisualUpdate();
    } else {
      insert();
    }
    return controller;
  }

  void clearSnackBars() => _active?.close();
  void hideCurrentSnackBar() => _active?.close();
  void removeCurrentSnackBar() => _active?.close();
}

/// Thẻ toast: trượt xuống từ trên, tự ẩn theo `SnackBar.duration`, vuốt lên để đóng.
class AppToastCard extends StatefulWidget {
  const AppToastCard({super.key, required this.bar, required this.onClose});

  final SnackBar bar;
  final VoidCallback onClose;

  @override
  State<AppToastCard> createState() => _AppToastCardState();
}

class _AppToastCardState extends State<AppToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.bar.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.bar;
    final action = bar.action;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.4),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(
          opacity: curve,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -100) _dismiss();
            },
            child: Semantics(
              liveRegion: true,
              container: true,
              child: Material(
                color: bar.backgroundColor ?? NomadKit.ink,
                elevation: 6,
                shadowColor: Colors.black54,
                clipBehavior: Clip.antiAlias,
                shape:
                    bar.shape ??
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          child: bar.content,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          key: action.key,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                action.textColor ?? NomadKit.sandLight,
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            action.onPressed();
                            _dismiss();
                          },
                          child: Text(action.label),
                        ),
                      ],
                    ],
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
