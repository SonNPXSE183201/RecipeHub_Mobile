import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/utils/navigation.dart';
import 'sop_detail_page.dart';

class SopCatalogPage extends StatefulWidget {
  const SopCatalogPage({super.key});

  @override
  State<SopCatalogPage> createState() => _SopCatalogPageState();
}

class _SopCatalogPageState extends State<SopCatalogPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Kỹ thuật pha chế',
    'Vệ sinh máy móc',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sops = MockDataService.instance.sops;
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = sops.where((s) {
      final matchesCat = _selectedCategory == 'Tất cả' || s.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          s.title.toLowerCase().contains(query) ||
          s.code.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thư viện SOP kỹ thuật chuỗi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NomadKit.ink),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: NomadKit.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NomadKit.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14, color: NomadKit.ink),
                      decoration: InputDecoration(
                        hintText: 'Tìm SOP theo tên hoặc mã quy trình...',
                        hintStyle: const TextStyle(fontSize: 13, color: NomadKit.secondary),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Image.asset(
                            'assets/icons/icon_search.png',
                            width: 22,
                            height: 22,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.search_rounded, color: NomadKit.ocean, size: 22),
                          ),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: NomadKit.secondary),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : NomadKit.ink,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: NomadKit.ocean,
                            backgroundColor: NomadKit.surface,
                            side: BorderSide(color: isSelected ? NomadKit.ocean : NomadKit.border),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: NomadKit.border),

            // SOP List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/illustrations/empty_search_2k.png',
                            width: 130,
                            height: 130,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.search_off_rounded, size: 70, color: NomadKit.secondary),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Không tìm thấy SOP phù hợp',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: NomadKit.ink),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final sop = filtered[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: NomadKit.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: NomadKit.border),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => go(context, SopDetailPage(sop: sop)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Code & Version
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/icons/icon_sop_protocol.png',
                                          width: 22,
                                          height: 22,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder: (ctx, err, stack) => const Icon(Icons.description_outlined, size: 18, color: NomadKit.ocean),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: NomadKit.oceanLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            sop.code,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'monospace',
                                              color: NomadKit.ocean,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: NomadKit.canvas,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: NomadKit.border),
                                          ),
                                          child: Text(
                                            'Phiên bản ${sop.version}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.secondary),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          sop.category,
                                          style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Title
                                    Text(
                                      sop.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: NomadKit.ink),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sop.summary,
                                      style: const TextStyle(fontSize: 13, color: NomadKit.secondary, height: 1.35),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),

                                    // Bottom row: Linked recipe chips
                                    Row(
                                      children: [
                                        const Icon(Icons.link_rounded, size: 16, color: NomadKit.sandDark),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Áp dụng: ${sop.linkedRecipeCodes.join(', ')}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NomadKit.sandDark),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: NomadKit.secondary),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
