import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class BrewingTimerPage extends StatefulWidget {
  const BrewingTimerPage({super.key});

  @override
  State<BrewingTimerPage> createState() => _BrewingTimerPageState();
}

class _BrewingTimerPageState extends State<BrewingTimerPage> {
  int _secondsLeft = 45;
  bool _isRunning = false;
  Timer? _timer;
  int _currentStep = 0;

  final List<String> _steps = [
    'Rót 100ml Cold Brew vào ca đong chuẩn',
    'Thêm 40ml nước cam tươi và 15ml syrup quế',
    'Khuấy đều và rót vào ly đá viên 200g',
    'Gác 1 lát cam vàng sấy trang trí và phục vụ khách',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 45;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Quy trình pha chế từng bước',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Large Countdown Timer Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: NomadKit.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: NomadKit.border),
              boxShadow: const [
                BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const Text('ĐỒNG HỒ ĐẾM NGƯỢC PHA CHẾ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                Text(
                  '00:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: NomadKit.ink),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? const Color(0xFFEF4444) : NomadKit.sand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _toggleTimer,
                      icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                      label: Text(_isRunning ? 'Tạm dừng' : 'Bắt đầu đếm', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NomadKit.border),
                        foregroundColor: NomadKit.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _resetTimer,
                      child: const Text('Đặt lại (45s)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Steps Stepper
          const Text('Các bước thực hiện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
          const SizedBox(height: 10),

          ..._steps.asMap().entries.map((e) {
            final idx = e.key;
            final isCurrent = idx == _currentStep;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: isCurrent ? NomadKit.sandLight : NomadKit.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isCurrent ? NomadKit.sand : NomadKit.border),
                ),
                child: ListTile(
                  onTap: () => setState(() => _currentStep = idx),
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? NomadKit.sand : NomadKit.canvas,
                    radius: 14,
                    child: Text('${idx + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isCurrent ? Colors.white : NomadKit.secondary)),
                  ),
                  title: Text(e.value, style: TextStyle(fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: NomadKit.ink)),
                  trailing: isCurrent ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NomadKit.sandDark) : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
