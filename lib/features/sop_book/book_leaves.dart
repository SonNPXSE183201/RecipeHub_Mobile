import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/nomad_kit.dart';
import 'sop_book_pages.dart';
import 'sop_book_views.dart' show formatAmount;

// ─────────────────────────────────────────────────────────────────────────────
// Chia nội dung sổ tay thành các trang giấy CỐ ĐỊNH (không cuộn), giống
// `paginateDocument` của prototype: đo chiều cao thật của chữ rồi xếp khối vào
// từng trang; khối quá dài thì cắt theo từ và chuyển sang trang kế.
// ─────────────────────────────────────────────────────────────────────────────

const leafH1 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800,
  color: NomadKit.ink,
  height: 1.25,
);
const leafH1Small = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w800,
  color: NomadKit.ink,
  height: 1.25,
);
const leafH2 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: NomadKit.sandDark,
);
const leafBody = TextStyle(fontSize: 13, color: NomadKit.ink, height: 1.4);
const leafBodyBold = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w800,
  color: NomadKit.ink,
  height: 1.4,
);
const leafMuted = TextStyle(fontSize: 12, color: NomadKit.secondary, height: 1.35);

const double leafPadH = 22;
const double leafPadTop = 22;
const double leafFolioSpace = 34;
const double leafSlack = 6;
const double _chipRowHeight = 24;
const double _tocItemHeight = 36;

enum LeafBlockKind { heading, tableRow, note, text, step, tocHeader, tocItem }

class LeafBlock {
  const LeafBlock({
    required this.id,
    required this.kind,
    this.title = '',
    this.body = '',
    this.meta = '',
    this.cells = const [],
    this.number,
    this.warn = false,
    this.bold = false,
    this.target,
    this.offset = 0,
    this.showTitle = true,
    this.showMeta = true,
  });

  final int id;
  final LeafBlockKind kind;
  final String title;
  final String body;
  final String meta;
  final List<String> cells;
  final int? number;
  final bool warn;
  final bool bold;

  /// Chỉ số trang sổ tay mà dòng mục lục trỏ tới.
  final int? target;

  /// Số từ của `body` đã nằm ở trang trước (khối bị cắt qua nhiều trang).
  final int offset;
  final bool showTitle;
  final bool showMeta;

  bool get isHeading =>
      kind == LeafBlockKind.heading || kind == LeafBlockKind.tocHeader;

  bool get splittable =>
      (kind == LeafBlockKind.step ||
          kind == LeafBlockKind.note ||
          kind == LeafBlockKind.text) &&
      body.trim().split(RegExp(r'\s+')).length > 1;

  String get shownBody =>
      kind == LeafBlockKind.note && offset == 0 ? '• $body' : body;

  LeafBlock copyWith({
    String? body,
    int? offset,
    bool? showTitle,
    bool? showMeta,
  }) => LeafBlock(
    id: id,
    kind: kind,
    title: title,
    body: body ?? this.body,
    meta: meta,
    cells: cells,
    number: number,
    warn: warn,
    bold: bold,
    target: target,
    offset: offset ?? this.offset,
    showTitle: showTitle ?? this.showTitle,
    showMeta: showMeta ?? this.showMeta,
  );
}

class BookLeaf {
  const BookLeaf({
    required this.pageIndex,
    required this.continuation,
    this.blocks = const [],
  });
  final int pageIndex;
  final bool continuation;
  final List<LeafBlock> blocks;
}

/// Kết quả chia trang: danh sách trang giấy + trang giấy đầu tiên của mỗi trang sổ tay.
class BookLayout {
  const BookLayout(this.leaves, this.firstLeafOfPage);
  final List<BookLeaf> leaves;
  final List<int> firstLeafOfPage;

  int leafIndexFor(int page, {int block = 0, int offset = 0}) {
    for (var i = 0; i < leaves.length; i++) {
      final leaf = leaves[i];
      if (leaf.pageIndex != page) continue;
      for (final b in leaf.blocks) {
        final words = b.body.trim().isEmpty
            ? 1
            : b.body.trim().split(RegExp(r'\s+')).length;
        if (b.id == block && b.offset <= offset && b.offset + words > offset) {
          return i;
        }
      }
    }
    if (page >= 0 && page < firstLeafOfPage.length) return firstLeafOfPage[page];
    return 0;
  }
}

class LeafMetrics {
  LeafMetrics({required this.width, required this.scaler, required this.base});

  final double width;
  final TextScaler scaler;
  final TextStyle base;

  double text(String s, TextStyle style, double w, {int? maxLines}) {
    if (s.isEmpty) return 0;
    final tp = TextPainter(
      text: TextSpan(text: s, style: base.merge(style)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: math.max(1, w));
    final h = tp.height;
    tp.dispose();
    return h;
  }

  List<double> cellWidths(int n) {
    final total = 2.2 + (n - 1);
    return [width * 2.2 / total, for (var i = 1; i < n; i++) width / total];
  }

  double height(LeafBlock b) {
    switch (b.kind) {
      case LeafBlockKind.heading:
        return 20 + text(b.title, leafH2, width);
      case LeafBlockKind.tocHeader:
        return 12 + text(b.title, leafH2, width);
      case LeafBlockKind.tocItem:
        return _tocItemHeight;
      case LeafBlockKind.tableRow:
        final ws = cellWidths(b.cells.length);
        var m = 0.0;
        for (var i = 0; i < b.cells.length; i++) {
          m = math.max(
            m,
            text(b.cells[i], b.bold ? leafBodyBold : leafBody, ws[i] - 4),
          );
        }
        return 13 + m;
      case LeafBlockKind.note:
        return 4 + text(b.shownBody, leafMuted, width);
      case LeafBlockKind.text:
        return 2 + text(b.body, leafBody, width);
      case LeafBlockKind.step:
        final w2 = width - 34;
        var col = 0.0;
        if (b.showTitle) col += text(b.title, leafBodyBold, w2);
        col += text(b.body, leafBody, w2);
        if (b.showMeta) col += text(b.meta, leafMuted, w2);
        return math.max(24, col) + 10;
    }
  }

  double headerHeight(BookPage page, bool continuation) {
    if (page.kind == BookPageKind.toc) {
      final t = continuation ? 'Mục lục (tiếp)' : 'Mục lục';
      return text(t, leafH1, width) + 8;
    }
    final title = continuation ? '${page.title} (tiếp)' : page.title;
    final titleH = continuation
        ? text(title, leafH1Small, width, maxLines: 2)
        : text(title, leafH1, width);
    var desc = 0.0;
    if (!continuation) {
      final d = bookDescription(page);
      if (d.isNotEmpty) desc = 6 + text(d, leafMuted, width, maxLines: 3);
    }
    return _chipRowHeight + 10 + titleH + desc + 12;
  }
}

String bookDescription(BookPage page) =>
    page.recipe?.description ?? page.sop?.summary ?? '';

List<LeafBlock> recipeBlocks(RecipeItem r) {
  final out = <LeafBlock>[];
  void add(LeafBlock Function(int id) make) => out.add(make(out.length));

  add((id) => LeafBlock(id: id, kind: LeafBlockKind.heading, title: 'Định lượng'));
  if (r.sizes.isEmpty) {
    add((id) => LeafBlock(id: id, kind: LeafBlockKind.text, body: 'Chưa có định lượng.'));
  } else {
    final names = <String>[];
    for (final s in r.sizes) {
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

    add(
      (id) => LeafBlock(
        id: id,
        kind: LeafBlockKind.tableRow,
        bold: true,
        cells: ['Nguyên liệu', for (final s in r.sizes) s.sizeCode],
      ),
    );
    for (final n in names) {
      add(
        (id) => LeafBlock(
          id: id,
          kind: LeafBlockKind.tableRow,
          cells: [n, for (final s in r.sizes) cell(s, n)],
        ),
      );
    }
    final notes = <String>{
      for (final s in r.sizes)
        for (final i in s.ingredients)
          if ((i.warning ?? '').isNotEmpty || (i.note ?? '').isNotEmpty)
            '${i.name}: ${[if ((i.note ?? '').isNotEmpty) i.note, if ((i.warning ?? '').isNotEmpty) i.warning].join(' · ')}',
    };
    for (final n in notes) {
      add((id) => LeafBlock(id: id, kind: LeafBlockKind.note, body: n, warn: true));
    }
  }
  final serving = r.sizes.where((s) => s.servingNotes.trim().isNotEmpty);
  if (serving.isNotEmpty) {
    add((id) => LeafBlock(id: id, kind: LeafBlockKind.heading, title: 'Ghi chú phục vụ'));
    for (final s in serving) {
      add(
        (id) => LeafBlock(
          id: id,
          kind: LeafBlockKind.text,
          body: r.sizes.length > 1
              ? '${s.sizeCode}: ${s.servingNotes}'
              : s.servingNotes,
        ),
      );
    }
  }
  add((id) => LeafBlock(id: id, kind: LeafBlockKind.heading, title: 'Các bước thực hiện'));
  if (r.steps.isEmpty) {
    add((id) => LeafBlock(id: id, kind: LeafBlockKind.text, body: 'Chưa có bước thực hiện.'));
  }
  for (final st in r.steps) {
    final meta = [
      if ((st.temperature ?? '').isNotEmpty) 'Nhiệt độ: ${st.temperature}',
      if ((st.durationText ?? '').isNotEmpty) 'Thời gian: ${st.durationText}',
    ].join('  ·  ');
    add(
      (id) => LeafBlock(
        id: id,
        kind: LeafBlockKind.step,
        number: st.stepNumber,
        title: st.title,
        body: st.instruction,
        meta: meta,
      ),
    );
  }
  return out;
}

List<LeafBlock> sopBlocks(SopItem sop) {
  final out = <LeafBlock>[];
  void add(LeafBlock Function(int id) make) => out.add(make(out.length));
  add((id) => LeafBlock(id: id, kind: LeafBlockKind.heading, title: 'Các bước'));
  for (final st in sop.steps) {
    add(
      (id) => LeafBlock(
        id: id,
        kind: LeafBlockKind.step,
        number: st.stepNumber,
        title: st.title,
        body: st.content,
        meta: (st.note ?? '').isEmpty ? '' : 'Lưu ý: ${st.note}',
        warn: true,
      ),
    );
  }
  if (sop.linkedRecipeCodes.isNotEmpty) {
    add((id) => LeafBlock(id: id, kind: LeafBlockKind.heading, title: 'Món áp dụng'));
    add(
      (id) => LeafBlock(
        id: id,
        kind: LeafBlockKind.text,
        body: '${sop.linkedRecipeCodes.length} món liên quan',
      ),
    );
  }
  return out;
}

List<LeafBlock> tocBlocks(BookPage page) {
  final out = <LeafBlock>[];
  for (final e in page.tocEntries) {
    out.add(
      e.isHeader
          ? LeafBlock(id: out.length, kind: LeafBlockKind.tocHeader, title: e.label)
          : LeafBlock(
              id: out.length,
              kind: LeafBlockKind.tocItem,
              title: e.label,
              target: e.pageIndex,
            ),
    );
  }
  return out;
}

class BookPaginator {
  const BookPaginator._();

  static BookLayout paginate({
    required SopBook book,
    required Size paper,
    required TextScaler scaler,
    required TextStyle base,
  }) {
    final width = math.max(80.0, paper.width - leafPadH * 2);
    final height = paper.height - leafPadTop - leafFolioSpace - leafSlack;
    final m = LeafMetrics(width: width, scaler: scaler, base: base);
    final leaves = <BookLeaf>[];
    final firstLeaf = <int>[];

    for (var p = 0; p < book.pages.length; p++) {
      final page = book.pages[p];
      firstLeaf.add(leaves.length);
      final blocks = switch (page.kind) {
        BookPageKind.recipe => recipeBlocks(page.recipe!),
        BookPageKind.sop => sopBlocks(page.sop!),
        BookPageKind.toc => tocBlocks(page),
        _ => const <LeafBlock>[],
      };
      if (blocks.isEmpty) {
        leaves.add(BookLeaf(pageIndex: p, continuation: false));
        continue;
      }
      final capFirst = math.max(80.0, height - m.headerHeight(page, false));
      final capRest = math.max(80.0, height - m.headerHeight(page, true));
      final pages = _paginate(blocks, capFirst, capRest, m.height);
      for (var i = 0; i < pages.length; i++) {
        leaves.add(
          BookLeaf(pageIndex: p, continuation: i > 0, blocks: pages[i]),
        );
      }
    }
    return BookLayout(leaves, firstLeaf);
  }

  static List<List<LeafBlock>> _paginate(
    List<LeafBlock> blocks,
    double capFirst,
    double capRest,
    double Function(LeafBlock) measure,
  ) {
    final pages = <List<LeafBlock>>[];
    var current = <LeafBlock>[];
    var used = 0.0;
    double cap() => pages.isEmpty ? capFirst : capRest;
    void flush() {
      if (current.isNotEmpty) {
        pages.add(current);
        current = <LeafBlock>[];
        used = 0;
      }
    }

    for (var i = 0; i < blocks.length; i++) {
      final original = blocks[i];
      if (original.isHeading) {
        final next = i + 1 < blocks.length ? blocks[i + 1] : null;
        final need =
            measure(original) +
            (next == null ? 0 : math.min(measure(next), cap() * .35));
        if (current.isNotEmpty && used + need > cap()) flush();
      }
      var block = original;
      var guard = 0;
      while (guard++ < 500) {
        final h = measure(block);
        if (used + h <= cap()) {
          current.add(block);
          used += h;
          break;
        }
        if (h <= cap() || !block.splittable) {
          flush();
          current.add(block);
          used = h;
          break;
        }
        final words = block.body.trim().split(RegExp(r'\s+'));
        var low = 0;
        var high = words.length;
        while (low < high) {
          final mid = (low + high + 1) ~/ 2;
          final head = block.copyWith(
            body: words.take(mid).join(' '),
            showMeta: false,
          );
          if (measure(head) <= cap() - used) {
            low = mid;
          } else {
            high = mid - 1;
          }
        }
        if (low == 0) {
          if (current.isNotEmpty) {
            flush();
            continue;
          }
          low = 1;
        }
        current.add(
          block.copyWith(body: words.take(low).join(' '), showMeta: false),
        );
        flush();
        block = block.copyWith(
          body: words.skip(low).join(' '),
          offset: block.offset + low,
          showTitle: false,
        );
      }
    }
    flush();
    return pages;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hiển thị một trang giấy. Bố cục phải khớp công thức đo ở LeafMetrics.height.
// ─────────────────────────────────────────────────────────────────────────────

class LeafView extends StatelessWidget {
  const LeafView({
    super.key,
    required this.leaf,
    required this.page,
    required this.base,
    required this.firstLeafOfPage,
    required this.onJump,
  });

  final BookLeaf leaf;
  final BookPage page;
  final TextStyle base;
  final List<int> firstLeafOfPage;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final isToc = page.kind == BookPageKind.toc;
    return DefaultTextStyle(
      style: base,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(leafPadH, leafPadTop, leafPadH, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isToc)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      leaf.continuation ? 'Mục lục (tiếp)' : 'Mục lục',
                      style: leafH1,
                    ),
                  )
                else
                  _header(),
                for (final b in leaf.blocks) _block(context, b),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final r = page.recipe;
    final s = page.sop;
    final version = r?.version ?? s?.version ?? '';
    final category = r?.category ?? s?.category ?? '';
    final desc = bookDescription(page);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _chipRowHeight,
          child: Row(
            children: [
              _Chip('Phiên bản $version', NomadKit.canvas, NomadKit.secondary),
              if (category.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _Chip(category, NomadKit.sandLight, NomadKit.sandDark),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (leaf.continuation)
          Text(
            '${page.title} (tiếp)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: leafH1Small,
          )
        else
          Text(page.title, style: leafH1),
        if (!leaf.continuation && desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: leafMuted),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _block(BuildContext context, LeafBlock b) {
    switch (b.kind) {
      case LeafBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(b.title, style: leafH2),
        );
      case LeafBlockKind.tocHeader:
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Text(b.title, style: leafH2),
        );
      case LeafBlockKind.tocItem:
        final number = (b.target! < firstLeafOfPage.length)
            ? firstLeafOfPage[b.target!] + 1
            : b.target! + 1;
        return InkWell(
          onTap: () => onJump(b.target!),
          child: SizedBox(
            height: _tocItemHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: leafBody,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$number',
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
        );
      case LeafBlockKind.tableRow:
        return _TableRow(block: b);
      case LeafBlockKind.note:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            b.shownBody,
            style: leafMuted.copyWith(color: b.warn ? NomadKit.warning : null),
          ),
        );
      case LeafBlockKind.text:
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(b.body, style: leafBody),
        );
      case LeafBlockKind.step:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: b.showTitle && b.number != null
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          color: NomadKit.sand,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${b.number}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (b.showTitle && b.title.isNotEmpty)
                      Text(b.title, style: leafBodyBold),
                    if (b.body.isNotEmpty) Text(b.body, style: leafBody),
                    if (b.showMeta && b.meta.isNotEmpty)
                      Text(
                        b.meta,
                        style: leafMuted.copyWith(
                          color: b.warn ? NomadKit.warning : null,
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
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.block});
  final LeafBlock block;

  @override
  Widget build(BuildContext context) {
    final n = block.cells.length;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NomadKit.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                flex: i == 0 ? 22 : 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    block.cells[i],
                    style: block.bold ? leafBodyBold : leafBody,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: NomadKit.border),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
    ),
  );
}
