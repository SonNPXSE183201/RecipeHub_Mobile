import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/utils/navigation.dart';
import '../system/loading_transition_page.dart';
import 'pdf_cover_preview_page.dart';

class BatchExportPage extends StatefulWidget {
  const BatchExportPage({super.key});

  @override
  State<BatchExportPage> createState() => _BatchExportPageState();
}

class _BatchExportPageState extends State<BatchExportPage> {
  final Map<String, bool> _selected = {
    'Matcha Latte Mây (v3 - Bản nháp)': true,
    'Cold Brew Cam Quế (v2 - Đã duyệt)': true,
    'Ô Long Sen Vàng (v1 - Đã duyệt)': true,
  };

  @override
  Widget build(BuildContext context) {
    final count = _selected.values.where((v) => v).length;

    return ScreenFrame(
      title: 'Đóng gói SOP Master Book',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Chọn các công thức để đóng gói thành 1 cuốn tài liệu SOP chuẩn chuỗi duy nhất.', style: TextStyle(fontSize: 13, color: NomadKit.secondary)),
          const SizedBox(height: 16),

          ..._selected.keys.map(
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NomadKit.ink)),
                  subtitle: Text(key.contains('Bản nháp') ? 'Sẽ tự động đóng dấu Watermark BẢN NHÁP' : 'Công thức đã chốt chính thức', style: TextStyle(fontSize: 11, color: key.contains('Bản nháp') ? NomadKit.warning : NomadKit.forest)),
                  value: _selected[key],
                  onChanged: (val) => setState(() => _selected[key] = val ?? false),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: NomadKit.sand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                if (count == 0) return;
                go(
                  context,
                  LoadingTransitionPage(
                    message: 'Đang kết xuất bộ PDF gồm $count công thức...',
                    onComplete: () {
                      Navigator.pop(context);
                      go(context, PdfCoverPreviewPage(recipeCount: count));
                    },
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text('Xuất 1 bộ PDF SOP ($count món)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
