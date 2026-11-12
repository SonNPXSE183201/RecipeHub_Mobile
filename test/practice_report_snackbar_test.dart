import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipehub_mobile/app.dart';
import 'package:recipehub_mobile/core/di/app_services.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/navigation/app_keys.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_file_save_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/storage_viewmodel.dart';
import 'package:recipehub_mobile/features/practice/practice_history_page.dart';
import 'package:recipehub_mobile/features/shell/main_app_shell.dart';

import 'support/fake_recipe_source.dart';

class _ExportStorage extends StorageViewModel {
  _ExportStorage(AppServices s, {this.pending})
    : super(
        storage: s.storage,
        picker: s.mediaPicker,
        auth: s.auth,
        analytics: s.analytics,
        crash: s.crash,
      );

  int openCount = 0;
  final Completer<UploadResult?>? pending;

  @override
  SavedFile get savedFile => const SavedFile(
    name: 'luyen-tap.pdf',
    displayPath: 'Download/RecipeHub/luyen-tap.pdf',
    uri: 'content://test/report',
  );

  @override
  Future<UploadResult?> exportPracticeReport({
    required List<SelfPracticeRecord> records,
    required String traineeLabel,
  }) async => pending != null
      ? await pending!.future
      : const UploadResult(
          storagePath: 'reports/test.pdf',
          downloadUrl: 'https://example.com/test.pdf',
          sizeBytes: 100,
        );

  @override
  Future<bool> openSavedFile([SavedFile? file]) async {
    openCount++;
    return true;
  }
}

Future<_ExportStorage> _showReport(
  WidgetTester tester, {
  Completer<UploadResult?>? pending,
}) async {
  // Đủ chỗ cho font test; hành vi SnackBar không phụ thuộc kích thước màn.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = AppServices.mock(
    recipes: FakeRecipeSource(),
    notifications: MockNotificationService(
      permission: NotificationPermission.granted,
    ),
    auth: MockAuthService(
      initialUser: const AppUser(uid: 'u1', method: AuthMethod.google),
    ),
  );
  await tester.pumpWidget(RecipeHubApp(services: s));
  await tester.pumpAndSettle();
  final context = tester.element(find.byType(MainAppShell));
  await context.read<PracticeHistoryViewModel>().add(
    const SelfPracticeRecord(
      id: 'test',
      recipeName: 'Trà sữa',
      recipeCode: 'test',
      size: 'M',
      durationSeconds: 60,
      notes: '',
      practicedAt: '08/11/2026',
    ),
  );
  final storage = _ExportStorage(s, pending: pending);
  addTearDown(storage.dispose);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<StorageViewModel>.value(
        value: storage,
        child: const PracticeHistoryPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(AppKeys.exportReport));
  await tester.pumpAndSettle();
  if (pending == null) {
    expect(
      find.text('Đã lưu: Download/RecipeHub/luyen-tap.pdf'),
      findsOneWidget,
    );
  }
  return storage;
}

void main() {
  testWidgets('Xuất xong trong lúc quay lại không hiện thông báo ở màn khác', (
    tester,
  ) async {
    final pending = Completer<UploadResult?>();
    await _showReport(tester, pending: pending);
    Navigator.of(tester.element(find.byType(PracticeHistoryPage))).pop();
    // Route còn mounted trong animation pop nhưng không còn là route hiện tại.
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Thông báo lưu PDF tự ẩn sau 5 giây', (tester) async {
    await _showReport(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Nút Mở vẫn mở PDF đã lưu', (tester) async {
    final storage = await _showReport(tester);
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(storage.openCount, 1);
  });

  for (final systemBack in [false, true]) {
    testWidgets(
      'Rời lịch sử bằng ${systemBack ? 'system back' : 'nút quay lại'} dọn cả hàng đợi',
      (tester) async {
        await _showReport(tester);
        ScaffoldMessenger.of(tester.element(find.byType(PracticeHistoryPage)))
            .showSnackBar(const SnackBar(content: Text('Thông báo đang chờ')));
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        }
        await tester.pumpAndSettle();
        expect(find.byType(PracticeHistoryPage), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        await tester.tap(find.text('Phản hồi').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tạo phản hồi'));
        await tester.pumpAndSettle();
        expect(find.text('Gửi phản hồi'), findsWidgets);
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  }

  for (final programmatic in [false, true]) {
    testWidgets(
      'Đổi tab ${programmatic ? 'qua switchTab' : 'qua NavigationBar'} dọn SnackBar',
      (tester) async {
        await _showReport(tester);
        Navigator.of(tester.element(find.byType(PracticeHistoryPage))).pop();
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MainAppShell));
        ScaffoldMessenger.of(context)
          ..showSnackBar(
            const SnackBar(
              content: Text('Đã lưu: Download/RecipeHub/test.pdf'),
            ),
          )
          ..showSnackBar(const SnackBar(content: Text('Thông báo đang chờ')));
        await tester.pumpAndSettle();
        if (programmatic) {
          tester
              .state<MainAppShellState>(find.byType(MainAppShell))
              .switchTab(2);
        } else {
          await tester.tap(find.text('Phản hồi').last);
        }
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  }
}
