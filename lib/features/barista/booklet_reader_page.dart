import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';

class BookletReaderPage extends StatefulWidget {
  const BookletReaderPage({super.key, this.initialPage = 0, this.autoOpenToc = false});
  final int initialPage;
  final bool autoOpenToc;

  @override
  State<BookletReaderPage> createState() => _BookletReaderPageState();
}

class _BookletReaderPageState extends State<BookletReaderPage> {
  late PageController _pageCtrl;
  late int _currentPage;
  final int _totalPages = 8;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageCtrl = PageController(initialPage: widget.initialPage);
    if (widget.autoOpenToc) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _showTOC();
        });
      });
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageCtrl.animateToPage(page, duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    setState(() => _currentPage = page);
  }

  void _showTOC() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NomadKit.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MỤC LỤC SỔ TAY SOP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NomadKit.ink)),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _tocItem(ctx, 'Trang 1: Bìa Sổ tay SOP Master Book 2026', 0),
                      _tocItem(ctx, 'Trang 2: Tiêu chuẩn vệ sinh & an toàn quầy bar', 1),
                      _tocItem(ctx, 'Trang 3: SOP Cold Brew Cam Quế (v2 - Đã duyệt)', 2),
                      _tocItem(ctx, 'Trang 4: Kỹ thuật ủ lạnh 16 tiếng & bảo quản', 3),
                      _tocItem(ctx, 'Trang 5: SOP Ô Long Sen Vàng (v1 - Đã duyệt)', 4),
                      _tocItem(ctx, 'Trang 6: Kỹ thuật đánh kem Macchiato sánh mịn', 5),
                      _tocItem(ctx, 'Trang 7: SOP Matcha Latte Mây (v3 - Bản nháp)', 6),
                      _tocItem(ctx, 'Trang 8: Bảng quy đổi dung sai & Hotline R&D', 7),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tocItem(BuildContext ctx, String label, int pageIndex) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _currentPage == pageIndex ? NomadKit.sand : NomadKit.sandLight, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text('${pageIndex + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _currentPage == pageIndex ? Colors.white : NomadKit.sandDark)),
          ),
        ),
        title: Text(label, style: TextStyle(fontSize: 13, fontWeight: _currentPage == pageIndex ? FontWeight.w800 : FontWeight.w600, color: NomadKit.ink)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: NomadKit.secondary),
        onTap: () {
          Navigator.pop(ctx);
          _goTo(pageIndex);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EFE9), // Warm book desk canvas
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EFE9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sổ tay SOP E-Booklet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            Text('Trang ${_currentPage + 1} / $_totalPages · Vuốt để lật trang', style: const TextStyle(fontSize: 11, color: NomadKit.secondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mục lục (TOC)',
            icon: const Icon(Icons.list_alt_rounded, color: NomadKit.sandDark, size: 22),
            onPressed: _showTOC,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // E-Booklet Reader Container with 3D Spine and Drop Shadows
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
                      BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // PageView
                        PageView(
                          controller: _pageCtrl,
                          onPageChanged: (p) => setState(() => _currentPage = p),
                          children: [
                            _buildCoverPage(),
                            _buildPage2Sanitation(),
                            _buildPage3ColdBrew(),
                            _buildPage4ColdBrewTechnique(),
                            _buildPage5OLongSenVang(),
                            _buildPage6CreamTechnique(),
                            _buildPage7MatchaDraftWatermark(),
                            _buildPage8ToleranceHotline(),
                          ],
                        ),

                        // Left 3D Spine Shadow Overlay (Realistic Book Spine)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 24,
                          child: IgnorePointer(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x35000000),
                                    Color(0x15000000),
                                    Color(0x00000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Book Navigation Bar & Scrubber
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFF2EFE9),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    onPressed: _currentPage > 0 ? () => _goTo(_currentPage - 1) : null,
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentPage.toDouble(),
                      min: 0,
                      max: (_totalPages - 1).toDouble(),
                      divisions: _totalPages - 1,
                      activeColor: NomadKit.sand,
                      inactiveColor: const Color(0xFFD6CEBF),
                      onChanged: (v) => _goTo(v.toInt()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onPressed: _currentPage < _totalPages - 1 ? () => _goTo(_currentPage + 1) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Cover Page
  Widget _buildCoverPage() => Container(
        color: const Color(0xFFFBF9F4),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: NomadKit.sand, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.coffee_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: NomadKit.sandLight, borderRadius: BorderRadius.circular(8)),
              child: const Text('R&D MASTER BOOK · BAN HÀNH 2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            ),
            const SizedBox(height: 16),
            const Text(
              'SỔ TAY QUY TRÌNH\nPHA CHẾ CHUẨN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: NomadKit.ink, height: 1.3),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chuỗi Cà Phê & Trà Nomad\nToàn bộ 45 Chi Nhánh Áp Dụng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.4),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.swipe_rounded, color: NomadKit.sandDark, size: 18),
                SizedBox(width: 8),
                Text('Vuốt sang trái để mở trang mục lục', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NomadKit.sandDark)),
              ],
            ),
          ],
        ),
      );

  // 2. Sanitation & Bar Safety
  Widget _buildPage2Sanitation() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: const [
            Text('CHƯƠNG I: TIÊU CHUẨN VỆ SINH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            SizedBox(height: 6),
            Text('Quy Định Vệ Sinh & An Toàn Quầy Bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            Divider(height: 24),
            Text('1. Khăn lau quầy bar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: NomadKit.ink)),
            Text('• Khăn xanh: Dành riêng lau vòi đánh sữa.\n• Khăn vàng: Lau bề mặt quầy pha chế.\n• Khăn trắng: Lau ly tách và dụng cụ đong.', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.secondary)),
            SizedBox(height: 14),
            Text('2. Nhiệt độ bảo quản tủ mát', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: NomadKit.ink)),
            Text('• Sữa tươi thanh trùng: Luôn duy trì từ 2°C đến 4°C.\n• Cốt trà ủ lạnh (Cold Brew): 4°C, tối đa 48 giờ sau khi chiết xuất.', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.secondary)),
          ],
        ),
      );

  // 3. Cold Brew Cam Quế
  Widget _buildPage3ColdBrew() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: NomadKit.forestLight, borderRadius: BorderRadius.circular(6)),
                  child: const Text('ĐÃ DUYỆT v2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.forest)),
                ),
                const Text('RC-COLD-02 · Trang 3', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary)),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Cold Brew Cam Quế', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink)),
            const Text('Hương vị thanh mát, chua nhẹ của cam tươi hòa quyện vị cà phê ủ lạnh 16 tiếng.', style: TextStyle(fontSize: 12, color: NomadKit.secondary, height: 1.4)),
            const Divider(height: 24),
            const Text('ĐỊNH LƯỢNG NGUYÊN LIỆU (Ly 350ml)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            const SizedBox(height: 8),
            _recipeRow('Cà phê Cold Brew ủ lạnh 16h', '100 ml'),
            _recipeRow('Nước cam tươi vắt nguyên chất', '40 ml'),
            _recipeRow('Syrup quế thanh tự nhiên', '15 ml'),
            _recipeRow('Đá viên bi tinh khiết', '200 g'),
            _recipeRow('Cam vàng sấy khô trang trí', '1 lát'),
            const SizedBox(height: 16),
            const Text('CÁC BƯỚC PHA CHẾ NHANH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            const SizedBox(height: 6),
            const Text('1. Cho đá viên vào ly đến vạch 350ml.\n2. Rót lần lượt syrup quế và nước cam vào khuấy đều.\n3. Rót nhẹ nhàng 100ml Cold Brew lên bề mặt để phân tầng.\n4. Đặt 1 lát cam sấy lên trên và đậy nắp.', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.ink)),
          ],
        ),
      );

  // 4. Cold Brew Technique
  Widget _buildPage4ColdBrewTechnique() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: const [
            Text('CHƯƠNG II: KỸ THUẬT Ủ LẠNH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            SizedBox(height: 6),
            Text('Kỹ Thuật Chiết Xuất Cold Brew Chuẩn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            Divider(height: 24),
            Text('• Tỷ lệ pha cốt: 1 phần cà phê Arabica Cầu Đất : 10 phần nước tinh khiết.\n• Nhiệt độ nước ngâm: Nước lọc RO 20°C - 24°C.\n• Thời gian ủ lạnh: 16 tiếng liên tục trong buồng mát 4°C.\n• Lọc bã: Dùng màng lọc giấy 2 lớp để nước cốt trong veo, không cặn khét.', style: TextStyle(fontSize: 12, height: 1.6, color: NomadKit.ink)),
          ],
        ),
      );

  // 5. O Long Sen Vang
  Widget _buildPage5OLongSenVang() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: NomadKit.forestLight, borderRadius: BorderRadius.circular(6)),
                  child: const Text('ĐÃ DUYỆT v1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.forest)),
                ),
                const Text('RC-OOL-01 · Trang 5', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary)),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Ô Long Sen Vàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink)),
            const Text('Vị trà ô long thanh đậm kết hợp hạt sen bùi ngậy và kem Macchiato béo mặn.', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
            const Divider(height: 24),
            _recipeRow('Cốt trà Ô Long nướng', '120 ml'),
            _recipeRow('Hạt sen Huế ngâm đường', '30 g (5-6 hạt)'),
            _recipeRow('Sữa tươi không đường', '50 ml'),
            _recipeRow('Lớp kem Macchiato sánh mịn', '50 ml'),
          ],
        ),
      );

  // 6. Cream Technique
  Widget _buildPage6CreamTechnique() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: const [
            Text('CHƯƠNG III: KỸ THUẬT ĐÁNH KEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            SizedBox(height: 6),
            Text('Kỹ Thuật Đánh Kem Phô Mai Macchiato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            Divider(height: 24),
            Text('• Thành phần: 200ml kem Topping Base + 100ml kem Rich + 3g muối biển hồng.\n• Máy đánh: Mức tốc độ số 3 trong 90 giây.\n• Kiểm tra độ sánh: Nhấc que đánh tạo chóp mềm nghiêng 45 độ, bề mặt bóng mịn.', style: TextStyle(fontSize: 12, height: 1.6, color: NomadKit.ink)),
          ],
        ),
      );

  // 7. Matcha Latte May with DRAFT WATERMARK
  Widget _buildPage7MatchaDraftWatermark() => Container(
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: NomadKit.warningLight, borderRadius: BorderRadius.circular(6)),
                        child: const Text('BẢN NHÁP v3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: NomadKit.warning)),
                      ),
                      const Text('RC-MATCHA-01 · Trang 7', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: NomadKit.secondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Matcha Latte Mây', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: NomadKit.ink)),
                  const Text('Công thức đang thử nghiệm mùa thu đông, chưa duyệt toàn chuỗi.', style: TextStyle(fontSize: 12, color: NomadKit.secondary)),
                  const Divider(height: 24),
                  _recipeRow('Bột Matcha Uji Ceremonial', '5 g'),
                  _recipeRow('Nước ấm 75°C đánh tan', '40 ml'),
                  _recipeRow('Sữa tươi thanh trùng DalatMilk', '150 ml'),
                  _recipeRow('Kem bọt sữa muối biển (Sea salt foam)', '60 ml'),
                ],
              ),
            ),

            // Diagonal Draft Watermark Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0x45CA8A04), width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BẢN NHÁP · DRAFT',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0x55CA8A04),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // 8. Tolerance & Hotline
  Widget _buildPage8ToleranceHotline() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: const [
            Text('CHƯƠNG IV: QUY ĐỔI & TRỢ GIÚP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            SizedBox(height: 6),
            Text('Bảng Dung Sai & Hotline Hỗ Trợ R&D', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NomadKit.ink)),
            Divider(height: 24),
            Text('• Dung sai định lượng chất lỏng: Tối đa ±2 ml.\n• Dung sai định lượng bột trà/cà phê: Tối đa ±0.2 g.\n• Dung sai nhiệt độ nước ủ: Tối đa ±2°C.', style: TextStyle(fontSize: 12, height: 1.6, color: NomadKit.ink)),
            SizedBox(height: 20),
            Text('HOTLINE PHÒNG R&D CHUỖI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: NomadKit.sandDark)),
            SizedBox(height: 4),
            Text('• Kỹ thuật pha chế: 1900 6868 (Ext: 201)\n• Phản ánh chất lượng nguyên liệu: rnd-support@nomadhub.vn', style: TextStyle(fontSize: 12, height: 1.5, color: NomadKit.secondary)),
          ],
        ),
      );

  Widget _recipeRow(String name, String amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: NomadKit.ink))),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: NomadKit.sandDark)),
          ],
        ),
      );
}
