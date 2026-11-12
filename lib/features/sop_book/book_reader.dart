import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/rh_motion.dart';

/// Thông số lật trang lấy từ prototype (book-reader.tsx, ebooklet.ts, styles.css).
class BookMotion {
  BookMotion._();
  static const turn = Duration(milliseconds: 400); // pageTurnDuration = .4
  static const turnCurve = Cubic(.32, .05, .2, 1);
  static const settle = Duration(milliseconds: 180);
  static const close = Duration(milliseconds: 240);
  static const perspective = 1400.0;
  static const maxDragDeg = 35.0;
  static const swipeMinDx = 72.0;
}

enum _Gesture { pending, horizontal, dismiss }

/// Trang sách cố định, lật quanh gáy trái như prototype: trang đang lật xoay
/// rotateY 0→-180° trên trang đích, mặt sau hiện chữ "RecipeHub".
/// `index` do bên ngoài giữ; đổi `index` (cùng `layoutToken`) sẽ chạy hiệu ứng lật.
class BookReaderStage extends StatefulWidget {
  const BookReaderStage({
    super.key,
    required this.leafCount,
    required this.index,
    required this.layoutToken,
    required this.leafBuilder,
    required this.onIndexRequested,
    required this.onClose,
  });

  final int leafCount;
  final int index;

  /// Đổi giá trị khi bố cục trang bị tính lại (xoay màn hình, cỡ chữ…): không chạy hiệu ứng.
  final Object layoutToken;
  final Widget Function(BuildContext context, int leaf) leafBuilder;
  final ValueChanged<int> onIndexRequested;
  final VoidCallback onClose;

  @override
  State<BookReaderStage> createState() => _BookReaderStageState();
}

class _BookReaderStageState extends State<BookReaderStage>
    with TickerProviderStateMixin {
  late final AnimationController _turnCtl = AnimationController(
    vsync: this,
    duration: BookMotion.turn,
  )..addStatusListener(_onTurnStatus);
  late final AnimationController _settleCtl = AnimationController(
    vsync: this,
    duration: BookMotion.settle,
  );
  late final AnimationController _closeCtl = AnimationController(
    vsync: this,
    duration: BookMotion.close,
  );

  int _from = 0;
  int _to = 0;
  int _dir = 0;
  bool get _turning => _dir != 0;

  // Kéo tay.
  Offset? _start;
  double _dx = 0;
  double _dy = 0;
  DateTime _startTime = DateTime.now();
  _Gesture _gesture = _Gesture.pending;
  double _angle = 0; // rad, xem trước khi kéo ngang
  double _lift = 0; // px, kéo xuống để đóng
  double _angle0 = 0;
  double _lift0 = 0;
  bool _closing = false;
  double _stageHeight = 800;

  bool get _reduced => RhMotion.reduced(context);

  @override
  void initState() {
    super.initState();
    _settleCtl.addListener(() {
      final t = Curves.easeOut.transform(_settleCtl.value);
      setState(() {
        _angle = _angle0 * (1 - t);
        _lift = _lift0 * (1 - t);
      });
    });
    _closeCtl.addListener(() => setState(() {
      _lift = _lift0 + (_stageHeight - _lift0) *
          Cubic(.2, 0, 0, 1).transform(_closeCtl.value);
    }));
    _closeCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onClose();
    });
  }

  @override
  void didUpdateWidget(BookReaderStage old) {
    super.didUpdateWidget(old);
    if (old.layoutToken != widget.layoutToken) {
      _turnCtl.stop();
      _dir = 0;
      return;
    }
    if (old.index != widget.index) {
      if (_reduced || widget.leafCount == 0) {
        _dir = 0;
        return;
      }
      // Đang lật dở thì chốt trang cũ rồi lật tiếp từ vị trí hiện tại.
      _turnCtl.stop();
      _from = old.index;
      _to = widget.index;
      _dir = _to > _from ? 1 : -1;
      _turnCtl.forward(from: 0);
    }
  }

  void _onTurnStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) setState(() => _dir = 0);
  }

  @override
  void dispose() {
    _turnCtl.dispose();
    _settleCtl.dispose();
    _closeCtl.dispose();
    super.dispose();
  }

  // ── Cử chỉ ────────────────────────────────────────────────────────────────

  void _down(PointerDownEvent e) {
    if (_closing || _turning) return;
    _settleCtl.stop();
    _start = e.position;
    _dx = _dy = 0;
    _startTime = DateTime.now();
    _gesture = _Gesture.pending;
  }

  _Gesture _lock(double dx, double dy) {
    if (math.max(dx.abs(), dy.abs()) < 12) return _Gesture.pending;
    if (dx.abs() > dy.abs() * 1.35) return _Gesture.horizontal;
    if (dy > dx.abs() * 1.35) return _Gesture.dismiss;
    return _Gesture.pending;
  }

  void _move(PointerMoveEvent e) {
    final s = _start;
    if (s == null) return;
    _dx = e.position.dx - s.dx;
    _dy = e.position.dy - s.dy;
    if (_gesture == _Gesture.pending) _gesture = _lock(_dx, _dy);
    if (_gesture == _Gesture.dismiss) {
      setState(() => _lift = math.max(0, _dy));
    } else if (_gesture == _Gesture.horizontal) {
      final can =
          (_dx < 0 && widget.index < widget.leafCount - 1) ||
          (_dx > 0 && widget.index > 0);
      if (can && !_reduced) {
        final deg = (_dx / 10).clamp(-BookMotion.maxDragDeg, BookMotion.maxDragDeg);
        setState(() => _angle = deg * math.pi / 180);
      }
    }
  }

  void _up(PointerEvent e, {bool cancel = false}) {
    final s = _start;
    _start = null;
    if (s == null) return;
    final ms = math.max(
      1,
      DateTime.now().difference(_startTime).inMilliseconds,
    );
    final velocity = _lift / ms;
    final dismiss =
        !cancel &&
        _gesture == _Gesture.dismiss &&
        (_lift >= math.min(180, _stageHeight * .24) ||
            (_lift >= 56 && velocity >= .75));
    if (dismiss) {
      _closing = true;
      if (_reduced) {
        widget.onClose();
      } else {
        _lift0 = _lift;
        _closeCtl.forward(from: 0);
      }
      return;
    }
    if (!cancel && _gesture == _Gesture.horizontal) {
      final swipe = _dx.abs() >= BookMotion.swipeMinDx &&
          _dx.abs() > _dy.abs() * 1.8;
      if (swipe) {
        final target = (widget.index + (_dx < 0 ? 1 : -1)).clamp(
          0,
          widget.leafCount - 1,
        );
        if (target != widget.index) widget.onIndexRequested(target);
      }
    }
    if (_reduced) {
      setState(() => _angle = _lift = 0);
    } else if (_angle != 0 || _lift != 0) {
      _angle0 = _angle;
      _lift0 = _lift;
      _settleCtl.forward(from: 0);
    }
  }

  // ── Dựng hình ─────────────────────────────────────────────────────────────

  /// perspective(1400px) quanh tâm sân khấu, rồi xoay quanh gáy trái (x = 0).
  Matrix4 _matrix(Size size, double theta) {
    final m = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
      ..setEntry(3, 2, -1 / BookMotion.perspective)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1)
      ..rotateY(theta);
    return m;
  }

  Widget _paper(BuildContext context, int leaf, {bool shade = false}) {
    return _BookPaper(
      folio: leaf + 1,
      shade: shade,
      child: widget.leafBuilder(context, leaf),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.leafCount == 0) return const SizedBox.shrink();
    final index = widget.index.clamp(0, widget.leafCount - 1);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        _stageHeight = size.height;
        final baseIndex = _turning && _dir < 0 ? _from : index;

        Widget base = _paper(context, baseIndex);
        if (_angle != 0 && !_turning) {
          base = Transform(
            transform: _matrix(size, _angle),
            child: base,
          );
        }

        final children = <Widget>[base];
        if (_turning) {
          children.add(
            AnimatedBuilder(
              animation: _turnCtl,
              builder: (context, _) {
                final t = BookMotion.turnCurve.transform(_turnCtl.value);
                final mag = (_dir > 0 ? t : 1 - t) * math.pi; // 0..π
                final front = mag < math.pi / 2;
                final frontLeaf = _dir > 0 ? _from : _to;
                Widget face = front
                    ? _paper(context, frontLeaf, shade: true)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: const _BookBack(),
                      );
                face = DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x2E3A2A1C),
                        offset: const Offset(10, 6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: face,
                );
                return IgnorePointer(
                  child: Transform(
                    transform: _matrix(size, -mag),
                    child: face,
                  ),
                );
              },
            ),
          );
        }

        final scale = _reduced ? 1.0 : 1.0 - math.min(.05, _lift / 6000);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: (e) => _up(e),
          onPointerCancel: (e) => _up(e, cancel: true),
          child: Transform.translate(
            offset: Offset(0, _lift),
            child: Transform.scale(
              scale: scale,
              child: Stack(fit: StackFit.expand, children: children),
            ),
          ),
        );
      },
    );
  }
}

/// Tờ giấy: nền giấy, gáy sách đổ bóng, số trang in ở chân (printed-folio).
class _BookPaper extends StatelessWidget {
  const _BookPaper({required this.child, required this.folio, this.shade = false});
  final Widget child;
  final int folio;
  final bool shade;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.horizontal(
      left: Radius.circular(3),
      right: Radius.circular(10),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: radius,
        border: Border.all(color: NomadKit.border),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(2, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Text(
                '$folio',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 16 / 11,
                  color: NomadKit.secondary,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Bóng gáy sách.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 22,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: .09),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (shade)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF3A2A1C).withValues(alpha: .08),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookBack extends StatelessWidget {
  const _BookBack();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: NomadKit.sandLight,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(3),
        right: Radius.circular(10),
      ),
      border: Border.all(color: NomadKit.border),
    ),
    child: const SizedBox.expand(
      child: Center(
        child: Text(
          'RecipeHub',
          style: TextStyle(
            fontSize: 13,
            color: NomadKit.secondary,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}
