import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class BaristaViewerPage extends StatefulWidget {
  const BaristaViewerPage({super.key});

  @override
  State<BaristaViewerPage> createState() => _BaristaViewerPageState();
}

class _BaristaViewerPageState extends State<BaristaViewerPage> {
  final Map<String, bool> _done = {
    '1. Rót 100ml Cold Brew vào ca đong': true,
    '2. Thêm 40ml nước cam vắt': false,
    '3. Đong 15ml syrup quế thanh': false,
    '4. Đổ đầy ly 200g đá viên bi': false,
    '5. Trang trí 1 lát cam vàng sấy': false,
  };

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Chế độ Barista Viewer',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Barista Header Card (High Contrast)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NomadKit.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: NomadKit.forestLight, borderRadius: BorderRadius.circular(10)),
                        child: const Text('CHÍNH THỨC v2.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.forest)),
                      ),
                      const Text('RC-COLD-02', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: NomadKit.secondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Cold Brew Cam Quế', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: NomadKit.ink)),
                  const SizedBox(height: 4),
                  const Text('Thời gian phục vụ tiêu chuẩn: 45 giây', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Định lượng nguyên liệu nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            const SizedBox(height: 10),

            ..._done.keys.map(
              (key) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  color: NomadKit.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: NomadKit.border),
                  ),
                  child: CheckboxListTile(
                    activeColor: NomadKit.sand,
                    title: Text(
                      key,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _done[key]! ? NomadKit.secondary : NomadKit.ink,
                        decoration: _done[key]! ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    value: _done[key],
                    onChanged: (v) => setState(() => _done[key] = v ?? false),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
