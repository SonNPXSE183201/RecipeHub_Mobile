import 'package:flutter/material.dart';

/// Thông số chuyển động lấy từ prototype (docs/4943d36c.../src/styles.css, primitives.tsx, app.tsx):
/// --motion-press 100ms · --motion-tab 180ms · --motion-page 260ms · --ease-standard cubic-bezier(.2,0,0,1).
class RhMotion {
  RhMotion._();

  static const press = Duration(milliseconds: 100);
  static const tab = Duration(milliseconds: 180);
  static const page = Duration(milliseconds: 260);
  static const standard = Cubic(.2, 0, 0, 1);

  /// Màn bên dưới lùi sang trái 18px khi có màn mới phủ lên (animate x: -18).
  static const underShift = 18.0;

  /// Nhấn nút: scale(.975).
  static const pressScale = .975;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Màn con trượt từ phải vào 260ms (thoát ngược lại), màn bên dưới lùi 18px.
/// Tương đương `Screen` trong prototype; bật "giảm chuyển động" thì chỉ mờ dần.
class RhPageRoute<T> extends MaterialPageRoute<T> {
  RhPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => RhMotion.page;

  @override
  Duration get reverseTransitionDuration => RhMotion.page;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (RhMotion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final under = secondaryAnimation.drive(
      CurveTween(curve: RhMotion.standard),
    );
    return AnimatedBuilder(
      animation: under,
      builder: (context, content) => Transform.translate(
        offset: Offset(-RhMotion.underShift * under.value, 0),
        child: content,
      ),
      child: SlideTransition(
        position: animation
            .drive(CurveTween(curve: RhMotion.standard))
            .drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
        child: child,
      ),
    );
  }
}

/// Phản hồi khi chạm: thu nhỏ còn 97.5% trong 100ms (button:active trong prototype).
/// Không chặn cử chỉ của con.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = _down && widget.enabled && !RhMotion.reduced(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: active ? RhMotion.pressScale : 1,
        duration: RhMotion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
