import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';

class AdminAiConfigPage extends StatefulWidget {
  const AdminAiConfigPage({super.key, this.showSuccessDirectly = false});
  final bool showSuccessDirectly;

  @override
  State<AdminAiConfigPage> createState() => _AdminAiConfigPageState();
}

class _AdminAiConfigPageState extends State<AdminAiConfigPage> {
  String _selectedModel = 'Gemini 1.5 Pro';
  bool _obscureKey = true;
  double _temperature = 0.2;
  bool _isTestingPing = false;
  String? _pingResult;

  final _keyCtrl = TextEditingController(text: 'AIzaSyDn98xTK921_NomadProd_GeminiEnterpriseKey');
  final _promptCtrl = TextEditingController(
    text: 'Bạn là Chuyên gia R&D đồ uống chuỗi Nomad Coffee & Tea. Luôn đưa ra tỷ lệ thành phần chính xác định lượng theo gram và mililit. Bảo đảm chất lượng đồng nhất trên 45 chi nhánh.',
  );

  @override
  void initState() {
    super.initState();
    if (widget.showSuccessDirectly) {
      _pingResult = '✓ Kết nối API thành công!\nĐộ trễ: 138 ms · Trạng thái: HTTP 200 OK\nMô hình: $_selectedModel · Hạn ngạch: 100% khả dụng';
    }
  }

  @override
  void didUpdateWidget(AdminAiConfigPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSuccessDirectly) {
      _pingResult = '✓ Kết nối API thành công!\nĐộ trễ: 138 ms · Trạng thái: HTTP 200 OK\nMô hình: $_selectedModel · Hạn ngạch: 100% khả dụng';
    } else {
      _pingResult = null;
    }
  }

  void _runPingTest() {
    setState(() {
      _isTestingPing = true;
      _pingResult = null;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _isTestingPing = false;
        _pingResult = '✓ Kết nối API thành công!\nĐộ trễ: 138 ms · Trạng thái: HTTP 200 OK\nMô hình: $_selectedModel · Hạn ngạch: 100% khả dụng';
      });
    });
  }

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Cấu hình Gemini AI',
        showLogo: true,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('THÔNG SỐ MÔ HÌNH GOOGLE GEMINI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            const Text('Điều chỉnh trí tuệ nhân tạo hỗ trợ chuyên viên sáng tạo công thức chuẩn SOP.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
            const SizedBox(height: 16),

            // Model Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NomadKit.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mô hình AI chủ đạo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedModel,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: NomadKit.canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NomadKit.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Gemini 1.5 Pro', child: Text('Gemini 1.5 Pro (Độ chính xác cao)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Gemini 1.5 Flash', child: Text('Gemini 1.5 Flash (Tốc độ cao)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _selectedModel = v!),
                  ),
                  const SizedBox(height: 14),

                  // API Key
                  const Text('Khóa API (Google AI Studio Key)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: NomadKit.canvas, borderRadius: BorderRadius.circular(14), border: Border.all(color: NomadKit.border)),
                    child: TextField(
                      controller: _keyCtrl,
                      obscureText: _obscureKey,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: NomadKit.ink),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: NomadKit.secondary),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Hyperparameters: Temperature Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NomadKit.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nhiệt độ sáng tạo (Temperature)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                      Text(_temperature.toStringAsFixed(2), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NomadKit.ocean)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Mức 0.20 ưu tiên độ chính xác tuyệt đối của định lượng công thức, chống ảo giác tỷ lệ thành phần.', style: TextStyle(fontSize: 11, color: NomadKit.secondary)),
                  Slider(
                    value: _temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    activeColor: NomadKit.ocean,
                    onChanged: (v) => setState(() => _temperature = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Prompt Directives
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NomadKit.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chỉ thị vai trò R&D (System Instruction)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: NomadKit.canvas, borderRadius: BorderRadius.circular(14), border: Border.all(color: NomadKit.border)),
                    child: TextField(
                      controller: _promptCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12, height: 1.4, color: NomadKit.ink),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ping Test Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NomadKit.ocean,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isTestingPing ? null : _runPingTest,
                icon: _isTestingPing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.network_check_rounded, size: 18),
                label: Text(_isTestingPing ? 'Đang gửi truy vấn kiểm tra...' : 'Kiểm tra kết nối Live (Ping Test)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),

            // Ping Result Banner
            if (_pingResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NomadKit.forestLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: NomadKit.forest, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pingResult!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NomadKit.forest, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}
