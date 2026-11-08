import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/firebase/firebase_notification_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_practice_history_store.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';

class _DelayedStore extends MockPracticeHistoryStore {
  final waiting = <String, Completer<List<SelfPracticeRecord>>>{};
  @override
  Future<List<SelfPracticeRecord>> load(String uid) =>
      (waiting[uid] = Completer<List<SelfPracticeRecord>>()).future;
}

SelfPracticeRecord _record(String name) => SelfPracticeRecord(
  id: name,
  recipeName: name,
  recipeCode: 'CF-01',
  size: 'M',
  durationSeconds: 30,
  notes: '',
  practicedAt: 'Hôm nay',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Thông báo nền và lịch sử chỉ nhập đúng uid; bỏ pending cũ vô chủ',
    () async {
      String encoded(String id) => jsonEncode(
        AppNotification(
          id: id,
          title: id,
          body: '',
          receivedAt: DateTime(2026),
        ).toJson(),
      );
      SharedPreferences.setMockInitialValues({
        'rh_notification_history_v1_a': [encoded('history-a')],
        'rh_notification_pending_bg_v1_a': [encoded('pending-a')],
        'rh_notification_pending_bg_v1_b': [encoded('pending-b')],
        'rh_notification_pending_bg_v1': [encoded('legacy')],
      });
      final prefs = await SharedPreferences.getInstance();
      final b = await FirebaseNotificationService.loadScopedHistory(prefs, 'b');
      expect(b.map((n) => n.id), ['pending-b']);
      final a = await FirebaseNotificationService.loadScopedHistory(prefs, 'a');
      expect(a.map((n) => n.id), ['pending-a', 'history-a']);
      expect(prefs.containsKey('rh_notification_pending_bg_v1'), isFalse);
    },
  );

  test(
    'Đổi uid xóa lịch sử ngay; load cũ không kết thúc loading phiên mới',
    () async {
      final store = _DelayedStore();
      final vm = PracticeHistoryViewModel(
        store: store,
        crash: MockCrashReporter(),
      );
      addTearDown(vm.dispose);
      final a = vm.load('a');
      final b = vm.load('b');
      store.waiting['a']!.complete([_record('của A')]);
      await a;
      expect(vm.records, isEmpty);
      expect(vm.isLoading, isTrue);
      store.waiting['b']!.complete([_record('của B')]);
      await b;
      expect(vm.records.single.recipeName, 'của B');
      final c = vm.load('c');
      expect(vm.records, isEmpty);
      store.waiting['c']!.complete([]);
      await c;
    },
  );

  test('Đăng xuất khi add chờ load không đưa bản ghi cũ trở lại', () async {
    final store = _DelayedStore();
    final vm = PracticeHistoryViewModel(
      store: store,
      crash: MockCrashReporter(),
    );
    addTearDown(vm.dispose);
    final loading = vm.load('a');
    final adding = vm.add(_record('cũ'));
    vm.clear();
    store.waiting['a']!.complete([]);
    await loading;
    await adding;
    expect(vm.records, isEmpty);
    expect(store.data, isEmpty);
  });
}
