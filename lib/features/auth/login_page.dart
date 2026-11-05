import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/app_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/auth_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;

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

  Future<void> _afterAttempt(bool ok) async {
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!ok) {
      final msg = _auth.errorMessage;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(key: AppKeys.loginError, content: Text(msg), backgroundColor: NomadKit.error),
        );
      }
    }
    // Thành công: AuthGate tự chuyển sang Shell theo authStateChanges.
  }

  /// Google Sign-In (Firebase Auth). Email chứa "admin" → xin vai trò Store Admin
  /// (AuthViewModel vẫn kiểm soát: khách không được làm Admin).
  Future<void> _handleLogin() async {
    final admin = _emailCtrl.text.toLowerCase().contains('admin');
    _auth.selectRole(admin ? UserRole.admin : UserRole.viewer);
    setState(() => _isLoading = true);
    await _afterAttempt(await _auth.signInWithGoogle());
  }

  /// Tra cứu nhanh tại quầy: Firebase Anonymous Auth, vai trò Barista.
  Future<void> _handleGuest() async {
    _auth.selectRole(UserRole.viewer);
    setState(() => _isLoading = true);
    await _afterAttempt(await _auth.continueAsGuest());
  }

  @override
  Widget build(BuildContext context) {
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
                                      fontSize: 13,
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
                                            borderRadius: BorderRadius.circular(18),
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
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Image.asset(
                                                'assets/icons/app_logo_hero_2k.png',
                                                width: 68,
                                                height: 68,
                                                filterQuality: FilterQuality.medium,
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
                                            borderRadius: BorderRadius.circular(3),
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
                                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFF0EAE1)),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x12000000),
                                                blurRadius: 14,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: NomadKit.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: NomadKit.border.withOpacity(0.8)),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: NomadKit.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _emailCtrl,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(
                                            fontSize: 15,
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mật khẩu',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: NomadKit.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _passCtrl,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(
                                            fontSize: 15,
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
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: NomadKit.secondary,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Remember Login Session & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: NomadKit.sand,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ghi nhớ phiên đăng nhập',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: NomadKit.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng liên hệ Admin chi nhánh để cấp lại mật khẩu.'),
                                ),
                              );
                            },
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.sandDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Primary Pill CTA Button: Đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NomadKit.sand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Secondary Pill Button: Tiếp tục với Google
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          key: AppKeys.googleSignIn,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: NomadKit.surface,
                            foregroundColor: NomadKit.ink,
                            side: const BorderSide(color: NomadKit.border, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              _GoogleLogoIcon(size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Tiếp tục với Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: NomadKit.ink,
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
                              GestureDetector(
                                key: AppKeys.guestSignIn,
                                onTap: _isLoading ? null : _handleGuest,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Tra cứu nhanh tại quầy bar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: NomadKit.sandDark,
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
                                  fontSize: 11.5,
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
      canvas.drawLine(Offset(startX, size.height / 2), Offset(endX, size.height / 2), paint);
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
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
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
