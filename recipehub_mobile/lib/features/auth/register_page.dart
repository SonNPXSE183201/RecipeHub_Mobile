import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
        ),
        title: const Text(
          'Đăng ký tài khoản',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: NomadKit.ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tham gia R&D Hub', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink)),
              const SizedBox(height: 4),
              const Text('Chuẩn hóa công thức và chia sẻ tài liệu SOP cho toàn chuỗi.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
              const SizedBox(height: 24),

              _inputField('Họ và tên', 'Trần Thùy Linh'),
              const SizedBox(height: 14),
              _inputField('Email công việc', 'linh.tran@recipehub.vn'),
              const SizedBox(height: 14),
              _inputField('Vai trò R&D', 'Chuyên viên nghiên cứu & phát triển (Beverage)'),
              const SizedBox(height: 14),
              _inputField('Mật khẩu', '••••••••', obscure: true),
              const SizedBox(height: 14),
              _inputField('Xác nhận mật khẩu', '••••••••', obscure: true),
              const SizedBox(height: 24),

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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đăng ký tài khoản R&D thành công!')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Hoàn tất đăng ký', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, String value, {bool obscure = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NomadKit.border),
            ),
            child: TextField(
              controller: TextEditingController(text: value),
              obscureText: obscure,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, color: NomadKit.ink),
            ),
          ),
        ],
      );
}
