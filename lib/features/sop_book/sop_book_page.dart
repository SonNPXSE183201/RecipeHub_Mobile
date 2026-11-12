import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/sop_book_viewmodel.dart';
import '../../core/viewmodels/training_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import 'sop_book_pages.dart';
import 'sop_book_views.dart';

/// Sổ tay công thức & SOP dạng cuốn sách, lật trang 3D quanh gáy trái.
class SopBookPage extends StatelessWidget {
  const SopBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<TrainingViewModel>().uid;
    return ChangeNotifierProvider(
      create: (c) => SopBookViewModel(
        source: c.read<AppServices>().recipes,
        uid: uid,
        fileSaver: c.read<AppServices>().fileSaver,
      )..load(),
      child: const _SopBookScaffold(),
    );
  }
}

class _SopBookScaffold extends StatefulWidget {
  const _SopBookScaffold();
  @override
  State<_SopBookScaffold> createState() => _SopBookScaffoldState();
}

class _SopBookScaffoldState extends State<_SopBookScaffold> {
  PageController? _ctrl;
  int _current = 0;
  SopBook _book = const SopBook(pages: [], recipeCount: 0, sopCount: 0);
  List<RecipeItem>? _builtFor;
  List<SopItem>? _builtSops;
  final DateTime _updatedAt = DateTime.now();

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _rebuildBook(List<RecipeItem> recipes, List<SopItem> sops) {
    if (identical(_builtFor, recipes) && identical(_builtSops, sops)) return;
    _builtFor = recipes;
    _builtSops = sops;
    _book = SopBookPageBuilder.build(recipes: recipes, sops: sops);
    if (_current >= _book.pages.length) {
      _current = math.max(0, _book.pages.length - 1);
    }
  }

  void _goto(int page) {
    final c = _ctrl;
    if (c == null || !c.hasClients) return;
    final target = page.clamp(0, _book.pages.length - 1);
    if (MediaQuery.of(context).disableAnimations) {
      c.jumpToPage(target);
    } else {
      c.animateToPage(
        target,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _search() async {
    final recipes = _book.pages
        .where((p) => p.kind == BookPageKind.recipe)
        .toList();
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NomadKit.canvas,
      builder: (_) => _SearchSheet(book: _book, recipes: recipes),
    );
    if (picked != null) _goto(picked);
  }

  Future<void> _export() async {
    if (!mounted) return;
    final vm = context.read<SopBookViewModel>();
    final training = context.read<TrainingViewModel>();
    if (training.sopState != LoadState.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chưa tải đủ SOP để xuất toàn bộ sổ tay.'),
          action: SnackBarAction(label: 'Thử lại', onPressed: training.retry),
        ),
      );
      return;
    }
    final file = await vm.exportPdf(sops: training.sops);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (file == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.exportError ?? 'Không xuất được PDF sổ tay.'),
          action: SnackBarAction(label: 'Thử lại', onPressed: _export),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 12),
        content: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('Đã lưu: ${file.displayPath}'),
            TextButton(
              onPressed: () async {
                final opened = await vm.openPdf(file);
                if (!opened && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Không tìm thấy ứng dụng đọc PDF trên máy.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Mở', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final shared = await vm.sharePdf(file);
                if (!shared && mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Không chia sẻ được PDF trên thiết bị này.',
                      ),
                      action: SnackBarAction(
                        label: 'Thử lại',
                        onPressed: () async {
                          final retried = await vm.sharePdf(file);
                          if (!retried && mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không chia sẻ được PDF. Vui lòng mở file từ Tải xuống.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Chia sẻ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SopBookViewModel>();
    final sops = context.watch<TrainingViewModel>().sops;
    if (vm.state == SopBookLoad.ready) {
      _rebuildBook(vm.recipes, sops);
      if (_ctrl == null && _book.pages.isNotEmpty) {
        _current = vm.savedPage.clamp(0, _book.pages.length - 1);
        _ctrl = PageController(initialPage: _current);
      }
    }
    final ready =
        vm.state == SopBookLoad.ready && !_book.isEmpty && _ctrl != null;

    final onToc = ready && _book.pages[_current].kind == BookPageKind.toc;
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _BookHeader(onBack: () => Navigator.pop(context)),
            if (vm.exporting)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  children: [
                    Text('Đang tạo PDF sổ tay...', style: NomadKit.caption),
                    SizedBox(height: 6),
                    LinearProgressIndicator(color: NomadKit.sand),
                  ],
                ),
              ),
            Expanded(
              child: switch (vm.state) {
                SopBookLoad.loading => const LoadStateView.loading(),
                SopBookLoad.error => LoadStateView.error(
                  message: vm.error ?? 'Không tải được sổ tay.',
                  onRetry: vm.load,
                ),
                SopBookLoad.ready when _book.isEmpty =>
                  const LoadStateView.empty(
                    message: 'Chưa có công thức hoặc SOP nào được ban hành.',
                  ),
                SopBookLoad.ready when !ready => const LoadStateView.loading(),
                SopBookLoad.ready => _buildBook(vm),
              },
            ),
            if (ready)
              _BookNavBar(
                onToc: onToc,
                exporting: vm.exporting,
                onRead: () => _goto(_lastReadPage()),
                onTocTap: () => _goto(1),
                onExport: _export,
                onSearch: _search,
              ),
          ],
        ),
      ),
    );
  }

  /// Trang đọc gần nhất không phải mục lục (mặc định trang đầu của món đầu tiên).
  int _lastReadPage() {
    if (_current > 0 && _book.pages[_current].kind != BookPageKind.toc) {
      return _current;
    }
    final first = _book.pages.indexWhere(
      (p) => p.kind == BookPageKind.recipe || p.kind == BookPageKind.sop,
    );
    return first >= 0 ? first : 0;
  }

  Widget _buildBook(SopBookViewModel vm) {
    final total = _book.pages.length;
    final noAnim = MediaQuery.of(context).disableAnimations;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: PageView.builder(
              controller: _ctrl,
              itemCount: total,
              onPageChanged: (i) {
                setState(() => _current = i);
                vm.savePage(i);
              },
              itemBuilder: (context, i) {
                if ((i - _current).abs() > 1) return const SizedBox.shrink();
                final page = _book.pages[i];
                Widget content = Semantics(
                  container: true,
                  label: 'Trang ${i + 1} trên $total, ${page.title}',
                  child: _PaperPage(pageNumber: i + 1, child: _content(page)),
                );
                if (noAnim) return content;
                return AnimatedBuilder(
                  animation: _ctrl!,
                  child: content,
                  builder: (context, child) {
                    var delta = 0.0;
                    if (_ctrl!.position.haveDimensions) {
                      delta = (_ctrl!.page ?? _current.toDouble()) - i;
                    }
                    // Trang đang lật sang: xoay quanh gáy trái (cạnh trái cố định).
                    final t = delta.clamp(-1.0, 1.0);
                    final angle = t > 0 ? 0.0 : t * 0.9;
                    return Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          child!,
                          if (t != 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.black.withValues(
                                      alpha: t.abs() * 0.18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        _Controls(
          current: _current,
          total: total,
          onPrev: _current > 0 ? () => _goto(_current - 1) : null,
          onNext: _current < total - 1 ? () => _goto(_current + 1) : null,
          onSlide: (v) => _ctrl!.jumpToPage(v),
        ),
      ],
    );
  }

  Widget _content(BookPage p) {
    switch (p.kind) {
      case BookPageKind.cover:
        return BookCover(
          recipeCount: _book.recipeCount,
          sopCount: _book.sopCount,
          updatedAt: _updatedAt,
        );
      case BookPageKind.toc:
        return BookToc(page: p, onJump: _goto);
      case BookPageKind.recipe:
        return RecipeBookPage(recipe: p.recipe!);
      case BookPageKind.sop:
        return SopBookPageView(sop: p.sop!);
      case BookPageKind.end:
        return BookEnd(onToc: () => _goto(1));
    }
  }
}

class _PaperPage extends StatelessWidget {
  const _PaperPage({required this.pageNumber, required this.child});
  final int pageNumber;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NomadKit.canvas,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(3),
          right: Radius.circular(10),
        ),
        border: Border.all(color: NomadKit.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(3),
          right: Radius.circular(10),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: child),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$pageNumber',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NomadKit.secondary,
                    ),
                  ),
                ),
              ],
            ),
            // Bóng gáy sách.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 16,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onSlide,
  });
  final int current;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onSlide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Trang ${current + 1}/$total',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NomadKit.ink,
            ),
          ),
          if (total > 1)
            Slider(
              min: 0,
              max: (total - 1).toDouble(),
              divisions: total - 1,
              value: current.toDouble().clamp(0, (total - 1).toDouble()),
              activeColor: NomadKit.sand,
              semanticFormatterCallback: (v) =>
                  'Trang ${v.round() + 1} trên $total',
              onChanged: (v) => onSlide(v.round()),
            ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onPrev,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Trước'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: NomadKit.sandDark,
                    ),
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconAlignment: IconAlignment.end,
                    label: const Text('Sau'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.book, required this.recipes});
  final SopBook book;
  final List<BookPage> recipes;
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final hits = widget.recipes
        .where(
          (p) =>
              q.isEmpty ||
              p.title.toLowerCase().contains(q) ||
              p.recipe!.code.toLowerCase().contains(q),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Tìm trong sổ tay', style: NomadKit.title),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Tìm món trong sổ tay...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: NomadKit.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NomadKit.border),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${hits.length} công thức phù hợp',
                  style: NomadKit.caption,
                ),
              ),
            ),
            Expanded(
              child: hits.isEmpty
                  ? const Center(child: Text('Không tìm thấy món phù hợp'))
                  : ListView.builder(
                      itemCount: hits.length,
                      itemBuilder: (context, i) {
                        final p = hits[i];
                        final idx = widget.book.indexOfRecipe(p.recipe!.code);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Material(
                            color: NomadKit.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: NomadKit.border),
                            ),
                            child: ListTile(
                              minTileHeight: 56,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(p.title, style: NomadKit.label),
                              subtitle: Text(
                                'Công thức · ${p.group}',
                                style: NomadKit.caption,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${idx + 1}',
                                    style: NomadKit.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: NomadKit.sandDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: NomadKit.sandDark,
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.pop(context, idx),
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

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: 'Quay lại',
            style: IconButton.styleFrom(backgroundColor: NomadKit.sandLight),
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: NomadKit.sandDark,
            ),
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'RecipeHub / Sổ tay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NomadKit.secondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BookNavBar extends StatelessWidget {
  const _BookNavBar({
    required this.onToc,
    required this.exporting,
    required this.onRead,
    required this.onTocTap,
    required this.onExport,
    required this.onSearch,
  });
  final bool onToc;
  final bool exporting;
  final VoidCallback onRead;
  final VoidCallback onTocTap;
  final VoidCallback onExport;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 66,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: NomadKit.sandLight,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(color: NomadKit.border),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Đọc tiếp',
                  active: !onToc,
                  onTap: onRead,
                ),
                _NavItem(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Mục lục',
                  active: onToc,
                  onTap: onTocTap,
                ),
                _NavItem(
                  icon: Icons.download_rounded,
                  label: 'Xuất PDF',
                  active: false,
                  tooltip: exporting ? 'Đang tạo PDF' : 'Xuất PDF',
                  onTap: exporting ? null : onExport,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 66,
          height: 66,
          child: IconButton(
            tooltip: 'Tìm món',
            style: IconButton.styleFrom(
              backgroundColor: NomadKit.sandLight,
              side: const BorderSide(color: NomadKit.border),
            ),
            icon: const Icon(
              Icons.search_rounded,
              size: 24,
              color: NomadKit.sandDark,
            ),
            onPressed: onSearch,
          ),
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : NomadKit.sandDark;
    return Expanded(
      child: Tooltip(
        message: tooltip ?? label,
        child: Material(
          color: active ? NomadKit.sandDark : Colors.transparent,
          borderRadius: BorderRadius.circular(27),
          child: InkWell(
            borderRadius: BorderRadius.circular(27),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
