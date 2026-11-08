import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_file_save_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_file_save_service.dart';
import 'package:recipehub_mobile/core/services/report/practice_report_pdf.dart';
import 'package:recipehub_mobile/core/services/report/report_font.dart';
import 'package:recipehub_mobile/core/services/report/sop_book_pdf.dart';
import 'package:recipehub_mobile/core/services/report/report_file_actions.dart';
import 'package:recipehub_mobile/core/viewmodels/sop_book_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_recipe_source.dart';

String _hex(String s) =>
    s.codeUnits.map((c) => c.toRadixString(16).padLeft(4, '0')).join();
int _pages(String pdf) => RegExp(r'/Type /Page\s').allMatches(pdf).length;
String _pdf(Uint8List bytes) => latin1.decode(bytes);

RecipeItem _recipe(
  int index, {
  String description = 'Trà thơm, hậu vị dịu.',
  String? code,
}) => RecipeItem(
  id: 'private-$index',
  code: code ?? 'CODE-$index',
  name: 'Trà sữa ô long $index',
  category: 'Trà sữa',
  version: '1.0',
  status: 'Ban hành',
  publishedDate: '',
  publisher: '',
  description: description,
  standardTime: '60 giây',
  standardTemp: '85°C',
  sizes: const [
    RecipeSizeOption(
      sizeCode: 'M',
      label: 'Vừa',
      servingNotes: 'Ít đá; yêu cầu đặc biệt: không đường.',
      ingredients: [
        IngredientPortion(name: 'Trà ô long', amount: 120, unit: 'ml'),
      ],
    ),
    RecipeSizeOption(
      sizeCode: 'L',
      label: 'Lớn',
      servingNotes: 'Dùng ngay.',
      ingredients: [
        IngredientPortion(name: 'Trà ô long', amount: 180, unit: 'ml'),
      ],
    ),
  ],
  steps: const [
    RecipeStepItem(
      stepNumber: 1,
      title: 'Ủ trà',
      instruction: 'Ủ trà rồi lọc.',
      videoStartSeconds: 0,
      videoEndSeconds: 30,
      temperature: '85°C',
      durationText: '30 giây',
    ),
  ],
  videoUrl: '',
);

const _sop = SopItem(
  id: 'private-sop',
  code: 'SOP-1',
  title: 'Vệ sinh máy',
  category: 'Vệ sinh',
  version: '1.0',
  publishedDate: '',
  summary: 'Vệ sinh sau ca.',
  linkedRecipeCodes: [],
  steps: [
    SopStepItem(
      stepNumber: 1,
      title: 'Rửa sạch',
      content: 'Rửa bằng nước ấm.',
      note: 'Đeo găng.',
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List font;
  setUpAll(() async {
    font = await ReportFont.load();
  });
  final at = DateTime(2026, 11, 8, 9, 5);

  test('PDF sổ tay và lịch sử ẩn mã món, giữ thông tin hiển thị', () {
    const codes = ['CF-PHELANN', 'CF-AMERICANON'];
    final book = _pdf(
      SopBookPdf.build(
        fontBytes: font,
        recipes: [
          for (var i = 0; i < codes.length; i++) _recipe(i, code: codes[i]),
        ],
        sops: [],
        generatedAt: at,
      ),
    );
    final history = _pdf(
      PracticeReportPdf.build(
        fontBytes: font,
        storeLabel: 'Quận 1',
        traineeLabel: 'Nguyễn Ánh',
        records: [
          for (var i = 0; i < codes.length; i++)
            SelfPracticeRecord(
              id: 'private-$i',
              recipeCode: codes[i],
              recipeName: 'Trà sữa ô long $i',
              size: 'Vừa',
              durationSeconds: 45,
              targetSeconds: 60,
              notes: '',
              practicedAt: '2026-11-08T09:00:00+07:00',
            ),
        ],
        generatedAt: at,
      ),
    );
    for (final pdf in [book, history]) {
      for (final code in codes) {
        expect(pdf, isNot(contains(_hex(code))));
        expect(pdf, isNot(contains(code)));
      }
      for (var i = 0; i < codes.length; i++) {
        expect(pdf, contains(_hex('Trà sữa ô long $i')));
      }
      expect(pdf, contains(_hex('Vừa')));
    }
    expect(book, contains(_hex('Trà sữa · Phiên bản 1.0')));
  });

  test('Lịch sử: Unicode, A4, tiêu đề, mọi lượt sau lượt 30 và chân trang', () {
    final bytes = PracticeReportPdf.build(
      fontBytes: font,
      storeLabel: 'Quận 1',
      traineeLabel: 'Nguyễn Ánh',
      generatedAt: at,
      records: [
        for (var i = 0; i < 90; i++)
          SelfPracticeRecord(
            id: '$i',
            recipeCode: 'INTERNAL-$i',
            recipeName: 'Cà phê sữa $i',
            size: 'M',
            durationSeconds: 45,
            targetSeconds: 60,
            notes: i == 89 ? 'Ghi chú cuối cùng' : 'Ít đá',
            practicedAt: '2026-11-08T09:00:00+07:00',
          ),
      ],
    );
    final pdf = _pdf(bytes);
    expect(pdf, startsWith('%PDF-1.4'));
    expect(_pages(pdf), greaterThan(1));
    expect(pdf, contains(_hex('Lịch sử tự luyện cá nhân')));
    expect(pdf, contains(_hex('Cà phê sữa 89')));
    expect(pdf, contains(_hex('Ghi chú cuối cùng')));
    expect(pdf, isNot(contains(_hex('INTERNAL-89'))));
    expect(pdf, contains('/FontFile2'));
    expect(pdf, contains('/ToUnicode'));
    expect(pdf, contains('/MediaBox [0 0 595.28 841.89]'));
    expect(pdf, contains(_hex('Trang 1/${_pages(pdf)}')));
  });

  test('Lịch sử rỗng và chưa có chuẩn không chia cho 0', () {
    final pdf = _pdf(
      PracticeReportPdf.build(
        fontBytes: font,
        storeLabel: '',
        traineeLabel: '',
        records: [],
        generatedAt: at,
      ),
    );
    expect(_pages(pdf), greaterThan(0));
    expect(pdf, contains(_hex('Chưa có chuẩn')));
    expect(pdf, contains(_hex('Chưa có lượt tự luyện.')));
  });

  test('Sổ tay: bìa + mục lục + mỗi món/SOP một trang, thông tin đầy đủ', () {
    final pdf = _pdf(
      SopBookPdf.build(
        fontBytes: font,
        recipes: [_recipe(1), _recipe(2)],
        sops: [_sop],
        generatedAt: at,
      ),
    );
    expect(_pages(pdf), 5);
    for (final text in [
      'Sổ tay công thức & SOP',
      'Mục lục',
      'Vệ sinh máy',
      '85°C',
      '30 giây',
      '120 ml',
      '180 ml',
    ]) {
      expect(pdf, contains(_hex(text)));
    }
    expect(pdf, isNot(contains(_hex('CODE-1'))));
    expect(pdf, contains(_hex('Trang 5/5')));
    expect(SopBookPdf.fileName(at), 'so-tay-cong-thuc_20261108.pdf');
  });

  test('Sổ tay dài: thêm trang mục lục và giữ nội dung cuối', () {
    final pdf = _pdf(
      SopBookPdf.build(
        fontBytes: font,
        recipes: [for (var i = 0; i < 55; i++) _recipe(i)],
        sops: [_sop],
        generatedAt: at,
      ),
    );
    expect(_pages(pdf), greaterThan(58));
    expect(pdf, contains(_hex('Trà sữa ô long 54')));
  });

  test('Sổ tay không cắt mất mô tả dài', () {
    final pdf = _pdf(
      SopBookPdf.build(
        fontBytes: font,
        recipes: [
          _recipe(
            1,
            description:
                '${List.filled(150, 'Hướng dẫn pha chế rõ ràng.').join('\n')}\nKết thúc mô tả',
          ),
        ],
        sops: [_sop],
        generatedAt: at,
      ),
    );
    expect(_pages(pdf), greaterThan(4));
    expect(pdf, contains(_hex('Kết thúc mô tả')));
  });

  group('Chia sẻ PDF đã lưu', () {
    const channel = MethodChannel('test.recipehub/report_share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const file = SavedFile(
      name: 'book.pdf',
      displayPath: 'Download/RecipeHub/book.pdf',
      uri: 'content://downloads/42',
    );
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('Chia sẻ content URI với MIME PDF', () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(channel, (call) async {
        captured = call;
        return true;
      });
      expect(await ReportFileActions(channel: channel).share(file), isTrue);
      expect(captured!.method, 'shareFile');
      expect(captured!.arguments, {'uri': file.uri, 'mime': 'application/pdf'});
    });

    test('Lỗi native không gây exception ra UI', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'no_handler'),
      );
      expect(await ReportFileActions(channel: channel).share(file), isFalse);
    });
  });

  group('SopBookViewModel xuất PDF', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    SopBookViewModel vm(MockFileSaveService saver, {SopPdfBuilder? builder}) =>
        SopBookViewModel(
          source: FakeRecipeSource(),
          fileSaver: saver,
          pdfBuilder:
              builder ??
              (recipes, sops, at) async => Uint8List.fromList([37, 80, 68, 70]),
        );

    test('Lưu thành công đúng thư mục/tên; mở file', () async {
      final saver = MockFileSaveService();
      final model = vm(saver);
      addTearDown(model.dispose);
      await model.load();
      final file = await model.exportPdf(sops: [_sop], generatedAt: at);
      expect(
        file!.displayPath,
        'Download/RecipeHub/so-tay-cong-thuc_20261108.pdf',
      );
      expect(model.exporting, isFalse);
      expect(model.exportError, isNull);
      expect(await model.openPdf(file), isTrue);
    });

    test('Lỗi lưu có thông báo; thử lại thành công', () async {
      final model = vm(
        MockFileSaveService(
          failNext: const FileSaveFailure('Bộ nhớ máy đã đầy.'),
        ),
      );
      addTearDown(model.dispose);
      await model.load();
      expect(await model.exportPdf(sops: []), isNull);
      expect(model.exportError, 'Bộ nhớ máy đã đầy.');
      expect(model.exporting, isFalse);
      expect(await model.exportPdf(sops: []), isNotNull);
      expect(model.exportError, isNull);
    });

    test('Lỗi tạo PDF được đổi sang tiếng Việt', () async {
      final saver = MockFileSaveService();
      final model = vm(
        saver,
        builder: (_, _, _) async => throw StateError('private error'),
      );
      addTearDown(model.dispose);
      await model.load();
      expect(await model.exportPdf(sops: []), isNull);
      expect(model.exportError, 'Không tạo được PDF sổ tay. Vui lòng thử lại.');
      expect(saver.savedNames, isEmpty);
      expect(model.exporting, isFalse);
    });

    test('Chặn xuất trùng; dispose khi đang tạo không lưu file', () async {
      final gate = Completer<Uint8List>();
      final saver = MockFileSaveService();
      final model = vm(saver, builder: (_, _, _) => gate.future);
      await model.load();
      final pending = model.exportPdf(sops: []);
      expect(model.exporting, isTrue);
      expect(await model.exportPdf(sops: []), isNull);
      model.dispose();
      gate.complete(Uint8List(1));
      expect(await pending, isNull);
      expect(saver.savedNames, isEmpty);
    });
  });
}
