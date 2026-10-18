import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class ErrorRecoveryPage extends StatelessWidget {
  const ErrorRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Chẩn đoán kết nối',
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NomadKit.warningLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: NomadKit.warning.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: NomadKit.warning,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mất kết nối mạng tạm thời',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: NomadKit.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Không thể kết nối đến máy chủ trung tâm. Mọi thay đổi và bản nháp công thức của bạn đã được mã hóa và lưu trữ an toàn trong bộ nhớ ngoại tuyến cục bộ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: NomadKit.secondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NomadKit.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NomadKit.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NomadKit.forestLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined, color: NomadKit.forest, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Bảo vệ dữ liệu nháp',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink),
                            ),
                            Text(
                              '2 công thức đang sửa đã tự động lưu trữ an toàn',
                              style: TextStyle(fontSize: 11, color: NomadKit.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NomadKit.ink,
                          side: const BorderSide(color: NomadKit.border, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Xem nháp ngoại tuyến', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NomadKit.sand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang thử lại kết nối đến máy chủ RecipeHub...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Thử lại kết nối', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
