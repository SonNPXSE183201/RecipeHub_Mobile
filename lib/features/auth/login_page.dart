import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../rd_staff/main_nav_shell.dart';
import '../barista/viewer_home_page.dart';
import '../admin/admin_console_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _selectedRoleIndex = 0; // 0: R&D, 1: Barista, 2: Admin
  bool _obscurePassword = true;
  bool _rememberMe = true;

  final _emailCtrl = TextEditingController(text: 'rnd@recipehub.vn');
  final _passCtrl = TextEditingController(text: '••••••••');

  void _onRoleChanged(int index) {
    setState(() {
      _selectedRoleIndex = index;
      if (index == 0) {
        _emailCtrl.text = 'rnd@recipehub.vn';
      } else if (index == 1) {
        _emailCtrl.text = 'barista@recipehub.vn';
      } else {
        _emailCtrl.text = 'admin@recipehub.vn';
      }
    });
  }

  void _handleLogin() {
    if (_selectedRoleIndex == 0) {
      go(context, const MainNavShell(initialTab: 0));
    } else if (_selectedRoleIndex == 1) {
      go(context, const ViewerHomePage());
    } else {
      go(context, const AdminConsolePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Figma Coffee Squircle Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: NomadKit.sand,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.coffee_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),

              // Headline & Subtitle
              const Text(
                'RecipeHub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: NomadKit.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Biến thử nghiệm thành quy trình chuẩn.',
                style: TextStyle(fontSize: 14, color: NomadKit.secondary),
              ),
              const SizedBox(height: 28),

              // Role Segmented Selector (Clean Production UI)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NomadKit.border),
                ),
                child: Row(
                  children: [
                    _roleSegmentItem('R&D Lead', 0),
                    _roleSegmentItem('Barista', 1),
                    _roleSegmentItem('Quản trị', 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              const Text(
                'Email công việc',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NomadKit.border),
                ),
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: NomadKit.secondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14, color: NomadKit.ink),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              const Text(
                'Mật khẩu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: NomadKit.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NomadKit.border),
                ),
                child: TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: NomadKit.secondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: NomadKit.secondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14, color: NomadKit.ink),
                ),
              ),
              const SizedBox(height: 12),

              // Remember Me & Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: NomadKit.sand,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) => setState(() => _rememberMe = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ghi nhớ đăng nhập',
                        style: TextStyle(fontSize: 12, color: NomadKit.secondary),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(fontSize: 12, color: NomadKit.ocean, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Primary Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NomadKit.sand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Register Navigation Link
              Center(
                child: TextButton(
                  onPressed: () => go(context, const RegisterPage()),
                  child: const Text(
                    'Chưa có tài khoản? Đăng ký chuyên viên mới',
                    style: TextStyle(fontSize: 13, color: NomadKit.ocean, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleSegmentItem(String label, int index) {
    final isSelected = _selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? NomadKit.sand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : NomadKit.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
