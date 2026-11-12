import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/widgets/app_toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  AuthViewModel get _auth => context.read<AuthViewModel>();

  void _showError() {
    final msg = _auth.errorMessage;
    if (msg == null) return;
    ToastMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: AppKeys.loginError,
          content: Text(msg),
          backgroundColor: NomadKit.error,
        ),
      );
  }

  /// Luồng chính: email + mật khẩu. Thành công → AuthGate tự chuyển sang Shell.
  Future<void> _handleEmailLogin() async {
    if (_auth.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _auth.signInWithEmail(_emailCtrl.text, _passCtrl.text);
    if (mounted && !ok) _showError();
  }

  /// Luồng riêng: Google Sign-In. Vai trò do server cấp, không đoán theo email nhập.
  Future<void> _handleGoogle() async {
    if (_auth.isBusy) return;
    _auth.selectRole(UserRole.viewer);
    final ok = await _auth.signInWithGoogle();
    if (mounted && !ok) _showError();
  }

  /// Tra cứu nhanh tại quầy: Firebase Anonymous Auth, vai trò Barista.
  Future<void> _handleGuest() async {
    if (_auth.isBusy) return;
    _auth.selectRole(UserRole.viewer);
    final ok = await _auth.continueAsGuest();
    if (mounted && !ok) _showError();
  }

  Future<void> _openForgotPassword() async {
    if (_auth.isBusy) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NomadKit.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider<AuthViewModel>.value(
        value: _auth,
        child: _ForgotPasswordSheet(initialEmail: _emailCtrl.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final busy = auth.isBusy;
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),

                      // Top Hero Section (2-Column Title + Tilted Polaroid & Ticket Collage)
                      SizedBox(
                        height: 220,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Left Column: Brand Overline + Greeting + Tagline
                            Positioned(
                              left: 0,
                              top: 12,
                              right: 160,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'RECIPEHUB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.sandDark,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Chào mừng\ntrở lại',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: NomadKit.ink,
                                      height: 1.14,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Công thức chuẩn. Quầy bar vững vàng.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: NomadKit.secondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right Collage: Tilted Polaroid Card + Tape + Ticket
                            Positioned(
                              right: -4,
                              top: 0,
                              child: SizedBox(
                                width: 175,
                                height: 215,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Tilted Polaroid Frame
                                    Positioned(
                                      right: 6,
                                      top: 10,
                                      child: Transform.rotate(
                                        angle: 0.11,
                                        child: Container(
                                          width: 136,
                                          height: 136,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x14000000),
                                                blurRadius: 18,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCEAD5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Image.asset(
                                                'assets/icons/app_logo_hero_2k.png',
                                                width: 68,
                                                height: 68,
                                                filterQuality:
                                                    FilterQuality.medium,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Coral Washi Tape Strip on Top of Polaroid
                                    Positioned(
                                      right: 48,
                                      top: 0,
                                      child: Transform.rotate(
                                        angle: -0.14,
                                        child: Container(
                                          width: 48,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E84),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Overlapping Tilted Receipt/Ticket Card
                                    Positioned(
                                      left: 0,
                                      bottom: 6,
                                      child: Transform.rotate(
                                        angle: -0.06,
                                        child: Container(
                                          width: 168,
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            12,
                                            14,
                                            14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFF0EAE1),
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x12000000),
                                                blurRadius: 14,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                'CA PHA CHẾ · V2.0',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: NomadKit.secondary,
                                                  letterSpacing: 0.7,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '100% Chuẩn vị',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: NomadKit.sandDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 54),

                      // Unified White Input Card (Email + Dashed Line + Password)
                      Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: NomadKit.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: NomadKit.border.withOpacity(0.8),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Email Row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9EFE4),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.mail_outline_rounded,
                                        size: 20,
                                        color: NomadKit.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: NomadKit.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          TextFormField(
                                            key: AppKeys.loginEmail,
                                            controller: _emailCtrl,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: const [
                                              AutofillHints.email,
                                            ],
                                            enabled: !busy,
                                            validator: (v) =>
                                                (v == null ||
                                                    !v.contains('@') ||
                                                    v.trim().length < 5)
                                                ? 'Nhập email hợp lệ'
                                                : null,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: NomadKit.ink,
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Dashed Divider
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: _DashedDivider(color: NomadKit.border),
                              ),

                              // Password Row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9EFE4),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 20,
                                        color: NomadKit.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Mật khẩu',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: NomadKit.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          TextFormField(
                                            key: AppKeys.loginPassword,
                                            controller: _passCtrl,
                                            obscureText: _obscurePassword,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: const [
                                              AutofillHints.password,
                                            ],
                                            enabled: !busy,
                                            onFieldSubmitted: (_) =>
                                                _handleEmailLogin(),
                                            validator: (v) =>
                                                (v == null || v.isEmpty)
                                                ? 'Nhập mật khẩu'
                                                : null,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: NomadKit.ink,
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      key: AppKeys.loginTogglePassword,
                                      tooltip: _obscurePassword
                                          ? 'Hiện mật khẩu'
                                          : 'Ẩn mật khẩu',
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: NomadKit.secondary,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: AppKeys.loginForgot,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: busy ? null : _openForgotPassword,
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: NomadKit.sandDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nút chính: Đăng nhập bằng email + mật khẩu
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          key: AppKeys.loginSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NomadKit.sand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: busy ? null : _handleEmailLogin,
                          child: auth.isEmailBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: const [
                          Expanded(child: Divider(color: NomadKit.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'hoặc',
                              style: TextStyle(
                                fontSize: 14,
                                color: NomadKit.secondary,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: NomadKit.border)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Nút phụ: Google (luồng riêng)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          key: AppKeys.googleSignIn,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: NomadKit.surface,
                            foregroundColor: NomadKit.ink,
                            side: const BorderSide(
                              color: NomadKit.border,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: busy ? null : _handleGoogle,
                          child: auth.isGoogleBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NomadKit.ink,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    _GoogleLogoIcon(size: 20),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Đăng nhập với Google',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: NomadKit.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const Spacer(),

                      // Bottom Footer Links & Version Pinned to Bottom
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 24),
                        child: Center(
                          child: Column(
                            children: [
                              TextButton(
                                key: AppKeys.guestSignIn,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: busy ? null : _handleGuest,
                                child: auth.isGuestBusy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Flexible(
                                            child: Text(
                                              'Tra cứu nhanh tại quầy bar',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: NomadKit.sandDark,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: NomadKit.sandDark,
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Phiên bản 2.0 · Quản lý công thức & đào tạo RecipeHub',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: NomadKit.secondary.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1.5),
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      final endX = math.min(startX + dashWidth, size.width);
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.20;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 0.60, false, paint);

    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.78, math.pi * 0.44, false, paint);

    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.18, math.pi * 0.60, false, paint);

    // Blue right arc + horizontal bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.04, math.pi * 0.24, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.41,
        size.width * 0.46,
        strokeWidth * 0.92,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom sheet "Quên mật khẩu": luôn trả lời trung tính, không lộ email có tài khoản hay không.
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialEmail,
  );
  String? _result;
  bool _isError = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _ctrl.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _result = 'Nhập email hợp lệ.';
        _isError = true;
      });
      return;
    }
    final auth = context.read<AuthViewModel>();
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _isError = !ok;
      _result = ok
          ? 'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.'
          : (auth.errorMessage ?? 'Không gửi được yêu cầu. Vui lòng thử lại.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthViewModel>().isBusy;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quên mật khẩu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: NomadKit.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.',
            style: TextStyle(
              fontSize: 14,
              color: NomadKit.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: AppKeys.forgotEmail,
            controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => busy ? null : _submit(),
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Text(
              _result!,
              key: AppKeys.forgotResult,
              style: TextStyle(
                fontSize: 14,
                color: _isError ? NomadKit.error : NomadKit.ink,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: AppKeys.forgotSubmit,
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gửi thư đặt lại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
