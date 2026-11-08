import '../../core/models/app_models.dart';

enum BookPageKind { cover, toc, recipe, sop, end }

/// Một dòng mục lục: tiêu đề nhóm (pageIndex = null) hoặc mục trỏ tới trang.
class TocEntry {
  const TocEntry.header(this.label, {this.code = ''}) : pageIndex = null;
  const TocEntry.item(this.label, this.pageIndex, {this.code = ''});

  final String label;
  final String code;
  final int? pageIndex;
  bool get isHeader => pageIndex == null;
  int? get pageNumber => pageIndex == null ? null : pageIndex! + 1;
}

class BookPage {
  const BookPage({
    required this.kind,
    required this.title,
    this.recipe,
    this.sop,
    this.tocEntries = const [],
    this.group = '',
  });

  final BookPageKind kind;
  final String title;
  final RecipeItem? recipe;
  final SopItem? sop;
  final List<TocEntry> tocEntries;
  final String group;
}

class SopBook {
  const SopBook({
    required this.pages,
    required this.recipeCount,
    required this.sopCount,
  });
  final List<BookPage> pages;
  final int recipeCount;
  final int sopCount;
  bool get isEmpty => recipeCount == 0 && sopCount == 0;

  /// Chỉ số trang (0-based) của món theo mã; -1 nếu không có.
  int indexOfRecipe(String code) => pages.indexWhere(
    (p) => p.kind == BookPageKind.recipe && p.recipe!.code == code,
  );
}

/// Hàm thuần dựng danh sách trang: Bìa → Mục lục → Món (theo nhóm) → SOP → Trang cuối.
class SopBookPageBuilder {
  const SopBookPageBuilder._();

  static const int tocLinesPerPage = 14;

  static SopBook build({
    required List<RecipeItem> recipes,
    required List<SopItem> sops,
  }) {
    if (recipes.isEmpty && sops.isEmpty) {
      return const SopBook(pages: [], recipeCount: 0, sopCount: 0);
    }
    // Nhóm món giữ thứ tự xuất hiện đầu tiên.
    final groups = <String, List<RecipeItem>>{};
    for (final r in recipes) {
      final g = r.category.trim().isEmpty ? 'Khác' : r.category.trim();
      groups.putIfAbsent(g, () => []).add(r);
    }
    final lineCount =
        groups.length + recipes.length + (sops.isEmpty ? 0 : 1 + sops.length);
    final tocPages = (lineCount / tocLinesPerPage).ceil().clamp(1, 1 << 20);
    var next = 1 + tocPages; // chỉ số trang nội dung đầu tiên

    final lines = <TocEntry>[];
    final contentPages = <BookPage>[];
    groups.forEach((g, list) {
      lines.add(TocEntry.header(g));
      for (final r in list) {
        lines.add(TocEntry.item(r.name, next, code: r.code));
        contentPages.add(
          BookPage(
            kind: BookPageKind.recipe,
            title: r.name,
            recipe: r,
            group: g,
          ),
        );
        next++;
      }
    });
    if (sops.isNotEmpty) {
      lines.add(const TocEntry.header('Quy trình SOP'));
      for (final s in sops) {
        lines.add(TocEntry.item(s.title, next, code: s.code));
        contentPages.add(
          BookPage(
            kind: BookPageKind.sop,
            title: s.title,
            sop: s,
            group: 'SOP',
          ),
        );
        next++;
      }
    }

    final pages = <BookPage>[
      const BookPage(kind: BookPageKind.cover, title: 'Bìa sổ tay'),
    ];
    for (var i = 0; i < tocPages; i++) {
      final from = i * tocLinesPerPage;
      final to = (from + tocLinesPerPage).clamp(0, lines.length);
      pages.add(
        BookPage(
          kind: BookPageKind.toc,
          title: 'Mục lục ${i + 1}/$tocPages',
          tocEntries: from >= lines.length ? const [] : lines.sublist(from, to),
        ),
      );
    }
    pages
      ..addAll(contentPages)
      ..add(const BookPage(kind: BookPageKind.end, title: 'Trang cuối'));
    return SopBook(
      pages: pages,
      recipeCount: recipes.length,
      sopCount: sops.length,
    );
  }
}
