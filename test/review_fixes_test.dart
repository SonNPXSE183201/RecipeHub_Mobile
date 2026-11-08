// Hồi quy cho các lỗi tìm được khi rà soát code (deep review 05/11/2026) + service Firebase thật trên Firestore giả.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/models/incident_report.dart';
import 'package:recipehub_mobile/core/models/recipe_models.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/device/prefs_practice_history_store.dart';
import 'package:recipehub_mobile/core/services/firebase/firebase_user_profile_service.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_device_registry.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_incident_reporter.dart';
import 'package:recipehub_mobile/core/services/firebase/firestore_recipe_source.dart';
import 'package:recipehub_mobile/core/services/i_recipe_source.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_device_registry.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_user_profile_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_analytics_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_auth_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_device_registry.dart';
import 'package:recipehub_mobile/core/services/mock/mock_incident_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/services/mock/mock_practice_history_store.dart';
import 'package:recipehub_mobile/core/services/mock/mock_user_profile_service.dart';
import 'package:recipehub_mobile/core/services/recipe_mapper.dart';
import 'package:recipehub_mobile/core/viewmodels/auth_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/practice_history_viewmodel.dart';
import 'package:recipehub_mobile/core/viewmodels/recipe_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_recipe_source.dart';

Future<void> _settle([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

/// Thiết bị không bao giờ xác nhận xóa (Firestore offline).
class _HangingRegistry implements IDeviceRegistry {
  @override
  Future<void> register(String uid, String token) async {}

  @override
  Future<void> unregister(String uid, String token) => Completer<void>().future;
}

/// Đồng bộ hồ sơ chờ tới khi test cho phép.
class _SlowProfile extends MockUserProfileService {
  _SlowProfile({super.role});
  final Completer<void> gate = Completer<void>();
  bool failRefresh = false;

  @override
  Future<ProfileState> sync() async {
    await gate.future;
    return super.sync();
  }

  @override
  Future<String> currentRole({bool forceRefresh = false}) async {
    if (forceRefresh && failRefresh) throw StateError('offline');
    return super.currentRole(forceRefresh: forceRefresh);
  }
}

class _OfflineSource extends FakeRecipeSource {
  @override
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({String? query, int pageSize = 50}) =>
      Future.error(const RecipeOfflineException());
}

/// Món thứ hai lỗi (vừa bị ẩn) – lần tải vẫn phải ra các món còn lại.
class _PartlyBrokenSource extends FakeRecipeSource {
  @override
  Future<RecipeDetailResponse> getRecipe(String id) {
    if (id == 'r2') return Future.error(StateError('hidden'));
    return super.getRecipe(id);
  }
}

AuthViewModel _vm(MockAuthService auth, {IUserProfileService? profile}) =>
    AuthViewModel(auth: auth, analytics: MockAnalyticsService(), crash: MockCrashReporter(), profile: profile)
      ..start();

Map<String, dynamic> _recipeDoc(String code, String name, {String status = 'published'}) => {
      'code': code,
      'name': name,
      'description': 'Mô tả $name',
      'status': status,
      'versionNumber': 1,
      'ingredients': [
        {'name': 'Espresso', 'quantity': 40, 'unit': 'ml'},
      ],
      'steps': [
        {'title': 'Chiết xuất', 'description': '2 shot', 'durationSeconds': 28, 'equipment': 'Máy', 'safetyNote': 'Nóng'},
      ],
      'searchKeywords': FirestoreRecipeSource.normalize('$name $code').split(' '),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 11, 5)),
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthViewModel', () {
    test('RF-01 đăng xuất KHÔNG treo khi xóa thiết bị không bao giờ xong (offline)', () async {
      final auth = MockAuthService();
      final vm = _vm(auth);
      final notif = NotificationViewModel(service: MockNotificationService(), crash: MockCrashReporter(), devices: _HangingRegistry());
      vm.addBeforeSignOut(notif.unregisterDevice);
      await _settle();
      await vm.signInWithGoogle();
      await notif.start(roleCode: 'viewer', storeCode: 'Q1', uid: vm.user!.uid);
      await _settle();
      final sw = Stopwatch()..start();
      await vm.signOut();
      expect(vm.status, AuthStatus.unauthenticated);
      expect(sw.elapsed, lessThan(const Duration(seconds: 12)));
    });

    test('RF-02 chưa vào màn chính trước khi server xác nhận; bị khóa ngay lúc đồng bộ → không bao giờ authenticated', () async {
      final profile = _SlowProfile(role: 'admin');
      final vm = _vm(MockAuthService(), profile: profile);
      await _settle();
      final signIn = vm.signInWithGoogle();
      await _settle();
      expect(vm.status, isNot(AuthStatus.authenticated));
      profile.gate.complete();
      await signIn;
      await _settle();
      expect(vm.status, AuthStatus.authenticated);
      expect(vm.isAdmin, isTrue);
      expect(profile.syncCalls, 1, reason: 'authStateChanges và signIn dùng chung một lần đồng bộ');

      final locked = _SlowProfile()..disabled = true;
      final vm2 = _vm(MockAuthService(), profile: locked);
      await _settle();
      final f = vm2.signInWithGoogle();
      locked.gate.complete();
      await f;
      await _settle();
      expect(vm2.status, AuthStatus.unauthenticated);
      expect(vm2.lastFailure, AuthFailureCode.disabled);
    });

    test('RF-03 SDK tự đăng xuất (token bị thu hồi) → dọn phiên; đăng nhập lại đồng bộ lại từ đầu', () async {
      final auth = MockAuthService();
      final profile = MockUserProfileService(role: 'admin');
      final vm = _vm(auth, profile: profile);
      await _settle();
      await vm.signInWithGoogle();
      await _settle();
      expect(vm.isAdmin, isTrue);
      await auth.signOut(); // không qua ViewModel
      await _settle();
      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.isAdmin, isFalse);
      profile.role = 'viewer';
      await vm.signInWithGoogle();
      await _settle();
      expect(profile.syncCalls, 2);
      expect(vm.isAdmin, isFalse);
    });

    test('RF-04 làm mới token lỗi khi vai trò đổi → không crash, dùng vai trò Firestore; khóa 2 lần chỉ đăng xuất 1 lần', () async {
      final profile = _SlowProfile(role: 'viewer')..failRefresh = true;
      profile.gate.complete();
      final analytics = MockAnalyticsService();
      final vm = AuthViewModel(auth: MockAuthService(), analytics: analytics, crash: MockCrashReporter(), profile: profile)
        ..start();
      await _settle();
      await vm.signInWithGoogle();
      await _settle();
      profile.emit(const ProfileState(role: 'viewer', disabled: false, claimsVersion: 1));
      await _settle();
      profile.emit(const ProfileState(role: 'admin', disabled: false, claimsVersion: 2));
      await _settle();
      expect(vm.isAdmin, isTrue);
      profile.emit(const ProfileState(role: 'admin', disabled: true));
      profile.emit(const ProfileState(role: 'admin', disabled: true));
      await _settle(50);
      expect(analytics.eventNames.where((e) => e == 'logout'), hasLength(1));
    });
  });

  group('NotificationViewModel', () {
    test('RF-05 lịch sử thông báo tách theo người dùng', () async {
      final service = MockNotificationService();
      final vm = NotificationViewModel(service: service, crash: MockCrashReporter(), devices: MockDeviceRegistry());
      await vm.start(roleCode: 'viewer', storeCode: 'Q1', uid: 'A');
      service.simulateForeground(AppNotification(id: 'n1', title: 'Riêng A', body: '', receivedAt: DateTime.now()));
      await _settle();
      expect(vm.items, hasLength(1));
      await vm.reset();
      await vm.start(roleCode: 'viewer', storeCode: 'Q1', uid: 'B');
      await _settle();
      expect(vm.items, isEmpty, reason: 'B không thấy thông báo của A');
    });

    test('RF-06 vai trò đổi → đổi topic role_*', () async {
      final vm = NotificationViewModel(service: MockNotificationService(), crash: MockCrashReporter());
      await vm.start(roleCode: 'viewer', storeCode: 'Q1', uid: 'A');
      await _settle();
      expect(vm.topics, contains('role_viewer'));
      await vm.updateRole('admin');
      expect(vm.topics, contains('role_admin'));
      expect(vm.topics, isNot(contains('role_viewer')));
    });
  });

  group('Sự cố', () {
    test('RF-07 cùng id gửi 2 lần không trùng; gửi bù chỉ sau khi đăng nhập', () async {
      final r = MockIncidentReporter();
      final rep = IncidentReport(kind: IncidentKind.fatal, source: IncidentSource.flutterError, message: 'x');
      await r.report(rep);
      await r.report(rep);
      expect(r.reported, hasLength(1));
      await r.stashForNextLaunch(IncidentReport(kind: IncidentKind.fatal, source: IncidentSource.platformError, message: 'y'));
      r.scheduleFlush(crashedLastRun: true);
      expect(r.flushCount, 0, reason: 'chưa đăng nhập → chưa gửi');
      r.setUser(uid: 'u1', email: 'a@x.com');
      await _settle();
      expect(r.flushCount, 1);
      expect(r.reported.map((e) => e.message), contains('y'));
    });

    test('RF-08 Firestore reporter: id = document id; gửi bù không đổi người dùng hiện tại; stash người khác gửi ẩn danh', () async {
      final db = FakeFirebaseFirestore();
      final reporter = FirestoreIncidentReporter(firestore: db);
      reporter.setUser(uid: 'u1', email: 'u1@x.com');
      await reporter.stashForNextLaunch(IncidentReport(kind: IncidentKind.fatal, source: IncidentSource.flutterError, message: 'cũ của u1'));
      reporter.setUser(uid: 'u2', email: 'u2@x.com');
      final rep = IncidentReport(kind: IncidentKind.nonFatal, source: IncidentSource.nonFatalReport, message: 'mới');
      expect(await reporter.report(rep), isTrue);
      final doc = (await db.doc('incidents/${rep.id}').get()).data()!;
      expect(doc['uid'], 'u2');
      expect(doc['status'], 'open');
      expect(await reporter.flushPending(crashedLastRun: false), 1);
      final all = (await db.collection('incidents').get()).docs.map((d) => d.data()).toList();
      final old = all.firstWhere((d) => d['message'] == 'cũ của u1');
      expect(old['uid'], isNull, reason: 'rules chỉ cho ghi uid của chính mình');
      final rep2 = IncidentReport(kind: IncidentKind.nonFatal, source: IncidentSource.nonFatalReport, message: 'sau flush');
      await reporter.report(rep2);
      expect((await db.doc('incidents/${rep2.id}').get()).data()!['uid'], 'u2', reason: 'flush không xóa người dùng hiện tại');
      await reporter.stashForNextLaunch(rep2);
      await reporter.removeStashed(rep2.id);
      expect(await reporter.flushPending(crashedLastRun: false), 0);
    });

    test('RF-09 crash lần trước: gửi previous_crash một lần; nút demo đã báo thì không', () async {
      final db = FakeFirebaseFirestore();
      final reporter = FirestoreIncidentReporter(firestore: db)..setUser(uid: 'u', email: 'u@x.com');
      expect(await reporter.flushPending(crashedLastRun: true), 1);
      await reporter.markCrashAlreadyReported();
      expect(await reporter.flushPending(crashedLastRun: true), 0);
      expect((await db.collection('incidents').get()).docs.single.data()['source'], 'previous_crash');
    });
  });

  group('Công thức', () {
    test('RF-10 offline chưa có dữ liệu → lỗi mạng, không phải "chưa có món"', () async {
      final vm = RecipeViewModel(source: _OfflineSource(), crash: MockCrashReporter());
      await vm.load();
      expect(vm.state, ViewState.error);
      expect(vm.error, contains('mạng'));
    });

    test('RF-11 một món lỗi không làm hỏng cả danh sách', () async {
      final vm = RecipeViewModel(source: _PartlyBrokenSource(), crash: MockCrashReporter());
      await vm.load();
      expect(vm.state, ViewState.ready);
      expect(vm.items.map((r) => r.code), isNot(contains('RC-CFE-01')));
      expect(vm.items, isNotEmpty);
    });

    test('RF-12 FirestoreRecipeSource: tải một lần đủ chi tiết, deep link đọc thẳng theo mã, món ẩn bị chặn', () async {
      final db = FakeFirebaseFirestore();
      for (final (code, name) in [('CF-A1', 'Cà Phê A'), ('CF-A2', 'Cà Phê B'), ('CF-A3', 'Cà Phê C'), ('CF-A4', 'Cà Phê D'), ('CF-A5', 'Cà Phê E'), ('CF-BACXIU', 'Bạc Xỉu')]) {
        await db.doc('recipes/$code').set(_recipeDoc(code, name));
      }
      await db.doc('recipes/TS-HIDE').set(_recipeDoc('TS-HIDE', 'Ẩn', status: 'hidden'));
      final src = FirestoreRecipeSource(firestore: db);
      final details = await src.loadPublishedDetails(limit: 50);
      expect(details, hasLength(6));
      expect(details.first.steps.single.equipment, 'Máy');
      final vm = RecipeViewModel(source: src, crash: MockCrashReporter());
      await vm.load(limit: 2);
      expect(vm.items, hasLength(2));
      final found = await vm.findForDeepLink('CF-BACXIU');
      expect(found?.name, 'Bạc Xỉu');
      expect(found?.category, 'Cà phê & Cold Brew');
      expect(await vm.findForDeepLink('TS-HIDE'), isNull);
      final search = await src.searchApproved(query: 'bạc xỉu');
      expect(search.items.single.code, 'CF-BACXIU');
      expect(() => src.getRecipe('TS-HIDE'), throwsStateError);
    });

    test('RF-13 nhóm món theo tiền tố mã; RecipeItem so sánh theo id', () {
      expect(RecipeMapper.categoryOf('Bạc Xỉu', code: 'CF-BACXIU'), 'Cà phê & Cold Brew');
      expect(RecipeMapper.categoryOf('Matcha', code: 'TS-MATCHA'), 'Trà Sữa & Kem Mây');
      expect(RecipeMapper.categoryOf('Đào', code: 'TT-DAO'), 'Trà Trái Cây');
      expect(RecipeMapper.categoryOf('Bạc xỉu đá'), 'Cà phê & Cold Brew');
      final a = RecipeMapper.fromDetail(FakeRecipeSource.detail('r-1', 'RC-1', 'A'));
      final b = RecipeMapper.fromDetail(FakeRecipeSource.detail('r-1', 'RC-1', 'A'));
      expect(a, b);
      expect({a, b}, hasLength(1));
    });
  });

  group('Thiết bị + hồ sơ (Firestore giả)', () {
    test('RF-14 đăng ký / gỡ thiết bị theo hash token', () async {
      final db = FakeFirebaseFirestore();
      final reg = FirestoreDeviceRegistry(firestore: db);
      await reg.register('u1', 'tok:abc');
      final id = FirestoreDeviceRegistry.deviceIdOf('tok:abc');
      expect(id, hasLength(32));
      final d = (await db.doc('users/u1/devices/$id').get()).data()!;
      expect(d['token'], 'tok:abc');
      expect(d.keys, containsAll(['platform', 'model', 'osVersion', 'appVersion', 'updatedAt']));
      await reg.unregister('u1', 'tok:abc');
      expect((await db.doc('users/u1/devices/$id').get()).exists, isFalse);
    });

    test('RF-15 hồ sơ: ensureProfile + làm mới token khi cần; nghe khóa / đổi vai trò', () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'u1@x.com', customClaim: {'role': 'admin'}));
      final calls = <String>[];
      final svc = FirebaseUserProfileService(
        auth: auth,
        firestore: db,
        call: (name) async {
          calls.add(name);
          return {'role': 'admin', 'disabled': false, 'refreshToken': true};
        },
      );
      final state = await svc.sync();
      expect(calls, ['ensureProfile']);
      expect(state.isAdmin, isTrue);
      await db.doc('users/u1').set({'role': 'viewer', 'disabled': false, 'claimsUpdatedAt': Timestamp.fromMillisecondsSinceEpoch(5)});
      final events = <ProfileState>[];
      final sub = svc.watch('u1').listen(events.add);
      await _settle();
      await db.doc('users/u1').update({'disabled': true});
      await _settle();
      await sub.cancel();
      expect(events.first.role, 'viewer');
      expect(events.first.claimsVersion, 5);
      expect(events.last.disabled, isTrue);
    });
  });

  group('Lịch sử tự luyện', () {
    SelfPracticeRecord rec(String id, int secs, int target) => SelfPracticeRecord(
          id: id, recipeName: 'Muối', recipeCode: 'CF-MUOI', size: 'M', durationSeconds: secs, notes: '',
          practicedAt: '05/11/2026 10:00', targetSeconds: target,
        );

    test('RF-16 lưu bền theo uid qua SharedPreferences; tỷ lệ đạt thời gian chuẩn', () async {
      final store = PrefsPracticeHistoryStore();
      final vm = PracticeHistoryViewModel(store: store, crash: MockCrashReporter());
      await vm.load('u1');
      expect(vm.withinTolerancePercent, isNull);
      await vm.add(rec('a', 30, 30));
      await vm.add(rec('b', 50, 30));
      await vm.add(rec('c', 40, 0));
      expect(vm.withinTolerancePercent, 50);
      expect(vm.averageSeconds, 40);
      final again = PracticeHistoryViewModel(store: store, crash: MockCrashReporter());
      await again.load('u1');
      expect(again.records.map((r) => r.id), ['c', 'b', 'a']);
      await again.load('u2');
      expect(again.records, isEmpty);
    });

    test('RF-17 thêm bản ghi khi lịch sử đang tải không ghi đè dữ liệu cũ', () async {
      final store = MockPracticeHistoryStore()..data['u1'] = [rec('old', 10, 0)];
      final vm = PracticeHistoryViewModel(store: store, crash: MockCrashReporter());
      final loading = vm.load('u1');
      await vm.add(rec('new', 20, 0));
      await loading;
      expect(store.data['u1']!.map((r) => r.id), ['new', 'old']);
      vm.clear();
      expect(vm.records, isEmpty);
    });
  });
}
