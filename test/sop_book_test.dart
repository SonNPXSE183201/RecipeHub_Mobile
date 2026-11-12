// Sổ tay công thức & SOP: dựng trang (hàm thuần) + lật trang / nhảy mục lục / trạng thái trống.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/services/i_recipe_source.dart';
import 'package:recipehub_mobile/core/services/mock/mock_training_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/training_viewmodel.dart';
import 'package:recipehub_mobile/features/sop_book/book_leaves.dart';
import 'package:recipehub_mobile/features/sop_book/book_reader.dart';
import 'package:recipehub_mobile/features/sop_book/sop_book_page.dart';
import 'package:recipehub_mobile/features/sop_book/sop_book_pages.dart';
import 'package:recipehub_mobile/features/sop_book/sop_book_views.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_recipe_source.dart';

RecipeItem _r(String code, String name, String cat) => RecipeItem(
  id: code,
  code: code,
  name: name,
  category: cat,
  version: '1.0',
  status: 'Ban hành',
  publishedDate: '',
  publisher: '',
  description: 'Mô tả',
  standardTime: '',
  standardTemp: '',
  sizes: const [],
  steps: const [],
  videoUrl: '',
);

SopItem _s(String code, String title) => SopItem(
  id: code,
  code: code,
  title: title,
  category: 'Kỹ thuật',
  version: '1.0',
  publishedDate: '',
  summary: 'Tóm tắt',
  steps: const [],
  linkedRecipeCodes: const [],
);

class _EmptySource implements IRecipeSource {
  @override
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({
    String? query,
    int pageSize = 50,
  }) async => PagedResponse(
    items: const [],
    page: 1,
    pageSize: pageSize,
    totalCount: 0,
  );
  @override
  Future<RecipeDetailResponse> getRecipe(String id) =>
      throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, IRecipeSource src) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final s = AppServices.mock(recipes: src, training: MockTrainingRepository());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppServices>.value(value: s),
        ChangeNotifierProvider(
          create: (_) =>
              TrainingViewModel(repo: s.training, crash: s.crash)..bind('u1'),
        ),
      ],
      child: const MaterialApp(home: SopBookPage()),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('SopBookPageBuilder', () {
    test('thứ tự trang và số trang mục lục đúng', () {
      final recipes = [
        _r('A1', 'Món A1', 'Cà phê'),
        _r('B1', 'Món B1', 'Trà'),
        _r('A2', 'Món A2', 'Cà phê'),
      ];
      final book = SopBookPageBuilder.build(
        recipes: recipes,
        sops: [_s('SOP-1', 'Vệ sinh')],
      );
      expect(book.pages.first.kind, BookPageKind.cover);
      expect(book.pages[1].kind, BookPageKind.toc);
      expect(book.pages.last.kind, BookPageKind.end);
      // bìa + 1 mục lục + 3 món + 1 SOP + cuối
      expect(book.pages.length, 7);
      // Nhóm giữ thứ tự: A1, A2 (Cà phê) rồi B1 (Trà).
      expect(book.pages.sublist(2, 5).map((p) => p.recipe!.code), [
        'A1',
        'A2',
        'B1',
      ]);
      expect(book.pages[5].sop!.code, 'SOP-1');
      final items = book.pages[1].tocEntries.where((e) => !e.isHeader).toList();
      for (final e in items) {
        final p = book.pages[e.pageIndex!];
        expect(p.recipe?.code ?? p.sop?.code, e.code);
      }
      expect(book.indexOfRecipe('B1'), 4);
      expect(book.recipeCount, 3);
      expect(book.sopCount, 1);
    });

    test('nhiều món thì mục lục tách nhiều trang và số trang vẫn khớp', () {
      final recipes = [
        for (var i = 0; i < 61; i++) _r('R$i', 'Món $i', 'Nhóm ${i % 5}'),
      ];
      final book = SopBookPageBuilder.build(recipes: recipes, sops: const []);
      final tocPages = book.pages
          .where((p) => p.kind == BookPageKind.toc)
          .length;
      expect(tocPages, greaterThan(1));
      expect(book.pages.length, 1 + tocPages + 61 + 1);
      for (final p in book.pages.where((p) => p.kind == BookPageKind.toc)) {
        for (final e in p.tocEntries.where((e) => !e.isHeader)) {
          expect(book.pages[e.pageIndex!].recipe!.code, e.code);
        }
      }
    });

    test('rỗng thì không có trang', () {
      final book = SopBookPageBuilder.build(recipes: const [], sops: const []);
      expect(book.isEmpty, isTrue);
      expect(book.pages, isEmpty);
    });
  });

  group('SopBookPage', () {
    testWidgets('trang món giữ tên, danh mục, phiên bản và ẩn mã', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeBookPage(
              recipe: _r('CF-PHELANN', 'Cà phê phin', 'Cà phê'),
            ),
          ),
        ),
      );
      expect(find.textContaining('CF-PHELANN'), findsNothing);
      expect(find.text('Cà phê phin'), findsOneWidget);
      expect(find.text('Cà phê'), findsOneWidget);
      expect(find.text('Phiên bản 1.0'), findsOneWidget);
    });

    testWidgets('tìm món giữ danh mục, ẩn mã và vẫn nhảy đúng trang', (
      tester,
    ) async {
      await _pump(tester, FakeRecipeSource());
      await tester.tap(find.byTooltip('Tìm món'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cà Phê Muối');
      await tester.pumpAndSettle();
      expect(find.textContaining('RC-CFE-01'), findsNothing);
      expect(find.text('Công thức · Cà phê & Cold Brew'), findsOneWidget);
      // Ô tìm kiếm cũng chứa cùng chuỗi; chạm vào dòng kết quả.
      await tester.tap(find.text('Cà Phê Muối').last);
      await tester.pumpAndSettle();
      expect(find.byType(LeafView), findsWidgets);
      expect(
        tester.widget<LeafView>(find.byType(LeafView).last).page.recipe!.code,
        'RC-CFE-01',
      );
      expect(find.text('Cà Phê Muối'), findsWidgets);
      expect(find.textContaining('RC-CFE-01'), findsNothing);
    });

    testWidgets('vuốt lật trang và nhảy qua mục lục', (tester) async {
      await _pump(tester, FakeRecipeSource());
      expect(find.text('Sổ tay công thức & SOP'), findsWidgets);
      expect(find.byTooltip('Xuất PDF'), findsOneWidget);
      expect(find.textContaining('Trang 1/'), findsOneWidget);

      await tester.drag(find.byType(BookReaderStage), const Offset(-240, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 2/'), findsOneWidget);
      expect(find.text('Mục lục'), findsWidgets);

      await tester.tap(find.text('Trà Sữa Oolong').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 3/'), findsOneWidget);
      expect(find.textContaining('RC-OOL-02'), findsNothing);
      expect(find.text('Trà Sữa Oolong'), findsWidgets);
      expect(find.textContaining('Phiên bản'), findsWidgets);

      await tester.drag(find.byType(BookReaderStage), const Offset(240, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 2/'), findsOneWidget);
    });

    testWidgets('không có công thức: hiện trạng thái trống', (tester) async {
      await _pump(tester, _EmptySource());
      expect(
        find.text('Chưa có công thức hoặc SOP nào được ban hành.'),
        findsOneWidget,
      );
    });
  });
}
