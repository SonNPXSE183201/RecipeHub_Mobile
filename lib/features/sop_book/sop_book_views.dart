import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import 'sop_book_pages.dart';

String formatAmount(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

const _h1 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800,
  color: NomadKit.ink,
  height: 1.25,
);
const _h2 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: NomadKit.sandDark,
);
const _body = TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.4);
const _muted = TextStyle(fontSize: 12, color: NomadKit.secondary, height: 1.35);

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.recipeCount,
    required this.sopCount,
    required this.updatedAt,
  });
  final int recipeCount;
  final int sopCount;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: NomadKit.sandDark,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sổ tay công thức & SOP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: NomadKit.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Text('$recipeCount món  ·  $sopCount SOP', style: _h2),
            const SizedBox(height: 8),
            Text('Cập nhật ${formatDate(updatedAt)}', style: _muted),
            const SizedBox(height: 24),
            const Text(
              'Vuốt sang trái hoặc bấm "Sau" để lật trang',
              style: _muted,
            ),
          ],
        ),
      ),
    );
  }
}

class BookToc extends StatelessWidget {
  const BookToc({super.key, required this.page, required this.onJump});
  final BookPage page;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.title.startsWith('Mục lục') ? 'Mục lục' : page.title,
            style: _h1,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              children: [
                for (final e in page.tocEntries)
                  if (e.isHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: Text(e.label, style: _h2),
                    )
                  else
                    InkWell(
                      onTap: () => onJump(e.pageIndex!),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 36),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _body,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.pageNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: NomadKit.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: NomadKit.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookEnd extends StatelessWidget {
  const BookEnd({super.key, required this.onToc});
  final VoidCallback onToc;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 52,
          color: NomadKit.forest,
        ),
        const SizedBox(height: 12),
        const Text('Hết sổ tay', style: _h1),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onToc,
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Về mục lục'),
          ),
        ),
      ],
    ),
  );
}

class RecipeBookPage extends StatelessWidget {
  const RecipeBookPage({super.key, required this.recipe});
  final RecipeItem recipe;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip(
                'Phiên bản ${r.version}',
                NomadKit.canvas,
                NomadKit.secondary,
              ),
              if (r.category.isNotEmpty)
                _chip(r.category, NomadKit.sandLight, NomadKit.sandDark),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.name, style: _h1),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.description, style: _muted),
          ],
          const SizedBox(height: 14),
          const Text('Định lượng', style: _h2),
          const SizedBox(height: 6),
          _IngredientTable(sizes: r.sizes),
          for (final s in r.sizes.where(
            (s) => s.servingNotes.trim().isNotEmpty,
          )) ...[
            const SizedBox(height: 10),
            const Text('Ghi chú phục vụ', style: _h2),
            const SizedBox(height: 2),
            Text(
              r.sizes.length > 1
                  ? '${s.sizeCode}: ${s.servingNotes}'
                  : s.servingNotes,
              style: _body,
            ),
          ],
          const SizedBox(height: 14),
          const Text('Các bước thực hiện', style: _h2),
          const SizedBox(height: 6),
          if (r.steps.isEmpty)
            const Text('Chưa có bước thực hiện.', style: _muted),
          for (final st in r.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: NomadKit.sand,
                    child: Text(
                      '${st.stepNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.title,
                          style: _body.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (st.instruction.isNotEmpty)
                          Text(st.instruction, style: _body),
                        if ((st.temperature ?? '').isNotEmpty ||
                            (st.durationText ?? '').isNotEmpty)
                          Text(
                            [
                              if ((st.temperature ?? '').isNotEmpty)
                                'Nhiệt độ: ${st.temperature}',
                              if ((st.durationText ?? '').isNotEmpty)
                                'Thời gian: ${st.durationText}',
                            ].join('  ·  '),
                            style: _muted,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IngredientTable extends StatelessWidget {
  const _IngredientTable({required this.sizes});
  final List<RecipeSizeOption> sizes;

  @override
  Widget build(BuildContext context) {
    if (sizes.isEmpty) return const Text('Chưa có định lượng.', style: _muted);
    final names = <String>[];
    for (final s in sizes) {
      for (final i in s.ingredients) {
        if (!names.contains(i.name)) names.add(i.name);
      }
    }
    String cell(RecipeSizeOption s, String n) {
      for (final i in s.ingredients) {
        if (i.name == n) return '${formatAmount(i.amount)} ${i.unit}'.trim();
      }
      return '—';
    }

    final notes = <String>{
      for (final s in sizes)
        for (final i in s.ingredients)
          if ((i.warning ?? '').isNotEmpty || (i.note ?? '').isNotEmpty)
            '${i.name}: ${[if ((i.note ?? '').isNotEmpty) i.note, if ((i.warning ?? '').isNotEmpty) i.warning].join(' · ')}',
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: NomadKit.border),
          ),
          columnWidths: {
            0: const FlexColumnWidth(2.2),
            for (var i = 0; i < sizes.length; i++)
              i + 1: const FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                const _Cell('Nguyên liệu', bold: true),
                for (final s in sizes) _Cell(s.sizeCode, bold: true),
              ],
            ),
            for (final n in names)
              TableRow(
                children: [_Cell(n), for (final s in sizes) _Cell(cell(s, n))],
              ),
          ],
        ),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '• $n',
              style: _muted.copyWith(color: NomadKit.warning),
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});
  final String text;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
    child: Text(
      text,
      style: _body.copyWith(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
      ),
    ),
  );
}

class SopBookPageView extends StatelessWidget {
  const SopBookPageView({super.key, required this.sop});
  final SopItem sop;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip(
                'Phiên bản ${sop.version}',
                NomadKit.canvas,
                NomadKit.secondary,
              ),
              if (sop.category.isNotEmpty)
                _chip(sop.category, NomadKit.sandLight, NomadKit.sandDark),
            ],
          ),
          const SizedBox(height: 10),
          Text(sop.title, style: _h1),
          if (sop.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sop.summary, style: _muted),
          ],
          const SizedBox(height: 14),
          const Text('Các bước', style: _h2),
          const SizedBox(height: 6),
          for (final st in sop.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${st.stepNumber}. ${st.title}',
                    style: _body.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (st.content.isNotEmpty) Text(st.content, style: _body),
                  if ((st.note ?? '').isNotEmpty)
                    Text(
                      'Lưu ý: ${st.note}',
                      style: _muted.copyWith(color: NomadKit.warning),
                    ),
                ],
              ),
            ),
          if (sop.linkedRecipeCodes.isNotEmpty) ...[
            const Text('Món áp dụng', style: _h2),
            const SizedBox(height: 2),
            Text('${sop.linkedRecipeCodes.length} món liên quan', style: _body),
          ],
        ],
      ),
    );
  }
}

Widget _chip(String text, Color bg, Color fg, {bool mono = false}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: NomadKit.border),
  ),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: fg,
      fontFamily: mono ? 'monospace' : null,
    ),
  ),
);
