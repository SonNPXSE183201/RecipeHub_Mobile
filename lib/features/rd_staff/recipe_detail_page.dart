import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import 'recipe_editor_page.dart';
import 'pdf_cover_preview_page.dart';
import 'pdf_draft_preview_page.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({
    super.key,
    this.initialTabIndex = 0,
    this.title = 'Matcha Latte Mây',
    this.code = 'RC-MATCHA-01',
    this.version = 'v3',
    this.isDraft = true,
  });

  final int initialTabIndex;
  final String title;
  final String code;
  final String version;
  final bool isDraft;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
  }

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
        actions: [
          IconButton(
            tooltip: 'Chia sẻ công thức',
            icon: const Icon(Icons.share_outlined, size: 20, color: NomadKit.ink),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép liên kết công thức ${widget.code}')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip & Code Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statusChip(isDraft: widget.isDraft),
                        Text(
                          '${widget.code} · ${widget.version}',
                          style: const TextStyle(fontSize: 12, color: NomadKit.secondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title & Description
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: NomadKit.ink),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Matcha thanh dịu, lớp kem sữa mặn nhẹ và hậu vị hạt rang.',
                      style: TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),

                    // Immutable Lock Banner for Approved Recipes
                    if (!widget.isDraft)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: NomadKit.forestLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: NomadKit.forest, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Phiên bản ${widget.version} đã chốt chính thức (Khóa bất biến). Sửa đổi cần tạo bản mới.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.forest),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Meta Row
                    Row(
                      children: const [
                        Icon(Icons.local_cafe_outlined, size: 15, color: NomadKit.sandDark),
                        SizedBox(width: 4),
                        Text('1 ly · 500 ml', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                        SizedBox(width: 16),
                        Icon(Icons.inventory_2_outlined, size: 15, color: NomadKit.sandDark),
                        SizedBox(width: 4),
                        Text('4 thành phần', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3 Tabs: Thành phần | Quy trình | AI hỗ trợ
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: NomadKit.border)),
                      ),
                      child: Row(
                        children: [
                          _tabItem('Thành phần', 0),
                          _tabItem('Quy trình', 1),
                          _tabItem('AI hỗ trợ', 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Content
                    if (_tabIndex == 0) _buildIngredientsTab(),
                    if (_tabIndex == 1) _buildProcessTab(),
                    if (_tabIndex == 2) _buildAITab(),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: NomadKit.canvas,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: NomadKit.surface,
                        foregroundColor: NomadKit.ink,
                        side: const BorderSide(color: NomadKit.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (widget.isDraft) {
                          go(context, PdfDraftPreviewPage(recipeName: widget.title, version: widget.version, code: widget.code));
                        } else {
                          go(context, const PdfCoverPreviewPage(recipeCount: 1));
                        }
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        widget.isDraft ? 'Xem trước nháp' : 'Xem trước PDF',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDraft ? NomadKit.sand : NomadKit.forest,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (widget.isDraft) {
                          go(context, const RecipeEditorPage());
                        } else {
                          _showNewVersionDialog();
                        }
                      },
                      icon: Icon(widget.isDraft ? Icons.edit_note_rounded : Icons.content_copy_rounded, size: 16),
                      label: Text(
                        widget.isDraft ? 'Sửa bản nháp' : 'Tạo bản sửa v3',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewVersionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: NomadKit.surface,
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: NomadKit.forest, size: 24),
            SizedBox(width: 8),
            Text('Tạo bản sửa đổi mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
          ],
        ),
        content: Text(
          'Công thức ${widget.title} (${widget.version}) đã được khóa bất biến. Hệ thống sẽ nhân bản sang bản nháp mới (v3) để chỉnh sửa mà không ảnh hưởng bản đang áp dụng tại 45 chi nhánh.',
          style: const TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: NomadKit.secondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NomadKit.sand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              go(context, const RecipeEditorPage());
            },
            child: const Text('Bắt đầu sửa v3', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({required bool isDraft}) {
    final bg = isDraft ? NomadKit.warningLight : NomadKit.forestLight;
    final text = isDraft ? NomadKit.warning : NomadKit.forest;
    final label = isDraft ? 'Bản nháp hoạt động' : 'Đã duyệt · Áp dụng toàn chuỗi';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text)),
    );
  }

  Widget _tabItem(String title, int idx) {
    final isSel = _tabIndex == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSel ? NomadKit.sand : Colors.transparent, width: 2)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? NomadKit.sandDark : NomadKit.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsTab() {
    final items = [
      {'name': 'Bột Matcha Uji Ceremonial', 'amount': '5 g', 'note': 'Hòa cùng 40 ml nước ấm 75°C', 'pct': '50%'},
      {'name': 'Sữa tươi thanh trùng Barista', 'amount': '150 ml', 'note': 'Ướp lạnh 4–6°C', 'pct': '100%'},
      {'name': 'Nước đường mía tự nhiên', 'amount': '15 ml', 'note': 'Tùy chỉnh 50% / 70% / 100%', 'pct': '70%'},
      {'name': 'Kem sữa muối biển (Sea salt foam)', 'amount': '60 ml', 'note': 'Đánh bông mịn, phủ mặt ly', 'pct': '100%'},
    ];

    return Column(
      children: items
          .map(
            (it) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NomadKit.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NomadKit.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: NomadKit.ink)),
                        const SizedBox(height: 2),
                        Text(it['note']!, style: const TextStyle(fontSize: 12, color: NomadKit.secondary)),
                      ],
                    ),
                  ),
                  Text(it['amount']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildProcessTab() {
    final steps = [
      'Đánh tan 5g bột Matcha với 40ml nước ấm 75°C bằng chổi Chasen đến khi sủi bọt mịn.',
      'Cho 15ml nước đường và 150ml sữa tươi vào ly đá viên 200g, khuấy nhẹ 3 vòng.',
      'Rót từ từ phần Matcha đã đánh tan lên bề mặt ly để tạo tầng phân lớp màu xanh đẹp mắt.',
      'Rót nhẹ 60ml kem sữa muối biển lên trên cùng, rắc một chút bột Matcha trang trí.',
    ];

    return Column(
      children: steps.asMap().entries.map((e) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NomadKit.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NomadKit.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: NomadKit.sandLight, shape: BoxShape.circle),
                child: Center(
                  child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.45, color: NomadKit.ink)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAITab() {
    return Container(
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
            children: const [
              Icon(Icons.auto_awesome_rounded, color: NomadKit.ocean, size: 18),
              SizedBox(width: 8),
              Text('Gợi ý từ Gemini 1.5 Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: NomadKit.ink)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• Giảm 2g đường mía nếu dùng sữa tươi nguyên kem béo để giữ vị umami tự nhiên của trà.\n• Đối với các chi nhánh miền Bắc vào mùa đông, khuyến nghị nhiệt độ đánh bọt ấm 60°C thay vì đá viên lạnh.',
            style: TextStyle(fontSize: 13, height: 1.5, color: NomadKit.ink),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: NomadKit.ocean,
              side: const BorderSide(color: Color(0xFFBAE6FD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang cập nhật phân tích định lượng mới từ Gemini AI...')),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Phân tích lại công thức', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
