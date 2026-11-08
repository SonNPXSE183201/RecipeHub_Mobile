
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/device/android_file_save_service.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_file_save_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_file_save_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_media_picker_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_storage_service.dart';
import 'package:recipehub_mobile/core/services/report/practice_report_pdf.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';

StorageViewModel _vm(MockFileSaveService saver, MockStorageService storage) =>
    StorageViewModel(
      storage: storage,
      picker: MockMediaPickerService(),
      auth: MockAuthService(
        initialUser: const AppUser(uid: 'u1', method: AuthMethod.guest),
      ),
      analytics: MockAnalyticsService(),
      crash: MockCrashReporter(),
      fileSaver: saver,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Tên file luyen-tap_yyyyMMdd-HHmm.pdf', () {
    expect(
      PracticeReportPdf.fileName(DateTime(2026, 11, 7, 9, 5)),
      'luyen-tap_20261107-0905.pdf',
    );
  });

  test('Xuất báo cáo: lưu máy + upload Storage', () async {
    final saver = MockFileSaveService();
    final storage = MockStorageService();
    final vm = _vm(saver, storage);
    final r = await vm.exportPracticeReport(
      records: const [],
      traineeLabel: 'A',
    );
    expect(r, isNotNull);
    expect(storage.uploadedPaths, hasLength(1));
    expect(
      saver.savedNames.single,
      matches(RegExp(r'^luyen-tap_\d{8}-\d{4}\.pdf$')),
    );
    expect(vm.savedFile!.displayPath, startsWith('Download/RecipeHub/'));
    expect(vm.saveError, isNull);
    expect(await vm.openSavedFile(), isTrue);
    expect(saver.opened, hasLength(1));
  });

  test('Lưu máy thất bại: báo lỗi tiếng Việt, vẫn upload', () async {
    final saver = MockFileSaveService(
      failNext: const FileSaveFailure('Bộ nhớ máy đã đầy.'),
    );
    final storage = MockStorageService();
    final vm = _vm(saver, storage);
    await vm.exportPracticeReport(records: const [], traineeLabel: 'A');
    expect(vm.savedFile, isNull);
    expect(vm.saveError, 'Bộ nhớ máy đã đầy.');
    expect(storage.uploadedPaths, hasLength(1));
    // thử lại thành công
    await vm.exportPracticeReport(records: const [], traineeLabel: 'A');
    expect(vm.saveError, isNull);
    expect(vm.savedFile, isNotNull);
  });

  test('Upload lỗi vẫn giữ PDF trên máy và mở được', () async {
    final saver = MockFileSaveService();
    final vm = _vm(
      saver,
      MockStorageService(
        failNext: const StorageFailure(StorageFailureCode.unknown),
      ),
    );
    addTearDown(vm.dispose);
    expect(
      await vm.exportPracticeReport(records: const [], traineeLabel: 'A'),
      isNull,
    );
    expect(vm.reportStatus, UploadStatus.error);
    expect(vm.savedFile, isNotNull);
    expect(vm.saveError, isNull);
    expect(await vm.openSavedFile(), isTrue);
  });

  test('Reset phiên xóa file và URL báo cáo cũ', () async {
    final vm = _vm(MockFileSaveService(), MockStorageService());
    addTearDown(vm.dispose);
    await vm.exportPracticeReport(records: const [], traineeLabel: 'A');
    vm.reset();
    expect(vm.savedFile, isNull);
    expect(vm.saveError, isNull);
    expect(vm.lastReportBytes, 0);
    expect(vm.reports, isEmpty);
    expect(await vm.openSavedFile(), isFalse);
  });

  test('Reset khi đang xuất không đưa báo cáo phiên cũ trở lại', () async {
    final storage = MockStorageService();
    final vm = _vm(MockFileSaveService(), storage);
    addTearDown(vm.dispose);
    final pending = vm.exportPracticeReport(
      records: const [],
      traineeLabel: 'A',
    );
    expect(vm.reportStatus, UploadStatus.uploading);
    vm.reset();
    expect(await pending, isNull);
    expect(vm.savedFile, isNull);
    expect(vm.reports, isEmpty);
    expect(vm.reportStatus, UploadStatus.idle);
    expect(storage.uploadedPaths, isEmpty);
  });

  group('Android file channel', () {
    const channel = MethodChannel('test.recipehub/files');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('Gửi đúng tên, bytes, thư mục; mở content URI', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'savePdf' ? 'content://downloads/42' : true;
      });
      final service = AndroidFileSaveService(channel: channel);
      final bytes = Uint8List.fromList([37, 80, 68, 70]);
      final file = await service.savePdf(
        fileName: 'luyen-tap_20261108-0930.pdf',
        bytes: bytes,
      );
      expect(
        file.displayPath,
        'Download/RecipeHub/luyen-tap_20261108-0930.pdf',
      );
      expect(calls.single.arguments, {
        'name': 'luyen-tap_20261108-0930.pdf',
        'bytes': bytes,
        'folder': 'RecipeHub',
      });
      expect(await service.open(file), isTrue);
      expect(calls.last.method, 'openFile');
      expect(calls.last.arguments, {
        'uri': 'content://downloads/42',
        'mime': 'application/pdf',
      });
    });

    test('Lỗi bộ nhớ được đổi sang câu tiếng Việt', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'no_space', message: 'ENOSPC');
      });
      expect(
        AndroidFileSaveService(channel: channel)
            .savePdf(fileName: 'test.pdf', bytes: Uint8List(1)),
        throwsA(
          isA<FileSaveFailure>().having(
            (e) => e.message,
            'message',
            contains('Bộ nhớ máy đã đầy'),
          ),
        ),
      );
    });
  });
}
