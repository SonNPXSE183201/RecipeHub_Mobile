import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/utils/navigation.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../sop_book/sop_book_page.dart';
import 'sop_detail_page.dart';

class SopCatalogPage extends StatefulWidget {
  const SopCatalogPage({super.key});
  @override
  State<SopCatalogPage> createState() => _SopCatalogPageState();
}

class _SopCatalogPageState extends State<SopCatalogPage> {
  final _searchCtrl = TextEditingController();
  String _category = 'Tất cả';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingViewModel>();
    final categories = [
      'Tất cả',
      ...{for (final sop in training.sops) sop.category},
    ];
    if (!categories.contains(_category)) _category = 'Tất cả';
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = training.sops.where((sop) {
      final categoryMatch = _category == 'Tất cả' || sop.category == _category;
      return categoryMatch &&
          (query.isEmpty || sop.title.toLowerCase().contains(query));
    }).toList();

    Widget content;
    if (training.sopState == LoadState.loading && training.sops.isEmpty) {
      content = const LoadStateView.loading();
    } else if (training.sopState == LoadState.error && training.sops.isEmpty) {
      content = LoadStateView.error(
        message: training.error ?? 'Không tải được quy trình SOP.',
        onRetry: training.retry,
      );
    } else if (training.sops.isEmpty) {
      content = const LoadStateView.empty(
        message: 'Chưa có SOP nào được ban hành.',
      );
    } else if (filtered.isEmpty) {
      content = const LoadStateView.empty(
        message: 'Không tìm thấy quy trình phù hợp.',
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final sop = filtered[index];
          return Material(
            color: NomadKit.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: NomadKit.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => go(context, SopDetailPage(sop: sop)),
              child: SizedBox(
                height: 78,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: NomadKit.sandDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sop.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NomadKit.label.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${sop.category} · Phiên bản ${sop.version}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NomadKit.caption,
                            ),
                          ],
                        ),
                      ),
                      const RhChevron(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: NomadKit.canvas,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Quy trình SOP', style: NomadKit.title),
        actions: [
          IconButton(
            tooltip: 'Mở sổ tay',
            onPressed: () => go(context, const SopBookPage()),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm quy trình',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: category == _category,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = category),
                  );
                },
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
